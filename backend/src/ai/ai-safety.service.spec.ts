import { RoomStatus } from '@prisma/client';
import { AiSafetyService } from './ai-safety.service';

describe('AiSafetyService', () => {
  let service: AiSafetyService;

  beforeEach(() => {
    service = new AiSafetyService();
  });

  it('allows AI replies only in BOT_ONLY rooms', () => {
    expect(service.canAiReply(RoomStatus.BOT_ONLY)).toBe(true);
    expect(service.canAiReply(RoomStatus.NEED_HUMAN)).toBe(false);
    expect(service.canAiReply(RoomStatus.STAFF_ACTIVE)).toBe(false);
    expect(service.canAiReply(RoomStatus.CLOSED)).toBe(false);
  });

  it('detects Vietnamese handoff requests', () => {
    expect(
      service.isHumanHandoffRequest('minh muon gap nhan vien ho tro'),
    ).toBe(true);
    expect(service.isHumanHandoffRequest('cho minh noi chuyen voi shop')).toBe(
      true,
    );
    expect(service.isHumanHandoffRequest('toi muon gap tu van vien')).toBe(
      true,
    );
    expect(service.isHumanHandoffRequest('toi muon lien he shop')).toBe(true);
    expect(service.isHumanHandoffRequest('can nguoi that tu van')).toBe(true);
    expect(service.isHumanHandoffRequest('support that duoc khong')).toBe(true);
    expect(
      service.isHumanHandoffRequest('tu van giup minh mau ban phim co'),
    ).toBe(false);
  });
});
