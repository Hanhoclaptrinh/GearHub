import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class GoogleLoginDto {
    @IsNotEmpty({ message: 'idToken không được để trống' })
    @IsString()
    idToken: string;

    @IsOptional()
    @IsString()
    deviceId?: string;
}
