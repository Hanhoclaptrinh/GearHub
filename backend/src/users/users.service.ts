import { ConflictException, Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { Role } from '@prisma/client';

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
}
