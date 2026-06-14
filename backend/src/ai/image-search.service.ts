import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { AssetType, ImageEmbeddingSourceType, Prisma } from '@prisma/client';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from 'src/prisma/prisma.service';
import { ProductImageEmbeddingService } from './product-image-embedding.service';

const productImageSearchSelect = {
  id: true,
  productId: true,
  variantId: true,
  assetId: true,
  imageUrl: true,
  sourceType: true,
  embedding: true,
  product: {
    select: {
      id: true,
      name: true,
      slug: true,
      thumbnailUrl: true,
      tagline: true,
      description: true,
      averageRating: true,
      reviewCount: true,
      viewsCount: true,
      soldCount: true,
      attributeConfig: true,
      metadata: true,
      brand: { select: { id: true, name: true } },
      category: { select: { id: true, name: true } },
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
          imageUrl: true,
          isActive: true,
        },
      },
      assets: {
        where: { type: AssetType.IMAGE },
        orderBy: [{ isPrimary: 'desc' }, { createdAt: 'asc' }],
        select: {
          id: true,
          type: true,
          url: true,
          isPrimary: true,
        },
      },
    },
  },
} satisfies Prisma.ProductImageEmbeddingSelect;

type ProductImageSearchRecord = Prisma.ProductImageEmbeddingGetPayload<{
  select: typeof productImageSearchSelect;
}>;

type ScoredProduct = {
  record: ProductImageSearchRecord;
  score: number;
};

@Injectable()
export class ImageSearchService {
  private readonly logger = new Logger(ImageSearchService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly productImageEmbeddingService: ProductImageEmbeddingService,
    private readonly configService: ConfigService,
  ) { }

  /**
   * tìm kiếm sản phẩm tương tự dựa trên hình ảnh đầu vào của người dùng
   * sử dụng GME API để vector hóa hình ảnh và tính toán độ tương đồng cosine
   *
   * vector hóa hình ảnh đầu vào của user
   * lấy toàn bộ dữ liệu vector của hình ảnh sản phẩm đang hoạt động từ db
   * tính điểm cosine giữa ảnh tìm kiếm và ảnh sản phẩm trên ram
   * gộp nhóm theo sản phẩm
   * sắp xếp, lọc kết quả theo threshold và trả về danh sách sản phẩm phù hợp
   */
  async searchByImage(imageBase64: string, limit = 20) {
    // chuẩn hóa số lượng kết quả giới hạn từ 1 đến 50
    const normalizedLimit = Math.min(Math.max(limit, 1), 50);

    // parse và sinh vector embedding cho hình ảnh từ client gửi lên
    const query = await this.productImageEmbeddingService.embedDataUriImage(
      imageBase64,
    );

    // truy vấn các vector ảnh từ CSDL có điều kiện lọc:
    // - chỉ lấy sản phẩm đang hoạt động và có ít nhất một phiên bản đang bán
    // - nếu là ảnh của biến thể, thì phiên bản biển thể đó cũng phải đang hoạt động
    const rows = await this.prisma.productImageEmbedding.findMany({
      where: {
        product: {
          isActive: true,
          variants: { some: { isActive: true } },
        },
        OR: [
          { sourceType: { not: ImageEmbeddingSourceType.VARIANT_IMAGE } },
          {
            sourceType: ImageEmbeddingSourceType.VARIANT_IMAGE,
            variant: { isActive: true },
          },
        ],
      },
      select: productImageSearchSelect,
    });

    this.logger.log(`Loaded ${rows.length} product image embeddings`);

    // báo lỗi dịch vụ khi chưa backfill
    if (rows.length === 0) {
      throw new ServiceUnavailableException(
        'Chưa có dữ liệu vector của sản phẩm. Hãy thử lại sau ít phút.',
      );
    }

    // tính điểm cosine trên ram và gộp theo sản phẩm
    const bestByProduct = new Map<string, ScoredProduct>();
    for (const row of rows) {
      const vector = this.toVector(row.embedding);
      if (vector.length === 0) continue;

      const score = this.cosineSimilarity(query.embedding, vector);
      const current = bestByProduct.get(row.productId);

      // nếu sản phẩm chưa có trong danh sách hoặc tìm thấy ảnh khác có score cao hơn thì cập nhật
      if (!current || score > current.score) {
        bestByProduct.set(row.productId, { record: row, score });
      }
    }

    // chuyển map thành mảng & sort theo điểm
    const ranked = Array.from(bestByProduct.values()).sort(
      (a, b) => b.score - a.score,
    );

    // lấy điểm tương đồng cao nhất của sản phẩm khớp nhất
    const top1 = ranked[0]?.score ?? null;

    const minConfidence = this.getNumberConfig(
      'IMAGE_SEARCH_MIN_CONFIDENCE',
      0.65,
    );
    const minGap = this.getNumberConfig('IMAGE_SEARCH_MIN_GAP', 0.03);

    // lọc theo ngưỡng tối thiểu dựa trên điểm cosine
    if (top1 == null || top1 < minConfidence) {
      return {
        success: false,
        message:
          'GearHub chưa tìm thấy sản phẩm đủ tương tự. Vui lòng thử ảnh rõ hơn hoặc đổi góc chụp.',
        query: {
          mode: 'IMAGE_SEARCH',
          confidenceScore: null,
        },
        results: [],
      };
    }

    // lọc các kết quả thỏa mãn ngưỡng tin cậy, giới hạn số lượng và map thành prd card
    const results = ranked
      .filter((item) => item.score >= minConfidence)
      .slice(0, normalizedLimit)
      .map((item) => this.toProductCard(item));

    this.logTopMatches(ranked.slice(0, 3));

    const top2 = ranked[1]?.score;
    const isAmbiguous = top2 != null && top1 - top2 < minGap;

    return {
      success: true,
      message: isAmbiguous
        ? 'GearHub đã tìm thấy các sản phẩm tương tự với hình ảnh của bạn.'
        : 'GearHub đã tìm thấy các sản phẩm phù hợp với hình ảnh của bạn.',
      query: {
        mode: 'IMAGE_SEARCH',
        confidenceScore: this.roundScore(top1),
      },
      results,
    };
  }

  /**
   * map kết quả tìm kiếm thô có kèm điểm số độ tương đồng
   * thành cấu trúc dữ liệu hiển thị để trả về cho fe
   */
  private toProductCard(item: ScoredProduct) {
    const product = item.record.product;
    const variants = product.variants;

    // tính toán khoảng giá (minpr, maxpr) dựa trên danh sách phiên bản sản phẩm
    const prices = variants.map((variant) => Number(variant.price));
    const minPrice = prices.length > 0 ? Math.min(...prices) : 0;
    const maxPrice = prices.length > 0 ? Math.max(...prices) : minPrice;

    // tổng stock từ các phiên bản đang kinh doanh 
    const stock = variants.reduce((sum, variant) => sum + variant.stock, 0);

    const primaryAsset = product.assets.find((asset) => asset.isPrimary);
    const firstAsset = product.assets[0];

    const thumbnailUrl =
      item.record.imageUrl ||
      product.thumbnailUrl ||
      primaryAsset?.url ||
      firstAsset?.url ||
      variants.find((variant) => variant.imageUrl)?.imageUrl ||
      '';

    return {
      id: product.id,
      name: product.name,
      slug: product.slug,
      brand: product.brand
        ? { id: product.brand.id, name: product.brand.name }
        : null,
      category: product.category
        ? { id: product.category.id, name: product.category.name }
        : null,
      thumbnailUrl,
      matchedImageUrl: item.record.imageUrl,
      matchedVariantId: item.record.variantId,
      price: minPrice,
      minPrice,
      maxPrice,
      stock,
      averageRating: product.averageRating,
      reviewCount: product.reviewCount,
      confidenceScore: this.roundScore(item.score),
      tagline: product.tagline,
      description: product.description,
      viewsCount: product.viewsCount,
      soldCount: product.soldCount,
      attributeConfig: product.attributeConfig,
      metadata: product.metadata,
      variants: variants.map((variant) => ({
        id: variant.id,
        sku: variant.sku,
        name: variant.name,
        price: Number(variant.price),
        stock: variant.stock,
        attributes: variant.attributes,
        imageUrl: variant.imageUrl,
        isActive: variant.isActive,
      })),
      assets: product.assets.map((asset) => ({
        id: asset.id,
        type: asset.type,
        url: asset.url,
        isPrimary: asset.isPrimary,
      })),
    };
  }

  private cosineSimilarity(a: number[], b: number[]) {
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

  private toVector(value: Prisma.JsonValue): number[] {
    if (!Array.isArray(value)) return [];
    return value
      .map((item) => (typeof item === 'number' ? item : Number(item)))
      .filter((item) => Number.isFinite(item));
  }

  private logTopMatches(items: ScoredProduct[]) {
    for (const item of items) {
      this.logger.log(
        `Image search match product="${item.record.product.name}" image="${item.record.imageUrl}" score=${this.roundScore(item.score)}`,
      );
    }
  }

  private roundScore(value: number) {
    return Number(value.toFixed(4));
  }

  private getNumberConfig(key: string, fallback: number) {
    const value = Number(this.configService.get<string>(key));
    return Number.isFinite(value) ? value : fallback;
  }
}
