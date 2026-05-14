import {
    Body,
    Controller,
    Get,
    Param,
    Post,
    Query,
    Request,
    UseGuards,
} from '@nestjs/common';
import { InventoriesService } from './inventories.service';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { RolesGuard } from 'src/common/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';
import { InventoryTransactionType, Role } from '@prisma/client';
import { AdjustStockDto, AdjustmentMode } from './dto/adjust-stock.dto';
import { BadRequestException } from '@nestjs/common';

@Controller('inventory')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN, Role.STAFF)
export class InventoriesController {
    constructor(private inventoriesService: InventoriesService) { }

    @Get()
    async getInventoryList(
        @Query('search') search?: string,
        @Query('categoryId') categoryId?: string,
        @Query('brandId') brandId?: string,
        @Query('stockFilter') stockFilter?: 'all' | 'low_stock' | 'out_of_stock',
        @Query('page') page?: string,
        @Query('limit') limit?: string,
    ) {
        return this.inventoriesService.getInventoryList({
            search,
            categoryId,
            brandId,
            stockFilter,
            page: page ? Number(page) : 1,
            limit: limit ? Number(limit) : 20,
        });
    }

    @Post(':variantId/adjust')
    async adjustStock(
        @Param('variantId') variantId: string,
        @Body() dto: AdjustStockDto,
        @Request() req,
    ) {
        const typeMap: Record<string, InventoryTransactionType> = {
            IMPORT: InventoryTransactionType.IMPORT,
            DAMAGED: InventoryTransactionType.DAMAGED,
            ADJUSTMENT: InventoryTransactionType.ADJUSTMENT,
            RETURN: InventoryTransactionType.RETURN,
        };

        const transactionType = typeMap[dto.type];
        if (!transactionType) {
            throw new BadRequestException(`Loại điều chỉnh không hợp lệ: ${dto.type}`);
        }

        if (dto.type === 'ADJUSTMENT' && !dto.mode) {
            throw new BadRequestException('ADJUSTMENT cần có mode (INCREASE hoặc DECREASE)');
        }

        if (['DAMAGED', 'ADJUSTMENT'].includes(dto.type) && !dto.reason) {
            throw new BadRequestException('Lý do là bắt buộc cho DAMAGED và ADJUSTMENT');
        }

        return this.inventoriesService.adjustStock({
            variantId,
            type: transactionType,
            quantity: dto.quantity,
            reason: dto.reason,
            createdById: req.user.userId,
            mode: dto.mode as AdjustmentMode | undefined,
        });
    }

    @Get(':variantId/transactions')
    async getTransactionHistory(
        @Param('variantId') variantId: string,
        @Query('page') page?: string,
        @Query('limit') limit?: string,
    ) {
        return this.inventoriesService.getTransactionHistory(variantId, {
            page: page ? Number(page) : 1,
            limit: limit ? Number(limit) : 20,
        });
    }
}
