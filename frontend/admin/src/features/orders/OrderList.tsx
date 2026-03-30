import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  ShoppingBag,
  Search,
  Clock,
  Truck,
  CheckCircle,
  XCircle,
  AlertCircle,
  RefreshCcw,
  ExternalLink,
  AlertTriangle,
  Loader2
} from 'lucide-react';
import { orderService } from '../../services/order.service';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Card, CardContent } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';
import { cn } from '../../utils/cn';
import { OrderStatus } from '../../types';
import type { Order } from '../../types';

export const OrderList: React.FC = () => {
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<OrderStatus | ''>('');
  const [page, setPage] = useState(1);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const queryClient = useQueryClient();

  const { data, isLoading, isError } = useQuery({
    queryKey: ['orders', search, status, page],
    queryFn: () => orderService.getOrders({ search, status, page, limit: 10 }),
  });

  const updateStatusMutation = useMutation({
    mutationFn: ({ id, status }: { id: string; status: OrderStatus }) =>
      orderService.updateStatus(id, { status }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      setSuccessMessage('Cập nhật trạng thái thành công');
      setTimeout(() => setSuccessMessage(null), 3000);
    },
    onError: (error: any) => {
      const errorMsg = error?.response?.data?.message || 'Cập nhật trạng thái thất bại';
      setErrorMessage(`${errorMsg}`);
      setTimeout(() => setErrorMessage(null), 3000);
    }
  });

  const orders = data?.data || [];
  const meta = data?.meta || { total: 0, lastPage: 1 };

  const getStatusLabel = (status: OrderStatus): string => {
    const statusLabels: Record<OrderStatus, string> = {
      PENDING: 'Chờ xác nhận',
      CONFIRMED: 'Đã xác nhận',
      PROCESSING: 'Đang đóng gói',
      SHIPPING: 'Đang giao',
      DELIVERED: 'Hoàn tất',
      CANCELLED: 'Đã hủy',
      RETURNED: 'Khách trả hàng',
      FAILED: 'Giao hàng thất bại'
    };
    return statusLabels[status] || status;
  };

  const getStatusBadge = (status: OrderStatus) => {
    switch (status) {
      case OrderStatus.PENDING:
        return <Badge variant="warning"><Clock className="w-3 h-3" /> Chờ xác nhận</Badge>;
      case OrderStatus.CONFIRMED:
        return <Badge variant="info"><RefreshCcw className="w-3 h-3" /> Đã xác nhận</Badge>;
      case OrderStatus.PROCESSING:
        return <Badge variant="info"><RefreshCcw className="w-3 h-3" /> Đang đóng gói</Badge>;
      case OrderStatus.SHIPPING:
        return <Badge variant="info"><Truck className="w-3 h-3" /> Đang giao</Badge>;
      case OrderStatus.DELIVERED:
        return <Badge variant="success"><CheckCircle className="w-3 h-3" /> Hoàn tất</Badge>;
      case OrderStatus.CANCELLED:
        return <Badge variant="danger"><XCircle className="w-3 h-3" /> Đã hủy</Badge>;
      case OrderStatus.RETURNED:
        return <Badge variant="danger"><AlertCircle className="w-3 h-3" /> Khách trả hàng</Badge>;
      case OrderStatus.FAILED:
        return <Badge variant="danger"><AlertTriangle className="w-3 h-3" /> Thất bại</Badge>;
      default:
        return <Badge>{status}</Badge>;
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 font-heading leading-tight">Quản lý đơn hàng</h1>
          <p className="text-sm font-bold text-slate-500 uppercase tracking-widest">Tất cả {meta.total} đơn hàng từ khách hàng</p>
        </div>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        {[
          { label: 'Tất cả', value: '', icon: ShoppingBag, color: 'primary' },
          { label: 'Chờ xác nhận', value: OrderStatus.PENDING, icon: Clock, color: 'orange' },
          { label: 'Đang xử lý', value: OrderStatus.PROCESSING, icon: RefreshCcw, color: 'blue' },
          { label: 'Đang giao', value: OrderStatus.SHIPPING, icon: Truck, color: 'cyan' },
          { label: 'Hoàn tất', value: OrderStatus.DELIVERED, icon: CheckCircle, color: 'green' }
        ].map((tab) => (
          <button
            key={tab.label}
            onClick={() => { setStatus(tab.value as any); setPage(1); }}
            className={cn(
              "flex flex-col items-center justify-center p-4 rounded-3xl border-2 transition-all group",
              status === tab.value
                ? "bg-white border-primary shadow-xl shadow-primary/10 ring-4 ring-primary/5"
                : "bg-slate-50/50 border-transparent hover:bg-white hover:border-slate-200"
            )}
          >
            <div className={cn(
              "w-10 h-10 rounded-2xl flex items-center justify-center mb-2 transition-transform group-hover:scale-110",
              status === tab.value ? "bg-primary text-white" : "bg-white text-slate-400 border border-slate-100"
            )}>
              <tab.icon className="w-5 h-5" />
            </div>
            <span className={cn(
              "text-xs font-black uppercase tracking-tighter transition-colors",
              status === tab.value ? "text-primary" : "text-slate-500"
            )}>{tab.label}</span>
          </button>
        ))}
      </div>

      <Card>
        <CardContent className="p-4">
          <div className="flex flex-col md:flex-row gap-4 items-center">
            <div className="relative flex-1 w-full group">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-primary transition-colors" />
              <Input
                placeholder="Tìm theo Mã đơn hàng, Tên khách hàng hoặc SĐT..."
                className="pl-11 py-2.5 h-11"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <Button variant="outline" className="px-6 h-11" onClick={() => queryClient.invalidateQueries({ queryKey: ['orders'] })}>
              <RefreshCcw className="w-5 h-5" />
            </Button>
          </div>
        </CardContent>
      </Card>

      <div className="bg-white rounded-[32px] shadow-2xl shadow-slate-200/50 border border-slate-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1000px]">
            <thead className="bg-slate-50/50 border-b border-slate-100">
              <tr>
                <th className="px-8 py-5 text-xs font-black text-slate-500 uppercase tracking-widest">Mã đơn hàng</th>
                <th className="px-8 py-5 text-xs font-black text-slate-500 uppercase tracking-widest">Khách hàng</th>
                <th className="px-8 py-5 text-xs font-black text-slate-500 uppercase tracking-widest">Thời gian</th>
                <th className="px-8 py-5 text-xs font-black text-slate-500 uppercase tracking-widest">Tổng tiền</th>
                <th className="px-8 py-5 text-xs font-black text-slate-500 uppercase tracking-widest">Trạng thái</th>
                <th className="px-8 py-5 text-xs font-black text-slate-500 uppercase tracking-widest text-right">Chi tiết</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 font-body">
              {isLoading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td colSpan={6} className="px-8 py-6 bg-slate-50/20" />
                  </tr>
                ))
              ) : orders.length > 0 ? (
                orders.map((order: Order) => (
                  <tr key={order.id} className="hover:bg-slate-50/50 transition-colors group">
                    <td className="px-8 py-5">
                      <div className="flex flex-col">
                        <span className="font-black text-slate-900 group-hover:text-primary transition-colors">#{order.orderNumber || order.id.slice(-8).toUpperCase()}</span>
                        <span className="text-[10px] font-bold text-primary bg-primary/5 w-fit px-1.5 rounded mt-1">{order.items?.length || 0} món</span>
                      </div>
                    </td>
                    <td className="px-8 py-5">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-400 font-black text-xs uppercase">
                          {(order.receiverName || order.user?.fullName)?.[0] || 'G'}
                        </div>
                        <div className="flex flex-col">
                          <span className="font-extrabold text-slate-800 line-clamp-1">{order.receiverName || order.user?.fullName || 'N/A'}</span>
                          <span className="text-[11px] font-bold text-slate-400 uppercase tracking-tighter">{order.receiverPhone || order.phone || 'N/A'}</span>
                        </div>
                      </div>
                    </td>
                    <td className="px-8 py-5">
                      <div className="flex flex-col">
                        <span className="text-sm font-bold text-slate-700">{order.createdAt ? new Date(order.createdAt).toLocaleDateString('vi-VN') : 'N/A'}</span>
                        <span className="text-[11px] font-bold text-slate-400">{order.createdAt ? new Date(order.createdAt).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) : 'N/A'}</span>
                      </div>
                    </td>
                    <td className="px-8 py-5">
                      <span className="font-black text-slate-900 tracking-tight">
                        {new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(order.totalAmount || 0)}
                      </span>
                    </td>
                    <td className="px-8 py-5">
                      {getStatusBadge(order.status)}
                    </td>
                    <td className="px-8 py-5">
                      <div className="flex items-center justify-end gap-2">
                        <select
                          className="bg-slate-100 text-[10px] font-black uppercase px-2 py-1 rounded-lg border-none outline-none cursor-pointer hover:bg-slate-200 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                          value={order.status}
                          onChange={(e) => updateStatusMutation.mutate({ id: order.id, status: e.target.value as OrderStatus })}
                          disabled={updateStatusMutation.isPending}
                        >
                          {Object.values(OrderStatus).map(s => (
                            <option key={s} value={s}>{getStatusLabel(s as OrderStatus)}</option>
                          ))}
                        </select>
                        {updateStatusMutation.isPending && <Loader2 className="w-4 h-4 animate-spin text-primary" />}
                        <Button variant="ghost" className="p-2 h-10 w-10 text-slate-400 hover:text-primary hover:bg-primary/5 rounded-full border-none">
                          <ExternalLink className="w-5 h-5" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={6} className="px-8 py-20 text-center">
                    <div className="flex flex-col items-center gap-4">
                      <div className="w-20 h-20 bg-slate-50 rounded-[32px] flex items-center justify-center text-slate-200">
                        <ShoppingBag size={40} />
                      </div>
                      <div>
                        <p className="text-slate-800 text-lg font-black">Chưa có đơn hàng nào.</p>
                        <p className="text-slate-400 font-bold text-sm">Hãy thử thay đổi bộ lọc hoặc tìm kiếm.</p>
                      </div>
                      <Button variant="outline" size="sm" className="rounded-full px-6" onClick={() => { setStatus(''); setSearch(''); }}>Xóa bộ lọc</Button>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {meta.lastPage > 1 && (
          <div className="px-10 py-6 border-t border-slate-100 bg-slate-50/10 flex items-center justify-between">
            <p className="text-xs font-black text-slate-400 uppercase tracking-widest">Trang {page} / {meta.lastPage}</p>
            <div className="flex gap-2">
              <Button variant="outline" size="sm" disabled={page === 1} onClick={() => setPage(page - 1)} className="rounded-xl border-slate-200">Trước</Button>
              <Button variant="outline" size="sm" disabled={page === meta.lastPage} onClick={() => setPage(page + 1)} className="rounded-xl border-slate-200">Sau</Button>
            </div>
          </div>
        )}
      </div>

      {isError && (
        <div className="p-6 bg-red-50 border border-red-100 rounded-[32px] flex items-center gap-4 text-red-600 shadow-lg shadow-red-100">
          <AlertCircle className="w-6 h-6 flex-shrink-0" />
          <p className="text-sm font-black">Lỗi nạp dữ liệu đơn hàng. Vui lòng kiểm tra lại kết nối server.</p>
        </div>
      )}

      {errorMessage && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-2xl flex items-center gap-3 text-red-700 shadow-md animate-in slide-in-from-top-3">
          <AlertTriangle className="w-5 h-5 flex-shrink-0" />
          <span className="font-bold text-sm">{errorMessage}</span>
        </div>
      )}

      {successMessage && (
        <div className="p-4 bg-green-50 border border-green-200 rounded-2xl flex items-center gap-3 text-green-700 shadow-md animate-in slide-in-from-top-3">
          <CheckCircle className="w-5 h-5 flex-shrink-0" />
          <span className="font-bold text-sm">{successMessage}</span>
        </div>
      )}
    </div>
  );
};
