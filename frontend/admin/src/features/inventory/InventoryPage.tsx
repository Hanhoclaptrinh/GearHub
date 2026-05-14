import React, { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Package, Search, Filter, History, ArrowUpDown,
  AlertTriangle, XCircle, CheckCircle, Warehouse,
  ChevronDown, ChevronRight, List
} from 'lucide-react';
import { inventoryService, type InventoryItem, type InventoryVariant } from '../../services/inventory.service';
import { categoryService } from '../../services/category.service';
import { brandService } from '../../services/brand.service';
import { AdjustStockModal } from './AdjustStockModal';
import { TransactionHistoryModal } from './TransactionHistoryModal';
import { cn } from '../../utils/cn';
import type { Category, Brand } from '../../types';

const stockStatusConfig = {
  IN_STOCK: { label: 'Còn hàng', color: 'bg-emerald-50 text-emerald-700 border-emerald-200', icon: CheckCircle },
  LOW_STOCK: { label: 'Sắp hết', color: 'bg-amber-50 text-amber-700 border-amber-200', icon: AlertTriangle },
  OUT_OF_STOCK: { label: 'Hết hàng', color: 'bg-red-50 text-red-700 border-red-200', icon: XCircle },
};

export const InventoryPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [brandId, setBrandId] = useState('');
  const [stockFilter, setStockFilter] = useState('all');
  const [page, setPage] = useState(1);
  const [expandedProducts, setExpandedProducts] = useState<Set<string>>(new Set());

  const [adjustVariant, setAdjustVariant] = useState<InventoryVariant & { productName: string } | null>(null);
  const [historyVariantId, setHistoryVariantId] = useState<string | null>(null);
  const [historyVariantName, setHistoryVariantName] = useState('');

  const limit = 15;

  const { data: categories } = useQuery<Category[]>({ queryKey: ['categories'], queryFn: categoryService.getAllCategories });
  const { data: brands } = useQuery<Brand[]>({ queryKey: ['brands'], queryFn: brandService.getAllBrands });

  const { data, isLoading } = useQuery({
    queryKey: ['inventory', search, categoryId, brandId, stockFilter, page],
    queryFn: () => inventoryService.getInventoryList({
      search: search || undefined,
      categoryId: categoryId || undefined,
      brandId: brandId || undefined,
      stockFilter,
      page,
      limit
    }),
  });

  const products: InventoryItem[] = data?.data || [];
  const meta = data?.meta || { total: 0, page: 1, lastPage: 1 };

  const toggleExpand = (productId: string) => {
    const newExpanded = new Set(expandedProducts);
    if (newExpanded.has(productId)) {
      newExpanded.delete(productId);
    } else {
      newExpanded.add(productId);
    }
    setExpandedProducts(newExpanded);
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-300">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="space-y-1">
          <h1 className="text-3xl font-black text-slate-900 font-heading flex items-center gap-3">
            <div className="bg-primary p-2.5 rounded-2xl shadow-lg shadow-primary/20">
              <Warehouse className="w-6 h-6 text-white" />
            </div>
            Quản lý tồn kho
          </h1>
          <p className="text-sm font-bold text-slate-400 uppercase tracking-widest ml-14">Inventory Management</p>
        </div>
      </div>

      {/* Stats - Giữ nguyên logic cũ nhưng tính toán lại dựa trên cấu trúc mới */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Tổng Sản phẩm', value: meta.total, color: 'from-blue-500 to-blue-600' },
          { label: 'SKU Hoạt động', value: products.reduce((acc, p) => acc + p.variants.length, 0), color: 'from-emerald-500 to-emerald-600' },
          { label: 'Sản phẩm LOW', value: products.filter(p => p.variants.some(v => v.stockStatus === 'LOW_STOCK')).length, color: 'from-amber-500 to-amber-600' },
          { label: 'Sản phẩm OUT', value: products.filter(p => p.variants.some(v => v.stockStatus === 'OUT_OF_STOCK')).length, color: 'from-red-500 to-red-600' },
        ].map(s => (
          <div key={s.label} className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm hover:shadow-md transition-shadow">
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{s.label}</p>
            <p className={cn("text-3xl font-black mt-1 bg-gradient-to-r bg-clip-text text-transparent", s.color)}>{s.value}</p>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm">
        <div className="flex items-center gap-2 mb-4">
          <Filter className="w-4 h-4 text-slate-400" />
          <span className="text-xs font-black text-slate-500 uppercase tracking-widest">Bộ lọc</span>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input className="w-full h-10 pl-10 pr-4 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:border-primary focus:ring-4 focus:ring-primary/5 font-bold text-slate-700 text-xs transition-all" placeholder="Tìm Sản phẩm, SKU..."
              value={search} onChange={e => { setSearch(e.target.value); setPage(1); }} />
          </div>
          <select className="h-10 px-3 bg-slate-50 border border-slate-200 rounded-xl font-bold text-slate-700 text-xs cursor-pointer" value={categoryId} onChange={e => { setCategoryId(e.target.value); setPage(1); }}>
            <option value="">Tất cả danh mục</option>
            {categories?.map(c => (<option key={c.id} value={c.id}>{c.name}</option>))}
          </select>
          <select className="h-10 px-3 bg-slate-50 border border-slate-200 rounded-xl font-bold text-slate-700 text-xs cursor-pointer" value={brandId} onChange={e => { setBrandId(e.target.value); setPage(1); }}>
            <option value="">Tất cả thương hiệu</option>
            {brands?.map(b => (<option key={b.id} value={b.id}>{b.name}</option>))}
          </select>
          <select className="h-10 px-3 bg-slate-50 border border-slate-200 rounded-xl font-bold text-slate-700 text-xs cursor-pointer" value={stockFilter} onChange={e => { setStockFilter(e.target.value); setPage(1); }}>
            <option value="all">Tất cả trạng thái</option>
            <option value="low_stock">Sắp hết hàng</option>
            <option value="out_of_stock">Hết hàng</option>
          </select>
        </div>
      </div>

      {/* Inventory Table */}
      <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
        {isLoading ? (
          <div className="flex items-center justify-center py-20">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
          </div>
        ) : products.length === 0 ? (
          <div className="text-center py-20">
            <Package className="w-12 h-12 text-slate-300 mx-auto mb-3" />
            <p className="font-bold text-slate-400">Không tìm thấy sản phẩm nào</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse">
              <thead>
                <tr className="border-b border-slate-100 bg-slate-50/50">
                  <th className="w-10 px-5 py-3"></th>
                  {['Sản phẩm / Biến thể', 'Tổng tồn / SKU', 'Danh mục / Brand', 'Trạng thái', 'Thao tác'].map(h => (
                    <th key={h} className="px-5 py-3 text-left text-[10px] font-black text-slate-400 uppercase tracking-widest">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {products.map(product => {
                  const isExpanded = expandedProducts.has(product.productId);
                  const hasIssues = product.variants.some(v => v.stockStatus !== 'IN_STOCK');

                  return (
                    <React.Fragment key={product.productId}>
                      {/* Product Row */}
                      <tr className={cn(
                        "border-b border-slate-50 transition-colors cursor-pointer group",
                        isExpanded ? "bg-blue-50/20" : "hover:bg-slate-50/50"
                      )} onClick={() => toggleExpand(product.productId)}>
                        <td className="px-5 py-4 text-center">
                          {isExpanded ? <ChevronDown className="w-4 h-4 text-primary" /> : <ChevronRight className="w-4 h-4 text-slate-400" />}
                        </td>
                        <td className="px-5 py-4">
                          <div className="flex items-center gap-3">
                            <div className="w-12 h-12 rounded-2xl overflow-hidden bg-slate-100 flex-shrink-0 border border-slate-200">
                              {product.thumbnailUrl ? (
                                <img src={product.thumbnailUrl} alt="" className="w-full h-full object-cover" />
                              ) : (
                                <Package className="w-6 h-6 text-slate-300 m-auto mt-3" />
                              )}
                            </div>
                            <div className="min-w-0">
                              <p className="text-sm font-black text-slate-800 truncate max-w-[300px]">{product.productName}</p>
                              <p className="text-[10px] font-bold text-slate-400 uppercase tracking-tight">{product.variants.length} biến thể</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-5 py-4">
                          <div className="flex flex-col">
                            <span className="text-lg font-black text-slate-700">{product.totalStock}</span>
                            <span className="text-[10px] font-bold text-slate-400 uppercase">Tổng tồn kho</span>
                          </div>
                        </td>
                        <td className="px-5 py-4">
                          <div className="flex flex-col gap-0.5">
                            <span className="text-[10px] font-bold text-slate-600 uppercase tracking-tight">{product.category?.name || 'N/A'}</span>
                            <span className="text-[10px] font-bold text-slate-400">{product.brand?.name || 'N/A'}</span>
                          </div>
                        </td>
                        <td className="px-5 py-4">
                          {hasIssues ? (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-black uppercase bg-amber-50 text-amber-600 border border-amber-100">
                              <AlertTriangle className="w-3 h-3" /> Cần kiểm tra
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-black uppercase bg-emerald-50 text-emerald-600 border border-emerald-100">
                              <CheckCircle className="w-3 h-3" /> Ổn định
                            </span>
                          )}
                        </td>
                        <td className="px-5 py-4">
                          <button className="p-2 hover:bg-white rounded-xl transition-all shadow-sm border border-transparent hover:border-slate-200">
                            <List className="w-4 h-4 text-slate-400 group-hover:text-primary" />
                          </button>
                        </td>
                      </tr>

                      {/* Variant Rows */}
                      {isExpanded && product.variants.map((variant) => {
                        const status = stockStatusConfig[variant.stockStatus];
                        const StatusIcon = status.icon;
                        return (
                          <tr key={variant.variantId} className="border-b border-slate-50 bg-slate-50/30 animate-in slide-in-from-top-1 duration-200">
                            <td className="px-5 py-3"></td>
                            <td className="px-5 py-3">
                              <div className="flex items-center gap-3 pl-4 border-l-2 border-primary/20">
                                <div className="w-8 h-8 rounded-lg overflow-hidden bg-white border border-slate-200">
                                  {variant.imageUrl ? (
                                    <img src={variant.imageUrl} alt="" className="w-full h-full object-cover" />
                                  ) : (
                                    <Package className="w-4 h-4 text-slate-200 m-auto mt-2" />
                                  )}
                                </div>
                                <div>
                                  <div className="flex items-center gap-2">
                                    <span className="font-mono text-[10px] font-black text-slate-500 bg-white px-2 py-0.5 rounded border border-slate-200 uppercase tracking-tighter">
                                      {variant.sku}
                                    </span>
                                    <span className="text-[11px] font-bold text-slate-600 truncate max-w-[200px]">
                                      {variant.variantName.split(' - ')[1] || variant.variantName}
                                    </span>
                                  </div>
                                  <div className="flex gap-1 mt-1">
                                    {Object.entries(variant.attributes as Record<string, any>).map(([k, v]) => (
                                      <span key={k} className="text-[9px] font-bold text-blue-500 bg-blue-50 px-1.5 py-0.5 rounded uppercase">{k}: {String(v)}</span>
                                    ))}
                                  </div>
                                </div>
                              </div>
                            </td>
                            <td className="px-5 py-3">
                              <span className={cn("text-base font-black", variant.currentStock === 0 ? "text-red-500" : variant.currentStock <= 10 ? "text-amber-500" : "text-emerald-600")}>
                                {variant.currentStock}
                              </span>
                            </td>
                            <td className="px-5 py-3" colSpan={1}>
                              <span className="text-[10px] font-bold text-slate-400">
                                {Number(variant.price).toLocaleString('vi-VN')}₫
                              </span>
                            </td>
                            <td className="px-5 py-3">
                              <span className={cn("inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[9px] font-black uppercase border", status.color)}>
                                <StatusIcon className="w-3 h-3" />{status.label}
                              </span>
                            </td>
                            <td className="px-5 py-3">
                              <div className="flex items-center gap-2">
                                <button onClick={(e) => { e.stopPropagation(); setAdjustVariant({ ...variant, productName: product.productName }); }} className="p-1.5 hover:bg-primary hover:text-white rounded-lg transition-all text-slate-400" title="Điều chỉnh">
                                  <ArrowUpDown className="w-3.5 h-3.5" />
                                </button>
                                <button onClick={(e) => { e.stopPropagation(); setHistoryVariantId(variant.variantId); setHistoryVariantName(`${product.productName} - ${variant.sku}`); }} className="p-1.5 hover:bg-slate-200 rounded-lg transition-all text-slate-400" title="Lịch sử">
                                  <History className="w-3.5 h-3.5" />
                                </button>
                              </div>
                            </td>
                          </tr>
                        );
                      })}
                    </React.Fragment>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination */}
        {meta.lastPage > 1 && (
          <div className="flex items-center justify-between px-5 py-4 border-t border-slate-100 bg-slate-50/50">
            <p className="text-xs font-bold text-slate-400">Trang {meta.page} / {meta.lastPage} ({meta.total} Sản phẩm mẹ)</p>
            <div className="flex gap-2">
              <button disabled={page <= 1} onClick={() => setPage(p => p - 1)} className="px-4 py-2 text-xs font-bold rounded-xl border border-slate-200 hover:bg-slate-50 disabled:opacity-40 transition-all">Trước</button>
              <button disabled={page >= meta.lastPage} onClick={() => setPage(p => p + 1)} className="px-4 py-2 text-xs font-bold rounded-xl border border-slate-200 hover:bg-slate-50 disabled:opacity-40 transition-all">Sau</button>
            </div>
          </div>
        )}
      </div>

      {/* Modals */}
      {adjustVariant && (
        <AdjustStockModal variant={{ ...adjustVariant, currentStock: adjustVariant.currentStock }} onClose={() => setAdjustVariant(null)} onSuccess={() => { queryClient.invalidateQueries({ queryKey: ['inventory'] }); setAdjustVariant(null); }} />
      )}
      {historyVariantId && (
        <TransactionHistoryModal variantId={historyVariantId} variantName={historyVariantName} onClose={() => setHistoryVariantId(null)} />
      )}
    </div>
  );
};
