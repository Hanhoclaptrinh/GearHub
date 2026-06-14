import { createHash } from 'node:crypto';
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { Prisma } from '@prisma/client';
import { PrismaService } from 'src/prisma/prisma.service';

// dữ liệu cần được vector hóa
const productEmbeddingSelect = {
  id: true,
  name: true,
  slug: true,
  tagline: true,
  description: true,
  metadata: true,
  averageRating: true,
  reviewCount: true,
  isActive: true,
  isFeatured: true,
  brand: { select: { name: true } },
  category: { select: { name: true } },
  variants: {
    where: { isActive: true },
    orderBy: { price: 'asc' },
    select: {
      sku: true,
      name: true,
      price: true,
      stock: true,
      attributes: true,
      isActive: true,
    },
  },
} satisfies Prisma.ProductSelect;

type ProductForEmbedding = Prisma.ProductGetPayload<{
  select: typeof productEmbeddingSelect;
}>;

@Injectable()
export class EmbeddingService {
  private readonly logger = new Logger(EmbeddingService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) { }

  // chuyển đổi đoạn văn bản thô thành mảng vector embedding số thực
  async embedText(text: string): Promise<number[]> {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY chưa được cấu hình');
    }

    const genAi = new GoogleGenerativeAI(apiKey);
    const model = genAi.getGenerativeModel({
      model: this.getEmbeddingModelName(),
    });

    // call api sinh vector có giới hạn chiều
    const result = await model.embedContent({
      content: { role: 'user', parts: [{ text }] },
      outputDimensionality: this.getEmbeddingDimensions(),
    } as Parameters<typeof model.embedContent>[0] & {
      outputDimensionality: number;
    });

    return result.embedding.values;
  }

  hashText(text: string) {
    return createHash('sha256')
      .update(
        JSON.stringify({
          model: this.getEmbeddingModelName(),
          dimensions: this.getEmbeddingDimensions(),
          text,
        }),
      )
      .digest('hex');
  }

  /**
   * đồng bộ và sinh vector embedding hàng loạt cho toàn bộ sản phẩm đang hoạt động
   * 
   * phân trang và chạy theo từng batch tránh overload
   * chỉ vector hóa các sản phẩm đang được kinh doanh
   */
  async backfillProducts(batchSize = 50) {
    let cursor: string | undefined;
    let processed = 0;
    let updated = 0;
    let skipped = 0;

    while (true) {
      // phân trang
      const products = await this.prisma.product.findMany({
        where: { isActive: true },
        orderBy: { id: 'asc' },
        take: batchSize,
        ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
        select: productEmbeddingSelect,
      });

      if (products.length === 0) break;

      // vector hóa các sp trong batch hiện tại
      for (const product of products) {
        const result = await this.syncProductEmbedding(product.id, product);
        processed += 1;
        if (result === 'updated') updated += 1;
        if (result === 'skipped') skipped += 1;
      }

      // update cursor id bằng id sp cuối trong lô
      cursor = products[products.length - 1]?.id;
    }

    return { processed, updated, skipped };
  }

  async syncProductEmbeddingBestEffort(productId: string) {
    if (
      !this.isAiEnabled() ||
      !this.configService.get<string>('GEMINI_API_KEY')
    ) {
      return;
    }

    try {
      await this.syncProductEmbedding(productId);
    } catch (error) {
      this.logger.warn(
        `Product text embedding sync skipped for ${productId}: ${this.errorMessage(error)}`,
      );
    }
  }

  /**
   * đồng bộ hóa vector embedding cho một sản phẩm cụ thể
   * 
   * thuật toán:
   * lấy thông tin chi tiết sản phẩm (nếu chưa được cung cấp sẵn qua hydratedProduct)
   * nếu sản phẩm bị xóa hoặc ngừng kinh doanh, tự động xóa vector cũ trong db
   * xây dựng source text cho sản phẩm và tính text hash
   * so sánh với text hash hiện tại trong db, bỏ qua nếu trùng khớp
   * sinh vector mới nếu có thay đổi
   */
  async syncProductEmbedding(
    productId: string,
    hydratedProduct?: ProductForEmbedding,
  ): Promise<'updated' | 'skipped'> {
    // thông tin prd
    const product =
      hydratedProduct ??
      (await this.prisma.product.findUnique({
        where: { id: productId },
        select: productEmbeddingSelect,
      }));

    // xóa vector cũ của sp nếu ngừng kinh doanh
    if (!product || !product.isActive) {
      await this.deleteProductEmbeddingIfTableExists(productId);
      return 'updated';
    }

    // build source text & text hash
    const sourceText = this.buildProductSourceText(product);
    const textHash = this.hashText(sourceText);

    // lấy text hash trong db và so sánh
    // bỏ qua nếu trùng
    const existing = await this.prisma.productEmbedding.findUnique({
      where: { productId },
      select: { textHash: true },
    });
    if (existing?.textHash === textHash) {
      return 'skipped';
    }

    // sinh vector mới
    const embedding = await this.embedText(sourceText);
    await this.prisma.productEmbedding.upsert({
      where: { productId },
      create: {
        productId,
        textHash,
        sourceText,
        embedding,
      },
      update: {
        textHash,
        sourceText,
        embedding,
      },
    });

    return 'updated';
  }

  // xây dựng source text dựa trên thông tin sản phẩm và thuộc tính sản phẩm + biến thể
  buildProductSourceText(product: ProductForEmbedding) {
    const attributeMap = new Map<string, Set<string>>();

    for (const variant of product.variants) {
      if (variant.attributes && typeof variant.attributes === 'object') {
        const attrs = variant.attributes as Record<string, unknown>;
        for (const [key, value] of Object.entries(attrs)) {
          if (value != null) {
            const valStr = String(value).trim();
            if (valStr) {
              if (!attributeMap.has(key)) {
                attributeMap.set(key, new Set());
              }
              attributeMap.get(key)!.add(valStr);
            }
          }
        }
      }
    }

    const formattedAttrs = Array.from(attributeMap.entries())
      .map(([key, values]) => `${key}: ${Array.from(values).join(', ')}`)
      .join(' | ');

    return [
      `Sản phẩm: ${product.name}`,
      product.isFeatured ? 'Trạng thái: Khuyên dùng / Bán chạy nhất' : '',
      `Thương hiệu: ${product.brand?.name ?? 'Chưa rõ'}`,
      `Danh mục: ${product.category?.name ?? 'Chưa rõ'}`,
      product.tagline ? `Slogan: ${product.tagline}` : '',
      product.description
        ? `Mô tả: ${this.truncate(product.description, 900)}`
        : '',
      product.metadata
        ? `Thông số chung: ${this.safeJson(this.getCommonSpecs(product.metadata))}`
        : '',
      `Đánh giá: ${product.averageRating}/5 sao (${product.reviewCount} lượt đánh giá)`,
      formattedAttrs ? `Các phiên bản hỗ trợ: ${formattedAttrs}` : '',
    ]
      .filter(Boolean)
      .join('\n');
  }

  private async deleteProductEmbeddingIfTableExists(productId: string) {
    try {
      await this.prisma.productEmbedding.deleteMany({ where: { productId } });
    } catch (error) {
      this.logger.warn(
        `Product text embedding delete skipped for ${productId}: ${this.errorMessage(error)}`,
      );
    }
  }

  private isAiEnabled() {
    const value = this.configService.get<string>('AI_CHAT_ENABLED');
    return ['1', 'true', 'yes', 'on'].includes((value ?? '').toLowerCase());
  }

  private getEmbeddingModelName() {
    const model = this.configService.get<string>('GEMINI_EMBEDDING_MODEL');
    if (!model) {
      throw new Error('GEMINI_EMBEDDING_MODEL chưa được cấu hình');
    }

    return model;
  }

  private getEmbeddingDimensions() {
    const configured =
      this.configService.get<string>('GEMINI_EMBEDDING_DIMENSIONS') ??
      '768';
    const dimensions = Number(configured);
    if (!Number.isInteger(dimensions) || dimensions <= 0) {
      throw new Error('GEMINI_EMBEDDING_DIMENSIONS phải là số nguyên dương');
    }

    return dimensions;
  }

  private truncate(value: string, maxLength: number) {
    return value.length <= maxLength
      ? value
      : `${value.slice(0, maxLength)}...`;
  }

  private getCommonSpecs(metadata: Prisma.JsonValue) {
    if (!metadata || typeof metadata !== 'object' || Array.isArray(metadata)) {
      return null;
    }

    return (metadata as Record<string, unknown>).common_specs ?? null;
  }

  private safeJson(value: unknown) {
    if (value == null) return '';

    try {
      return this.truncate(JSON.stringify(value), 1200);
    } catch {
      return '';
    }
  }

  private errorMessage(error: unknown) {
    return error instanceof Error ? error.message : String(error);
  }
}
