import { IsUUID } from 'class-validator';

export class TypingDto {
  @IsUUID('4')
  roomId: string;
}
