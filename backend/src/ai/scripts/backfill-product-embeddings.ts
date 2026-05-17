import { NestFactory } from '@nestjs/core';
import { AppModule } from 'src/app.module';
import { EmbeddingService } from '../embedding.service';

/// vector hoa toan bo danh sach san pham dang hoat dong
async function bootstrap() {
  /// khoi dong NestJS IoC Container nhung khong mo server port
  /// chay duoi dang CLI
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['log', 'warn', 'error'],
  });

  try {
    const batchSize = Number(process.env.AI_EMBEDDING_BACKFILL_BATCH_SIZE); /// so luong san pham duoc vector hoa moi request
    const embeddingService = app.get(EmbeddingService);
    const result = await embeddingService.backfillProducts(batchSize);
    console.log(
      `Product embedding backfill complete: processed=${result.processed} updated=${result.updated} skipped=${result.skipped}`,
    );
  } finally {
    await app.close();
  }
}

bootstrap().catch((error) => {
  console.error(error);
  process.exit(1);
});
