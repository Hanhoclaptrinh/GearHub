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
  children?: Category[];
}

export interface Brand {
  id: string;
  name: string;
  slug: string;
  description?: string;
  logoUrl?: string;
  quote?: string;
  philosophy?: string;
  isActive: boolean;
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

export interface Order {
  id: string;
  orderNumber: string;
  status: OrderStatus;
  totalAmount: number;
  shippingAddress: string;
  phone: string;
  notes?: string;
  userId: string;
  user?: User;
  items: OrderItem[];
  createdAt: string;
  receiverName?: string;
  receiverPhone?: string;
  paymentMethod?: 'COD' | 'ONLINE';
  paymentStatus?: 'PENDING' | 'PAID' | 'FAILED' | 'REFUNDED';
}

export interface DashboardStats {
  totalOrders: number;
  totalRevenue: number;
  totalProducts: number;
  totalUsers: number;
  recentOrders: Order[];
  revenueByMonth: { month: string; amount: number }[];
}
