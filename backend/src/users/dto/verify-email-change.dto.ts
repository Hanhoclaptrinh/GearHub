import { IsString, Length } from 'class-validator';

export class VerifyEmailChangeDto {
  @IsString()
  @Length(6, 6, { message: 'Mã OTP phải gồm 6 ký tự' })
  otp: string;
}
