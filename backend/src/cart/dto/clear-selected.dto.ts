import { IsArray, IsString } from 'class-validator';

export class ClearSelectedDto {
    @IsArray()
    @IsString({ each: true })
    variantIds: string[];
}