import { IsInt, IsString, IsOptional, Min, Max, Length } from 'class-validator';

export class UpdateReviewDto {
    @IsInt()
    @IsOptional()
    @Min(1)
    @Max(5)
    rating?: number;

    @IsString()
    @IsOptional()
    @Length(5, 1000)
    comment?: string;
}
