import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '@prisma/client';
import { PrismaService } from 'src/prisma/prisma.service';
import { EmbeddingService } from './embedding.service';
import { PublicProductContext } from './types/ai.types';

const publicProductSelect = {
  id: true,
  name: true,
  slug: true,
  thumbnailUrl: true,
  tagline: true,
  description: true,
  metadata: true,
  vaultSpecs: true,
  averageRating: true,
  reviewCount: true,
  isActive: true,
  isVault: true,
  isFeatured: true,
  brand: { select: { name: true } },
  category: { select: { name: true } },
  variants: {
    where: { isActive: true },
    orderBy: { price: 'asc' },
    select: {
      id: true,
      sku: true,
      name: true,
      price: true,
      stock: true,
      attributes: true,
    },
  },
} satisfies Prisma.ProductSelect;

type PublicProductRecord = Prisma.ProductGetPayload<{
  select: typeof publicProductSelect;
}>;

@Injectable()
export class ProductRetrievalService {
  private readonly logger = new Logger(ProductRetrievalService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly embeddingService: EmbeddingService,
    private readonly configService: ConfigService,
  ) { }

  async retrieveProducts(
    query: string,
    topK = 5,
  ): Promise<PublicProductContext[]> {
    const maxProducts = Math.min(
      Math.max(topK, 1),
      Number(this.configService.get<string>('AI_RAG_MAX_PRODUCTS') ?? 5),
    );

    try {
      const queryEmbedding = await this.embeddingService.embedText(query);
      // 2-stage retrieval
      // stage 1 - chỉ lấy id và embedding, giảm áp lực RAM và băng thông
      const rows = await this.prisma.productEmbedding.findMany({
        where: {
          product: {
            isActive: true,
            variants: { some: { isActive: true } },
          },
        },
        select: {
          embedding: true,
          productId: true,
        },
      });

      // ngưỡng tương đồng - chỉ lấy những sản phẩm có điểm tương đồng >= threshold
      const threshold = Number(
        this.configService.get<string>('AI_RAG_SIMILARITY_THRESHOLD') ?? 0.55,
      );

      // stage 2 - tính toán ma trận cosine trên mảng id
      const scoredRows = rows
        .map((row) => ({
          productId: row.productId,
          score: this.cosineSimilarity(
            queryEmbedding,
            this.toVector(row.embedding),
          ),
        }))
        .sort((a, b) => b.score - a.score);

      let filtered = scoredRows.filter((item) => item.score >= threshold);

      // set ngưỡng chấp nhận = 0.48 nếu không có sản phẩm nào đạt ngưỡng 0.55
      if (filtered.length === 0) {
        filtered = scoredRows.filter((item) => item.score >= 0.48);
      }

      // danh sách n sản phẩm tốt nhất
      const targetItems = filtered.slice(0, maxProducts);
      if (targetItems.length === 0) return [];

      // stage 3 - truy vấn các sản phẩm được chọn
      const targetIds = targetItems.map(item => item.productId);
      const products = await this.prisma.product.findMany({
        where: { id: { in: targetIds } },
        select: publicProductSelect
      });

      // map lại score và trả về ctx
      return products.map(p => {
        const match = targetItems.find(item => item.productId === p.id);
        return {
          ...this.toPublicContext(p),
          score: match?.score ?? 0
        }
      }).sort((a, b) => b.score - a.score);
    } catch (er) {
      this.logger.error(
        `Embedding retrieval unavailable, using keyword fallback: ${this.errorMessage(er)}`,
      );
      return this.keywordFallback(query, maxProducts);
    }
  }

  // tinh diem tuong dong san pham va yeu cau cua khach
  // dua tren dinh ly cosine tinh goc giua 2 vector
  cosineSimilarity(a: number[], b: number[]) {
    if (a.length === 0 || b.length === 0 || a.length !== b.length) return 0;

    let dot = 0;
    let aMagnitude = 0;
    let bMagnitude = 0;
    for (let i = 0; i < a.length; i += 1) {
      dot += a[i] * b[i];
      aMagnitude += a[i] * a[i];
      bMagnitude += b[i] * b[i];
    }

    if (aMagnitude === 0 || bMagnitude === 0) return 0;
    return dot / (Math.sqrt(aMagnitude) * Math.sqrt(bMagnitude));
  }

  toPublicContext(product: PublicProductRecord): PublicProductContext {
    return {
      id: product.id,
      name: product.name,
      slug: product.slug,
      url: this.productUrl(product.slug),
      thumbnailUrl: product.thumbnailUrl,
      brand: product.brand?.name ?? null,
      category: product.category?.name ?? null,
      tagline: product.tagline,
      description: this.truncate(product.description, 650),
      commonSpecs: this.getCommonSpecs(product.metadata),
      vaultSpecs: product.vaultSpecs,
      averageRating: product.averageRating,
      reviewCount: product.reviewCount,
      variants: product.variants.map((variant) => ({
        id: variant.id,
        sku: variant.sku,
        name: variant.name,
        price: Number(variant.price),
        stock: variant.stock,
        attributes: variant.attributes,
      })),
    };
  }

  // fallback
  // chuyen sang tim kiem bang keyword neu api bi loi
  private async keywordFallback(query: string, take: number) {
    const terms = query
      .toLowerCase()
      .split(/\s+/)
      .map((term) => term.trim())
      .filter((term) => term.length >= 3) // bo di cac tu qua ngan duoi 3 ky tu
      .slice(0, 5); // gioi han toi da 5 tu khoa

    if (terms.length === 0) {
      // tra ve top rated neu khong co san pham nao match
      const products = await this.prisma.product.findMany({
        where: {
          isActive: true,
          variants: { some: { isActive: true } },
        },
        orderBy: [{ averageRating: 'desc' }, { reviewCount: 'desc' }],
        take,
        select: publicProductSelect,
      });
      return products.map((product) => this.toPublicContext(product));
    }

    const products = await this.prisma.product.findMany({
      where: {
        isActive: true,
        variants: { some: { isActive: true } },
        // flatmap nhan ban filter
        // quet toan bo thuoc tinh lien quan
        OR: terms.flatMap((term) => [
          { name: { contains: term } },
          { tagline: { contains: term } },
          { description: { contains: term } },
          { brand: { name: { contains: term } } },
          { category: { name: { contains: term } } },
        ]),
      },
      orderBy: [{ averageRating: 'desc' }, { reviewCount: 'desc' }], // sap xep theo avgrating va so luong danh gia
      take,
      select: publicProductSelect,
    });

    return products.map((product) => this.toPublicContext(product));
  }

  private toVector(value: Prisma.JsonValue): number[] {
    if (!Array.isArray(value)) return [];
    return value
      .map((item) => (typeof item === 'number' ? item : Number(item)))
      .filter((item) => Number.isFinite(item));
  }

  private productUrl(slug: string) {
    const baseUrl = this.configService.get<string>('PUBLIC_PRODUCT_BASE_URL');
    if (!baseUrl) return `gearhub://products/${slug}`;
    return `${baseUrl.replace(/\/$/, '')}/products/${slug}`;
  }

  private truncate(value: string | null, maxLength: number) {
    if (!value) return null;
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

  private errorMessage(error: unknown) {
    return error instanceof Error ? error.message : String(error);
  }
}
