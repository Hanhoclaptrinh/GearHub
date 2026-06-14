import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import {
  Package,
  Plus,
  Search,
  Filter,
  Edit,
  Trash2,
  ImageIcon,
  CheckCircle2,
  XCircle,
  AlertCircle,
  ChevronRight,
  ChevronLeft,
  Box,
  EyeOff,
  Star,
  MoreHorizontal,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  CalendarDays,
} from '../../components/ui/IconlyIcons';
import {
  Bag as IconlyBag,
  Category as IconlyCategory,
  Chart as IconlyChart,
  Danger as IconlyDanger,
  TickSquare as IconlyTickSquare,
} from 'react-iconly';
import { toast } from 'sonner';
import { productService } from '../../services/product.service';
import { brandService } from '../../services/brand.service';
import { categoryService } from '../../services/category.service';
import { ConfirmModal } from '../../components/ui/ConfirmModal';
import { Badge } from '../../components/ui/Badge';
import { Button } from '../../components/ui/Button';
import { Card, CardContent, CardHeader, CardTitle } from '../../components/ui/Card';
import { ThreeDViewerModal } from '../../components/products/ThreeDViewerModal';
import { cn } from '../../utils/cn';
import type { Brand, Category, Product } from '../../types';

type SortKey = 'name' | 'brand' | 'price' | 'stock' | 'updatedAt';
type SortDirection = 'asc' | 'desc';
type BulkAction = 'hide' | 'restore';

export const ProductList: React.FC = () => {
  const [selected3DModel, setSelected3DModel] = useState<{ glb: string; usdz?: string; name: string } | null>(null);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [showAllVariantIds, setShowAllVariantIds] = useState<string[]>([]);
  const [inventoryStatus, setInventoryStatus] = useState<'all' | 'in_stock' | 'low_stock' | 'out_of_stock'>('all');
  const [assetType, setAssetType] = useState<'all' | 'has_3d' | 'only_2d'>('all');
  const [minPrice, setMinPrice] = useState('');
  const [maxPrice, setMaxPrice] = useState('');
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [categoryId, setCategoryId] = useState('all');
  const [brandId, setBrandId] = useState('all');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [productIdsToDelete, setProductIdsToDelete] = useState<string[]>([]);
  const [showInactiveOnly, setShowInactiveOnly] = useState(false);
  const [showActiveOnly, setShowActiveOnly] = useState(false);
  const [sortKey, setSortKey] = useState<SortKey>('updatedAt');
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc');
  const [selectedProductIds, setSelectedProductIds] = useState<string[]>([]);
  const [openActionMenuId, setOpenActionMenuId] = useState<string | null>(null);

  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const { data: inventoryStats } = useQuery({
    queryKey: ['products', 'inventory-stats'],
    queryFn: productService.getInventoryStats,
  });

  const { data, isLoading, isError } = useQuery({
    queryKey: ['products', search, page, 'admin', inventoryStatus, assetType, minPrice, maxPrice, categoryId, brandId, showInactiveOnly, showActiveOnly],
    queryFn: () => productService.getProducts({
      search,
      page,
      limit: 10,
      isAdmin: 'true',
      inventoryStatus: inventoryStatus !== 'all' ? inventoryStatus : undefined,
      assetType: assetType !== 'all' ? assetType : undefined,
      minPrice: minPrice ? Number(minPrice) : undefined,
      maxPrice: maxPrice ? Number(maxPrice) : undefined,
      categoryId: categoryId !== 'all' ? categoryId : undefined,
      brandId: brandId !== 'all' ? brandId : undefined,
      showInactiveOnly: showInactiveOnly ? 'true' : undefined,
      showActiveOnly: showActiveOnly ? 'true' : undefined,
    }),
  });

  const { data: categories = [] } = useQuery<Category[]>({
    queryKey: ['categories'],
    queryFn: categoryService.getAllCategories,
  });

  const { data: brands = [] } = useQuery<Brand[]>({
    queryKey: ['brands'],
    queryFn: () => brandService.getAllBrands(),
  });

  const deleteMutation = useMutation({
    mutationFn: async (ids: string[]) => {
      const responses = await Promise.all(ids.map((id) => productService.hardDelete(id)));
      return {
        message: ids.length > 1 ? `Đã xóa vĩnh viễn ${ids.length} sản phẩm` : responses[0]?.message,
      };
    },
    onSuccess: (res: any) => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['products', 'inventory-stats'] });
      toast.success(res.message || 'Xóa sản phẩm thành công');
      setIsConfirmOpen(false);
      setProductIdsToDelete([]);
      setSelectedProductIds([]);
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Có lỗi xảy ra khi xóa sản phẩm');
    },
  });

  const restoreMutation = useMutation({
    mutationFn: (id: string) => productService.restore(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['products', 'inventory-stats'] });
      toast.success('Đã khôi phục sản phẩm thành công');
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Có lỗi xảy ra khi khôi phục');
    },
  });

  const toggleMutation = useMutation({
    mutationFn: (id: string) => productService.deleteProduct(id),
    onSuccess: (res: any) => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['products', 'inventory-stats'] });
      toast.success(res.message || 'Cập nhật trạng thái thành công');
    },
    onError: (err: any) => {
      toast.error(err.response?.data?.message || 'Không thể cập nhật trạng thái');
    },
  });

  const toggleFeaturedMutation = useMutation({
    mutationFn: (id: string) => productService.toggleFeatured(id),
    onSuccess: (res: any) => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      toast.success(res.message || 'Cập nhật trạng thái nổi bật thành công');
    },
    onError: (err: any) => {
      toast.error(err.response?.data?.message || 'Không thể cập nhật trạng thái nổi bật');
    },
  });

  const toggleVariantMutation = useMutation({
    mutationFn: (variantId: string) => productService.toggleVariant(variantId),
    onSuccess: (res: any) => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['products', 'inventory-stats'] });
      toast.success(res.message || 'Cập nhật trạng thái biến thể thành công');
    },
    onError: (err: any) => {
      toast.error(err.response?.data?.message || 'Không thể cập nhật trạng thái biến thể');
    },
  });

  const bulkActionMutation = useMutation({
    mutationFn: async ({ action, ids }: { action: BulkAction; ids: string[] }) => {
      if (action === 'hide') {
        await Promise.all(ids.map((id) => productService.deleteProduct(id)));
        return `Đã ẩn ${ids.length} sản phẩm`;
      }

      await Promise.all(ids.map((id) => productService.restore(id)));
      return `Đã khôi phục ${ids.length} sản phẩm`;
    },
    onSuccess: (message: string) => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['products', 'inventory-stats'] });
      toast.success(message);
      setSelectedProductIds([]);
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Không thể thực hiện thao tác hàng loạt');
    },
  });

  const products: Product[] = data?.data || [];
  const meta = data?.meta || { total: 0, lastPage: 1 };

  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(value);

  const formatCompact = (value: number) =>
    new Intl.NumberFormat('vi-VN', { notation: 'compact', maximumFractionDigits: 1 } as any).format(value);

  const formatDate = (value?: string) => {
    if (!value) return 'N/A';
    return new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(new Date(value));
  };

  const getTotalStock = (product: Product) =>
    product.variants?.reduce((sum, variant) => sum + (variant.stock || 0), 0) || 0;

  const getMinVariantPrice = (product: Product) =>
    product.variants?.length ? Math.min(...product.variants.map((variant) => variant.price)) : 0;

  const resetFilters = () => {
    setInventoryStatus('all');
    setAssetType('all');
    setMinPrice('');
    setMaxPrice('');
    setCategoryId('all');
    setBrandId('all');
    setSearch('');
    setShowActiveOnly(false);
    setShowInactiveOnly(false);
    setSelectedProductIds([]);
    setPage(1);
  };

  const filterOptions = [
    { id: 'all', label: 'Tất cả' },
    { id: 'in_stock', label: 'Còn hàng' },
    { id: 'low_stock', label: 'Sắp hết' },
    { id: 'out_of_stock', label: 'Đã hết' },
  ] as const;

  const assetOptions = [
    { id: 'all', label: 'Tất cả' },
    { id: 'has_3d', label: 'Có 3D/AR' },
    { id: 'only_2d', label: 'Chỉ 2D' },
  ] as const;

  const statCards = [
    {
      label: 'Tổng SKU',
      value: inventoryStats?.totalSKUs ?? 0,
      icon: IconlyCategory,
      bgClass: 'bg-[#9694ff]',
      onClick: () => { setInventoryStatus('all'); setPage(1); setShowInactiveOnly(false); setShowActiveOnly(false); },
    },
    {
      label: 'Tổng tồn kho',
      value: inventoryStats?.totalStock ?? 0,
      icon: IconlyBag,
      bgClass: 'bg-[#5ddc97]',
      onClick: () => { setInventoryStatus('in_stock'); setPage(1); setShowInactiveOnly(false); setShowActiveOnly(false); },
    },
    {
      label: 'Đang kinh doanh',
      value: inventoryStats?.actualStock ?? 0,
      icon: IconlyTickSquare,
      bgClass: 'bg-[#57caeb]',
      onClick: () => { setInventoryStatus('all'); setPage(1); setShowInactiveOnly(false); setShowActiveOnly(true); },
    },
    {
      label: 'Sắp hết hàng',
      value: inventoryStats?.lowStockCount ?? 0,
      icon: IconlyDanger,
      bgClass: 'bg-[#ff7976]',
      onClick: () => { setInventoryStatus('low_stock'); setPage(1); setShowInactiveOnly(false); setShowActiveOnly(false); },
    },
    {
      label: 'Giá trị kho',
      value: `${formatCompact(inventoryStats?.actualCapital ?? 0)}₫`,
      icon: IconlyChart,
      bgClass: 'bg-[#57caeb]',
    },
  ];

  const visiblePages = Array.from({ length: Math.min(meta.lastPage, 5) }, (_, i) => {
    if (meta.lastPage <= 5) return i + 1;
    if (page <= 3) return i + 1;
    if (page >= meta.lastPage - 2) return meta.lastPage - 4 + i;
    return page - 2 + i;
  });

  const getSortValue = (product: Product, key: SortKey) => {
    if (key === 'name') return product.name?.toLowerCase() || '';
    if (key === 'brand') return product.brand?.name?.toLowerCase() || '';
    if (key === 'price') return getMinVariantPrice(product);
    if (key === 'stock') return getTotalStock(product);
    return new Date(product.updatedAt || product.createdAt || 0).getTime();
  };

  const sortedProducts = [...products].sort((a, b) => {
    const aValue = getSortValue(a, sortKey);
    const bValue = getSortValue(b, sortKey);

    if (typeof aValue === 'number' && typeof bValue === 'number') {
      return sortDirection === 'asc' ? aValue - bValue : bValue - aValue;
    }

    return sortDirection === 'asc'
      ? String(aValue).localeCompare(String(bValue), 'vi')
      : String(bValue).localeCompare(String(aValue), 'vi');
  });

  const selectedProducts = products.filter((product) => selectedProductIds.includes(product.id));
  const selectedActiveIds = selectedProducts.filter((product) => product.isActive).map((product) => product.id);
  const selectedInactiveIds = selectedProducts.filter((product) => !product.isActive).map((product) => product.id);
  const allVisibleSelected = products.length > 0 && products.every((product) => selectedProductIds.includes(product.id));

  const activeFilterChips = [
    search ? { id: 'search', label: `Từ khóa: ${search}`, onRemove: () => setSearch('') } : null,
    showActiveOnly ? { id: 'active', label: 'Đang kinh doanh', onRemove: () => setShowActiveOnly(false) } : null,
    showInactiveOnly ? { id: 'inactive', label: 'Ngưng kinh doanh', onRemove: () => setShowInactiveOnly(false) } : null,
    inventoryStatus !== 'all' ? { id: 'inventory', label: `Kho: ${filterOptions.find((option) => option.id === inventoryStatus)?.label || inventoryStatus}`, onRemove: () => setInventoryStatus('all') } : null,
    assetType !== 'all' ? { id: 'asset', label: `Asset: ${assetOptions.find((option) => option.id === assetType)?.label || assetType}`, onRemove: () => setAssetType('all') } : null,
    categoryId !== 'all' ? { id: 'category', label: `Danh mục: ${categories.find((category) => category.id === categoryId)?.name || categoryId}`, onRemove: () => setCategoryId('all') } : null,
    brandId !== 'all' ? { id: 'brand', label: `Thương hiệu: ${brands.find((brand) => brand.id === brandId)?.name || brandId}`, onRemove: () => setBrandId('all') } : null,
    minPrice || maxPrice ? { id: 'price', label: `Giá: ${minPrice || '0'} - ${maxPrice || '∞'}`, onRemove: () => { setMinPrice(''); setMaxPrice(''); } } : null,
  ].filter(Boolean) as { id: string; label: string; onRemove: () => void }[];

  const handleSort = (key: SortKey) => {
    setSortKey(key);
    setSortDirection((currentDirection) => sortKey === key && currentDirection === 'asc' ? 'desc' : 'asc');
  };

  const toggleSelectProduct = (id: string) => {
    setSelectedProductIds((currentIds) =>
      currentIds.includes(id) ? currentIds.filter((currentId) => currentId !== id) : [...currentIds, id],
    );
  };

  const toggleSelectVisibleProducts = () => {
    setSelectedProductIds(allVisibleSelected ? [] : products.map((product) => product.id));
  };

  const runBulkAction = (action: BulkAction, ids: string[]) => {
    if (ids.length === 0) return;
    bulkActionMutation.mutate({ action, ids });
  };

  const handleDelete = (ids: string | string[]) => {
    setProductIdsToDelete(Array.isArray(ids) ? ids : [ids]);
    setIsConfirmOpen(true);
  };

  const open3DViewer = (product: Product) => {
    const glbAsset = product.assets?.find((asset) => asset.type === 'GLB');
    const usdzAsset = product.assets?.find((asset) => asset.type === 'USDZ');

    if (glbAsset) {
      setSelected3DModel({ glb: glbAsset.url, usdz: usdzAsset?.url, name: product.name });
    } else if (usdzAsset) {
      setSelected3DModel({ glb: usdzAsset.url, usdz: usdzAsset.url, name: product.name });
    }
  };

  const toggleShowAllVariants = (productId: string) => {
    setShowAllVariantIds((currentIds) =>
      currentIds.includes(productId) ? currentIds.filter((id) => id !== productId) : [...currentIds, productId],
    );
  };

  const SortableHeader = ({ column, children }: { column: SortKey; children: React.ReactNode }) => {
    const isActive = sortKey === column;
    const SortIcon = !isActive ? ArrowUpDown : sortDirection === 'asc' ? ArrowUp : ArrowDown;

    return (
      <button
        type="button"
        onClick={() => handleSort(column)}
        className="inline-flex items-center gap-1.5 hover:text-primary transition-colors"
      >
        {children}
        <SortIcon className={cn('w-3.5 h-3.5', isActive ? 'text-primary' : 'text-[#a8b4c7]')} />
      </button>
    );
  };

  return (
    <div className="space-y-6 pb-10 animate-in fade-in slide-in-from-bottom-3 duration-500">
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-6">
        {statCards.map((stat) => (
          <Card
            key={stat.label}
            onClick={stat.onClick}
            className={cn(
              'border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white transition-all duration-300',
              stat.onClick && 'cursor-pointer group',
            )}
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

      {(inventoryStats?.inactiveSKUs > 0 || inventoryStats?.inactiveProducts?.length > 0) && (
        <div className="alert border-0 rounded-[12px] bg-[#fff7e6] text-[#946200] shadow-[0_5px_15px_rgba(25,42,70,0.04)] px-5 py-4 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-[10px] bg-white flex items-center justify-center text-[#ffb236] shrink-0">
              <EyeOff className="w-5 h-5" />
            </div>
            <div>
              <h6 className="font-extrabold text-[#25396f] mb-1">Mặt hàng ngưng kinh doanh</h6>
              <p className="text-sm font-semibold text-[#946200] mb-0">
                {inventoryStats?.inactiveSKUs} biến thể và {inventoryStats?.inactiveProducts?.length} sản phẩm đang bị ẩn.
              </p>
            </div>
          </div>
          <Button
            type="button"
            variant={showInactiveOnly ? 'secondary' : 'outline'}
            size="sm"
            onClick={() => { setShowInactiveOnly(!showInactiveOnly); setPage(1); setShowActiveOnly(false); }}
            className="rounded-[8px] shrink-0"
          >
            {showInactiveOnly ? 'Xem toàn bộ' : 'Xem mục ngưng KD'}
          </Button>
        </div>
      )}

      <Card className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white overflow-hidden">
        <CardHeader className="border-none px-6 pt-6 pb-3 flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4">
          <div>
            <CardTitle className="text-[20px] text-[#25396f] flex items-center gap-2">
              Danh sách sản phẩm
            </CardTitle>
          </div>

          <div className="flex flex-col sm:flex-row gap-3 w-full xl:w-auto">
            <div className="relative min-w-0 sm:min-w-[320px]">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#7c8db5]" />
              <input
                type="text"
                placeholder="Tìm theo tên sản phẩm, SKU..."
                className="w-full h-11 pl-11 pr-4 rounded-[8px] border border-[#dce7f1] bg-white text-sm font-semibold text-[#25396f] outline-none transition-all focus:border-primary focus:ring-4 focus:ring-primary/10"
                value={search}
                onChange={(e) => { setSearch(e.target.value); setPage(1); }}
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
            <Button
              type="button"
              variant="secondary"
              size="md"
              onClick={() => navigate('/products/create')}
              className="rounded-[8px] gap-2"
            >
              <Plus className="w-4 h-4" />
              Thêm sản phẩm
            </Button>
          </div>
        </CardHeader>

        {isFilterOpen && (
          <div className="mx-6 mb-4 rounded-[12px] bg-[#f2f7ff] border border-[#dce7f1] p-5">
            <div className="grid grid-cols-1 lg:grid-cols-4 gap-5">
              <div>
                <label className="block text-[11px] font-extrabold text-[#7c8db5] uppercase mb-2">Trạng thái kho</label>
                <div className="flex flex-wrap gap-2">
                  {filterOptions.map((option) => (
                    <button
                      key={option.id}
                      type="button"
                      onClick={() => { setInventoryStatus(option.id); setPage(1); }}
                      className={cn(
                        'px-3 py-1.5 rounded-[8px] text-xs font-extrabold border transition-all',
                        inventoryStatus === option.id
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
                <label className="block text-[11px] font-extrabold text-[#7c8db5] uppercase mb-2">Loại asset</label>
                <div className="flex flex-wrap gap-2">
                  {assetOptions.map((option) => (
                    <button
                      key={option.id}
                      type="button"
                      onClick={() => { setAssetType(option.id); setPage(1); }}
                      className={cn(
                        'px-3 py-1.5 rounded-[8px] text-xs font-extrabold border transition-all',
                        assetType === option.id
                          ? 'bg-[#57caeb] text-white border-[#57caeb] shadow-sm'
                          : 'bg-white text-[#7c8db5] border-[#dce7f1] hover:text-[#57caeb] hover:border-[#57caeb]',
                      )}
                    >
                      {option.label}
                    </button>
                  ))}
                </div>
              </div>

              <div className="space-y-3">
                <label className="block text-[11px] font-extrabold text-[#7c8db5] uppercase">Danh mục & thương hiệu</label>
                <select
                  className="w-full h-10 rounded-[8px] border border-[#dce7f1] bg-white px-3 text-sm font-semibold text-[#25396f] outline-none focus:border-primary"
                  value={categoryId}
                  onChange={(e) => { setCategoryId(e.target.value); setPage(1); }}
                >
                  <option value="all">Tất cả danh mục</option>
                  {categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
                </select>
                <select
                  className="w-full h-10 rounded-[8px] border border-[#dce7f1] bg-white px-3 text-sm font-semibold text-[#25396f] outline-none focus:border-primary"
                  value={brandId}
                  onChange={(e) => { setBrandId(e.target.value); setPage(1); }}
                >
                  <option value="all">Tất cả thương hiệu</option>
                  {brands.map((brand) => <option key={brand.id} value={brand.id}>{brand.name}</option>)}
                </select>
              </div>

              <div className="space-y-3">
                <label className="block text-[11px] font-extrabold text-[#7c8db5] uppercase">Khoảng giá</label>
                <div className="grid grid-cols-2 gap-2">
                  <input
                    type="number"
                    className="h-10 rounded-[8px] border border-[#dce7f1] bg-white px-3 text-sm font-semibold text-[#25396f] outline-none focus:border-primary"
                    placeholder="Từ"
                    value={minPrice}
                    onChange={(e) => setMinPrice(e.target.value)}
                  />
                  <input
                    type="number"
                    className="h-10 rounded-[8px] border border-[#dce7f1] bg-white px-3 text-sm font-semibold text-[#25396f] outline-none focus:border-primary"
                    placeholder="Đến"
                    value={maxPrice}
                    onChange={(e) => setMaxPrice(e.target.value)}
                  />
                </div>
                <button
                  type="button"
                  onClick={resetFilters}
                  className="w-full h-10 rounded-[8px] bg-white border border-red-100 text-red-500 text-xs font-extrabold uppercase hover:bg-red-50 transition-all"
                >
                  Xóa bộ lọc
                </button>
              </div>
            </div>
          </div>
        )}

        <CardContent className="px-0 pb-0 pt-0">
          {isError && (
            <div className="mx-6 mb-4 rounded-[10px] border border-red-100 bg-red-50 p-4 flex gap-3 text-red-600">
              <AlertCircle className="w-5 h-5 shrink-0 mt-0.5" />
              <div>
                <h6 className="font-extrabold text-red-700 mb-1">Không thể tải danh sách sản phẩm</h6>
                <p className="text-sm font-semibold text-red-500 mb-0">Máy chủ hiện không phản hồi. Vui lòng thử lại sau.</p>
              </div>
            </div>
          )}

          <div className="px-6 pb-3 flex flex-col md:flex-row md:items-center justify-between gap-3">
            <div className="flex flex-wrap items-center gap-2">
              <Badge variant="info" className="rounded-[6px] border-none bg-primary/10 text-primary">
                {meta.total} sản phẩm
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

          {selectedProductIds.length > 0 && (
            <div className="mx-6 mb-4 rounded-[12px] border border-primary/10 bg-primary/5 px-4 py-3 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3">
              <div>
                <p className="text-sm font-extrabold text-[#25396f] mb-0">Đã chọn {selectedProductIds.length} sản phẩm</p>
              </div>
              <div className="flex flex-wrap items-center gap-2">
                <Button
                  type="button"
                  size="sm"
                  variant="outline"
                  disabled={selectedActiveIds.length === 0 || bulkActionMutation.isPending}
                  onClick={() => runBulkAction('hide', selectedActiveIds)}
                  className="rounded-[8px] gap-2"
                >
                  <EyeOff className="w-4 h-4" />
                  Ẩn ({selectedActiveIds.length})
                </Button>
                <Button
                  type="button"
                  size="sm"
                  variant="outline"
                  disabled={selectedInactiveIds.length === 0 || bulkActionMutation.isPending}
                  onClick={() => runBulkAction('restore', selectedInactiveIds)}
                  className="rounded-[8px] gap-2"
                >
                  <CheckCircle2 className="w-4 h-4" />
                  Khôi phục ({selectedInactiveIds.length})
                </Button>
                <Button
                  type="button"
                  size="sm"
                  variant="danger"
                  disabled={deleteMutation.isPending}
                  onClick={() => handleDelete(selectedProductIds)}
                  className="rounded-[8px] gap-2"
                >
                  <Trash2 className="w-4 h-4" />
                  Xóa vĩnh viễn
                </Button>
                <Button type="button" size="sm" variant="ghost" onClick={() => setSelectedProductIds([])} className="rounded-[8px]">
                  Bỏ chọn
                </Button>
              </div>
            </div>
          )}

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse min-w-[1320px]">
              <thead>
                <tr className="border-y border-[#f2f7ff] bg-[#fbfcff] text-[#7c8db5] text-[11px] font-extrabold uppercase">
                  <th className="px-4 py-4 w-12">
                    <input
                      type="checkbox"
                      checked={allVisibleSelected}
                      onChange={toggleSelectVisibleProducts}
                      className="h-4 w-4 rounded border-[#dce7f1] text-primary focus:ring-primary/20"
                      aria-label="Chọn tất cả sản phẩm trên trang"
                    />
                  </th>
                  <th className="px-4 py-4 w-[30%]"><SortableHeader column="name">Sản phẩm</SortableHeader></th>
                  <th className="px-4 py-4"><SortableHeader column="brand">Thương hiệu</SortableHeader></th>
                  <th className="px-4 py-4">Danh mục</th>
                  <th className="px-4 py-4"><SortableHeader column="price">Giá bán</SortableHeader></th>
                  <th className="px-4 py-4"><SortableHeader column="stock">Tồn kho</SortableHeader></th>
                  <th className="px-4 py-4"><SortableHeader column="updatedAt">Cập nhật</SortableHeader></th>
                  <th className="px-4 py-4">Trạng thái</th>
                  <th className="px-6 py-4 text-center">Thao tác</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#f2f7ff] text-sm">
                {isLoading ? (
                  <tr>
                    <td colSpan={9} className="px-6 py-16 text-center">
                      <div className="inline-flex flex-col items-center gap-3">
                        <div className="w-10 h-10 rounded-full border-4 border-primary/20 border-t-primary animate-spin" />
                        <p className="text-sm font-bold text-[#7c8db5] mb-0">Đang tải dữ liệu sản phẩm...</p>
                      </div>
                    </td>
                  </tr>
                ) : sortedProducts.length > 0 ? (
                  sortedProducts.map((product) => {
                    const has2D = product.assets?.some((asset) => asset.type === 'IMAGE');
                    const has3D = product.assets?.some((asset) => ['GLB', 'USDZ'].includes(asset.type));
                    const hasAR = product.assets?.some((asset) => asset.type === 'USDZ');
                    const primaryAsset = product.assets?.find((asset) => asset.isPrimary) || product.assets?.find((asset) => asset.type === 'IMAGE');
                    const totalStock = getTotalStock(product);
                    const isExpanded = expandedId === product.id;
                    const minVariantPrice = getMinVariantPrice(product);
                    const isShowingAllVariants = showAllVariantIds.includes(product.id);
                    const visibleVariants = isShowingAllVariants ? product.variants : product.variants?.slice(0, 6);
                    const hiddenVariantCount = Math.max(0, (product.variants?.length || 0) - 6);

                    return (
                      <React.Fragment key={product.id}>
                        <tr
                          className={cn('group hover:bg-[#f8faff] transition-colors cursor-pointer', isExpanded && 'bg-[#f8faff]')}
                          onClick={() => setExpandedId(isExpanded ? null : product.id)}
                        >
                          <td className="px-4 py-4" onClick={(e) => e.stopPropagation()}>
                            <input
                              type="checkbox"
                              checked={selectedProductIds.includes(product.id)}
                              onChange={() => toggleSelectProduct(product.id)}
                              className="h-4 w-4 rounded border-[#dce7f1] text-primary focus:ring-primary/20"
                              aria-label={`Chọn ${product.name}`}
                            />
                          </td>
                          <td className="px-4 py-4">
                            <div className="flex items-center gap-4">
                              <button
                                type="button"
                                className="w-7 h-7 rounded-[8px] bg-[#f2f7ff] text-primary flex items-center justify-center shrink-0"
                                aria-label={isExpanded ? 'Thu gọn biến thể' : 'Mở rộng biến thể'}
                              >
                                <ChevronRight className={cn('w-4 h-4 transition-transform', isExpanded && 'rotate-90')} />
                              </button>
                              <div className="relative w-[56px] h-[56px] rounded-[12px] bg-[#f2f7ff] border border-[#dce7f1] overflow-hidden flex items-center justify-center shrink-0">
                                {primaryAsset?.url ? (
                                  <img src={primaryAsset.url} alt={product.name} className="w-full h-full object-cover" />
                                ) : has3D ? (
                                  <Box className="w-6 h-6 text-primary" />
                                ) : (
                                  <ImageIcon className="w-5 h-5 text-[#7c8db5]" />
                                )}
                              </div>
                              <div className="min-w-0">
                                <div className="flex items-center gap-2 mb-1">
                                  <h6 className="font-extrabold text-[#25396f] text-[14px] truncate max-w-[260px] mb-0">{product.name}</h6>
                                  {product.isFeatured && (
                                    <Badge variant="warning" className="rounded-[6px] px-2 py-0.5 border-none bg-[#fff3cd] text-[#946200]">
                                      <Star className="w-3 h-3 fill-[#eaca4a]" /> Nổi bật
                                    </Badge>
                                  )}
                                </div>
                                <div className="flex flex-wrap items-center gap-1.5">
                                  <span className="font-mono text-[10px] font-extrabold text-[#7c8db5] bg-[#f2f7ff] px-2 py-0.5 rounded-[5px]">
                                    {product.variants?.[0]?.sku || 'N/A'}
                                  </span>
                                  {product.variants && product.variants.length > 1 && (
                                    <span className="text-[10px] font-extrabold text-primary">+{product.variants.length - 1} biến thể</span>
                                  )}
                                  {has2D && <Badge variant="info" className="rounded-[5px] px-1.5 py-0.5 text-[9px] border-none">2D</Badge>}
                                  {has3D && (
                                    <button
                                      type="button"
                                      onClick={(e) => { e.stopPropagation(); open3DViewer(product); }}
                                      className="inline-flex items-center gap-1 rounded-[5px] bg-primary/10 text-primary px-1.5 py-0.5 text-[9px] font-extrabold hover:bg-primary/20"
                                    >
                                      <Box className="w-3 h-3" /> 3D
                                    </button>
                                  )}
                                  {hasAR && <Badge variant="warning" className="rounded-[5px] px-1.5 py-0.5 text-[9px] border-none">AR</Badge>}
                                </div>
                              </div>
                            </div>
                          </td>

                          <td className="px-4 py-4">
                            <div className="flex items-center gap-2 min-w-[140px]">
                              <span className="font-extrabold text-[#25396f] truncate">{product.brand?.name || 'Chưa có'}</span>
                            </div>
                          </td>

                          <td className="px-4 py-4">
                            <Badge variant="default" className="rounded-[6px] bg-[#f2f7ff] text-[#607080] border-none">
                              {product.category?.name || 'Chưa phân loại'}
                            </Badge>
                          </td>

                          <td className="px-4 py-4">
                            <p className="font-extrabold text-[#25396f] mb-0">
                              {product.variants && product.variants.length > 1 ? `từ ${formatCurrency(minVariantPrice)}` : formatCurrency(product.variants?.[0]?.price || 0)}
                            </p>
                          </td>

                          <td className="px-4 py-4">
                            <div className="min-w-[110px]">
                              <div className="flex items-center justify-between mb-1">
                                <span className={cn('font-extrabold', totalStock === 0 ? 'text-red-500' : totalStock < 10 ? 'text-[#ffb236]' : 'text-[#4fbe87]')}>
                                  {totalStock} món
                                </span>
                              </div>
                              <div className="h-1.5 rounded-full bg-[#f2f7ff] overflow-hidden">
                                <div
                                  className={cn('h-full rounded-full', totalStock === 0 ? 'bg-red-500' : totalStock < 10 ? 'bg-[#ffb236]' : 'bg-[#4fbe87]')}
                                  style={{ width: `${Math.min(100, totalStock === 0 ? 4 : totalStock < 10 ? 35 : 78)}%` }}
                                />
                              </div>
                            </div>
                          </td>

                          <td className="px-4 py-4">
                            <div className="flex items-start gap-2 min-w-[130px]">
                              <CalendarDays className="w-4 h-4 text-[#7c8db5] mt-0.5" />
                              <div>
                                <p className="font-extrabold text-[#25396f] mb-0">{formatDate(product.updatedAt || product.createdAt)}</p>
                                <p className="text-[10px] font-bold text-[#a8b4c7] mb-0">Tạo: {formatDate(product.createdAt)}</p>
                              </div>
                            </div>
                          </td>

                          <td className="px-4 py-4">
                            {!product.isActive ? (
                              <Badge variant="danger" className="rounded-[6px]">Tạm ngưng</Badge>
                            ) : product.variants?.some((variant) => !variant.isActive) ? (
                              <Badge variant="warning" className="rounded-[6px]">Có biến thể tắt</Badge>
                            ) : (
                              <Badge variant="success" className="rounded-[6px]">Đang bán</Badge>
                            )}
                          </td>

                          <td className="px-6 py-4" onClick={(e) => e.stopPropagation()}>
                            <div className="flex items-center justify-center gap-1 relative">
                              {!product.isActive ? (
                                <button
                                  type="button"
                                  onClick={() => restoreMutation.mutate(product.id)}
                                  className="w-9 h-9 rounded-[8px] inline-flex items-center justify-center text-[#4fbe87] bg-[#4fbe87]/10 hover:bg-[#4fbe87]/20 transition-colors"
                                  title="Kích hoạt lại"
                                >
                                  <CheckCircle2 className="w-4 h-4" />
                                </button>
                              ) : (
                                <>
                                  <button
                                    type="button"
                                    onClick={() => toggleFeaturedMutation.mutate(product.id)}
                                    disabled={toggleFeaturedMutation.isPending && toggleFeaturedMutation.variables === product.id}
                                    className={cn(
                                      'w-9 h-9 rounded-[8px] inline-flex items-center justify-center transition-colors disabled:opacity-60 disabled:cursor-not-allowed',
                                      product.isFeatured ? 'text-[#eaca4a] bg-[#eaca4a]/10 hover:bg-[#eaca4a]/20' : 'text-[#7c8db5] bg-[#f2f7ff] hover:bg-[#e9f1ff]',
                                    )}
                                    title={product.isFeatured ? 'Bỏ nổi bật và tự chọn sản phẩm thay thế' : 'Đặt làm sản phẩm nổi bật duy nhất'}
                                  >
                                    <Star className={cn('w-4 h-4', product.isFeatured && 'fill-[#eaca4a]')} />
                                  </button>
                                  <button
                                    type="button"
                                    onClick={() => toggleMutation.mutate(product.id)}
                                    className="w-9 h-9 rounded-[8px] inline-flex items-center justify-center text-[#ffb236] bg-[#ffb236]/10 hover:bg-[#ffb236]/20 transition-colors"
                                    title="Ẩn sản phẩm"
                                  >
                                    <EyeOff className="w-4 h-4" />
                                  </button>
                                </>
                              )}
                              <button
                                type="button"
                                onClick={() => navigate(`/products/edit/${product.slug}`)}
                                className="w-9 h-9 rounded-[8px] inline-flex items-center justify-center text-primary bg-primary/10 hover:bg-primary/20 transition-colors"
                                title="Chỉnh sửa"
                              >
                                <Edit className="w-4 h-4" />
                              </button>
                              <button
                                type="button"
                                onClick={() => setOpenActionMenuId(openActionMenuId === product.id ? null : product.id)}
                                className="w-9 h-9 rounded-[8px] inline-flex items-center justify-center text-[#7c8db5] bg-[#f2f7ff] hover:bg-[#e9f1ff] transition-colors"
                                title="Thêm thao tác"
                              >
                                <MoreHorizontal className="w-4 h-4" />
                              </button>

                              {openActionMenuId === product.id && (
                                <div className="absolute right-0 top-11 z-30 w-44 rounded-[10px] border border-red-100 bg-white shadow-[0_12px_24px_rgba(25,42,70,0.12)] p-1">
                                  <button
                                    type="button"
                                    onClick={() => { handleDelete(product.id); setOpenActionMenuId(null); }}
                                    className="w-full h-9 rounded-[8px] px-3 text-left text-[12px] font-extrabold text-red-500 hover:bg-red-50 inline-flex items-center gap-2"
                                  >
                                    <Trash2 className="w-4 h-4" />
                                    Xóa vĩnh viễn
                                  </button>
                                </div>
                              )}
                            </div>
                          </td>
                        </tr>

                        {isExpanded && (
                          <tr>
                            <td colSpan={9} className="px-6 py-5 bg-[#f8faff]">
                              <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-2 mb-4">
                                <div>
                                  <h6 className="text-[15px] font-extrabold text-[#25396f] mb-1">Chi tiết biến thể SKU</h6>
                                </div>
                                <Badge variant="info" className="rounded-[6px] border-none bg-primary/10 text-primary">
                                  {product.variants?.length || 0} phiên bản
                                </Badge>
                              </div>

                              <div className="overflow-x-auto rounded-[12px] border border-[#dce7f1] bg-white">
                                <table className="w-full min-w-[760px] text-left">
                                  <thead className="bg-[#fbfcff] text-[10px] font-extrabold uppercase text-[#7c8db5]">
                                    <tr>
                                      <th className="px-4 py-3">SKU</th>
                                      <th className="px-4 py-3">Thuộc tính</th>
                                      <th className="px-4 py-3">Giá</th>
                                      <th className="px-4 py-3">Tồn kho</th>
                                      <th className="px-4 py-3">Trạng thái</th>
                                      <th className="px-4 py-3 text-right">Thao tác</th>
                                    </tr>
                                  </thead>
                                  <tbody className="divide-y divide-[#f2f7ff]">
                                    {visibleVariants?.map((variant) => (
                                      <tr key={variant.id} className={cn(!variant.isActive && 'bg-red-50/40')}>
                                        <td className="px-4 py-3">
                                          <span className="font-mono text-[11px] font-extrabold text-[#25396f] bg-[#f2f7ff] px-2 py-1 rounded-[6px]">
                                            {variant.sku}
                                          </span>
                                        </td>
                                        <td className="px-4 py-3">
                                          <div className="flex flex-wrap gap-1.5">
                                            {variant.attributes && Object.entries(variant.attributes).length > 0 ? (
                                              Object.entries(variant.attributes).map(([key, val]) => (
                                                <span key={key} className="text-[11px] font-bold px-2 py-1 bg-[#f2f7ff] rounded-[6px] text-[#607080]">
                                                  <span className="text-[#7c8db5]">{key}:</span> {val as string}
                                                </span>
                                              ))
                                            ) : (
                                              <span className="text-[11px] font-bold text-[#a8b4c7]">Không có thuộc tính</span>
                                            )}
                                          </div>
                                        </td>
                                        <td className="px-4 py-3 font-extrabold text-[#25396f]">{formatCurrency(variant.price)}</td>
                                        <td className="px-4 py-3">
                                          <span className={cn('text-[12px] font-extrabold', variant.stock < 10 ? 'text-red-500' : 'text-[#4fbe87]')}>
                                            {variant.stock} món
                                          </span>
                                        </td>
                                        <td className="px-4 py-3">
                                          {variant.isActive ? (
                                            <Badge variant="success" className="rounded-[6px] px-2 py-1 text-[10px]">Bán</Badge>
                                          ) : (
                                            <Badge variant="danger" className="rounded-[6px] px-2 py-1 text-[10px]">Ngưng</Badge>
                                          )}
                                        </td>
                                        <td className="px-4 py-3 text-right">
                                          <button
                                            type="button"
                                            onClick={() => toggleVariantMutation.mutate(variant.id)}
                                            className={cn(
                                              'h-8 rounded-[8px] px-3 text-[10px] font-extrabold uppercase border transition-all',
                                              variant.isActive
                                                ? 'bg-[#fff7e6] text-[#946200] border-[#ffe6a6] hover:bg-[#ffefcc]'
                                                : 'bg-[#edf9f1] text-[#2f8f5b] border-[#d6f3df] hover:bg-[#dff5e8]',
                                            )}
                                          >
                                            {variant.isActive ? 'Ngưng bán' : 'Kích hoạt'}
                                          </button>
                                        </td>
                                      </tr>
                                    ))}
                                  </tbody>
                                </table>
                              </div>

                              {hiddenVariantCount > 0 && (
                                <div className="mt-4 flex justify-center">
                                  <button
                                    type="button"
                                    onClick={() => toggleShowAllVariants(product.id)}
                                    className="h-9 rounded-[8px] border border-[#dce7f1] bg-white px-4 text-[12px] font-extrabold text-primary hover:bg-primary/5"
                                  >
                                    {isShowingAllVariants ? 'Thu gọn biến thể' : `Xem thêm ${hiddenVariantCount} biến thể`}
                                  </button>
                                </div>
                              )}
                            </td>
                          </tr>
                        )}
                      </React.Fragment>
                    );
                  })
                ) : (
                  <tr>
                    <td colSpan={9} className="px-6 py-20 text-center">
                      <div className="mx-auto w-16 h-16 rounded-[14px] bg-[#f2f7ff] flex items-center justify-center mb-4">
                        <Package className="w-8 h-8 text-primary/50" />
                      </div>
                      <h6 className="text-[18px] font-extrabold text-[#25396f] mb-1">Chưa có sản phẩm nào</h6>
                      <p className="text-sm font-semibold text-[#7c8db5] mb-5">Thêm sản phẩm đầu tiên để bắt đầu quản lý catalog.</p>
                      <Button type="button" variant="secondary" onClick={() => navigate('/products/create')} className="rounded-[8px] gap-2">
                        <Plus className="w-4 h-4" />
                        Thêm sản phẩm
                      </Button>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {meta.lastPage > 1 && (
            <div className="px-6 py-5 border-t border-[#f2f7ff] flex flex-col md:flex-row md:items-center md:justify-between gap-4">
              <p className="text-[13px] font-semibold text-[#7c8db5] mb-0">
                Hiển thị trang <span className="font-extrabold text-[#25396f]">{page}</span> trên {meta.lastPage}, tổng {meta.total} sản phẩm
              </p>
              <nav aria-label="Product pagination">
                <ul className="flex items-center gap-1.5">
                  <li>
                    <button
                      type="button"
                      disabled={page === 1}
                      onClick={() => setPage(page - 1)}
                      className="h-9 px-3 rounded-[8px] border border-[#dce7f1] bg-white text-[#7c8db5] text-sm font-bold inline-flex items-center gap-1 hover:text-primary hover:border-primary disabled:opacity-40 disabled:pointer-events-none"
                    >
                      <ChevronLeft className="w-4 h-4" />
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
                      onClick={() => setPage(page + 1)}
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

      <ThreeDViewerModal
        isOpen={!!selected3DModel}
        onClose={() => setSelected3DModel(null)}
        glbUrl={selected3DModel?.glb || ''}
        usdzUrl={selected3DModel?.usdz}
        productName={selected3DModel?.name || ''}
      />

      <ConfirmModal
        isOpen={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={() => productIdsToDelete.length > 0 && deleteMutation.mutate(productIdsToDelete)}
        title={productIdsToDelete.length > 1 ? 'Xác nhận xóa nhiều sản phẩm' : 'Xác nhận xóa sản phẩm'}
        message={
          productIdsToDelete.length > 1
            ? `Bạn có chắc chắn muốn xóa vĩnh viễn ${productIdsToDelete.length} sản phẩm đã chọn? Mọi dữ liệu về biến thể và tồn kho sẽ bị gỡ bỏ hoàn toàn.`
            : 'Bạn có chắc chắn muốn xóa sản phẩm này? Mọi dữ liệu về biến thể và tồn kho sẽ bị gỡ bỏ hoàn toàn.'
        }
        confirmText="Xác nhận xóa"
        cancelText="Quay lại"
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
};
