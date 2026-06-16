export const Role = {
  USER: 'USER',
  STAFF: 'STAFF',
  ADMIN: 'ADMIN',
} as const;

export type Role = (typeof Role)[keyof typeof Role];

export interface User {
  id: string;
  email: string;
  role: Role;
  fullName?: string;
  avatarUrl?: string;
  profile?: {
    fullName?: string;
    avatarUrl?: string;
    phone?: string;
  };
  isActive: boolean;
  createdAt: string;
}

export interface Tokens {
  accessToken: string;
  refreshToken: string;
}

export interface AuthResponse {
  message: string;
  data: {
    user: User;
    tokens: Tokens;
  };
}

export interface Category {
  id: string;
  name: string;
  slug: string;
  description?: string;
  icon?: string;
  iconUrl?: string;
  parentId?: string;
  createdAt?: string;
  updatedAt?: string;
  _count?: {
    products?: number;
    children?: number;
  };
  children?: Category[];
}

export interface Brand {
  id: string;
  name: string;
  slug: string;
  description?: string;
  logoUrl?: string;
  bannerUrl?: string;
  quote?: string;
  philosophy?: string;
  isActive: boolean;
  isFeatured?: boolean;
  score?: number;
  createdAt?: string;
  updatedAt?: string;
  _count?: {
    products: number;
  };
}

export type AssetType = 'IMAGE' | 'GLB' | 'USDZ';

export interface ProductAsset {
  id: string;
  url: string;
  isPrimary: boolean;
  type: AssetType;
}

export interface ProductVariant {
  id: string;
  sku: string;
  price: number;
  stock: number;
  attributes: Record<string, any>;
  isActive: boolean;
}

export interface Product {
  id: string;
  name: string;
  slug: string;
  tagline?: string;
  thumbnailUrl?: string;
  description: string;
  categoryId: string;
  brandId: string;
  category?: Category;
  brand?: Brand;
  isActive: boolean;
  isFeatured?: boolean;
  assets: ProductAsset[];
  variants: ProductVariant[];
  attributeConfig?: string[];
  createdAt: string;
  updatedAt?: string;
}

export const OrderStatus = {
  PENDING: 'PENDING',
  CONFIRMED: 'CONFIRMED',
  PROCESSING: 'PROCESSING',
  SHIPPING: 'SHIPPING',
  DELIVERED: 'DELIVERED',
  CANCELLED: 'CANCELLED',
  RETURNED: 'RETURNED',
  FAILED: 'FAILED',
  COMPLETED: 'COMPLETED',
} as const;

export type OrderStatus = (typeof OrderStatus)[keyof typeof OrderStatus];

export interface OrderItem {
  id: string;
  productVariantId: string;
  quantity: number;
  price: number;
  productName: string;
  sku: string;
}

export interface OrderTracking {
  id: string;
  orderId: string;
  statusLabel: string | null;
  description: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface Order {
  id: string;
  orderNumber: string;
  status: OrderStatus;
  totalAmount: number;
  shippingAddress: string;
  phone: string;
  notes?: string;
  note?: string;
  voucherDiscount?: number;
  userId: string;
  user?: User;
  items: OrderItem[];
  createdAt: string;
  receiverName?: string;
  receiverPhone?: string;
  paymentMethod?: 'COD' | 'ONLINE' | 'PAYMENT_GATEWAY' | 'E_WALLET' | 'BANK_TRANSFER';
  paymentStatus?: 'PENDING' | 'PAID' | 'FAILED' | 'REFUNDED';
  tracking?: OrderTracking[];
}

export interface DashboardStats {
  totalOrders: number;
  totalRevenue: number;
  totalProducts: number;
  totalUsers: number;
  recentOrders: Order[];
  revenueByMonth: { month: string; amount: number }[];
}

export const VoucherType = {
  PERCENT: 'PERCENT',
  FIXED_AMOUNT: 'FIXED_AMOUNT',
} as const;

export type VoucherType = (typeof VoucherType)[keyof typeof VoucherType];

export interface Voucher {
  id: string;
  code: string;
  name: string;
  description?: string;
  type: VoucherType;
  value: number;
  minOrderAmount: number;
  maxDiscountAmount?: number;
  quantity: number;
  claimedCount: number;
  usedCount: number;
  startsAt?: string;
  expiresAt?: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ReviewAsset {
  id: string;
  reviewId: string;
  url: string;
  type: 'IMAGE' | 'VIDEO' | string;
}

export interface Review {
  id: string;
  userId: string;
  productId: string;
  rating: number;
  comment?: string;
  reply?: string;
  isVerifiedPurchase: boolean;
  isHidden: boolean;
  createdAt: string;
  updatedAt: string;
  orderItemId?: string;
  assets: ReviewAsset[];
  isAnonymous?: boolean;
  product?: Product;
  user?: User;
  variantName?: string;
}
export * from './flash-sale.types';
