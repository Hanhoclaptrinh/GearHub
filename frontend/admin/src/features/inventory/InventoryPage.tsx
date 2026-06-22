import React, { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Package,
  Search,
  Filter,
  History,
  ArrowUpDown,
  AlertTriangle,
  XCircle,
  ChevronDown,
  ChevronRight,
  SlidersHorizontal,
  RotateCcw,
} from '../../components/ui/IconlyIcons';
import {
  Bag as IconlyBag,
  Bookmark as IconlyBookmark,
  Chart as IconlyChart,
  Danger as IconlyDanger,
  Category as IconlyCategory,
} from 'react-iconly';
import { inventoryService, type InventoryItem, type InventoryVariant } from '../../services/inventory.service';
import { productService } from '../../services/product.service';
import { categoryService } from '../../services/category.service';
import { brandService } from '../../services/brand.service';
import { authService } from '../../services/auth.service';
import { AdjustStockModal } from './AdjustStockModal';
import { TransactionHistoryModal } from './TransactionHistoryModal';
import { Badge } from '../../components/ui/Badge';
import { Button } from '../../components/ui/Button';
import { Card, CardContent, CardHeader, CardTitle } from '../../components/ui/Card';
import { cn } from '../../utils/cn';
import type { Category, Brand } from '../../types';

const LOW_STOCK_THRESHOLD = 10;

const stockStatusConfig = {
  IN_STOCK: {
    label: 'Còn hàng',
    color: 'bg-[#edf9f1] text-[#2f8f5b] border-[#d6f3df]',
  },
  LOW_STOCK: {
    label: 'Sắp hết',
    color: 'bg-[#fff7e6] text-[#946200] border-[#ffe6a6]',
  },
  OUT_OF_STOCK: {
    label: 'Hết hàng',
    color: 'bg-red-50 text-red-600 border-red-100',
  },
};

export const InventoryPage: React.FC = () => {
  const user = authService.getCurrentUser();
  const isAdmin = user?.role === 'ADMIN';

  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [brandId, setBrandId] = useState('');
  const [stockFilter, setStockFilter] = useState<'all' | 'low_stock' | 'out_of_stock'>('all');
  const [page, setPage] = useState(1);
  const [isFilterOpen, setIsFilterOpen] = useState(true);
  const [expandedProducts, setExpandedProducts] = useState<Set<string>>(new Set());
  const [showAllVariantIds, setShowAllVariantIds] = useState<string[]>([]);

  const [adjustVariant, setAdjustVariant] = useState<InventoryVariant & { productName: string } | null>(null);
  const [historyVariantId, setHistoryVariantId] = useState<string | null>(null);
  const [historyVariantName, setHistoryVariantName] = useState('');

  const limit = 15;

  const { data: categories = [] } = useQuery<Category[]>({
    queryKey: ['categories'],
    queryFn: categoryService.getAllCategories,
  });

  const { data: brands = [] } = useQuery<Brand[]>({
    queryKey: ['brands'],
    queryFn: () => brandService.getAllBrands(),
  });

  const { data: inventoryStats } = useQuery({
    queryKey: ['products', 'inventory-stats'],
    queryFn: productService.getInventoryStats,
  });

  const { data, isLoading, isError } = useQuery({
    queryKey: ['inventory', search, categoryId, brandId, stockFilter, page],
    queryFn: () => inventoryService.getInventoryList({
      search: search || undefined,
      categoryId: categoryId || undefined,
      brandId: brandId || undefined,
      stockFilter,
      page,
      limit,
    }),
  });

  const products: InventoryItem[] = data?.data || [];
  const meta = data?.meta || { total: 0, page: 1, lastPage: 1 };

  const visibleSkuCount = products.reduce((sum, product) => sum + product.variants.length, 0);
  const visibleStock = products.reduce((sum, product) => sum + product.totalStock, 0);
  const visibleLowSkuCount = products.reduce((sum, product) => sum + product.variants.filter((variant) => variant.stockStatus === 'LOW_STOCK').length, 0);
  const visibleOutSkuCount = products.reduce((sum, product) => sum + product.variants.filter((variant) => variant.stockStatus === 'OUT_OF_STOCK').length, 0);
  const visibleIssueProductCount = products.filter((product) => product.variants.some((variant) => variant.stockStatus !== 'IN_STOCK')).length;

  const formatCompact = (value: number) =>
    new Intl.NumberFormat('vi-VN', { notation: 'compact', maximumFractionDigits: 1 } as any).format(value);

  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(value);

  const resetFilters = () => {
    setSearch('');
    setCategoryId('');
    setBrandId('');
    setStockFilter('all');
    setPage(1);
  };

  const toggleExpand = (productId: string) => {
    setExpandedProducts((current) => {
      const next = new Set(current);
      if (next.has(productId)) {
        next.delete(productId);
      } else {
        next.add(productId);
      }
      return next;
    });
  };

  const toggleShowAllVariants = (productId: string) => {
    setShowAllVariantIds((currentIds) =>
      currentIds.includes(productId) ? currentIds.filter((id) => id !== productId) : [...currentIds, productId],
    );
  };

  const stockOptions = [
    { value: 'all', label: 'Tất cả' },
    { value: 'low_stock', label: 'Sắp hết' },
    { value: 'out_of_stock', label: 'Hết hàng' },
  ] as const;

  const activeFilterChips = [
    search ? { id: 'search', label: `Từ khóa: ${search}`, onRemove: () => setSearch('') } : null,
    categoryId ? { id: 'category', label: `Danh mục: ${categories.find((category) => category.id === categoryId)?.name || categoryId}`, onRemove: () => setCategoryId('') } : null,
    brandId ? { id: 'brand', label: `Thương hiệu: ${brands.find((brand) => brand.id === brandId)?.name || brandId}`, onRemove: () => setBrandId('') } : null,
    stockFilter !== 'all' ? { id: 'stock', label: `Kho: ${stockOptions.find((option) => option.value === stockFilter)?.label || stockFilter}`, onRemove: () => setStockFilter('all') } : null,
  ].filter(Boolean) as { id: string; label: string; onRemove: () => void }[];

  const statCards = [
    {
      label: 'Tổng SKU',
      value: inventoryStats?.totalSKUs ?? visibleSkuCount,
      icon: IconlyCategory,
      bgClass: 'bg-[#9694ff]',
    },
    {
      label: 'Tổng tồn kho',
      value: inventoryStats?.totalStock ?? visibleStock,
      icon: IconlyBag,
      bgClass: 'bg-[#5ddc97]',
    },
    {
      label: 'SKU sắp hết',
      value: inventoryStats?.lowStockCount ?? visibleLowSkuCount,
      icon: IconlyDanger,
      bgClass: 'bg-[#eaca4a]',
    },
    {
      label: 'SKU ngưng bán',
      value: inventoryStats?.inactiveSKUs ?? 0,
      icon: IconlyBookmark,
      bgClass: 'bg-[#ff7976]',
    },
    {
      label: 'Giá trị kho',
      value: `${formatCompact(inventoryStats?.actualCapital ?? 0)}₫`,
      icon: IconlyChart,
      bgClass: 'bg-[#57caeb]',
    },
  ];

  const visiblePages = Array.from({ length: Math.min(meta.lastPage, 5) }, (_, index) => {
    if (meta.lastPage <= 5) return index + 1;
    if (page <= 3) return index + 1;
    if (page >= meta.lastPage - 2) return meta.lastPage - 4 + index;
    return page - 2 + index;
  });

  return (
    <div className="space-y-6 pb-10 animate-in fade-in slide-in-from-bottom-3 duration-500">
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-6">
        {statCards.map((stat) => (
          <Card
            key={stat.label}
            className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white transition-all duration-300 group"
          >
            <CardContent className="py-6 px-6 flex items-center gap-4">
              <div className={cn('w-12 h-12 rounded-[10px] flex items-center justify-center transition-transform duration-300 group-hover:scale-105 shadow-xs shrink-0 text-white', stat.bgClass)}>
                <stat.icon set="bold" primaryColor="white" size={24} />
              </div>
              <div className="flex-1 min-w-0">
                <h6 className="text-[15px] font-semibold text-[#7c8db5] leading-tight mb-1 truncate">{stat.label}</h6>
                <div className="text-[24px] font-extrabold text-[#25396f] leading-none font-heading truncate">
                  {stat.value}
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {visibleIssueProductCount > 0 && (
        <div className="rounded-[12px] bg-[#fff7e6] text-[#946200] shadow-[0_5px_15px_rgba(25,42,70,0.04)] px-5 py-4 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center gap-3">

            <div>
              <h6 className="font-extrabold text-[#25396f] mb-1">Có hàng cần kiểm tra trên trang này</h6>
              <p className="text-sm font-semibold text-[#946200] mb-0">
                {visibleIssueProductCount} sản phẩm có SKU sắp hết hoặc đã hết hàng. Có {visibleLowSkuCount} SKU sắp hết và {visibleOutSkuCount} SKU hết hàng.
              </p>
            </div>
          </div>
          <Button
            type="button"
            variant={stockFilter === 'low_stock' ? 'secondary' : 'outline'}
            size="sm"
            onClick={() => { setStockFilter(stockFilter === 'low_stock' ? 'all' : 'low_stock'); setPage(1); }}
            className="rounded-[8px] shrink-0"
          >
            {stockFilter === 'low_stock' ? 'Xem toàn bộ' : 'Lọc SKU sắp hết'}
          </Button>
        </div>
      )}

      <Card className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white overflow-hidden">
        <CardHeader className="border-none px-6 pt-6 pb-3 flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4">
          <div>
            <CardTitle className="text-[20px] text-[#25396f] flex items-center gap-2">
              Quản lý kho hàng
            </CardTitle>
          </div>

          <div className="flex flex-col sm:flex-row gap-3 w-full xl:w-auto">
            <div className="relative min-w-0 sm:min-w-[320px]">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#7c8db5]" />
              <input
                type="text"
                placeholder="Tìm sản phẩm, SKU, biến thể..."
                className="w-full h-11 pl-11 pr-4 rounded-[8px] border border-[#dce7f1] bg-white text-sm font-semibold text-[#25396f] outline-none transition-all focus:border-primary focus:ring-4 focus:ring-primary/10"
                value={search}
                onChange={(event) => { setSearch(event.target.value); setPage(1); }}
              />
            </div>
            <Button
              type="button"
              variant={isFilterOpen ? 'secondary' : 'outline'}
              size="md"
              onClick={() => setIsFilterOpen(!isFilterOpen)}
              className="rounded-[8px] gap-2"
            >
              <Filter className="w-4 h-4" />
              Bộ lọc
            </Button>
          </div>
        </CardHeader>

        {isFilterOpen && (
          <div className="mx-6 mb-4 rounded-[12px] bg-[#f2f7ff] border border-[#dce7f1] p-5">
            <div className="grid grid-cols-1 lg:grid-cols-4 gap-5">
              <div>
                <label className="block text-[11px] font-extrabold text-[#7c8db5] uppercase mb-2">Trạng thái kho</label>
                <div className="flex flex-wrap gap-2">
                  {stockOptions.map((option) => (
                    <button
                      key={option.value}
                      type="button"
                      onClick={() => { setStockFilter(option.value); setPage(1); }}
                      className={cn(
                        'px-3 py-1.5 rounded-[8px] text-xs font-extrabold border transition-all',
                        stockFilter === option.value
                          ? 'bg-primary text-white border-primary shadow-sm'
                          : 'bg-white text-[#7c8db5] border-[#dce7f1] hover:text-primary hover:border-primary',
                      )}
                    >
                      {option.label}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-extrabold text-[#7c8db5] uppercase mb-2">Danh mục</label>
                <select
                  className="w-full h-10 rounded-[8px] border border-[#dce7f1] bg-white px-3 text-sm font-semibold text-[#25396f] outline-none focus:border-primary"
                  value={categoryId}
                  onChange={(event) => { setCategoryId(event.target.value); setPage(1); }}
                >
                  <option value="">Tất cả danh mục</option>
                  {categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
                </select>
              </div>

              <div>
                <label className="block text-[11px] font-extrabold text-[#7c8db5] uppercase mb-2">Thương hiệu</label>
                <select
                  className="w-full h-10 rounded-[8px] border border-[#dce7f1] bg-white px-3 text-sm font-semibold text-[#25396f] outline-none focus:border-primary"
                  value={brandId}
                  onChange={(event) => { setBrandId(event.target.value); setPage(1); }}
                >
                  <option value="">Tất cả thương hiệu</option>
                  {brands.map((brand) => <option key={brand.id} value={brand.id}>{brand.name}</option>)}
                </select>
              </div>

              <div className="flex items-end">
                <button
                  type="button"
                  onClick={resetFilters}
                  className="w-full h-10 rounded-[8px] bg-white border border-red-100 text-red-500 text-xs font-extrabold uppercase hover:bg-red-50 transition-all inline-flex items-center justify-center gap-2"
                >
                  <RotateCcw className="w-4 h-4" />
                  Xóa bộ lọc
                </button>
              </div>
            </div>
          </div>
        )}

        <CardContent className="px-0 pb-0 pt-0">
          {isError && (
            <div className="mx-6 mb-4 rounded-[10px] border border-red-100 bg-red-50 p-4 flex gap-3 text-red-600">
              <AlertTriangle className="w-5 h-5 shrink-0 mt-0.5" />
              <div>
                <h6 className="font-extrabold text-red-700 mb-1">Không thể tải dữ liệu kho</h6>
                <p className="text-sm font-semibold text-red-500 mb-0">Máy chủ hiện không phản hồi. Vui lòng thử lại sau.</p>
              </div>
            </div>
          )}

          <div className="px-6 pb-3 flex flex-col md:flex-row md:items-center justify-between gap-3">
            <div className="flex flex-wrap items-center gap-2">
              <Badge variant="info" className="rounded-[6px] border-none bg-primary/10 text-primary">
                {meta.total} sản phẩm
              </Badge>
              <Badge variant="default" className="rounded-[6px] border-none bg-[#f2f7ff] text-[#607080]">
                {visibleSkuCount} SKU trên trang
              </Badge>
              {activeFilterChips.map((chip) => (
                <button
                  key={chip.id}
                  type="button"
                  onClick={chip.onRemove}
                  className="inline-flex items-center gap-1.5 rounded-[6px] bg-[#f2f7ff] px-2.5 py-1 text-[11px] font-extrabold text-[#607080] hover:bg-red-50 hover:text-red-500 transition-colors"
                >
                  {chip.label}
                  <XCircle className="w-3.5 h-3.5" />
                </button>
              ))}
              {activeFilterChips.length > 0 && (
                <button type="button" onClick={resetFilters} className="text-[11px] font-extrabold text-red-500 hover:text-red-600">
                  Xóa tất cả
                </button>
              )}
            </div>
            <p className="text-[12px] font-bold text-[#7c8db5] mb-0">
              Trang <span className="text-[#25396f]">{page}</span> / {meta.lastPage || 1}
            </p>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse min-w-[1180px]">
              <thead>
                <tr className="border-y border-[#f2f7ff] bg-[#fbfcff] text-[#7c8db5] text-[11px] font-extrabold uppercase">
                  <th className="w-12 px-5 py-4"></th>
                  <th className="px-5 py-4 w-[34%]">Sản phẩm / biến thể</th>
                  <th className="px-5 py-4">Tổng tồn / SKU</th>
                  <th className="px-5 py-4">Danh mục / Brand</th>
                  <th className="px-5 py-4">Tình trạng kho</th>
                  <th className="px-5 py-4 text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#f2f7ff] text-sm">
                {isLoading ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-16 text-center">
                      <div className="inline-flex flex-col items-center gap-3">
                        <div className="w-10 h-10 rounded-full border-4 border-primary/20 border-t-primary animate-spin" />
                        <p className="text-sm font-bold text-[#7c8db5] mb-0">Đang tải dữ liệu kho...</p>
                      </div>
                    </td>
                  </tr>
                ) : products.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-20 text-center">
                      <div className="mx-auto w-16 h-16 rounded-[14px] bg-[#f2f7ff] flex items-center justify-center mb-4">
                        <Package className="w-8 h-8 text-primary/50" />
                      </div>
                      <h6 className="text-[18px] font-extrabold text-[#25396f] mb-1">Không tìm thấy hàng tồn kho</h6>
                      <p className="text-sm font-semibold text-[#7c8db5] mb-0">Thử đổi từ khóa tìm kiếm hoặc xóa bộ lọc đang áp dụng.</p>
                    </td>
                  </tr>
                ) : (
                  products.map((product) => {
                    const isExpanded = expandedProducts.has(product.productId);
                    const lowSkuCount = product.variants.filter((variant) => variant.stockStatus === 'LOW_STOCK').length;
                    const outSkuCount = product.variants.filter((variant) => variant.stockStatus === 'OUT_OF_STOCK').length;
                    const hasIssues = lowSkuCount > 0 || outSkuCount > 0;
                    const isShowingAllVariants = showAllVariantIds.includes(product.productId);
                    const visibleVariants = isShowingAllVariants ? product.variants : product.variants.slice(0, 6);
                    const hiddenVariantCount = Math.max(0, product.variants.length - 6);

                    return (
                      <React.Fragment key={product.productId}>
                        <tr
                          className={cn(
                            'group hover:bg-[#f8faff] transition-colors cursor-pointer',
                            isExpanded && 'bg-[#f8faff]',
                          )}
                          onClick={() => toggleExpand(product.productId)}
                        >
                          <td className="px-5 py-4 text-center">
                            <button
                              type="button"
                              className="w-7 h-7 rounded-[8px] bg-[#f2f7ff] text-primary inline-flex items-center justify-center"
                              aria-label={isExpanded ? 'Thu gọn biến thể' : 'Mở rộng biến thể'}
                            >
                              {isExpanded ? <ChevronDown className="w-4 h-4" /> : <ChevronRight className="w-4 h-4" />}
                            </button>
                          </td>

                          <td className="px-5 py-4">
                            <div className="flex items-center gap-4">
                              <div className="relative w-[56px] h-[56px] rounded-[12px] bg-[#f2f7ff] border border-[#dce7f1] overflow-hidden flex items-center justify-center shrink-0">
                                {product.thumbnailUrl ? (
                                  <img src={product.thumbnailUrl} alt={product.productName} className="w-full h-full object-cover" />
                                ) : (
                                  <Package className="w-6 h-6 text-[#7c8db5]" />
                                )}
                              </div>
                              <div className="min-w-0">
                                <h6 className="font-extrabold text-[#25396f] text-[14px] truncate max-w-[320px] mb-1">
                                  {product.productName}
                                </h6>
                                <div className="flex flex-wrap items-center gap-1.5">
                                  <Badge variant="default" className="rounded-[5px] px-1.5 py-0.5 text-[9px] border-none bg-[#f2f7ff] text-[#607080]">
                                    {product.variants.length} SKU
                                  </Badge>
                                  {lowSkuCount > 0 && <Badge variant="warning" className="rounded-[5px] px-1.5 py-0.5 text-[9px]">LOW {lowSkuCount}</Badge>}
                                  {outSkuCount > 0 && <Badge variant="danger" className="rounded-[5px] px-1.5 py-0.5 text-[9px]">OUT {outSkuCount}</Badge>}
                                </div>
                              </div>
                            </div>
                          </td>

                          <td className="px-5 py-4">
                            <div className="min-w-[120px]">
                              <div className="flex items-center justify-between mb-1">
                                <span className={cn('text-lg font-extrabold', product.totalStock === 0 ? 'text-red-500' : product.totalStock <= LOW_STOCK_THRESHOLD ? 'text-[#ffb236]' : 'text-[#4fbe87]')}>
                                  {product.totalStock}
                                </span>
                                <span className="text-[10px] font-bold text-[#7c8db5]">{product.variants.length} SKU</span>
                              </div>
                              <div className="h-1.5 rounded-full bg-[#f2f7ff] overflow-hidden">
                                <div
                                  className={cn('h-full rounded-full', product.totalStock === 0 ? 'bg-red-500' : product.totalStock <= LOW_STOCK_THRESHOLD ? 'bg-[#ffb236]' : 'bg-[#4fbe87]')}
                                  style={{ width: `${Math.min(100, product.totalStock === 0 ? 4 : product.totalStock <= LOW_STOCK_THRESHOLD ? 35 : 78)}%` }}
                                />
                              </div>
                            </div>
                          </td>

                          <td className="px-5 py-4">
                            <div className="flex flex-col gap-1 min-w-[150px]">
                              <span className="text-[11px] font-extrabold text-[#25396f] uppercase">{product.category?.name || 'Chưa phân loại'}</span>
                              <span className="text-[11px] font-bold text-[#7c8db5]">{product.brand?.name || 'Chưa có thương hiệu'}</span>
                            </div>
                          </td>

                          <td className="px-5 py-4">
                            {hasIssues ? (
                              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-[6px] text-[10px] font-extrabold uppercase bg-[#fff7e6] text-[#946200] border border-[#ffe6a6]">

                                Cần kiểm tra
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-[6px] text-[10px] font-extrabold uppercase bg-[#edf9f1] text-[#2f8f5b] border border-[#d6f3df]">

                                Ổn định
                              </span>
                            )}
                          </td>

                          <td className="px-5 py-4 text-right" onClick={(event) => event.stopPropagation()}>
                            <button
                              type="button"
                              onClick={() => toggleExpand(product.productId)}
                              className="h-9 rounded-[8px] px-3 inline-flex items-center gap-2 text-[11px] font-extrabold text-primary bg-primary/10 hover:bg-primary/20 transition-colors"
                            >
                              <SlidersHorizontal className="w-4 h-4" />
                              {isExpanded ? 'Thu gọn' : 'Xem SKU'}
                            </button>
                          </td>
                        </tr>

                        {isExpanded && (
                          <tr>
                            <td colSpan={6} className="px-6 py-5 bg-[#f8faff]">
                              <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-2 mb-4">
                                <div>
                                  <h6 className="text-[15px] font-extrabold text-[#25396f] mb-1">Chi tiết tồn kho theo SKU</h6>

                                </div>
                                <Badge variant="info" className="rounded-[6px] border-none bg-primary/10 text-primary">
                                  {product.variants.length} SKU
                                </Badge>
                              </div>

                              <div className="overflow-x-auto rounded-[12px] border border-[#dce7f1] bg-white">
                                <table className="w-full min-w-[840px] text-left">
                                  <thead className="bg-[#fbfcff] text-[10px] font-extrabold uppercase text-[#7c8db5]">
                                    <tr>
                                      <th className="px-4 py-3">SKU / biến thể</th>
                                      <th className="px-4 py-3">Thuộc tính</th>
                                      <th className="px-4 py-3">Tồn hiện tại</th>
                                      <th className="px-4 py-3">Giá bán</th>
                                      <th className="px-4 py-3">Trạng thái</th>
                                      <th className="px-4 py-3 text-right">Thao tác</th>
                                    </tr>
                                  </thead>
                                  <tbody className="divide-y divide-[#f2f7ff]">
                                    {visibleVariants.map((variant) => {
                                      const status = stockStatusConfig[variant.stockStatus];


                                      return (
                                        <tr key={variant.variantId} className={cn(!variant.isActive && 'bg-red-50/40')}>
                                          <td className="px-4 py-3">
                                            <div className="flex items-center gap-3">
                                              <div className="w-10 h-10 rounded-[8px] overflow-hidden bg-[#f2f7ff] border border-[#dce7f1] flex items-center justify-center shrink-0">
                                                {variant.imageUrl ? (
                                                  <img src={variant.imageUrl} alt={variant.variantName} className="w-full h-full object-cover" />
                                                ) : (
                                                  <Package className="w-5 h-5 text-[#7c8db5]" />
                                                )}
                                              </div>
                                              <div className="min-w-0">
                                                <span className="font-mono text-[10px] font-extrabold text-[#25396f] bg-[#f2f7ff] px-2 py-1 rounded-[6px]">
                                                  {variant.sku}
                                                </span>
                                                <p className="mt-1 text-[11px] font-bold text-[#607080] truncate max-w-[220px]">
                                                  {variant.variantName.split(' - ')[1] || variant.variantName}
                                                </p>
                                              </div>
                                            </div>
                                          </td>
                                          <td className="px-4 py-3">
                                            <div className="flex flex-wrap gap-1.5">
                                              {Object.entries(variant.attributes as Record<string, any>).length > 0 ? (
                                                Object.entries(variant.attributes as Record<string, any>).map(([key, value]) => (
                                                  <span key={key} className="text-[11px] font-bold px-2 py-1 bg-[#f2f7ff] rounded-[6px] text-[#607080]">
                                                    <span className="text-[#7c8db5]">{key}:</span> {String(value)}
                                                  </span>
                                                ))
                                              ) : (
                                                <span className="text-[11px] font-bold text-[#a8b4c7]">Không có thuộc tính</span>
                                              )}
                                            </div>
                                          </td>
                                          <td className="px-4 py-3">
                                            <span className={cn('text-base font-extrabold', variant.currentStock === 0 ? 'text-red-500' : variant.currentStock <= LOW_STOCK_THRESHOLD ? 'text-[#ffb236]' : 'text-[#4fbe87]')}>
                                              {variant.currentStock} món
                                            </span>
                                          </td>
                                          <td className="px-4 py-3 font-extrabold text-[#25396f]">
                                            {formatCurrency(Number(variant.price))}
                                          </td>
                                          <td className="px-4 py-3">
                                            <span className={cn('inline-flex items-center gap-1.5 px-2 py-1 rounded-[6px] text-[10px] font-extrabold uppercase border', status.color)}>

                                              {status.label}
                                            </span>
                                          </td>
                                          <td className="px-4 py-3 text-right">
                                            <div className="flex items-center justify-end gap-2">
                                              {isAdmin && (
                                                <button
                                                  type="button"
                                                  onClick={() => setAdjustVariant({ ...variant, productName: product.productName })}
                                                  className="h-8 rounded-[8px] px-3 inline-flex items-center gap-1.5 text-[10px] font-extrabold uppercase text-primary bg-primary/10 hover:bg-primary/20 transition-colors"
                                                  title="Điều chỉnh tồn kho"
                                                >
                                                  <ArrowUpDown className="w-3.5 h-3.5" />
                                                  Điều chỉnh
                                                </button>
                                              )}
                                              <button
                                                type="button"
                                                onClick={() => { setHistoryVariantId(variant.variantId); setHistoryVariantName(`${product.productName} - ${variant.sku}`); }}
                                                className="h-8 rounded-[8px] px-3 inline-flex items-center gap-1.5 text-[10px] font-extrabold uppercase text-[#607080] bg-[#f2f7ff] hover:bg-[#e9f1ff] transition-colors"
                                                title="Lịch sử tồn kho"
                                              >
                                                <History className="w-3.5 h-3.5" />
                                                Lịch sử
                                              </button>
                                            </div>
                                          </td>
                                        </tr>
                                      );
                                    })}
                                  </tbody>
                                </table>
                              </div>

                              {hiddenVariantCount > 0 && (
                                <div className="mt-4 flex justify-center">
                                  <button
                                    type="button"
                                    onClick={() => toggleShowAllVariants(product.productId)}
                                    className="h-9 rounded-[8px] border border-[#dce7f1] bg-white px-4 text-[12px] font-extrabold text-primary hover:bg-primary/5"
                                  >
                                    {isShowingAllVariants ? 'Thu gọn SKU' : `Xem thêm ${hiddenVariantCount} SKU`}
                                  </button>
                                </div>
                              )}
                            </td>
                          </tr>
                        )}
                      </React.Fragment>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>

          {meta.lastPage > 1 && (
            <div className="px-6 py-5 border-t border-[#f2f7ff] flex flex-col md:flex-row md:items-center md:justify-between gap-4">
              <p className="text-[13px] font-semibold text-[#7c8db5] mb-0">
                Hiển thị trang <span className="font-extrabold text-[#25396f]">{meta.page}</span> trên {meta.lastPage}, tổng {meta.total} sản phẩm
              </p>
              <nav aria-label="Inventory pagination">
                <ul className="flex items-center gap-1.5">
                  <li>
                    <button
                      type="button"
                      disabled={page === 1}
                      onClick={() => setPage((currentPage) => currentPage - 1)}
                      className="h-9 px-3 rounded-[8px] border border-[#dce7f1] bg-white text-[#7c8db5] text-sm font-bold inline-flex items-center gap-1 hover:text-primary hover:border-primary disabled:opacity-40 disabled:pointer-events-none"
                    >
                      <ChevronRight className="w-4 h-4 rotate-180" />
                      Trước
                    </button>
                  </li>
                  {visiblePages.map((visiblePage) => (
                    <li key={visiblePage}>
                      <button
                        type="button"
                        onClick={() => setPage(visiblePage)}
                        className={cn(
                          'w-9 h-9 rounded-[8px] text-sm font-extrabold transition-all',
                          visiblePage === page
                            ? 'bg-primary text-white shadow-sm'
                            : 'bg-white border border-[#dce7f1] text-[#7c8db5] hover:text-primary hover:border-primary',
                        )}
                      >
                        {visiblePage}
                      </button>
                    </li>
                  ))}
                  <li>
                    <button
                      type="button"
                      disabled={page === meta.lastPage}
                      onClick={() => setPage((currentPage) => currentPage + 1)}
                      className="h-9 px-3 rounded-[8px] border border-[#dce7f1] bg-white text-[#7c8db5] text-sm font-bold inline-flex items-center gap-1 hover:text-primary hover:border-primary disabled:opacity-40 disabled:pointer-events-none"
                    >
                      Sau
                      <ChevronRight className="w-4 h-4" />
                    </button>
                  </li>
                </ul>
              </nav>
            </div>
          )}
        </CardContent>
      </Card>

      {adjustVariant && (
        <AdjustStockModal
          variant={{ ...adjustVariant, currentStock: adjustVariant.currentStock }}
          onClose={() => setAdjustVariant(null)}
          onSuccess={() => {
            queryClient.invalidateQueries({ queryKey: ['inventory'] });
            queryClient.invalidateQueries({ queryKey: ['products', 'inventory-stats'] });
            setAdjustVariant(null);
          }}
        />
      )}

      {historyVariantId && (
        <TransactionHistoryModal
          variantId={historyVariantId}
          variantName={historyVariantName}
          onClose={() => setHistoryVariantId(null)}
        />
      )}
    </div>
  );
};
