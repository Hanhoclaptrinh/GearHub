import { MessageStatus, MessageType } from '@prisma/client';
import { PromptBuilderService } from './prompt-builder.service';

describe('PromptBuilderService', () => {
  it('builds a prompt with memory, recent messages, product context, and current message', () => {
    const service = new PromptBuilderService();
    const prompt = service.buildPrompt({
      aiSummary: 'Khach thich laptop mong nhe.',
      recentMessages: [
        {
          id: 'm1',
          roomId: 'r1',
          senderId: 'u1',
          content: 'Minh can laptop di lam.',
          type: MessageType.TEXT,
          status: MessageStatus.SENT,
          readAt: null,
          isAi: false,
          createdAt: new Date(),
        },
      ],
      products: [
        {
          id: 'p1',
          name: 'GearHub Pro 14',
          slug: 'gearhub-pro-14',
          url: 'gearhub://products/gearhub-pro-14',
          brand: 'GearHub',
          category: 'Laptop',
          tagline: 'Mong nhe',
          description: 'Laptop van phong cao cap',
          commonSpecs: { cpu: 'Core Ultra', ram: '16GB' },
          averageRating: 4.8,
          reviewCount: 24,
          variants: [
            {
              id: 'v1',
              sku: 'PRO14',
              name: 'GearHub Pro 14 - 16GB',
              price: 24000000,
              stock: 3,
              attributes: { ram: '16GB' },
            },
          ],
        },
      ],
      currentUserMessage: 'May nay con hang khong?',
    });

    expect(prompt).toContain('GearHub AI Concierge');
    expect(prompt).toContain('Khach thich laptop mong nhe.');
    expect(prompt).toContain('GearHub Pro 14');
    expect(prompt).toContain('May nay con hang khong?');
  });

  it('bounds recent messages, product context, summary, and current message', () => {
    const service = new PromptBuilderService();
    const messages = Array.from({ length: 20 }, (_, index) => ({
      id: `m${index}`,
      roomId: 'r1',
      senderId: 'u1',
      content: `message-${index}-${'x'.repeat(500)}`,
      type: MessageType.TEXT,
      status: MessageStatus.SENT,
      readAt: null,
      isAi: false,
      createdAt: new Date(),
    }));
    const products = Array.from({ length: 5 }, (_, index) => ({
      id: `p${index}`,
      name: `Product ${index}`,
      slug: `product-${index}`,
      url: `gearhub://products/product-${index}`,
      brand: 'GearHub',
      category: 'Laptop',
      tagline: null,
      description: 'Public catalog description',
      commonSpecs: null,
      averageRating: 4.5,
      reviewCount: 10,
      variants: [],
    }));

    const prompt = service.buildPrompt({
      aiSummary: 's'.repeat(3000),
      recentMessages: messages,
      products,
      currentUserMessage: 'u'.repeat(2000),
    });

    expect(prompt).not.toContain('message-0');
    expect(prompt).toContain('message-19');
    expect(prompt).toContain('Product 0');
    expect(prompt).toContain('Product 2');
    expect(prompt).not.toContain('Product 3');
    expect(prompt.length).toBeLessThanOrEqual(12003);
  });
});
