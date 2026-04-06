import { IsOptional, IsString, IsInt, Min, IsDateString } from 'class-validator';
import { Type } from 'class-transformer';
import * as activityLogConstants from 'src/common/constants/activity-log.constants';

export class QueryActivityLogDto {
    @IsOptional()
    @IsInt()
    @Min(1)
    @Type(() => Number)
    page?: number = 1;

    @IsOptional()
    @IsInt()
    @Min(1)
    @Type(() => Number)
    limit?: number = 20;

    @IsOptional()
    @IsString()
    userId?: string;

    @IsOptional()
    @IsString()
    action?: activityLogConstants.ActivityActionType;

    @IsOptional()
    @IsDateString()
    from?: string;

    @IsOptional()
    @IsDateString()
    to?: string;
}