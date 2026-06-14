import { BadRequestException, ConflictException, Injectable, NotFoundException, Logger } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { Prisma, Role, UserStatus } from '@prisma/client';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UpdateUserStatusDto } from './dto/update-user-status.dto';
import { UpdateUserRoleDto } from './dto/update-user-role.dto';
import { MailService } from 'src/mail/mail.service';
import { RedisService } from 'src/redis/redis.service';
import { UpdatePreferencesDto } from './dto/update-preferences.dto';
import { EmbeddingService } from 'src/ai/embedding.service';

export interface ICreateUser {
  email: string;
  password?: string;
  fullName: string;
  phone?: string;
  role?: Role;
  avatarUrl?: string;
}

type ShoppingPreferences = {
  categoryIds: string[];
  brandIds: string[];
  styleTags: string[];
  useCases: string[];
  budgetRange: {
    min: number | null;
    max: number | null;
  } | null;
  updatedAt: string | null;
  completedAt: string | null;
  skippedAt: string | null;
  preferenceVector?: number[];
};

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    private prisma: PrismaService,
    private mailService: MailService,
    private redisService: RedisService,
    private embeddingService: EmbeddingService
  ) { }

  private readonly emailChangeOtpTtlSeconds = 300;

  private getEmailChangeKey(userId: string) {
    return `email_change:${userId}`;
  }

  private getDefaultPreferences(): ShoppingPreferences {
    return {
      categoryIds: [],
      brandIds: [],
      styleTags: [],
      useCases: [],
      budgetRange: null,
      updatedAt: null,
      completedAt: null,
      skippedAt: null,
      preferenceVector: []
    };
  }

  private normalizeStringList(values?: string[]) {
    if (!values) return undefined;

    return [...new Set(values.map((value) => value.trim()).filter(Boolean))];
  }

  private normalizePreferences(preferences: Prisma.JsonValue | null | undefined): ShoppingPreferences {
    if (!preferences || typeof preferences !== 'object' || Array.isArray(preferences)) {
      return this.getDefaultPreferences();
    }

    const data = preferences as Record<string, unknown>;
    const budgetRange = data.budgetRange as Record<string, unknown> | null | undefined;

    return {
      categoryIds: Array.isArray(data.categoryIds) ? data.categoryIds.filter((id): id is string => typeof id === 'string') : [],
      brandIds: Array.isArray(data.brandIds) ? data.brandIds.filter((id): id is string => typeof id === 'string') : [],
      styleTags: Array.isArray(data.styleTags) ? data.styleTags.filter((tag): tag is string => typeof tag === 'string') : [],
      useCases: Array.isArray(data.useCases) ? data.useCases.filter((useCase): useCase is string => typeof useCase === 'string') : [],
      budgetRange: budgetRange && typeof budgetRange === 'object'
        ? {
          min: typeof budgetRange.min === 'number' ? budgetRange.min : null,
          max: typeof budgetRange.max === 'number' ? budgetRange.max : null
        }
        : null,
      updatedAt: typeof data.updatedAt === 'string' ? data.updatedAt : null,
      completedAt: typeof data.completedAt === 'string' ? data.completedAt : null,
      skippedAt: typeof data.skippedAt === 'string' ? data.skippedAt : null,
      preferenceVector: Array.isArray(data.preferenceVector)
        ? data.preferenceVector.filter((v): v is number => typeof v === 'number')
        : []
    };
  }

  /**
   * tạo user mới trong hệ thống
   * tự động check trùng email và số điện thoại, nếu trùng sẽ báo lỗi
   */
  async createNewUser(data: ICreateUser) {
    const existingUser = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email: data.email },
          ...(data.phone ? [{ profile: { phone: data.phone } }] : [])
        ]
      },
      include: { profile: true }
    });

    if (existingUser) {
      const isEmailDup = existingUser.email === data.email;
      throw new ConflictException(
        isEmailDup ? 'Email đã được sử dụng' : 'Số điện thoại đã được sử dụng'
      );
    }

    const newUser = await this.prisma.user.create({
      data: {
        email: data.email,
        password: data.password || '',
        role: data.role || Role.USER,
        profile: {
          create: {
            fullName: data.fullName,
            phone: data.phone || null,
            avatarUrl: data.avatarUrl || null
          }
        }
      },
      select: {
        id: true,
        email: true,
        role: true,
        profile: {
          select: {
            fullName: true,
            phone: true,
            avatarUrl: true,
            dateOfBirth: true,
            gender: true
          }
        }
      }
    });

    return newUser;
  }

  // lấy danh sách user kèm phân trang, tìm kiếm và bộ lọc (role, status)
  async getAllUsers(query: { page?: number; limit?: number; search?: string; role?: Role, status?: UserStatus }) {
    const { page = 1, limit = 10, search, role, status } = query;
    const skip = (page - 1) * limit;

    const where: any = {}; // tự động build filter

    if (role) {
      where.role = role;
    }

    if (status) {
      where.status = status;
    }

    if (search) {
      where.OR = [
        { email: { contains: search } },
        { profile: { fullName: { contains: search } } },
        { profile: { phone: { contains: search } } },
      ];
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: Number(limit),
        include: {
          profile: true,
          _count: {
            select: { orders: true } // xem user đã mua bao nhiêu đơn
          }
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.user.count({ where }),
    ]);

    // lấy tổng chi tiêu cho từng user trong trang
    // các đơn có trạng thái thanh toán là PAID || trạng thái đơn là DELIVERED || COMPLETED
    const userIds = users.map((u) => u.id);
    // thực hiện gom nhóm theo user id tránh n+1
    const spentGroups = userIds.length > 0
      ? await this.prisma.order.groupBy({
        by: ['userId'],
        where: {
          userId: { in: userIds },
          OR: [
            { paymentStatus: 'PAID' },
            { status: 'DELIVERED' },
            { status: 'COMPLETED' },
          ],
        },
        _sum: { totalAmount: true },
      })
      : [];

    // map userId -> totalSpent
    const spentMap = new Map(
      spentGroups.map((g) => [g.userId, g._sum.totalAmount ?? 0])
    );

    // map về dạng k-v
    // user : spent
    const usersWithSpent = users.map((u) => ({
      ...u,
      totalSpent: spentMap.get(u.id) ?? 0,
    }));

    return {
      data: usersWithSpent,
      meta: {
        total,
        page: Number(page),
        lastPage: Math.ceil(total / limit),
      },
    };
  }

  // tìm user bằng email hoặc số điện thoại
  async findByEmailOrPhone(identifier: string) {
    return await this.prisma.user.findFirst({
      where: {
        OR: [
          { email: identifier },
          { profile: { phone: identifier } }
        ]
      },
      include: { profile: true }
    });
  }

  // tìm user theo id
  async findByUserId(id: string) {
    return await this.prisma.user.findUnique({
      where: { id },
      include: { profile: true }
    })
  }

  async updatePassword(id: string, hashedPass: string) {
    return await this.prisma.user.update({
      where: { id },
      data: { password: hashedPass },
    });
  }

  /**
   * cập nhật hồ sơ cá nhân của người dùng
   * nếu thay đổi email thì cần gửi otp xác thực trước khi cập nhật chính thức
   */
  async updateProfile(id: string, data: UpdateProfileDto) {
    if (data.phone) {
      // kiểm tra xem số điện thoại đã được người khác sử dụng chưa
      const existingUser = await this.prisma.user.findFirst({
        where: {
          profile: { phone: data.phone },
          NOT: { id }
        }
      });

      if (existingUser) {
        throw new ConflictException('Số điện thoại đã được sử dụng');
      }
    }

    const { email, dateOfBirth, ...profileData } = data;
    let pendingEmail: string | null = null;

    const currentUser = email
      ? await this.prisma.user.findUnique({ where: { id }, select: { email: true } })
      : null;

    if (email && !currentUser) {
      throw new NotFoundException(`Không tìm thấy người dùng với ID: ${id}`);
    }

    // nếu đổi sang email mới khác email hiện tại thì cần xác thực qua otp
    if (email && currentUser && email !== currentUser.email) {
      const existingEmailUser = await this.prisma.user.findFirst({
        where: {
          email,
          NOT: { id }
        }
      });

      if (existingEmailUser) {
        throw new ConflictException('Email đã được sử dụng');
      }

      const otp = Math.floor(100000 + Math.random() * 900000).toString();

      // lưu email mới và mã otp tạm thời vào redis
      await this.redisService.set(
        this.getEmailChangeKey(id),
        JSON.stringify({ email, otp }),
        'EX',
        this.emailChangeOtpTtlSeconds
      );

      // gửi mail thông báo otp đổi email
      await this.mailService.sendChangeEmailOtp(email, otp);

      pendingEmail = email;
    }

    if (dateOfBirth) {
      const birthday = new Date(dateOfBirth.split('T')[0]);

      if (birthday > new Date()) {
        throw new BadRequestException('Ngày sinh không được lớn hơn ngày hiện tại');
      }
    }

    const profileUpdateData = {
      ...profileData,
      ...(dateOfBirth !== undefined && {
        dateOfBirth: dateOfBirth ? new Date(dateOfBirth.split('T')[0]) : null,
      }),
    };
    const hasProfileUpdate = Object.keys(profileUpdateData).length > 0;

    const userSelect = {
      id: true,
      email: true,
      role: true,
      profile: {
        select: {
          fullName: true,
          phone: true,
          avatarUrl: true,
          dateOfBirth: true,
          gender: true,
          preferences: true
        }
      }
    } as const;

    // chỉ cập nhật db nếu có thay đổi thông tin profile
    const user = hasProfileUpdate
      ? await this.prisma.user.update({
        where: { id },
        data: {
          profile: {
            update: {
              ...profileUpdateData
            }
          }
        },
        select: userSelect
      })
      : await this.prisma.user.findUnique({
        where: { id },
        select: userSelect
      });

    if (!user) {
      throw new NotFoundException(`Không tìm thấy người dùng với ID: ${id}`);
    }

    return {
      ...user,
      pendingEmail,
      emailChangeOtpSent: Boolean(pendingEmail)
    };
  }

  /**
   * xác thực otp và hoàn tất quá trình đổi email mới cho người dùng
   */
  async verifyEmailChange(id: string, otp: string) {
    const key = this.getEmailChangeKey(id);
    const rawData = await this.redisService.get(key);

    if (!rawData) {
      throw new BadRequestException('Yêu cầu đổi email đã hết hạn, vui lòng thử lại');
    }

    const pendingData = JSON.parse(rawData) as { email: string; otp: string };

    if (pendingData.otp !== otp) {
      throw new BadRequestException('Mã OTP không đúng');
    }

    // kiểm tra lại tính khả dụng của email mới lần cuối trước khi cập nhật
    const existingEmailUser = await this.prisma.user.findFirst({
      where: {
        email: pendingData.email,
        NOT: { id }
      }
    });

    if (existingEmailUser) {
      await this.redisService.del(key);
      throw new ConflictException('Email đã được sử dụng');
    }

    // cập nhật email mới
    const user = await this.prisma.user.update({
      where: { id },
      data: { email: pendingData.email },
      select: {
        id: true,
        email: true,
        role: true,
        profile: {
          select: {
            fullName: true,
            phone: true,
            avatarUrl: true,
            dateOfBirth: true,
            gender: true,
            preferences: true
          }
        }
      }
    });

    // xóa otp đã sử dụng
    await this.redisService.del(key);

    return user;
  }

  /**
   * lấy sở thích mua sắm của người dùng
   */
  async getPreferences(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        profile: {
          select: {
            preferences: true
          }
        }
      }
    });

    if (!user) {
      throw new NotFoundException(`Không tìm thấy người dùng với ID: ${id}`);
    }

    return this.normalizePreferences(user.profile?.preferences);
  }

  /**
   * cập nhật hoặc khởi tạo sở thích mua sắm của người dùng
   */
  async updatePreferences(id: string, data: UpdatePreferencesDto) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        profile: {
          select: {
            preferences: true
          }
        }
      }
    });

    if (!user) {
      throw new NotFoundException(`Không tìm thấy người dùng với ID: ${id}`);
    }

    const currentPreferences = this.normalizePreferences(user.profile?.preferences);
    const categoryIds = data.categoryIds ? [...new Set(data.categoryIds)] : undefined;
    const brandIds = data.brandIds ? [...new Set(data.brandIds)] : undefined;
    const styleTags = this.normalizeStringList(data.styleTags);
    const useCases = this.normalizeStringList(data.useCases);

    // kiểm tra các danh mục có tồn tại hay không
    if (categoryIds) {
      const existingCategories = await this.prisma.category.findMany({
        where: { id: { in: categoryIds } },
        select: { id: true }
      });

      if (existingCategories.length !== categoryIds.length) {
        throw new BadRequestException('Một hoặc nhiều danh mục không tồn tại');
      }
    }

    // kiểm tra các thương hiệu có tồn tại hay không
    if (brandIds) {
      const existingBrands = await this.prisma.brand.findMany({
        where: { id: { in: brandIds } },
        select: { id: true }
      });

      if (existingBrands.length !== brandIds.length) {
        throw new BadRequestException('Một hoặc nhiều thương hiệu không tồn tại');
      }
    }

    let budgetRange = currentPreferences.budgetRange;

    // tính toán khoảng ngân sách mua sắm
    if (data.budgetRange !== undefined) {
      const min = data.budgetRange.min ?? null;
      const max = data.budgetRange.max ?? null;

      if (min !== null && max !== null && min > max) {
        throw new BadRequestException('Ngân sách tối thiểu không được lớn hơn ngân sách tối đa');
      }

      budgetRange = min === null && max === null ? null : { min, max };
    }

    const now = new Date().toISOString();
    const hasSelectionUpdate =
      categoryIds !== undefined ||
      brandIds !== undefined ||
      styleTags !== undefined ||
      useCases !== undefined ||
      data.budgetRange !== undefined;

    const shouldMarkCompleted = data.completed === true || (hasSelectionUpdate && data.skipped !== true);

    const nextPreferences: ShoppingPreferences = {
      categoryIds: categoryIds ?? currentPreferences.categoryIds,
      brandIds: brandIds ?? currentPreferences.brandIds,
      styleTags: styleTags ?? currentPreferences.styleTags,
      useCases: useCases ?? currentPreferences.useCases,
      budgetRange,
      updatedAt: now,
      completedAt: shouldMarkCompleted ? (currentPreferences.completedAt ?? now) : currentPreferences.completedAt,
      skippedAt: data.skipped === true ? now : currentPreferences.skippedAt,
      preferenceVector: currentPreferences.preferenceVector ?? []
    };

    if (shouldMarkCompleted && hasSelectionUpdate) {
      const targetCategoryIds = nextPreferences.categoryIds;
      const targetBrandIds = nextPreferences.brandIds;

      const categoryNames: string[] = [];
      if (targetCategoryIds.length > 0) {
        const categories = await this.prisma.category.findMany({
          where: { id: { in: targetCategoryIds } },
          select: { name: true }
        });
        categoryNames.push(...categories.map((c) => c.name));
      }

      const brandNames: string[] = [];
      if (targetBrandIds.length > 0) {
        const brands = await this.prisma.brand.findMany({
          where: { id: { in: targetBrandIds } },
          select: { name: true }
        });
        brandNames.push(...brands.map((b) => b.name));
      }

      const preferenceTextParts: string[] = [];
      if (categoryNames.length > 0) {
        preferenceTextParts.push(`Danh mục yêu thích: ${categoryNames.join(', ')}`);
      }
      if (brandNames.length > 0) {
        preferenceTextParts.push(`Thương hiệu ưu tiên: ${brandNames.join(', ')}`);
      }
      if (nextPreferences.styleTags.length > 0) {
        preferenceTextParts.push(`Phong cách và thiết kế ưa chuộng: ${nextPreferences.styleTags.join(', ')}`);
      }
      if (nextPreferences.useCases.length > 0) {
        preferenceTextParts.push(`Mục đích sử dụng chính: ${nextPreferences.useCases.join(', ')}`);
      }

      if (preferenceTextParts.length > 0) {
        const textToEmbed = preferenceTextParts.join('\n');
        try {
          const vector = await this.embeddingService.embedText(textToEmbed);
          nextPreferences.preferenceVector = vector;
        } catch (error) {
          this.logger.warn(`Failed to generate preference vector: ${error.message}`);
        }
      }
    }

    // cập nhật hoặc tạo mới preferences trong db
    const profile = await this.prisma.profile.upsert({
      where: { userId: id },
      create: {
        userId: id,
        preferences: nextPreferences as Prisma.InputJsonValue
      },
      update: {
        preferences: nextPreferences as Prisma.InputJsonValue
      },
      select: {
        preferences: true
      }
    });

    return this.normalizePreferences(profile.preferences);
  }

  /**
   * cập nhật trạng thái hoạt động của user (ACTIVE, BANNED...)
   * chặn admin tự khóa chính mình
   */
  async updateUserStatus(id: string, data: UpdateUserStatusDto, adminId: string) {
    // chặn admin tự khóa chính mình
    if (id === adminId && data.status === UserStatus.BANNED) {
      throw new BadRequestException('Bạn không thể tự khóa tài khoản của chính mình');
    }

    const user = await this.prisma.user.findUnique({
      where: { id }
    });

    if (!user) throw new NotFoundException(`Không tìm thấy người dùng với ID: ${id}`);

    return await this.prisma.user.update({
      where: { id },
      data: {
        status: data.status
      },
      include: {
        profile: true,
        _count: {
          select: { orders: true }
        }
      }
    });
  }

  /**
   * cập nhật quyền/vai trò của user (ADMIN, STAFF, USER)
   * chặn admin tự hạ quyền của chính mình
   */
  async updateUserRole(id: string, data: UpdateUserRoleDto, adminId: string) {
    // chặn admin tự hạ quyền
    if (id === adminId && data.role !== Role.ADMIN) {
      throw new BadRequestException('Bạn không thể tự hạ quyền Admin của chính mình');
    }

    const user = await this.prisma.user.findUnique({
      where: { id }
    });

    if (!user) throw new NotFoundException(`Không tìm thấy người dùng với ID: ${id}`);

    return await this.prisma.user.update({
      where: { id },
      data: {
        role: data.role
      },
      include: {
        profile: true,
        _count: {
          select: { orders: true }
        }
      }
    });
  }


  // lấy stats user cho trang admin
  async getUserStats() {
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const [
      total,
      active,
      admins,
      banned,
      customers,
      activeCustomers,
      inactiveCustomers,
      bannedCustomers,
      newCustomersThisMonth,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { status: UserStatus.ACTIVE } }),
      this.prisma.user.count({ where: { role: Role.ADMIN } }),
      this.prisma.user.count({ where: { status: UserStatus.BANNED } }),
      this.prisma.user.count({ where: { role: Role.USER } }),
      this.prisma.user.count({ where: { role: Role.USER, status: UserStatus.ACTIVE } }),
      this.prisma.user.count({ where: { role: Role.USER, status: UserStatus.INACTIVE } }),
      this.prisma.user.count({ where: { role: Role.USER, status: UserStatus.BANNED } }),
      this.prisma.user.count({ where: { role: Role.USER, createdAt: { gte: startOfMonth } } }),
    ]);

    return {
      total,
      active,
      admins,
      banned,
      customers,
      activeCustomers,
      inactiveCustomers,
      bannedCustomers,
      newCustomersThisMonth,
    };
  }

  async getDetailedUser(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        profile: true,
        orders: {
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: {
            _count: { select: { items: true } }
          }
        },
        activityLogs: {
          take: 10,
          orderBy: { createdAt: 'desc' }
        }
      }
    });

    if (!user) throw new NotFoundException(`Không tìm thấy người dùng với ID: ${id}`);

    // tính toán thống kê chi tiêu
    const [totalAggregate, spentAggregate] = await Promise.all([
      this.prisma.order.aggregate({
        where: { userId: id },
        _count: { id: true }
      }),
      this.prisma.order.aggregate({
        where: {
          userId: id,
          OR: [
            { paymentStatus: 'PAID' },
            { status: 'DELIVERED' }
          ]
        },
        _sum: { totalAmount: true }
      })
    ]);

    return {
      ...user,
      stats: {
        totalSpent: spentAggregate._sum.totalAmount || 0,
        totalOrders: totalAggregate._count.id || 0,
        successfulOrders: spentAggregate._sum.totalAmount ? spentAggregate._sum.totalAmount : 0,
      }
    };
  }
}
