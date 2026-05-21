import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { Role, UserStatus } from '@prisma/client';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UpdateUserStatusDto } from './dto/update-user-status.dto';
import { UpdateUserRoleDto } from './dto/update-user-role.dto';

export interface ICreateUser {
  email: string;
  password: string;
  fullName: string;
  phone: string;
  role?: Role;
}

@Injectable()
export class UsersService {
  constructor(
    private prisma: PrismaService
  ) { }

  async createNewUser(data: ICreateUser) {
    const existingUser = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email: data.email },
          { profile: { phone: data.phone } }
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
        password: data.password,
        role: data.role || Role.USER,
        profile: {
          create: {
            fullName: data.fullName,
            phone: data.phone
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

  async getAllUsers(query: { page?: number; limit?: number; search?: string; role?: Role, status?: UserStatus }) {
    const { page = 1, limit = 10, search, role, status } = query;
    const skip = (page - 1) * limit;

    const where: any = {}; // auto filter

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
            select: { orders: true } // xem user da mua bao nhieu don
          }
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data: users,
      meta: {
        total,
        page: Number(page),
        lastPage: Math.ceil(total / limit),
      },
    };
  }

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
            address: true,
            avatarUrl: true,
            preferences: true
          }
        }
      }
    });
  }

  async updateUserStatus(id: string, data: UpdateUserStatusDto, adminId: string) {
    // chan admin tu khoa chinh minh
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

  async updateUserRole(id: string, data: UpdateUserRoleDto, adminId: string) {
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

  async getUserStats() {
    const [total, active, admins, banned] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { status: UserStatus.ACTIVE } }),
      this.prisma.user.count({ where: { role: Role.ADMIN } }),
      this.prisma.user.count({ where: { status: UserStatus.BANNED } }),
    ]);

    return { total, active, admins, banned };
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

    // tinh toan thong ke
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
        successfulOrders: spentAggregate._sum.totalAmount ? spentAggregate._sum.totalAmount : 0, // day la vi du, ban co the tinh them count
      }
    };
  }
}

