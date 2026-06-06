import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export class BudgetRangeDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'Ngân sách tối thiểu phải là số nguyên' })
  @Min(0, { message: 'Ngân sách tối thiểu không được âm' })
  @Max(1000000000, { message: 'Ngân sách tối thiểu quá lớn' })
  min?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'Ngân sách tối đa phải là số nguyên' })
  @Min(0, { message: 'Ngân sách tối đa không được âm' })
  @Max(1000000000, { message: 'Ngân sách tối đa quá lớn' })
  max?: number;
}

export class UpdatePreferencesDto {
  @IsOptional()
  @IsArray({ message: 'Danh mục quan tâm phải là danh sách' })
  @ArrayMaxSize(10, { message: 'Chỉ được chọn tối đa 10 danh mục' })
  @IsUUID('4', { each: true, message: 'ID danh mục không hợp lệ' })
  categoryIds?: string[];

  @IsOptional()
  @IsArray({ message: 'Thương hiệu yêu thích phải là danh sách' })
  @ArrayMaxSize(10, { message: 'Chỉ được chọn tối đa 10 thương hiệu' })
  @IsUUID('4', { each: true, message: 'ID thương hiệu không hợp lệ' })
  brandIds?: string[];

  @IsOptional()
  @IsArray({ message: 'Phong cách mua sắm phải là danh sách' })
  @ArrayMaxSize(10, { message: 'Chỉ được chọn tối đa 10 phong cách' })
  @IsString({ each: true, message: 'Phong cách mua sắm không hợp lệ' })
  @MaxLength(50, { each: true, message: 'Phong cách mua sắm tối đa 50 ký tự' })
  styleTags?: string[];

  @IsOptional()
  @IsArray({ message: 'Mục đích sử dụng phải là danh sách' })
  @ArrayMaxSize(10, { message: 'Chỉ được chọn tối đa 10 mục đích sử dụng' })
  @IsString({ each: true, message: 'Mục đích sử dụng không hợp lệ' })
  @MaxLength(50, { each: true, message: 'Mục đích sử dụng tối đa 50 ký tự' })
  useCases?: string[];

  @IsOptional()
  @ValidateNested()
  @Type(() => BudgetRangeDto)
  budgetRange?: BudgetRangeDto;
}
