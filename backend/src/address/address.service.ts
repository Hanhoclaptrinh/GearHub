import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateAddressDto } from './dto/create-address.dto';
import { UpdateAddressDto } from './dto/update-address.dto';

@Injectable()
export class AddressService {
    constructor(
        private readonly prisma: PrismaService
    ) { }

    /**
     * tạo một địa chỉ giao hàng mới cho user
     * tự động thiết lập làm địa chỉ mặc định nếu đây là địa chỉ đầu tiên
     * nếu địa chỉ mới được đặt làm mặc định, hệ thống sẽ bỏ mặc định các địa chỉ cũ trong một transaction
     */
    async createAddress(userId: string, data: CreateAddressDto) {
        // đếm số lượng địa chỉ hiện có để xác định trạng thái mặc định
        const cnt = await this.prisma.address.count({
            where: { userId }
        });

        // địa chỉ đầu tiên luôn là địa chỉ mặc định
        const isDefault = cnt === 0 ? true : !!data.isDefault;

        return await this.prisma.$transaction(async (tx) => {
            // nếu địa chỉ này được thiết lập làm mặc định, bỏ trạng thái mặc định của các địa chỉ cũ
            if (isDefault) {
                await tx.address.updateMany({
                    where: { userId, isDefault: true },
                    data: { isDefault: false }
                });
            }

            // tạo mới địa chỉ trong DB
            return await tx.address.create({
                data: {
                    userId,
                    fullName: data.fullName,
                    phone: data.phone,
                    province: data.province,
                    district: data.district,
                    ward: data.ward,
                    detail: data.detail,
                    isDefault
                }
            });
        });
    }

    // lấy toàn bộ danh sách địa chỉ của một user cụ thể
    async findAllAddresses(userId: string) {
        return this.prisma.address.findMany({
            where: { userId },
            orderBy: [
                { isDefault: 'desc' },
                { createdAt: 'desc' }
            ]
        });
    }

    /**
     * lấy chi tiết thông tin của một địa chỉ cụ thể
     * thực hiện kiểm tra sự tồn tại và quyền sở hữu để tránh lộ thông tin
     */
    async findOneAddress(userId: string, id: string) {
        const address = await this.prisma.address.findUnique({
            where: { id }
        });

        // đảm bảo địa chỉ có tồn tại
        if (!address) {
            throw new NotFoundException('Địa chỉ không tồn tại');
        }

        // đảm bảo địa chỉ thuộc về người dùng đang đăng nhập
        if (address.userId !== userId) {
            throw new ForbiddenException('Bạn không có quyền truy cập địa chỉ này');
        }

        return address;
    }

    /**
     * cập nhật thông tin chi tiết của một địa chỉ
     * không được tự bỏ trạng thái mặc định của địa chỉ hiện tại nếu không thiết lập địa chỉ khác thay thế
     */
    async updateAddress(userId: string, id: string, data: UpdateAddressDto) {
        const address = await this.findOneAddress(userId, id);

        // case 1: user set địa chỉ này làm địa chỉ mặc định
        if (data.isDefault === true) {
            return await this.prisma.$transaction(async (tx) => {
                // tắt mặc định của các địa chỉ cũ
                await tx.address.updateMany({
                    where: { userId, isDefault: true },
                    data: { isDefault: false }
                });

                // cập nhật địa chỉ này thành mặc định và lưu thông tin mới
                return await tx.address.update({
                    where: { id },
                    data: {
                        ...data,
                        isDefault: true
                    }
                });
            });
        }

        // case 2: bỏ mặc định của địa chỉ hiện tại
        // mà không có địa chỉ khác được set defaul thay thế
        if (address.isDefault && data.isDefault === false) {
            throw new BadRequestException('Không thể hủy mặc định. Vui lòng thiết lập địa chỉ khác làm mặc định thay thế.');
        }

        // case 3: update field khác - không hủy mặc định
        return this.prisma.address.update({
            where: { id },
            data
        });
    }

    /**
     * xóa một địa chỉ khỏi hệ thống
     * không được phép xóa địa chỉ đang là địa chỉ mặc định
     */
    async removeAddress(userId: string, id: string) {
        const address = await this.findOneAddress(userId, id);

        // không được xóa địa chỉ đang set mặc định
        if (address.isDefault) {
            throw new BadRequestException('Không thể xóa địa chỉ mặc định. Vui lòng thiết lập địa chỉ khác làm mặc định trước khi xóa.');
        }

        await this.prisma.address.delete({
            where: { id }
        });

        return { message: 'Xóa địa chỉ thành công' };
    }

    // set mặc định
    async setDefaultAddress(userId: string, id: string) {
        // địa chỉ phải tồn tại và thuộc qsh của user
        await this.findOneAddress(userId, id);

        return await this.prisma.$transaction(async (tx) => {
            // đặt tất cả các địa chỉ khác của người dùng này về trạng thái không mặc định
            await tx.address.updateMany({
                where: { userId, isDefault: true },
                data: { isDefault: false }
            });

            // thiết lập địa chỉ được chọn làm mặc định
            return await tx.address.update({
                where: { id },
                data: { isDefault: true }
            });
        });
    }
}
