import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma, NotificationType } from '@prisma/client';
import * as admin from 'firebase-admin';
import { PrismaService } from 'src/prisma/prisma.service';
import { RegisterFcmTokenDto } from './dto/register-fcm-token.dto';

@Injectable()
export class NotificationService implements OnModuleInit {
  private readonly logger = new Logger(NotificationService.name);
  private firebaseReady = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) { }

  onModuleInit() {
    this.initializeFirebase();
  }

  async registerToken(userId: string, data: RegisterFcmTokenDto) {
    const deviceType = data.deviceType?.trim() || null;

    await this.prisma.fcmToken.upsert({
      where: { token: data.token },
      update: {
        userId,
        deviceType,
      },
      create: {
        userId,
        token: data.token,
        deviceType,
      },
    });

    return { success: true };
  }

  async deregisterToken(userId: string, token: string) {
    await this.prisma.fcmToken.deleteMany({
      where: {
        userId,
        token,
      },
    });

    return { success: true };
  }

  async sendToUser(userId: string, payload: PushPayload) {
    try {
      // lưu thông báo vào db
      const notification = await this.prisma.notification.create({
        data: {
          userId,
          title: payload.notification.title,
          body: payload.notification.body,
          type: payload.type || NotificationType.SYSTEM,
          data: payload.data ? JSON.parse(JSON.stringify(payload.data)) : null,
        },
      });

      if (!this.firebaseReady) {
        this.logger.warn('Firebase Admin is not configured; push skipped');
        return;
      }

      const tokens = await this.prisma.fcmToken.findMany({
        where: { userId },
        select: { token: true },
      });

      if (tokens.length === 0) return;

      const tokenValues = tokens.map((item) => item.token);

      const fcmData = {
        ...(payload.data || {}),
        notificationId: notification.id,
      };

      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokenValues,
        notification: payload.notification,
        data: this.stringifyData(fcmData),
        android: {
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      });

      const invalidTokens = response.responses
        .map((result, index) =>
          !result.success && this.isInvalidTokenError(result.error)
            ? tokenValues[index]
            : null,
        )
        .filter((token): token is string => Boolean(token));

      if (invalidTokens.length > 0) {
        await this.prisma.fcmToken.deleteMany({
          where: { token: { in: invalidTokens } },
        });
      }

      if (response.failureCount > invalidTokens.length) {
        this.logger.warn(
          `Push delivery had ${response.failureCount} failures for user=${userId}`,
        );
      }
    } catch (error) {
      this.logger.error(
        `Failed to send push to user=${userId}: ${this.errorMessage(error)}`,
      );
    }
  }

  async getUserNotifications(
    userId: string,
    query: { page?: number; limit?: number; type?: NotificationType },
  ) {
    const page = Number(query.page) || 1;
    const limit = Number(query.limit) || 10;
    const skip = (page - 1) * limit;

    const where: Prisma.NotificationWhereInput = {
      userId,
      ...(query.type && { type: query.type }),
    };

    const [notifications, total] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.notification.count({ where }),
    ]);

    const unreadCount = await this.prisma.notification.count({
      where: {
        userId,
        isRead: false,
        ...(query.type && { type: query.type }),
      },
    });

    return {
      data: notifications,
      meta: {
        total,
        unreadCount,
        page,
        lastPage: Math.ceil(total / limit),
      },
    };
  }

  async markAsRead(userId: string, id: string) {
    return await this.prisma.notification.updateMany({
      where: { id, userId, isRead: false },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  async markAllAsRead(userId: string) {
    return await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  async deleteNotification(userId: string, id: string) {
    return await this.prisma.notification.deleteMany({
      where: { id, userId },
    });
  }

  async clearAllNotifications(userId: string) {
    return await this.prisma.notification.deleteMany({
      where: { userId },
    });
  }

  private initializeFirebase() {
    if (admin.apps.length > 0) {
      this.firebaseReady = true;
      return;
    }

    try {
      const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
      const clientEmail = this.configService.get<string>(
        'FIREBASE_CLIENT_EMAIL',
      );
      const privateKey = this.configService
        .get<string>('FIREBASE_PRIVATE_KEY')
        ?.replace(/\\n/g, '\n');

      if (projectId && clientEmail && privateKey) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey,
          }),
        });
      } else {
        admin.initializeApp({
          credential: admin.credential.applicationDefault(),
        });
      }

      this.firebaseReady = true;
    } catch (error) {
      this.firebaseReady = false;
      this.logger.warn(
        `Firebase Admin initialization skipped: ${this.errorMessage(error)}`,
      );
    }
  }

  private stringifyData(data: Record<string, string | number | boolean>) {
    return Object.fromEntries(
      Object.entries(data).map(([key, value]) => [key, String(value)]),
    );
  }

  private isInvalidTokenError(error?: admin.FirebaseError) {
    const code = error?.code;
    return (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token' ||
      code === 'messaging/invalid-argument'
    );
  }

  private errorMessage(error: unknown) {
    return error instanceof Error ? error.message : String(error);
  }
}

export type PushPayload = {
  notification: {
    title: string;
    body: string;
  };
  data: Record<string, string | number | boolean>;
  type?: NotificationType;
};
