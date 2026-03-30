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
  MoreVertical,
  Image as ImageIcon,
  CheckCircle2,
  XCircle,
  AlertCircle,
  TrendingUp,
  Clock,
  ChevronRight,
  ChevronLeft,
  Box,
  Eye,
  EyeOff
} from 'lucide-react';
import { productService } from '../../services/product.service';
import { toast } from 'sonner';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Card, CardContent } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';
import { ConfirmModal } from '../../components/ui/ConfirmModal';
import { cn } from '../../utils/cn';
import type { Product } from '../../types';

import { ThreeDViewerModal } from '../../components/products/ThreeDViewerModal';

export const ProductList: React.FC = () => {
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [productIdToDelete, setProductIdToDelete] = useState<string | null>(null);
  const [selected3DModel, setSelected3DModel] = useState<{ glb: string, usdz?: string, name: string } | null>(null);

  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const { data, isLoading, isError } = useQuery({
    queryKey: ['products', search, page, 'admin'], // add 'admin' key
    queryFn: () => productService.getProducts({ search, page, limit: 10, isAdmin: 'true' }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => productService.hardDelete(id),
    onSuccess: (res: any) => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      toast.success(res.message || 'Thay đổi trạng thái thành công');
      setIsConfirmOpen(false);
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Có lỗi xảy ra khi xóa sản phẩm');
    }
  });

  const restoreMutation = useMutation({
    mutationFn: (id: string) => productService.restore(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      toast.success('Đã khôi phục sản phẩm thành công');
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Có lỗi xảy ra khi khôi phục');
    }
  });

  const toggleMutation = useMutation({
    mutationFn: (id: string) => productService.deleteProduct(id),
    onSuccess: (res: any) => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      toast.success(res.message || 'Cập nhật trạng thái thành công');
    },
    onError: (err: any) => {
      toast.error(err.response?.data?.message || 'Không thể cập nhật trạng thái');
    }
  });

  const handleDelete = (id: string) => {
    setProductIdToDelete(id);
    setIsConfirmOpen(true);
  };

  const open3DViewer = (product: Product) => {
    const glbAsset = product.assets?.find(a => a.type === 'GLB');
    const usdzAsset = product.assets?.find(a => a.type === 'USDZ');

    if (glbAsset) {
      setSelected3DModel({
        glb: glbAsset.url,
        usdz: usdzAsset?.url,
        name: product.name
      });
    } else if (usdzAsset) {
      setSelected3DModel({
        glb: usdzAsset.url,
        usdz: usdzAsset.url,
        name: product.name
      });
    }
  };

  const products = data?.data || [];
  const meta = data?.meta || { total: 0, lastPage: 1 };

  return (
    <div className="space-y-8 pb-10">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div className="space-y-1">
          <h1 className="text-3xl font-black text-slate-900 font-heading leading-tight tracking-tight">Quản lý kho hàng</h1>
          <p className="text-sm font-bold text-slate-400 uppercase tracking-[0.2em]">Tổng {meta.total} sản phẩm hiện có</p>
        </div>
        <div className="flex gap-3">
          <Button variant="outline" className="h-14 px-6 rounded-2xl border-2 border-slate-100 bg-white hover:border-primary transition-all shadow-lg shadow-slate-100/50">
            <Filter className="w-5 h-5 mr-2" /> Bộ lọc
          </Button>
          <Button onClick={() => navigate('/products/create')} className="h-14 px-8 rounded-2xl shadow-primary/20 shadow-2xl group">
            <Plus className="w-6 h-6 mr-2 group-hover:rotate-90 transition-transform" />
            Thêm sản phẩm
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {[
          { label: 'Doanh thu 24h', value: '42.5M', icon: TrendingUp, trend: '+12%', color: 'blue' },
          { label: 'Đơn mới', value: '128', icon: Clock, trend: '+5%', color: 'indigo' },
          { label: 'Out of stock', value: '03', icon: Package, trend: '-2', color: 'red' },
          { label: 'Active', value: '1,204', icon: CheckCircle2, trend: 'Stable', color: 'green' }
        ].map((stat, i) => (
          <Card key={i} className="border-none shadow-xl shadow-slate-200/40 rounded-3xl overflow-hidden group hover:scale-[1.02] transition-transform">
            <CardContent className="p-6">
              <div className="flex justify-between items-start mb-4">
                <div className={cn("p-3 rounded-2xl", i === 3 ? "bg-green-50 text-green-500" : i === 2 ? "bg-red-50 text-red-500" : "bg-primary/5 text-primary")}>
                  <stat.icon className="w-6 h-6" />
                </div>
                <span className={cn("text-[10px] font-black px-2 py-1 rounded-full", stat.trend.includes('+') ? "bg-green-50 text-green-500" : "bg-slate-50 text-slate-400")}>
                  {stat.trend}
                </span>
              </div>
              <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{stat.label}</p>
              <h3 className="text-2xl font-black text-slate-900 mt-1">{stat.value}</h3>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card className="border-none shadow-2xl shadow-slate-200/50 rounded-[40px] p-2 bg-white/50 backdrop-blur-xl border border-white/20">
        <CardContent className="p-4">
          <div className="relative group">
            <Search className="absolute left-6 top-1/2 -translate-y-1/2 w-6 h-6 text-slate-300 group-focus-within:text-primary transition-colors" />
            <Input
              placeholder="Tìm sản phẩm theo tên, SKU hoặc ID..."
              className="pl-16 py-5 h-16 bg-slate-50 border-none rounded-[28px] text-lg font-bold placeholder:text-slate-300 focus:ring-4 focus:ring-primary/5 transition-all outline-none w-full"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </CardContent>
      </Card>

      <div className="bg-white rounded-[48px] shadow-2xl shadow-slate-200/70 border border-slate-100 overflow-hidden animate-in fade-in slide-in-from-bottom-5 duration-500">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1000px]">
            <thead className="bg-slate-50/50 border-b border-slate-100">
              <tr>
                <th className="px-10 py-6 text-xs font-black text-slate-500 uppercase tracking-[0.2em]">Thông tin sản phẩm</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-[0.2em]">Danh mục</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-[0.2em]">Giá bán</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-[0.2em]">Tồn kho</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-[0.2em]">Trạng thái</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-[0.2em] text-center">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 font-body">
              {isLoading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td colSpan={6} className="px-10 py-6 bg-slate-50/20 shadow-inner" />
                  </tr>
                ))
              ) : products.length > 0 ? (
                products.map((product: Product) => {
                  const has2D = product.assets?.some(a => a.type === 'IMAGE');
                  const has3D = product.assets?.some(a => ['GLB', 'USDZ'].includes(a.type));
                  const hasAR = product.assets?.some(a => a.type === 'USDZ');
                  const primaryAsset = product.assets?.find(a => a.isPrimary) || product.assets?.find(a => a.type === 'IMAGE');

                  return (
                    <tr key={product.id} className="hover:bg-slate-50/50 transition-colors group">
                      <td className="px-6 py-4 pl-10">
                        <div className="flex items-center gap-5">
                          <div className={cn(
                            "relative w-16 h-16 rounded-2xl border flex items-center justify-center overflow-hidden flex-shrink-0 group-hover:scale-105 transition-all duration-300 shadow-sm",
                            has3D ? "bg-indigo-50 border-indigo-100" : "bg-white border-slate-200"
                          )}>
                            {primaryAsset?.url ? (
                              <img src={primaryAsset.url} alt={product.name} className="w-full h-full object-cover" />
                            ) : has3D ? (
                              <Box className="w-8 h-8 text-indigo-400" />
                            ) : (
                              <ImageIcon className="w-6 h-6 text-slate-300" />
                            )}

                            <div className="absolute top-1 left-1 flex flex-col gap-0.5">
                              {has2D && <span className="bg-blue-500/90 text-[7px] text-white px-1 leading-tight rounded-sm font-black">2D</span>}
                              {has3D && <span className="bg-indigo-500/90 text-[7px] text-white px-1 leading-tight rounded-sm font-black">3D</span>}
                              {hasAR && <span className="bg-cta/90 text-[7px] text-white px-1 leading-tight rounded-sm font-black">AR</span>}
                            </div>
                          </div>
                          <div className="flex flex-col min-w-0">
                            <span className="font-extrabold text-slate-800 line-clamp-1 group-hover:text-primary transition-colors text-base flex items-center gap-2">
                              {product.name}
                              {has3D && (
                                <button
                                  onClick={() => open3DViewer(product)}
                                  className="p-1 px-2 bg-indigo-50 text-indigo-600 rounded-full text-[9px] font-black uppercase hover:bg-indigo-600 hover:text-white transition-all flex items-center gap-1 active:scale-95"
                                >
                                  <Box size={10} /> Xem 3D
                                </button>
                              )}
                            </span>
                            <span className="text-[10px] font-black text-slate-400 mt-1 uppercase tracking-tighter bg-slate-100 w-fit px-1.5 rounded">SKU: {product.variants?.[0]?.sku || 'N/A'}</span>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <Badge variant="default" className="bg-slate-100 text-slate-600 border-none font-bold py-1.5 px-3">
                          {product.category?.name || 'Chưa phân loại'}
                        </Badge>
                      </td>
                      <td className="px-6 py-4">
                        <span className="font-black text-slate-900 tracking-tight text-base">
                          {new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(product.variants?.[0]?.price || 0)}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex flex-col">
                          <span className={cn(
                            "text-base font-black",
                            (product.variants?.[0]?.stock || 0) < 5 ? "text-red-500" : "text-green-600"
                          )}>
                            {product.variants?.reduce((sum, v) => sum + (v.stock || 0), 0) || 0}
                          </span>
                          <span className="text-[10px] font-bold text-slate-400 uppercase">kiểm tại kho</span>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        {product.isActive ? (
                          <Badge variant="success" className="gap-1 animate-in fade-in slide-in-from-left-1 h-8 px-3">
                            <CheckCircle2 className="w-3.5 h-3.5" /> Đang bán
                          </Badge>
                        ) : (
                          <Badge variant="danger" className="gap-1 animate-in fade-in slide-in-from-left-1 h-8 px-3">
                            <XCircle className="w-3.5 h-3.5" /> Tạm ngưng
                          </Badge>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center justify-center gap-2">
                          {!product.isActive ? (
                            <Button
                              variant="ghost"
                              className="p-2 h-10 w-10 text-green-500 hover:bg-green-50 rounded-full shadow-none border-none transition-all hover:scale-110"
                              onClick={() => restoreMutation.mutate(product.id)}
                              isLoading={restoreMutation.isPending && restoreMutation.variables === product.id}
                              title="Kích hoạt lại"
                            >
                              <CheckCircle2 className="w-5 h-5" />
                            </Button>
                          ) : (
                            <>
                              <Button
                                variant="ghost"
                                className="p-2 h-10 w-10 text-amber-500 hover:bg-amber-50 rounded-full shadow-none border-none transition-all hover:scale-110"
                                onClick={() => toggleMutation.mutate(product.id)}
                                isLoading={toggleMutation.isPending && toggleMutation.variables === product.id}
                                title="Ẩn sản phẩm"
                              >
                                <EyeOff className="w-5 h-5" />
                              </Button>
                              <Button
                                variant="ghost"
                                className="p-2 h-10 w-10 text-primary hover:bg-primary/5 rounded-full shadow-none border-none transition-all hover:scale-110"
                                onClick={() => navigate(`/products/edit/${product.slug}`)}
                                title="Chỉnh sửa"
                              >
                                <Edit className="w-5 h-5" />
                              </Button>
                            </>
                          )}
                          <Button
                            variant="ghost"
                            className="p-2 h-10 w-10 text-red-500 hover:bg-red-50 rounded-full shadow-none border-none transition-all hover:scale-110"
                            onClick={() => handleDelete(product.id)}
                            isLoading={deleteMutation.isPending && deleteMutation.variables === product.id}
                            title="Xóa vĩnh viễn"
                          >
                            <Trash2 className="w-5 h-5" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={6} className="px-10 py-32 text-center">
                    <div className="flex flex-col items-center gap-6">
                      <div className="w-32 h-32 bg-slate-50 rounded-[48px] flex items-center justify-center text-slate-200">
                        <Package size={64} strokeWidth={1} />
                      </div>
                      <div>
                        <p className="text-slate-800 text-2xl font-black">Chưa có sản phẩm nào.</p>
                        <p className="text-slate-400 font-bold text-base mt-1">Hãy bắt đầu hành trình bằng cách thêm sản phẩm mới đầu tiên.</p>
                      </div>
                      <Button onClick={() => navigate('/products/create')} className="rounded-[20px] px-10 h-14 shadow-xl shadow-primary/20">Thêm ngay</Button>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {meta.lastPage > 1 && (
          <div className="px-12 py-8 border-t border-slate-100 bg-slate-50/10 flex items-center justify-between">
            <p className="text-sm font-black text-slate-400 uppercase tracking-widest">Trang {page} / {meta.lastPage}</p>
            <div className="flex gap-4">
              <Button
                variant="outline"
                size="sm"
                disabled={page === 1}
                onClick={() => setPage(page - 1)}
                className="rounded-2xl px-6 h-12 border-none bg-white shadow-sm font-black"
              >
                <ChevronLeft className="w-5 h-5 mr-1" /> Trước
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={page === meta.lastPage}
                onClick={() => setPage(page + 1)}
                className="rounded-2xl px-6 h-12 border-none bg-white shadow-sm font-black"
              >
                Sau <ChevronRight className="w-5 h-5 ml-1" />
              </Button>
            </div>
          </div>
        )}
      </div>

      {isError && (
        <div className="p-8 bg-red-50 border-2 border-red-100 rounded-[40px] flex items-center gap-6 text-red-600 shadow-2xl shadow-red-100/50 animate-in slide-in-from-bottom-5">
          <AlertCircle className="w-10 h-10 flex-shrink-0" />
          <div>
            <p className="text-xl font-black">Mất kết nối dữ liệu</p>
            <p className="text-base font-bold opacity-80">Máy chủ hiện không phản hồi. Vui lòng thử tải lại trang hoặc kiểm tra kết nối mạng.</p>
          </div>
        </div>
      )}

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
        onConfirm={() => productIdToDelete && deleteMutation.mutate(productIdToDelete)}
        title="Xác nhận xóa sản phẩm"
        message="Bạn có chắc chắn muốn xóa sản phẩm này? Mọi dữ liệu về biến thể và tồn kho sẽ bị gỡ bỏ hoàn toàn."
        confirmText="Xác nhận xóa"
        cancelText="Quay lại"
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
};
