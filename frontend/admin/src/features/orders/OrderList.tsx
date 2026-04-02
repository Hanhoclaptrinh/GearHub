import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useSearchParams } from 'react-router-dom';
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
  const [selectedOrderId, setSelectedOrderId] = useState<string | null>(null);
  const [searchParams] = useSearchParams();
  const queryClient = useQueryClient();

  const orderIdFromUrl = searchParams.get('orderId');

  useEffect(() => {
    if (orderIdFromUrl) {
      setSearch(orderIdFromUrl);
      setStatus('');
      setPage(1);
    }
  }, [orderIdFromUrl]);

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

  const { data: statsData } = useQuery({
    queryKey: ['orders', 'stats'],
    queryFn: orderService.getAdminStats,
  });

  const { data: orderDetail, isLoading: isLoadingDetail } = useQuery({
    queryKey: ['order-detail', selectedOrderId],
    queryFn: () => selectedOrderId ? orderService.getOrderById(selectedOrderId) : null,
    enabled: !!selectedOrderId
  });

  const statusStats = statsData?.stats?.ordersByStatus || {};

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

      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
        {[
          { label: 'Tất cả', value: '', icon: ShoppingBag, color: 'slate', count: meta.total },
          { label: 'Chờ xác nhận', value: OrderStatus.PENDING, icon: Clock, color: 'orange', count: statusStats[OrderStatus.PENDING] || 0 },
          { label: 'Đã xác nhận', value: OrderStatus.CONFIRMED, icon: CheckCircle, color: 'blue', count: statusStats[OrderStatus.CONFIRMED] || 0 },
          { label: 'Đang đóng gói', value: OrderStatus.PROCESSING, icon: RefreshCcw, color: 'indigo', count: statusStats[OrderStatus.PROCESSING] || 0 },
          { label: 'Đang giao', value: OrderStatus.SHIPPING, icon: Truck, color: 'cyan', count: statusStats[OrderStatus.SHIPPING] || 0 },
          { label: 'Hoàn tất', value: OrderStatus.DELIVERED, icon: CheckCircle, color: 'green', count: statusStats[OrderStatus.DELIVERED] || 0 },
          { label: 'Đã hủy', value: OrderStatus.CANCELLED, icon: XCircle, color: 'red', count: statusStats[OrderStatus.CANCELLED] || 0 },
          { label: 'Trả hàng', value: OrderStatus.RETURNED, icon: AlertCircle, color: 'pink', count: statusStats[OrderStatus.RETURNED] || 0 },
          { label: 'Thất bại', value: OrderStatus.FAILED, icon: XCircle, color: 'orange', count: statusStats[OrderStatus.FAILED] || 0 }
        ].map((tab) => (
          <button
            key={tab.label}
            onClick={() => { setStatus(tab.value as any); setPage(1); }}
            className={cn(
              "flex flex-col items-center justify-center p-3 rounded-2xl border-2 transition-all group relative overflow-hidden",
              status === tab.value
                ? "bg-white border-primary shadow-lg shadow-primary/5 ring-4 ring-primary/5"
                : "bg-slate-50/50 border-transparent hover:bg-white hover:border-slate-200"
            )}
          >
            <div className={cn(
              "w-8 h-8 rounded-xl flex items-center justify-center mb-2 transition-transform group-hover:scale-110",
              status === tab.value ? "bg-primary text-white" : "bg-white text-slate-400 border border-slate-100"
            )}>
              <tab.icon className="w-4 h-4" />
            </div>
            <span className={cn(
              "text-[9px] font-black uppercase tracking-tighter transition-colors text-center leading-none",
              status === tab.value ? "text-primary" : "text-slate-500"
            )}>{tab.label}</span>
            {tab.count > 0 && (
              <span className={cn(
                "absolute top-1 right-1 px-1.5 py-0.5 rounded-full text-[8px] font-black",
                status === tab.value ? "bg-primary text-white" : "bg-slate-200 text-slate-600"
              )}>
                {tab.count}
              </span>
            )}
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
                        <Button
                          variant="ghost"
                          className="p-2 h-10 w-10 text-slate-400 hover:text-primary hover:bg-primary/5 rounded-full border-none"
                          onClick={() => setSelectedOrderId(order.id)}
                        >
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
      {/* Order Detail Modal */}
      {selectedOrderId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-300">
          <div className="bg-white rounded-[40px] shadow-2xl w-full max-w-2xl overflow-hidden animate-in zoom-in-95 duration-300 flex flex-col max-h-[90vh]">
            <div className="p-8 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-2xl bg-primary/10 flex items-center justify-center text-primary">
                  <ShoppingBag size={24} />
                </div>
                <div>
                  <h3 className="text-xl font-black text-slate-900 uppercase tracking-tight">Chi tiết đơn hàng</h3>
                  {orderDetail && <p className="text-[10px] font-black text-primary uppercase tracking-[0.2em] mt-1">#{orderDetail.orderNumber || orderDetail.id.toUpperCase()}</p>}
                </div>
              </div>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setSelectedOrderId(null)}
                className="rounded-full hover:bg-slate-200"
              >
                <XCircle className="w-6 h-6 text-slate-400" />
              </Button>
            </div>

            <div className="flex-1 overflow-y-auto p-8 space-y-8">
              {isLoadingDetail ? (
                <div className="flex items-center justify-center py-20">
                  <Loader2 size={40} className="text-primary animate-spin" />
                </div>
              ) : orderDetail ? (
                <>
                  <div className="grid grid-cols-2 gap-8">
                    <div className="space-y-4">
                      <h4 className="text-xs font-black text-slate-400 uppercase tracking-widest border-b border-slate-100 pb-2">Người nhận</h4>
                      <div className="space-y-2">
                        <p className="font-extrabold text-slate-900 text-lg">{orderDetail.receiverName}</p>
                        <p className="font-bold text-slate-500">{orderDetail.receiverPhone}</p>
                        <p className="text-sm font-medium text-slate-600 leading-relaxed">{orderDetail.shippingAddress}</p>
                      </div>
                    </div>
                    <div className="space-y-4">
                      <h4 className="text-xs font-black text-slate-400 uppercase tracking-widest border-b border-slate-100 pb-2">Thông tin đơn</h4>
                      <div className="grid grid-cols-1 gap-3">
                        <div className="flex justify-between">
                          <span className="text-sm font-bold text-slate-400">Trạng thái:</span>
                          {getStatusBadge(orderDetail.status)}
                        </div>
                        <div className="flex justify-between">
                          <span className="text-sm font-bold text-slate-400">Thanh toán:</span>
                          <span className="text-sm font-black text-slate-900 uppercase">{orderDetail.paymentMethod}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-sm font-bold text-slate-400">Mã đơn:</span>
                          <span className="text-sm font-mono font-bold text-slate-900">#{orderDetail.id}</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-4">
                    <h4 className="text-xs font-black text-slate-400 uppercase tracking-widest border-b border-slate-100 pb-2">Danh sách sản phẩm</h4>
                    <div className="space-y-3">
                      {orderDetail.items?.map((item: any) => (
                        <div key={item.id} className="flex items-center justify-between p-4 rounded-2xl bg-slate-50 border border-slate-100 group hover:bg-white hover:border-primary/20 transition-all">
                          <div className="flex items-center gap-4">
                            <div className="w-12 h-12 rounded-xl bg-white border border-slate-200 flex items-center justify-center p-1 overflow-hidden">
                              {item.productVariant?.product?.images?.[0]?.url ? (
                                <img src={item.productVariant.product.images[0].url} alt={item.productName} className="w-full h-full object-cover rounded-lg" />
                              ) : (
                                <ShoppingBag className="text-slate-300 w-6 h-6" />
                              )}
                            </div>
                            <div>
                              <p className="text-sm font-black text-slate-900 group-hover:text-primary transition-colors">{item.productName}</p>
                              <p className="text-[10px] font-bold text-slate-400 uppercase">{item.variantName}</p>
                            </div>
                          </div>
                          <div className="text-right">
                            <p className="text-sm font-black text-slate-900">{new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(item.priceAtPurchase)}</p>
                            <p className="text-[10px] font-bold text-slate-400 uppercase">x{item.quantity}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </>
              ) : null}
            </div>

            <div className="p-8 bg-slate-50/50 border-t border-slate-100">
              <div className="flex items-center justify-between mb-6">
                <p className="text-sm font-black text-slate-400 uppercase tracking-tight">Tổng thanh toán</p>
                <p className="text-3xl font-black text-primary">
                  {orderDetail ? new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(orderDetail.totalAmount) : '...'}
                </p>
              </div>
              <div className="flex gap-3">
                <Button className="flex-1 h-14 rounded-2xl font-black uppercase tracking-widest" onClick={() => setSelectedOrderId(null)}>Đóng chi tiết</Button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
