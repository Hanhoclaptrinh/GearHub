import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class ReviewCancelDto {
    @IsBoolean()
    approve: boolean;

    @IsString()
    @IsOptional()
    reason?: string;
}
