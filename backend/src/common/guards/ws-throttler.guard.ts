import { Injectable } from '@nestjs/common';
import { ThrottlerGuard, ThrottlerRequest } from '@nestjs/throttler';
import { WsException } from '@nestjs/websockets';

@Injectable()
export class WsThrottlerGuard extends ThrottlerGuard {
  async handleRequest(requestProps: ThrottlerRequest): Promise<boolean> {
    const {
      context,
      limit,
      ttl,
      throttler,
      blockDuration,
      generateKey,
    } = requestProps;

    const client = context.switchToWs().getClient();

    // thông tin người gửi tin nhắn
    const tracker =
      client.data?.user?.id ??
      client.handshake?.address ??
      client._socket?.remoteAddress ??
      client.id;

    const throttlerName = throttler.name ?? 'default';
    // tạo unique rate-limit xác định ai đang bị đếm số req
    const key = generateKey(context, tracker, throttlerName);

    // tìm counter hiện tại và thực hiện tăng 1 mỗi lần gửi
    // block nếu vượt limit
    const result = await this.storageService.increment(
      key,
      ttl,
      limit,
      blockDuration,
      throttlerName,
    );

    if (result.isBlocked) {
      throw new WsException(
        'Tần suất gửi tin nhắn quá nhanh. Vui lòng thử lại sau giây lát.',
      );
    }

    return true;
  }
}