import { NestFactory } from '@nestjs/core';
import { AppModule } from 'src/app.module';
import { ProductImageEmbeddingService } from '../product-image-embedding.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['log', 'warn', 'error'],
  });

  try {
    const batchSize = Number(process.env.AI_IMAGE_EMBEDDING_BACKFILL_BATCH_SIZE);
    const productImageEmbeddingService = app.get(ProductImageEmbeddingService);
    const result = await productImageEmbeddingService.backfillProductImages(
      Number.isInteger(batchSize) && batchSize > 0 ? batchSize : 50,
    );
    console.log(
      `Product image embedding backfill complete: processed=${result.processed} updated=${result.updated} skipped=${result.skipped} failed=${result.failed}`,
    );
  } finally {
    await app.close();
  }
}

bootstrap().catch((error) => {
  console.error(error);
  process.exit(1);
});
