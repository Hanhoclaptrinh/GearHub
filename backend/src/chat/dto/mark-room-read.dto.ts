import { IsOptional, IsUUID } from 'class-validator';

export class MarkRoomReadDto {
  @IsOptional()
  @IsUUID('4')
  roomId?: string;
}
