import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class RegisterFcmTokenDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(512)
  token: string;

  @IsString()
  @IsOptional()
  @MaxLength(50)
  deviceType?: string;
}
