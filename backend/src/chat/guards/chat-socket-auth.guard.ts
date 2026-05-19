import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Role, UserStatus } from '@prisma/client';
import { PrismaService } from 'src/prisma/prisma.service';
import { SocketUser } from '../types/socket-user.type';
import { Socket } from 'socket.io';

type JwtPayload = {
  sub?: string;
  email?: string;
  role?: Role;
};

@Injectable()
export class ChatSocketAuthGuard {
  constructor(
    private readonly jwtService: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  async authenticate(socket: Socket): Promise<SocketUser> {
    const token = this.extractToken(socket);
    if (!token) {
      throw new UnauthorizedException('Thiếu socket auth token');
    }

    let payload: JwtPayload;
    try {
      payload = await this.jwtService.verifyAsync<JwtPayload>(token);
    } catch {
      throw new UnauthorizedException('Socket auth token không hợp lệ');
    }

    if (!payload.sub) {
      throw new UnauthorizedException('Socket auth payload không hợp lệ');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        email: true,
        role: true,
        status: true,
      },
    });

    if (!user || user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('Người dùng không hoạt động');
    }

    return {
      id: user.id,
      email: user.email,
      role: user.role,
    };
  }

  private extractToken(socket: Socket): string | null {
    const authToken = socket.handshake.auth?.token;
    if (typeof authToken === 'string' && authToken.trim()) {
      return authToken.trim();
    }

    const header = socket.handshake.headers.authorization;
    const authorization = Array.isArray(header) ? header[0] : header;
    if (authorization?.startsWith('Bearer ')) {
      return authorization.slice('Bearer '.length).trim();
    }

    return null;
  }
}
