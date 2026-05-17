import { IsOptional, IsUUID } from 'class-validator';

export class JoinRoomDto {
  @IsOptional()
  @IsUUID('4')
  roomId?: string;
}
