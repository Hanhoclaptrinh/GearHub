import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import * as path from 'node:path';
import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { AssetType, ImageEmbeddingSourceType, Prisma } from '@prisma/client';
import { PrismaService } from 'src/prisma/prisma.service';

type ProductImageCandidate = {
  productId: string;
  variantId?: string | null;
  assetId?: string | null;
  imageUrl: string;
  sourceType: ImageEmbeddingSourceType;
};

type ParsedImageInput = {
  mimeType: string;
  base64: string;
  buffer: Buffer;
  imageHash: string;
};

const SUPPORTED_MIME_TYPES = new Set([
  'image/png',
  'image/jpeg',
  'image/jpg',
  'image/webp',
]);

const DEFAULT_MAX_IMAGE_BYTES = 20 * 1024 * 1024; // max 20mb

@Injectable()
export class ProductImageEmbeddingService {
  private readonly logger = new Logger(ProductImageEmbeddingService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) { }

  // vector hóa hình ảnh được client gửi lên (uri base64)
  async embedDataUriImage(dataUri: string) {
    const parsed = this.parseDataUriImage(dataUri);
    const embedding = await this.embedInlineImage(parsed.mimeType, parsed.base64);

    return {
      embedding,
      imageHash: parsed.imageHash,
      mimeType: parsed.mimeType,
    };
  }

  /**
  * thực hiện quét và sinh vector embedding cho toàn bộ hình ảnh sản phẩm
  * 
  * xử lý theo từng batch
  * trích xuất tất cả ảnh hợp lệ của sản phẩm (ảnh thumbnail, ảnh album, ảnh biến thể) thành danh sách
  * bỏ qua ảnh đã có vector
  */
  async backfillProductImages(batchSize = 50) {
    let cursor: string | undefined;
    let processed = 0;
    let updated = 0;
    let skipped = 0;
    let failed = 0;

    // set lưu url tránh lặp
    const seenUrls = new Set<string>();

    while (true) {
      // phân trang
      const products = await this.prisma.product.findMany({
        where: { isActive: true },
        orderBy: { id: 'asc' },
        take: batchSize,
        ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
        select: {
          id: true,
          thumbnailUrl: true,
          assets: {
            where: { type: AssetType.IMAGE },
            select: { id: true, url: true },
          },
          variants: {
            where: { isActive: true },
            select: { id: true, imageUrl: true },
          },
        },
      });

      if (products.length === 0) break;

      // chuyển đổi dữ liệu lồng ghép của sản phẩm thành mảng phẳng chứa các ảnh
      for (const candidate of this.toImageCandidates(products)) {
        const normalizedUrl = this.normalizeImageUrl(candidate.imageUrl);
        if (!normalizedUrl || seenUrls.has(normalizedUrl)) {
          skipped += 1;
          continue;
        }

        seenUrls.add(normalizedUrl);
        processed += 1;

        try {
          const image = await this.readImageFromUrl(normalizedUrl);
          const existing = await this.prisma.productImageEmbedding.findUnique({
            where: { imageHash: image.imageHash },
            select: { id: true },
          });

          if (existing) {
            skipped += 1;
            continue;
          }

          // xóa vector cũ
          await this.deleteStaleImageEmbedding(candidate, image.imageHash);
          const embedding = await this.embedInlineImage(image.mimeType, image.base64);

          await this.prisma.productImageEmbedding.create({
            data: {
              productId: candidate.productId,
              variantId: candidate.variantId ?? null,
              assetId: candidate.assetId ?? null,
              imageUrl: normalizedUrl,
              imageHash: image.imageHash,
              embedding,
              sourceType: candidate.sourceType,
            },
          });

          updated += 1;
        } catch (error) {
          const fallbackHash = this.hashImageUrl(normalizedUrl);
          const existing = await this.prisma.productImageEmbedding.findUnique({
            where: { imageHash: fallbackHash },
            select: { id: true },
          });

          if (existing) {
            skipped += 1;
            continue;
          }

          failed += 1;
          this.logger.warn(
            `Image embedding backfill failed product=${candidate.productId} url=${normalizedUrl}: ${this.errorMessage(error)}`,
          );
        }
      }

      cursor = products[products.length - 1]?.id;
    }

    return { processed, updated, skipped, failed };
  }

  parseDataUriImage(dataUri: string): ParsedImageInput {
    const maxBytes = this.getMaxImageBytes();
    const match = dataUri.match(
      /^data:(image\/(?:png|jpe?g|webp));base64,([A-Za-z0-9+/=\r\n]+)$/i,
    );

    if (!match) {
      throw new BadRequestException(
        'Ảnh không hợp lệ. Vui lòng gửi data URI base64 png/jpeg/webp.',
      );
    }

    const mimeType = this.normalizeMimeType(match[1]);
    if (!SUPPORTED_MIME_TYPES.has(mimeType)) {
      throw new BadRequestException('Định dạng ảnh không được hỗ trợ.');
    }

    const base64 = match[2].replace(/\s/g, '');
    let buffer: Buffer;
    try {
      buffer = Buffer.from(base64, 'base64');
    } catch {
      throw new BadRequestException('Base64 ảnh không hợp lệ.');
    }

    if (buffer.length === 0 || buffer.length > maxBytes) {
      throw new BadRequestException('Ảnh rỗng hoặc vượt quá giới hạn 10MB.');
    }

    return {
      mimeType,
      base64: buffer.toString('base64'),
      buffer,
      imageHash: this.hashImageBuffer(buffer),
    };
  }

  private toImageCandidates(
    products: Array<{
      id: string;
      thumbnailUrl: string | null;
      assets: Array<{ id: string; url: string }>;
      variants: Array<{ id: string; imageUrl: string | null }>;
    }>,
  ): ProductImageCandidate[] {
    return products.flatMap((product) => {
      const candidates: ProductImageCandidate[] = [];

      if (product.thumbnailUrl) {
        candidates.push({
          productId: product.id,
          imageUrl: product.thumbnailUrl,
          sourceType: ImageEmbeddingSourceType.PRODUCT_THUMBNAIL,
        });
      }

      for (const asset of product.assets) {
        candidates.push({
          productId: product.id,
          assetId: asset.id,
          imageUrl: asset.url,
          sourceType: ImageEmbeddingSourceType.PRODUCT_ASSET,
        });
      }

      for (const variant of product.variants) {
        if (!variant.imageUrl) continue;
        candidates.push({
          productId: product.id,
          variantId: variant.id,
          imageUrl: variant.imageUrl,
          sourceType: ImageEmbeddingSourceType.VARIANT_IMAGE,
        });
      }

      return candidates;
    });
  }

  private async deleteStaleImageEmbedding(
    candidate: ProductImageCandidate,
    imageHash: string,
  ) {
    const sourceWhere = this.sourceWhere(candidate);
    await this.prisma.productImageEmbedding.deleteMany({
      where: {
        ...sourceWhere,
        imageHash: { not: imageHash },
      },
    });
  }

  private sourceWhere(candidate: ProductImageCandidate): Prisma.ProductImageEmbeddingWhereInput {
    if (candidate.assetId) {
      return {
        assetId: candidate.assetId,
        sourceType: candidate.sourceType,
      };
    }

    if (candidate.variantId) {
      return {
        variantId: candidate.variantId,
        sourceType: candidate.sourceType,
      };
    }

    return {
      productId: candidate.productId,
      sourceType: candidate.sourceType,
    };
  }

  private async readImageFromUrl(imageUrl: string): Promise<ParsedImageInput> {
    const url = this.tryParseUrl(imageUrl);
    if (url && ['http:', 'https:'].includes(url.protocol)) {
      return this.readRemoteImage(url);
    }

    return this.readLocalImage(imageUrl);
  }

  private async readRemoteImage(url: URL): Promise<ParsedImageInput> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15_000);

    try {
      const response = await fetch(url, { signal: controller.signal });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const contentLength = Number(response.headers.get('content-length'));
      if (contentLength > this.getMaxImageBytes()) {
        throw new Error('Kích thước ảnh quá lớn');
      }

      const contentType = response.headers.get('content-type')?.split(';')[0];
      const mimeType = this.normalizeMimeType(
        contentType || this.inferMimeType(url.pathname),
      );
      if (!SUPPORTED_MIME_TYPES.has(mimeType)) {
        throw new Error(`Định dạng không hỗ trợ: ${mimeType}`);
      }

      const buffer = Buffer.from(await response.arrayBuffer());
      if (buffer.length === 0 || buffer.length > this.getMaxImageBytes()) {
        throw new Error('Không tìm thấy ảnh hoặc kích thước ảnh quá lớn');
      }

      return {
        mimeType,
        base64: buffer.toString('base64'),
        buffer,
        imageHash: this.hashImageBuffer(buffer),
      };
    } finally {
      clearTimeout(timeout);
    }
  }

  private async readLocalImage(imageUrl: string): Promise<ParsedImageInput> {
    const filePath = imageUrl.startsWith('file://')
      ? new URL(imageUrl)
      : path.resolve(process.cwd(), imageUrl);
    const buffer = await readFile(filePath);
    const mimeType = this.normalizeMimeType(
      this.inferMimeType(typeof filePath === 'string' ? filePath : imageUrl),
    );

    if (!SUPPORTED_MIME_TYPES.has(mimeType)) {
      throw new Error(`Định dạng không hỗ trợ: ${mimeType}`);
    }

    if (buffer.length === 0 || buffer.length > this.getMaxImageBytes()) {
      throw new Error('Không tìm thấy ảnh hoặc kích thước ảnh quá lớn');
    }

    return {
      mimeType,
      base64: buffer.toString('base64'),
      buffer,
      imageHash: this.hashImageBuffer(buffer),
    };
  }

  private normalizeImageUrl(imageUrl: string) {
    const trimmed = imageUrl.trim();
    return trimmed.length > 0 ? trimmed : null;
  }

  private hashImageBuffer(buffer: Buffer) {
    return createHash('sha256')
      .update(
        JSON.stringify({
          model: this.getEmbeddingModelName(),
          dimensions: this.getEmbeddingDimensions(),
        }),
      )
      .update(buffer)
      .digest('hex');
  }

  private hashImageUrl(imageUrl: string) {
    return createHash('sha256')
      .update(
        JSON.stringify({
          model: this.getEmbeddingModelName(),
          dimensions: this.getEmbeddingDimensions(),
          imageUrl: imageUrl.trim().toLowerCase(),
        }),
      )
      .digest('hex');
  }

  private tryParseUrl(value: string) {
    try {
      return new URL(value);
    } catch {
      return null;
    }
  }

  private inferMimeType(value: string) {
    const ext = path.extname(value).toLowerCase();
    if (ext === '.png') return 'image/png';
    if (ext === '.jpg' || ext === '.jpeg') return 'image/jpeg';
    if (ext === '.webp') return 'image/webp';
    return 'application/octet-stream';
  }

  private normalizeMimeType(mimeType: string) {
    return mimeType.toLowerCase() === 'image/jpg'
      ? 'image/jpeg'
      : mimeType.toLowerCase();
  }

  private getMaxImageBytes() {
    const configured = Number(process.env.IMAGE_SEARCH_MAX_IMAGE_BYTES);
    return Number.isInteger(configured) && configured > 0
      ? configured
      : DEFAULT_MAX_IMAGE_BYTES;
  }

  private async embedInlineImage(mimeType: string, base64: string) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY chưa được cấu hình');
    }

    const genAi = new GoogleGenerativeAI(apiKey);
    const model = genAi.getGenerativeModel({
      model: this.getEmbeddingModelName(),
    });
    const result = await model.embedContent({
      content: {
        role: 'user',
        parts: [{ inlineData: { mimeType, data: base64 } }],
      },
      outputDimensionality: this.getEmbeddingDimensions(),
    } as Parameters<typeof model.embedContent>[0] & {
      outputDimensionality: number;
    });

    return result.embedding.values;
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
      throw new Error('GEMINI_EMBEDDING_DIMENSIONS phải là một số nguyên dương');
    }

    return dimensions;
  }

  async syncProductImageEmbeddingBestEffort(productId: string) {
    if (
      !this.isAiEnabled() ||
      !this.configService.get<string>('GEMINI_API_KEY')
    ) {
      return;
    }

    try {
      await this.syncProductImageEmbedding(productId);
    } catch (error) {
      this.logger.warn(
        `Product image embedding sync skipped for ${productId}: ${this.errorMessage(error)}`,
      );
    }
  }

  async syncProductImageEmbedding(productId: string) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
      select: {
        id: true,
        isActive: true,
        thumbnailUrl: true,
        assets: {
          where: { type: AssetType.IMAGE },
          select: { id: true, url: true },
        },
        variants: {
          where: { isActive: true },
          select: { id: true, imageUrl: true },
        },
      },
    });

    // xóa vector embedding nếu sp đó ngưng kd hoặc bị xóa
    if (!product || !product.isActive) {
      await this.prisma.productImageEmbedding.deleteMany({
        where: { productId },
      });
      return;
    }

    // lấy urls hình ảnh của sản phẩm hiện tại
    const candidates = this.toImageCandidates([product]);
    const currentUrls = new Set(candidates.map(c => this.normalizeImageUrl(c.imageUrl)).filter(Boolean) as string[]);

    await this.prisma.productImageEmbedding.deleteMany({
      where: {
        productId,
        imageUrl: { notIn: Array.from(currentUrls) },
      },
    });

    for (const candidate of candidates) {
      const normalizedUrl = this.normalizeImageUrl(candidate.imageUrl);
      if (!normalizedUrl) continue;

      try {
        const image = await this.readImageFromUrl(normalizedUrl);
        const existing = await this.prisma.productImageEmbedding.findUnique({
          where: { imageHash: image.imageHash },
          select: { id: true, imageUrl: true },
        });

        // bỏ qua nếu đã hash, tránh lặp lại lãng phí tài nguyên
        if (existing) {
          await this.prisma.productImageEmbedding.update({
            where: { id: existing.id },
            data: {
              productId: candidate.productId,
              variantId: candidate.variantId ?? null,
              assetId: candidate.assetId ?? null,
              imageUrl: normalizedUrl,
              sourceType: candidate.sourceType,
            },
          });
          continue;
        }

        await this.deleteStaleImageEmbedding(candidate, image.imageHash);
        // tạo mới
        const embedding = await this.embedInlineImage(image.mimeType, image.base64);

        await this.prisma.productImageEmbedding.create({
          data: {
            productId: candidate.productId,
            variantId: candidate.variantId ?? null,
            assetId: candidate.assetId ?? null,
            imageUrl: normalizedUrl,
            imageHash: image.imageHash,
            embedding,
            sourceType: candidate.sourceType,
          },
        });
      } catch (error) {
        this.logger.warn(
          `Failed to sync image embedding for product=${productId} url=${normalizedUrl}: ${this.errorMessage(error)}`,
        );
      }
    }
  }

  private isAiEnabled() {
    const value = this.configService.get<string>('AI_CHAT_ENABLED');
    return ['1', 'true', 'yes', 'on'].includes((value ?? '').toLowerCase());
  }

  private errorMessage(error: unknown) {
    return error instanceof Error ? error.message : String(error);
  }
}
