import { Test, TestingModule } from '@nestjs/testing';
import { ProductsService } from './products.service';
import { RedisService } from 'src/redis/redis.service';
import { PrismaService } from 'src/prisma/prisma.service';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { InventoriesService } from 'src/inventories/inventories.service';
import { EmbeddingService } from 'src/ai/embedding.service';

describe('ProductsService', () => {
  let service: ProductsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProductsService,
        { provide: RedisService, useValue: {} },
        { provide: PrismaService, useValue: {} },
        { provide: CloudinaryService, useValue: {} },
        { provide: InventoriesService, useValue: {} },
        {
          provide: EmbeddingService,
          useValue: { syncProductEmbeddingBestEffort: jest.fn() },
        },
      ],
    }).compile();

    service = module.get<ProductsService>(ProductsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
