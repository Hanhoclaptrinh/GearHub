import { ConflictException, Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { Role } from '@prisma/client';
import { UpdateProfileDto } from './dto/update-profile.dto';

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

  async getAllUsers(query: { page?: number; limit?: number; search?: string; role?: Role }) {
    const { page = 1, limit = 10, search, role } = query;
    const skip = (page - 1) * limit;

    const where: any = {}; // auto filter

    if (role) {
      where.role = role;
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

  async findByUserId(userId: string) {
    return await this.prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true }
    })
  }

  async updatePassword(userId: string, hashedPass: string) {
    return await this.prisma.user.update({
      where: { id: userId },
      data: { password: hashedPass },
    });
  }

  async updateProfile(userId: string, data: UpdateProfileDto) {
    if (data.email || data.phone) {
      const existingUser = await this.prisma.user.findFirst({
        where: {
          OR: [
            { email: data.email },
            { profile: { phone: data.phone } }
          ],
          NOT: { id: userId }
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
      where: { id: userId },
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
}
