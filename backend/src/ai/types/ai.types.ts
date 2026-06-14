import { ChatMessageRecord } from 'src/chat/repositories/chat.repository';

export type PublicProductVariantContext = {
  id: string;
  sku: string;
  name: string;
  price: number;
  stock: number;
  attributes: unknown;
};

export type PublicProductContext = {
  id: string;
  name: string;
  slug: string;
  url: string;
  thumbnailUrl: string | null;
  brand: string | null;
  category: string | null;
  tagline: string | null;
  description: string | null;
  commonSpecs: unknown;
  averageRating: number;
  reviewCount: number;
  variants: PublicProductVariantContext[];
  score?: number;
};

export type PromptInput = {
  aiSummary: string | null;
  recentMessages: ChatMessageRecord[];
  products: PublicProductContext[];
  currentUserMessage: string;
};

export type AiChatResponse = {
  content: string;
  promptText: string;
  retrievedProducts: PublicProductContext[];
  latencyMs: number;
  model: string;
  usedFallback: boolean;
};
