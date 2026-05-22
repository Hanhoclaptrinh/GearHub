import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class DeregisterFcmTokenDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(512)
  token: string;
}
