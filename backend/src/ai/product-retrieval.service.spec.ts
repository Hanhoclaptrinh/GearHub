import { ProductRetrievalService } from './product-retrieval.service';

describe('ProductRetrievalService', () => {
  it('computes cosine similarity', () => {
    const service = new ProductRetrievalService({} as any, {} as any, {} as any);

    expect(service.cosineSimilarity([1, 0], [1, 0])).toBeCloseTo(1);
    expect(service.cosineSimilarity([1, 0], [0, 1])).toBeCloseTo(0);
    expect(service.cosineSimilarity([1, 1], [1, 1])).toBeCloseTo(1);
  });
});
