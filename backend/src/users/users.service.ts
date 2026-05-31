import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { Role, UserStatus } from '@prisma/client';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UpdateUserStatusDto } from './dto/update-user-status.dto';
import { UpdateUserRoleDto } from './dto/update-user-role.dto';

export interface ICreateUser {
  email: string;
  password?: string;
  fullName: string;
  phone?: string;
  role?: Role;
  avatarUrl?: string;
}

@Injectable()
export class UsersService {
  constructor(
    private prisma: PrismaService
  ) { }

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
            avatarUrl: true
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

  async updateProfile(id: string, data: UpdateProfileDto) {
    if (data.email || data.phone) {
      const existingUser = await this.prisma.user.findFirst({
        where: {
          OR: [
            { email: data.email },
            { profile: { phone: data.phone } }
          ],
          NOT: { id }
        }
      });

      if (existingUser) {
        const isEmailDup = existingUser.email === data.email;
        throw new ConflictException(
          isEmailDup ? 'Email đã được sử dụng' : 'Số điện thoại đã được sử dụng'
        );
      }
    }

    const { email, ...profileData } = data;

    return await this.prisma.user.update({
      where: { id },
      data: {
        ...(email && { email }),
        profile: {
          update: {
            ...profileData
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
            preferences: true
          }
        }
      }
    });
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
