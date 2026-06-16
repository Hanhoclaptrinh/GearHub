import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Search, X, Check, Filter } from '../ui/IconlyIcons';
import { productService } from '../../services/product.service';
import { Button } from '../ui/Button';
import { cn } from '../../utils/cn';
import type { Product, ProductVariant, Brand, Category } from '../../types';

interface VariantSelectModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectMultiple: (selected: Array<{ variant: ProductVariant; product: Product }>) => void;
  initialSelectedIds?: string[];
}

export const VariantSelectModal: React.FC<VariantSelectModalProps> = ({
  isOpen,
  onClose,
  onSelectMultiple,
  initialSelectedIds = [],
}) => {
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [selectedCategoryId, setSelectedCategoryId] = useState('all');
  const [selectedBrandId, setSelectedBrandId] = useState('all');

  // Keep local state of selected items
  const [tempSelected, setTempSelected] = useState<
    Array<{ variant: ProductVariant; product: Product }>
  >([]);

  // Load Categories & Brands
  const { data: categories = [] } = useQuery<Category[]>({
    queryKey: ['categories'],
    queryFn: productService.getCategories,
    enabled: isOpen,
  });

  const { data: brands = [] } = useQuery<Brand[]>({
    queryKey: ['brands'],
    queryFn: productService.getBrands,
    enabled: isOpen,
  });

  // Query products with filters
  const { data, isLoading } = useQuery({
    queryKey: ['products', search, page, selectedCategoryId, selectedBrandId, 'select-modal-bulk'],
    queryFn: () =>
      productService.getProducts({
        search,
        page,
        limit: 10,
        isAdmin: 'true',
        categoryId: selectedCategoryId !== 'all' ? selectedCategoryId : undefined,
        brandId: selectedBrandId !== 'all' ? selectedBrandId : undefined,
      }),
    enabled: isOpen,
  });

  if (!isOpen) return null;

  const products: Product[] = data?.data || [];
  const meta = data?.meta || { total: 0, lastPage: 1 };

  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
      maximumFractionDigits: 0,
    }).format(value);

  const isSelected = (variantId: string) => {
    return (
      initialSelectedIds.includes(variantId) || tempSelected.some((x) => x.variant.id === variantId)
    );
  };

  const handleToggleVariant = (variant: ProductVariant, product: Product) => {
    if (initialSelectedIds.includes(variant.id)) return; // already saved

    setTempSelected((prev) => {
      const exists = prev.some((x) => x.variant.id === variant.id);
      if (exists) {
        return prev.filter((x) => x.variant.id !== variant.id);
      } else {
        return [...prev, { variant, product }];
      }
    });
  };

  const handleConfirm = () => {
    onSelectMultiple(tempSelected);
    setTempSelected([]);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white w-full max-w-4xl rounded-[24px] shadow-2xl overflow-hidden flex flex-col h-[90vh] animate-in zoom-in-95 duration-200 border border-white">
        {/* Header */}
        <div className="px-6 py-5 border-b border-slate-100 flex items-center justify-between">
          <div>
            <h3 className="text-lg font-black text-slate-900 uppercase tracking-tight">
              Chọn biến thể sản phẩm (Hàng loạt)
            </h3>
            <p className="text-xs font-semibold text-slate-400 mt-0.5">
              Chọn một hoặc nhiều biến thể, lọc theo danh mục hoặc thương hiệu để Flash Sale nhanh
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-full hover:bg-slate-50 transition-all text-slate-400 hover:text-slate-600"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Filters Bar */}
        <div className="p-4 bg-slate-50/50 border-b border-slate-100 flex flex-col md:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="text"
              placeholder="Tìm theo tên sản phẩm hoặc SKU..."
              className="w-full h-10 pl-11 pr-4 rounded-xl border border-slate-200 bg-white text-xs font-semibold text-[#25396f] outline-none focus:border-primary"
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
            />
          </div>

          <div className="flex items-center gap-2 bg-white border border-slate-200 rounded-xl px-3 h-10">
            <Filter className="w-3.5 h-3.5 text-slate-400" />
            <select
              value={selectedCategoryId}
              onChange={(e) => {
                setSelectedCategoryId(e.target.value);
                setPage(1);
              }}
              className="bg-transparent outline-none text-xs font-bold text-slate-500 cursor-pointer"
            >
              <option value="all">Tất cả Danh mục</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>

          <div className="flex items-center gap-2 bg-white border border-slate-200 rounded-xl px-3 h-10">
            <Filter className="w-3.5 h-3.5 text-slate-400" />
            <select
              value={selectedBrandId}
              onChange={(e) => {
                setSelectedBrandId(e.target.value);
                setPage(1);
              }}
              className="bg-transparent outline-none text-xs font-bold text-slate-500 cursor-pointer"
            >
              <option value="all">Tất cả Thương hiệu</option>
              {brands.map((b) => (
                <option key={b.id} value={b.id}>
                  {b.name}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6 custom-scrollbar space-y-6">
          {isLoading ? (
            <div className="flex flex-col items-center justify-center py-20 gap-3">
              <div className="w-8 h-8 rounded-full border-3 border-primary/20 border-t-primary animate-spin" />
              <p className="text-xs font-bold text-slate-400">Đang tìm kiếm sản phẩm...</p>
            </div>
          ) : products.length > 0 ? (
            <div className="space-y-4">
              {products.map((product) => (
                <div
                  key={product.id}
                  className="border border-slate-100 rounded-2xl p-4 bg-white hover:shadow-xs transition-shadow"
                >
                  <div className="flex gap-4 items-center mb-3">
                    <img
                      src={product.thumbnailUrl || '/placeholder.png'}
                      alt={product.name}
                      className="w-10 h-10 rounded-lg object-cover bg-slate-50 border border-slate-100"
                      onError={(e) => {
                        (e.target as HTMLImageElement).src = 'https://placehold.co/100x100?text=GearHub';
                      }}
                    />
                    <div className="min-w-0">
                      <h4 className="font-extrabold text-[#25396f] text-sm truncate">
                        {product.name}
                      </h4>
                      <p className="text-[10px] font-semibold text-slate-400 mt-0.5">
                        Thương hiệu: {product.brand?.name || 'GearHub'} · Danh mục:{' '}
                        {product.category?.name || 'Chưa phân loại'}
                      </p>
                    </div>
                  </div>

                  {/* Variants List */}
                  <div className="pl-12 grid grid-cols-1 md:grid-cols-2 gap-2">
                    {product.variants?.map((variant) => {
                      const active = isSelected(variant.id);
                      return (
                        <div
                          key={variant.id}
                          onClick={() => handleToggleVariant(variant, product)}
                          className={cn(
                            'flex items-center justify-between p-3 rounded-xl border transition-all cursor-pointer select-none',
                            active
                              ? 'border-primary/30 bg-primary/5'
                              : 'border-slate-100 bg-slate-50/50 hover:bg-slate-50'
                          )}
                        >
                          <div className="min-w-0 flex-1 pr-3">
                            <p className="font-mono text-xs font-extrabold text-[#25396f] truncate">
                              {variant.sku}
                            </p>
                            <div className="flex gap-2 items-center mt-1">
                              <span className="text-xs font-bold text-slate-500">
                                {formatCurrency(Number(variant.price))}
                              </span>
                              <span className="text-[10px] font-semibold text-slate-400">
                                Kho: {variant.stock}
                              </span>
                            </div>
                          </div>
                          <div
                            className={cn(
                              'w-6 h-6 rounded-full border flex items-center justify-center transition-all shrink-0',
                              active
                                ? 'bg-primary border-primary text-white'
                                : 'bg-white border-slate-200 text-transparent'
                            )}
                          >
                            <Check className="w-3.5 h-3.5" />
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-20">
              <p className="font-extrabold text-slate-600 mb-1">Không tìm thấy sản phẩm nào</p>
              <p className="text-xs font-semibold text-slate-400">
                Thử tìm kiếm với từ khóa hoặc bộ lọc khác.
              </p>
            </div>
          )}
        </div>

        {/* Footer with Pagination and Confirm Button */}
        <div className="px-6 py-4 border-t border-slate-100 flex flex-col sm:flex-row items-center justify-between bg-slate-50/50 gap-4">
          <div className="flex items-center gap-4">
            <p className="text-xs font-semibold text-slate-400">
              Trang <span className="text-[#25396f] font-bold">{page}</span> / {meta.lastPage}
            </p>
            <div className="flex gap-1">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="h-8 rounded-lg text-xs"
              >
                Trước
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage((p) => Math.min(meta.lastPage, p + 1))}
                disabled={page === meta.lastPage}
                className="h-8 rounded-lg text-xs"
              >
                Sau
              </Button>
            </div>
          </div>

          <div className="flex items-center gap-3 w-full sm:w-auto">
            <p className="text-xs font-bold text-slate-500 hidden md:block">
              Đang chọn: {tempSelected.length} biến thể
            </p>
            <Button
              onClick={handleConfirm}
              disabled={tempSelected.length === 0}
              className="w-full sm:w-auto h-10 rounded-xl px-5 text-xs font-bold bg-primary text-white"
            >
              Xác nhận chọn ({tempSelected.length})
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};
