import { IsNotEmpty, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class SendMessageDto {
  @IsOptional()
  @IsUUID('4')
  roomId?: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(4000)
  content: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  clientMessageId?: string;
}
