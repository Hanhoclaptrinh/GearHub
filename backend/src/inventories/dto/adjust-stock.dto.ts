import { IsEnum, IsInt, IsNotEmpty, IsOptional, IsString, Min } from 'class-validator';

export enum AdjustmentMode {
    INCREASE = 'INCREASE',
    DECREASE = 'DECREASE',
}

export class AdjustStockDto {
    @IsEnum(['IMPORT', 'DAMAGED', 'ADJUSTMENT', 'RETURN'], {
        message: 'Type phải là IMPORT, DAMAGED, ADJUSTMENT hoặc RETURN',
    })
    @IsNotEmpty()
    type: 'IMPORT' | 'DAMAGED' | 'ADJUSTMENT' | 'RETURN';

    @IsInt({ message: 'Số lượng phải là số nguyên' })
    @Min(1, { message: 'Số lượng phải lớn hơn 0' })
    quantity: number;

    @IsOptional()
    @IsString()
    reason?: string;

    @IsOptional()
    @IsEnum(AdjustmentMode, { message: 'Mode phải là INCREASE hoặc DECREASE' })
    mode?: AdjustmentMode;
}
