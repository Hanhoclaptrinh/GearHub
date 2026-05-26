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

  async onModuleInit() {
    this.initializeFirebase();
    await this.migrateExistingChatNotifications();
  }

  /**
   * chuyển đổi các thông báo tin nhắn cũ sang loại CHAT
   * 
   * lọc các thông báo cũ mang loại SYSTEM nhưng có dữ liệu dạng chat
   * cập nhật lại loại thông báo trong database để đồng bộ hiển thị
   */
  private async migrateExistingChatNotifications() {
    try {
      // thực hiện cập nhật hàng loạt các thông báo tin nhắn cũ sang loại CHAT
      const result = await this.prisma.notification.updateMany({
        where: {
          type: NotificationType.SYSTEM,
          data: {
            path: '$.type',
            equals: 'chat',
          },
        },
        data: {
          type: NotificationType.CHAT,
        },
      });
      if (result.count > 0) {
        this.logger.log(`Migrated ${result.count} legacy chat notifications to CHAT type.`);
      }
    } catch (error) {
      this.logger.error(`Failed to migrate legacy chat notifications: ${error instanceof Error ? error.message : error}`);
    }
  }

  /**
   * đăng ký hoặc cập nhật FCM token của thiết bị người dùng
   * 
   * làm sạch tên loại thiết bị gửi lên
   * thực hiện upsert token liên kết với tài khoản người dùng tương ứng
   */
  async registerToken(userId: string, data: RegisterFcmTokenDto) {
    const deviceType = data.deviceType?.trim() || null;

    // lưu hoặc cập nhật FCM token cho người dùng để chuẩn bị đẩy push notification
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

  /**
   * hủy đăng ký FCM token của người dùng (khi đăng xuất)
   * 
   * xóa bỏ token tương ứng trong db để dừng gửi push notification
   */
  async deregisterToken(userId: string, token: string) {
    await this.prisma.fcmToken.deleteMany({
      where: {
        userId,
        token,
      },
    });

    return { success: true };
  }

  /**
   * gửi thông báo đẩy đến người dùng và lưu lịch sử thông báo
   * 
   * lưu bản ghi thông báo vào db làm lịch sử in-app notification
   * lấy danh sách FCM token hợp lệ của người dùng
   * call firebase messaging để thực hiện đẩy multicast
   * tự động dọn và loại bỏ các FCM token hết hạn hoặc không còn hiệu lực
   */
  async sendToUser(userId: string, payload: PushPayload) {
    try {
      // lưu thông báo vào db làm lịch sử in-app
      const notification = await this.prisma.notification.create({
        data: {
          userId,
          title: payload.notification.title,
          body: payload.notification.body,
          type: payload.type || NotificationType.SYSTEM,
          data: payload.data ? JSON.parse(JSON.stringify(payload.data)) : null,
        },
      });

      // bỏ qua việc gửi push nếu firebase admin chưa được khởi tạo thành công
      if (!this.firebaseReady) {
        this.logger.warn('Firebase Admin is not configured; push skipped');
        return;
      }

      // truy vấn tất cả các FCM token của người dùng
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

      // thực hiện gửi multicast qua FCM
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

      // lọc danh sách các token không còn giá trị sử dụng dựa trên phản hồi của firebase
      const invalidTokens = response.responses
        .map((result, index) =>
          !result.success && this.isInvalidTokenError(result.error)
            ? tokenValues[index]
            : null,
        )
        .filter((token): token is string => Boolean(token));

      // xóa bỏ các token hết hạn khỏi cơ sở dữ liệu để tối ưu lượt gửi lần sau
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

  /**
   * lấy danh sách thông báo của người dùng kèm phân trang
   * 
   * phân giải tham số phân trang
   * xây dựng bộ lọc và loại trừ thông báo loại CHAT nếu không lọc theo type cụ thể
   * thực hiện truy vấn đồng thời danh sách và đếm số thông báo chưa đọc
   */
  async getUserNotifications(
    userId: string,
    query: { page?: number; limit?: number; type?: NotificationType },
  ) {
    const page = Number(query.page) || 1;
    const limit = Number(query.limit) || 10;
    const skip = (page - 1) * limit;

    // thiết lập điều kiện lọc dữ liệu (mặc định loại trừ thông báo chat để tránh làm nhiễu noti center)
    const where: Prisma.NotificationWhereInput = {
      userId,
      ...(query.type
        ? { type: query.type }
        : { type: { not: NotificationType.CHAT } }),
    };

    // thực hiện phân trang danh sách thông báo và đếm tổng số lượng bản ghi
    const [notifications, total] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.notification.count({ where }),
    ]);

    // đếm số lượng thông báo chưa đọc (đồng bộ theo điều kiện loại trừ thông báo chat)
    const unreadCount = await this.prisma.notification.count({
      where: {
        userId,
        isRead: false,
        ...(query.type
          ? { type: query.type }
          : { type: { not: NotificationType.CHAT } }),
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
      where: { userId, isRead: false, type: { not: NotificationType.CHAT } },
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
      where: { userId, type: { not: NotificationType.CHAT } },
    });
  }

  /**
   * khởi tạo firebase admin phục vụ đẩy push notification
   * 
   * cấu hình project
   * đăng ký chứng chỉ credential và kết nối tới FCM gateway
   */
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

      // ưu tiên khởi tạo bằng file cert nếu cấu hình đầy đủ thông tin credential
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

  /**
   * chuyển đổi toàn bộ giá trị trong object data sang kiểu string
   * 
   * bắt buộc theo chuẩn định dạng trường data của FCM payload
   */
  private stringifyData(data: Record<string, string | number | boolean>) {
    return Object.fromEntries(
      Object.entries(data).map(([key, value]) => [key, String(value)]),
    );
  }

  /**
   * kiểm tra xem mã lỗi trả về từ firebase có thuộc diện token không hợp lệ không
   * 
   * phục vụ lọc để tự động xóa sạch các token chết khỏi cơ sở dữ liệu
   */
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
