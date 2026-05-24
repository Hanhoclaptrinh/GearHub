import { Injectable } from '@nestjs/common';
import { RoomStatus } from '@prisma/client';

@Injectable()
export class AiSafetyService {
  private readonly handoffPhrases = [
    'gap nhan vien',
    'gap tu van vien',
    'noi chuyen voi shop',
    'noi chuyen voi nhan vien',
    'tu van vien',
    'nhan vien ho tro',
    'lien he shop',
    'nguoi that',
    'support that',
    'can nguoi ho tro',
    'cho minh gap shop',
    'human support',
    'support agent',
  ];

  canAiReply(status: RoomStatus) {
    return status === RoomStatus.BOT_ONLY;
  }

  // yêu cầu gặp nhân viên
  isHumanHandoffRequest(content: string) {
    const normalized = this.normalize(content);
    return this.handoffPhrases.some((phrase) => normalized.includes(phrase)); // chuẩn hóa yêu cầu của KH
  }

  buildFallbackMessage() {
    return 'GearHub AI hiện chưa thể trả lời ổn định. Bạn có thể mô tả nhu cầu ngắn gọn hơn, hoặc yêu cầu "gặp nhân viên" để GearHub chuyển sang nhân viên hỗ trợ nhé.';
  }

  // chuẩn hóa và làm sạch trước khi gửi
  sanitizeModelOutput(content: string) {
    let trimmed = content.replace(/\0/g, '').trim();

    // bỏ markdown json blocks
    if (trimmed.startsWith('```json')) {
      trimmed = trimmed.replace(/^```json\s*/i, '');
    } else if (trimmed.startsWith('```')) {
      trimmed = trimmed.replace(/^```\s*/, '');
    }
    if (trimmed.endsWith('```')) {
      trimmed = trimmed.replace(/\s*```$/, '');
    }
    trimmed = trimmed.trim();

    if (!trimmed) {
      // fallback
      return 'Mình cần thêm một chút thông tin để tư vấn chính xác hơn. Bạn đang tìm sản phẩm nào hoặc mức ngân sách khoảng bao nhiêu?';
    }

    return trimmed.slice(0, 3000);
  }

  private normalize(content: string) {
    return content
      .toLowerCase()
      .normalize('NFD')
      .replace(/\p{Diacritic}/gu, '')
      .replace(/đ/g, 'd')
      .replace(/[^a-z0-9\s]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }
}
