import { IsNotEmpty, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateCategoryDto {
    @IsString()
    @IsNotEmpty({ message: 'Tên danh mục không được để trống' })
    @MaxLength(100, { message: 'Tên danh mục tối đa 100 ký tự' })
    name: string;

    @IsString()
    @IsOptional()
    description?: string;

    @IsUUID('4', { message: 'ID danh mục cha không hợp lệ' })
    @IsOptional()
    parentId?: string;
}