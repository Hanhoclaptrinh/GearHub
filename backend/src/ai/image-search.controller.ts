import {
  Body,
  Controller,
  HttpCode,
  HttpException,
  InternalServerErrorException,
  Logger,
  Post,
} from '@nestjs/common';
import { ImageSearchDto } from './dto/image-search.dto';
import { ImageSearchService } from './image-search.service';

@Controller('api/v1/ai')
export class ImageSearchController {
  private readonly logger = new Logger(ImageSearchController.name);

  constructor(private readonly imageSearchService: ImageSearchService) {}

  @Post('image-search')
  @HttpCode(200)
  async imageSearch(@Body() dto: ImageSearchDto) {
    try {
      return await this.imageSearchService.searchByImage(
        dto.imageBase64,
        dto.limit ?? 20,
      );
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }

      this.logger.error(
        `Image search failed: ${error instanceof Error ? error.message : String(error)}`,
      );
      throw new InternalServerErrorException(
        'Không thể tìm kiếm bằng hình ảnh lúc này.',
      );
    }
  }
}
