import { IsInt, IsString, IsOptional, IsUUID, Min, Max, Length } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateReviewDto {
    @IsUUID()
    orderItemId: string;

    @Type(() => Number)
    @IsInt()
    @Min(1)
    @Max(5)
    rating: number;

    @IsString()
    @IsOptional()
    @Length(5, 1000)
    comment?: string;
}