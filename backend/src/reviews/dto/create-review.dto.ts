import { IsInt, IsString, IsOptional, IsUUID, Min, Max, Length } from 'class-validator';

export class CreateReviewDto {
    @IsUUID()
    productId: string;

    @IsInt()
    @Min(1)
    @Max(5)
    rating: number;

    @IsString()
    @IsOptional()
    @Length(5, 1000)
    comment?: string;

    @IsUUID()
    @IsOptional()
    orderId?: string; // check Verified Purchase cho chuan don hang
}