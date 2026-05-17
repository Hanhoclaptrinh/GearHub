import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Role, RoomStatus } from '@prisma/client';
import { ChatRepository } from './repositories/chat.repository';
import { ChatService } from './chat.service';

const baseRoom = {
  id: 'room-1',
  userId: 'customer-1',
  staffId: null,
  status: RoomStatus.NEED_HUMAN,
  lastMessageAt: null,
  lastMessageContent: null,
  customerUnreadCount: 0,
  staffUnreadCount: 0,
};

describe('ChatService', () => {
  let repository: jest.Mocked<
    Pick<
      ChatRepository,
      'claimRoom' | 'transaction' | 'findRoomById' | 'closeRoom'
    >
  >;

  let service: ChatService;

  beforeEach(() => {
    repository = {
      claimRoom: jest.fn(),
      transaction: jest.fn((callback) => callback({} as never)),
      findRoomById: jest.fn(),
      closeRoom: jest.fn(),
    };

    service = new ChatService(repository as unknown as ChatRepository);
  });

  describe('claimRoom', () => {
    it('returns the room when the same staff claims an already assigned room', async () => {
      repository.claimRoom.mockResolvedValue({
        count: 0,
        room: {
          ...baseRoom,
          staffId: 'staff-1',
          status: RoomStatus.STAFF_ACTIVE,
        },
      });

      const result = await service.claimRoom(
        {
          id: 'staff-1',
          email: 'staff@gearhub.com',
          role: Role.STAFF,
        },
        'room-1',
      );

      expect(result.room.staffId).toBe('staff-1');
      expect(result.room.status).toBe(RoomStatus.STAFF_ACTIVE);
    });

    it('throws conflict when another staff member already claimed the room', async () => {
      repository.claimRoom.mockResolvedValue({
        count: 0,
        room: {
          ...baseRoom,
          staffId: 'staff-2',
          status: RoomStatus.STAFF_ACTIVE,
        },
      });

      await expect(
        service.claimRoom(
          {
            id: 'staff-1',
            email: 'staff@gearhub.com',
            role: Role.STAFF,
          },
          'room-1',
        ),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('rejects claiming a closed room', async () => {
      repository.claimRoom.mockResolvedValue({
        count: 0,
        room: {
          ...baseRoom,
          status: RoomStatus.CLOSED,
        },
      });

      await expect(
        service.claimRoom(
          {
            id: 'staff-1',
            email: 'staff@gearhub.com',
            role: Role.STAFF,
          },
          'room-1',
        ),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('allows admin override claim policy explicitly', async () => {
      repository.claimRoom.mockResolvedValue({
        count: 0,
        room: {
          ...baseRoom,
          staffId: 'staff-2',
          status: RoomStatus.STAFF_ACTIVE,
        },
      });

      await expect(
        service.claimRoom(
          {
            id: 'admin-1',
            email: 'admin@gearhub.com',
            role: Role.ADMIN,
          },
          'room-1',
        ),
      ).rejects.toBeInstanceOf(ConflictException);
    });
  });

  describe('closeRoom', () => {
    it('throws not found when room does not exist', async () => {
      repository.findRoomById.mockResolvedValue(null);

      await expect(
        service.closeRoom(
          {
            id: 'staff-1',
            email: 'staff@gearhub.com',
            role: Role.STAFF,
          },
          'room-404',
        ),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('rejects closing a room assigned to another staff member', async () => {
      repository.findRoomById.mockResolvedValue({
        ...baseRoom,
        staffId: 'staff-2',
        status: RoomStatus.STAFF_ACTIVE,
      });

      await expect(
        service.closeRoom(
          {
            id: 'staff-1',
            email: 'staff@gearhub.com',
            role: Role.STAFF,
          },
          'room-1',
        ),
      ).rejects.toBeInstanceOf(ForbiddenException);

      expect(repository.closeRoom).not.toHaveBeenCalled();
    });

    it('rejects closing an unassigned room for staff', async () => {
      repository.findRoomById.mockResolvedValue({
        ...baseRoom,
        staffId: null,
        status: RoomStatus.NEED_HUMAN,
      });

      await expect(
        service.closeRoom(
          {
            id: 'staff-1',
            email: 'staff@gearhub.com',
            role: Role.STAFF,
          },
          'room-1',
        ),
      ).rejects.toBeInstanceOf(ForbiddenException);

      expect(repository.closeRoom).not.toHaveBeenCalled();
    });

    it('rejects closing an already closed room', async () => {
      repository.findRoomById.mockResolvedValue({
        ...baseRoom,
        staffId: 'staff-1',
        status: RoomStatus.CLOSED,
      });

      await expect(
        service.closeRoom(
          {
            id: 'staff-1',
            email: 'staff@gearhub.com',
            role: Role.STAFF,
          },
          'room-1',
        ),
      ).rejects.toBeInstanceOf(BadRequestException);

      expect(repository.closeRoom).not.toHaveBeenCalled();
    });

    it('allows the assigned staff member to close a room', async () => {
      const assignedRoom = {
        ...baseRoom,
        staffId: 'staff-1',
        status: RoomStatus.STAFF_ACTIVE,
      };

      repository.findRoomById.mockResolvedValue(assignedRoom);

      repository.closeRoom.mockResolvedValue({
        room: {
          ...assignedRoom,
          status: RoomStatus.CLOSED,
        },
        message: null,
      });

      const result = await service.closeRoom(
        {
          id: 'staff-1',
          email: 'staff@gearhub.com',
          role: Role.STAFF,
        },
        'room-1',
      );

      expect(result.room.status).toBe(RoomStatus.CLOSED);

      expect(repository.closeRoom).toHaveBeenCalled();
    });

    it('allows admin to close any assigned room', async () => {
      const assignedRoom = {
        ...baseRoom,
        staffId: 'staff-2',
        status: RoomStatus.STAFF_ACTIVE,
      };

      repository.findRoomById.mockResolvedValue(assignedRoom);

      repository.closeRoom.mockResolvedValue({
        room: {
          ...assignedRoom,
          status: RoomStatus.CLOSED,
        },
        message: null,
      });

      const result = await service.closeRoom(
        {
          id: 'admin-1',
          email: 'admin@gearhub.com',
          role: Role.ADMIN,
        },
        'room-1',
      );

      expect(result.room.status).toBe(RoomStatus.CLOSED);

      expect(repository.closeRoom).toHaveBeenCalled();
    });
  });
});