import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { 
  CreditCard, 
  Search, 
  ExternalLink, 
  Calendar, 
  Clock, 
  RefreshCcw,
  CheckCircle2,
  XCircle,
  AlertCircle,
  User,
  Phone,
  MapPin,
  ShoppingBag,
  NotebookText,
  FileText,
  DollarSign,
  Briefcase
} from 'lucide-react';
import { transactionService } from '../../services/transaction.service';
import { Button } from '../../components/ui/Button';
import { Drawer } from '../../components/ui/Drawer';
import { Input } from '../../components/ui/Input';
import { Card, CardContent } from '../../components/ui/Card';

export const TransactionList: React.FC = () => {
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [selectedTx, setSelectedTx] = useState<any>(null);
  const [paymentMethod, setPaymentMethod] = useState('');
  const [status, setStatus] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ['transactions', search, page, paymentMethod, status, startDate, endDate],
    queryFn: () => transactionService.getAllTransactions({ 
      search, 
      page, 
      limit: 10,
      paymentMethod: paymentMethod || undefined,
      status: status || undefined,
      startDate: startDate || undefined,
      endDate: endDate || undefined
    }),
  });

  const transactions = data?.data || [];
  const meta = data?.meta || { total: 0, lastPage: 1 };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'SUCCESS':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest bg-green-50 text-green-600 border border-green-100">
            <CheckCircle2 className="w-3 h-3" /> Thành công
          </span>
        );
      case 'FAILED':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest bg-red-50 text-red-600 border border-red-100">
            <XCircle className="w-3 h-3" /> Thất bại
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest bg-orange-50 text-orange-600 border border-orange-100">
            <Clock className="w-3 h-3" /> Chờ xử lý
          </span>
        );
    }
  };

  const getPaymentMethodLabel = (method: string, provider?: string) => {
    switch (method) {
      case 'PAYMENT_GATEWAY': 
        return `Cổng thanh toán${provider ? ` (${provider})` : ''}`;
      case 'BANK_TRANSFER': return 'Chuyển khoản';
      case 'E_WALLET': return 'Ví điện tử';
      case 'COD': return 'Thanh toán COD';
      default: return method;
    }
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <div className="w-10 h-10 rounded-2xl bg-primary/10 flex items-center justify-center text-primary">
              <CreditCard size={20} />
            </div>
            <h1 className="text-3xl font-black text-slate-900 tracking-tight uppercase">Quản lý giao dịch</h1>
          </div>
          <p className="text-slate-500 font-bold flex items-center gap-2">
            Tổng {meta.total} giao dịch trong hệ thống
          </p>
        </div>
      </div>

      <Card className="border-none shadow-2xl shadow-slate-200/50 bg-white/80 backdrop-blur-sm rounded-[32px] overflow-hidden">
        <CardContent className="p-6">
          <div className="space-y-4">
            <div className="flex flex-col md:flex-row gap-4 items-center">
              <div className="relative flex-1 w-full group">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-primary transition-colors" />
                <Input
                  placeholder="Tìm kiếm theo mã GD hoặc mã đơn hàng..."
                  className="pl-11 py-2.5 h-11 border-slate-200 focus:border-primary transition-all rounded-2xl"
                  value={search}
                  onChange={(e) => {
                    setSearch(e.target.value);
                    setPage(1);
                  }}
                />
              </div>
              <Button 
                  variant="outline" 
                  className="px-6 h-11 rounded-2xl hover:bg-slate-50 border-slate-200"
                  onClick={() => refetch()}
              >
                <RefreshCcw className="w-5 h-5" />
              </Button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-4 gap-4 w-full">
              <select
                className="h-11 px-4 rounded-2xl border border-slate-200 focus:border-primary focus:outline-none transition-all text-sm bg-white font-bold text-slate-700"
                value={paymentMethod}
                onChange={(e) => {
                  setPaymentMethod(e.target.value);
                  setPage(1);
                }}
              >
                <option value="">Tất cả phương thức</option>
                <option value="COD">Thanh toán COD</option>
                <option value="PAYMENT_GATEWAY">Cổng thanh toán (VNPay)</option>
                <option value="BANK_TRANSFER">Chuyển khoản</option>
                <option value="E_WALLET">Ví điện tử</option>
              </select>

              <select
                className="h-11 px-4 rounded-2xl border border-slate-200 focus:border-primary focus:outline-none transition-all text-sm bg-white font-bold text-slate-700"
                value={status}
                onChange={(e) => {
                  setStatus(e.target.value);
                  setPage(1);
                }}
              >
                <option value="">Tất cả trạng thái</option>
                <option value="SUCCESS">Thành công</option>
                <option value="PENDING">Chờ xử lý</option>
                <option value="FAILED">Thất bại</option>
              </select>

              <div className="flex items-center gap-2">
                <span className="text-[10px] font-black uppercase text-slate-400 pl-2 shrink-0">Từ ngày</span>
                <Input
                  type="date"
                  className="h-11 px-4 rounded-2xl border border-slate-200 focus:border-primary transition-all text-sm bg-white font-bold text-slate-700"
                  value={startDate}
                  onChange={(e) => {
                    setStartDate(e.target.value);
                    setPage(1);
                  }}
                />
              </div>

              <div className="flex items-center gap-2">
                <span className="text-[10px] font-black uppercase text-slate-400 pl-2 shrink-0">Đến ngày</span>
                <Input
                  type="date"
                  className="h-11 px-4 rounded-2xl border border-slate-200 focus:border-primary transition-all text-sm bg-white font-bold text-slate-700"
                  value={endDate}
                  onChange={(e) => {
                    setEndDate(e.target.value);
                    setPage(1);
                  }}
                />
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="bg-white rounded-[32px] shadow-2xl shadow-slate-200/50 border border-slate-100 overflow-hidden text-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1000px]">
            <thead className="bg-slate-50/50 border-b border-slate-100">
              <tr>
                <th className="px-8 py-5 text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">Mã GD</th>
                <th className="px-8 py-5 text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">Mã Đơn hàng</th>
                <th className="px-8 py-5 text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">Phương thức</th>
                <th className="px-8 py-5 text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">Số tiền</th>
                <th className="px-8 py-5 text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">Trạng thái</th>
                <th className="px-8 py-5 text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">Thời gian</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td colSpan={6} className="px-8 py-8 bg-slate-50/20" />
                  </tr>
                ))
              ) : transactions.length > 0 ? (
                transactions.map((tx: any) => (
                  <tr key={tx.id} className="hover:bg-slate-50/50 transition-colors group">
                    <td className="px-8 py-6">
                      <button 
                        onClick={() => setSelectedTx(tx)}
                        className="font-mono text-xs font-bold text-primary hover:underline underline-offset-4 decoration-primary/30 text-left line-clamp-1 max-w-[150px]"
                      >
                        {tx.transactionCode || tx.id}
                      </button>
                    </td>
                    <td className="px-8 py-6">
                      <div className="flex items-center gap-2">
                        <span className="font-black text-slate-900 uppercase">
                          #{tx.order?.orderNumber || (tx.orderId && tx.orderId.substring(0, 8).toUpperCase()) || 'N/A'}
                        </span>
                      </div>
                    </td>
                    <td className="px-8 py-6">
                       <span className="font-bold text-slate-600">{getPaymentMethodLabel(tx.paymentMethod, tx.provider)}</span>
                    </td>
                    <td className="px-8 py-6">
                      <span className="font-black text-slate-900 tracking-tight">
                        {new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(tx.amount || 0)}
                      </span>
                    </td>
                    <td className="px-8 py-6">
                      {getStatusBadge(tx.status)}
                    </td>
                    <td className="px-8 py-6">
                      <div className="flex flex-col">
                        <span className="text-xs font-bold text-slate-800 flex items-center gap-1.5">
                          <Calendar size={12} className="text-slate-400" />
                          {new Date(tx.createdAt).toLocaleDateString('vi-VN')}
                        </span>
                        <span className="text-[10px] font-bold text-slate-400 flex items-center gap-1.5 mt-1">
                          <Clock size={12} />
                          {new Date(tx.createdAt).toLocaleTimeString('vi-VN')}
                        </span>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={6} className="px-8 py-20 text-center">
                    <div className="flex flex-col items-center gap-4">
                        <div className="w-20 h-20 bg-slate-50 rounded-[32px] flex items-center justify-center text-slate-200">
                             <CreditCard size={40} />
                        </div>
                        <div>
                             <p className="text-slate-800 text-lg font-black tracking-tight underline-offset-4 decoration-primary/30">Chưa có giao dịch nào.</p>
                             <p className="text-slate-400 font-bold text-sm">Hãy thử thay đổi tiêu chí tìm kiếm.</p>
                        </div>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {meta.lastPage > 1 && (
          <div className="px-10 py-6 border-t border-slate-100 bg-slate-50/10 flex items-center justify-between">
            <p className="text-xs font-black text-slate-400 uppercase tracking-[0.2em]">Trang {page} / {meta.lastPage}</p>
            <div className="flex gap-2">
              <Button 
                  variant="outline" 
                  size="sm" 
                  disabled={page === 1} 
                  onClick={() => setPage(page - 1)}
                  className="rounded-xl px-6 font-bold"
              >
                Trước
              </Button>
              <Button 
                  variant="outline" 
                  size="sm" 
                  disabled={page === meta.lastPage} 
                  onClick={() => setPage(page + 1)}
                  className="rounded-xl px-6 font-bold"
              >
                Sau
              </Button>
            </div>
          </div>
        )}
      </div>

      {isError && (
        <div className="p-6 bg-red-50 border border-red-100 rounded-[32px] flex items-center gap-4 text-red-600 shadow-xl shadow-red-100/50">
          <AlertCircle className="w-6 h-6 flex-shrink-0" />
          <p className="text-sm font-black uppercase tracking-tight">Lỗi nạp dữ liệu giao dịch. Vui lòng kiểm tra lại server.</p>
        </div>
      )}
      {/* Transaction Detail Drawer */}
      <Drawer 
        isOpen={!!selectedTx} 
        onClose={() => setSelectedTx(null)} 
        title="Thông tin chi tiết"
      >
        {selectedTx && (
          <div className="space-y-8 animate-in slide-in-from-right duration-500">
            {/* Payment Summary Card */}
            <div className="p-6 rounded-[24px] bg-primary/5 border border-primary/10 space-y-4">
               <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2 px-3 py-1 bg-white border border-primary/20 rounded-full">
                     <DollarSign size={14} className="text-primary" />
                     <span className="text-[10px] font-black uppercase text-primary tracking-widest leading-none">Tổng thanh toán</span>
                  </div>
                  {getStatusBadge(selectedTx.status)}
               </div>
               <div className="text-4xl font-black text-slate-900 tracking-tight">
                  {new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(selectedTx.amount || 0)}
               </div>
            </div>

            {/* Main Info Blocks */}
            <div className="grid grid-cols-1 gap-6">
               {/* Transaction Basic Info */}
               <div className="space-y-5">
                  <h4 className="flex items-center gap-2 text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] mb-4">
                     <FileText size={14} className="text-slate-300" /> Chi tiết giao dịch
                  </h4>
                  <div className="space-y-4 bg-slate-50/50 p-5 rounded-3xl border border-slate-100">
                     <div className="flex flex-col gap-1">
                        <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Nội dung</span>
                        <p className="font-bold text-slate-800 leading-relaxed italic">"{selectedTx.description || 'Không có nội dung'}"</p>
                     </div>
                     <div className="grid grid-cols-2 gap-4">
                        <div className="flex flex-col gap-1">
                           <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Mã giao dịch</span>
                           <p className="font-mono text-xs font-bold text-slate-900 bg-white px-2 py-1 border border-slate-100 rounded-lg break-all">{selectedTx.transactionCode || selectedTx.id}</p>
                        </div>
                        <div className="flex flex-col gap-1">
                           <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Thời gian</span>
                           <p className="font-bold text-slate-900 text-sm">{new Date(selectedTx.createdAt).toLocaleString('vi-VN')}</p>
                        </div>
                     </div>
                     <div className="flex flex-col gap-1 pt-2">
                        <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Phương thức</span>
                        <div className="flex items-center gap-2">
                           <div className="w-8 h-8 bg-white border border-slate-100 rounded-xl flex items-center justify-center text-slate-400">
                              <Briefcase size={16} />
                           </div>
                           <p className="font-bold text-slate-900">{getPaymentMethodLabel(selectedTx.paymentMethod, selectedTx.provider)}</p>
                        </div>
                     </div>
                  </div>
               </div>

               {/* Recipient info */}
               <div className="space-y-5">
                  <h4 className="flex items-center gap-2 text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] mb-4">
                     <User size={14} className="text-slate-300" /> Thông tin khách hàng
                  </h4>
                  <div className="space-y-5 bg-white p-5 rounded-3xl border border-slate-100 shadow-sm">
                     <div className="flex items-start gap-4">
                        <div className="w-10 h-10 rounded-2xl bg-slate-50 border border-slate-100 flex items-center justify-center text-slate-400">
                           <User size={18} />
                        </div>
                        <div className="flex-1">
                           <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Người nhận</span>
                           <p className="font-black text-slate-900 text-lg">{selectedTx.order?.receiverName || 'N/A'}</p>
                        </div>
                     </div>
                     
                     <div className="flex items-start gap-4">
                        <div className="w-10 h-10 rounded-2xl bg-slate-50 border border-slate-100 flex items-center justify-center text-slate-400">
                           <Phone size={18} />
                        </div>
                        <div className="flex-1">
                           <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Số điện thoại</span>
                           <p className="font-bold text-slate-900">{selectedTx.order?.receiverPhone || 'N/A'}</p>
                        </div>
                     </div>

                     <div className="flex items-start gap-4">
                        <div className="w-10 h-10 rounded-2xl bg-slate-50 border border-slate-100 flex items-center justify-center text-slate-400">
                           <ExternalLink size={18} />
                        </div>
                        <div className="flex-1">
                           <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Tài khoản đặt hàng</span>
                           <p className="font-bold text-slate-900 italic underline underline-offset-4 decoration-primary/20">{selectedTx.order?.user?.email || 'Guest'}</p>
                        </div>
                     </div>

                     <div className="flex items-start gap-4">
                        <div className="w-10 h-10 rounded-2xl bg-slate-50 border border-slate-100 flex items-center justify-center text-slate-400">
                           <MapPin size={18} />
                        </div>
                        <div className="flex-1">
                           <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Địa chỉ giao hàng</span>
                           <p className="text-sm font-bold text-slate-800 leading-relaxed mt-1">{selectedTx.order?.shippingAddress || 'N/A'}</p>
                        </div>
                     </div>
                  </div>
               </div>

               {/* Products List */}
               <div className="space-y-5">
                  <h4 className="flex items-center gap-2 text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] mb-4">
                     <ShoppingBag size={14} className="text-slate-300" /> Sản phẩm ({selectedTx.order?.items?.length || 0})
                  </h4>
                  <div className="overflow-hidden border border-slate-100 rounded-3xl">
                     <table className="w-full text-left text-sm border-collapse">
                        <thead className="bg-slate-50/50">
                           <tr>
                              <th className="px-5 py-3 text-[9px] font-black text-slate-400 uppercase tracking-widest border-b border-slate-100">Sản phẩm</th>
                              <th className="px-5 py-3 text-[9px] font-black text-slate-400 uppercase tracking-widest border-b border-slate-100 text-right">Thành tiền</th>
                           </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-50">
                           {selectedTx.order?.items?.map((item: any, idx: number) => (
                              <tr key={idx} className="bg-white">
                                 <td className="px-5 py-4">
                                    <div className="flex flex-col gap-1">
                                       <span className="font-black text-slate-900 leading-tight">{item.productName}</span>
                                       <div className="flex items-center gap-2 mt-1">
                                          <span className="px-2 py-0.5 bg-slate-100 rounded-md text-[10px] font-bold text-slate-600">
                                             {item.variantName}
                                          </span>
                                          <span className="text-slate-400 text-xs font-bold">x {item.quantity}</span>
                                       </div>
                                    </div>
                                 </td>
                                 <td className="px-5 py-4 text-right">
                                    <span className="font-black text-slate-900 tracking-tight">
                                       {new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(Number(item.priceAtPurchase || 0) * item.quantity)}
                                    </span>
                                 </td>
                              </tr>
                           ))}
                           {!selectedTx.order?.items?.length && (
                              <tr>
                                 <td colSpan={2} className="px-5 py-10 text-center text-slate-400 italic">Không có dữ liệu sản phẩm</td>
                              </tr>
                           )}
                        </tbody>
                     </table>
                  </div>
               </div>

               {/* Note */}
               <div className="space-y-4">
                  <h4 className="flex items-center gap-2 text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] mb-4">
                     <NotebookText size={14} className="text-slate-300" /> Ghi chú đơn hàng
                  </h4>
                  <div className="p-5 rounded-3xl bg-amber-50/30 border border-amber-100 text-amber-900/70 italic text-sm font-bold leading-relaxed">
                     {selectedTx.order?.note || 'Không có ghi chú của khách hàng.'}
                  </div>
               </div>
            </div>

            <div className="pt-6 pb-2">
              <Button 
                variant="outline"
                className="w-full h-12 rounded-2xl font-black uppercase tracking-[0.2em] text-xs border-slate-200 hover:bg-slate-50 hover:text-slate-900 transition-all shadow-sm"
                onClick={() => setSelectedTx(null)}
              >
                Đóng thông tin
              </Button>
            </div>
          </div>
        )}
      </Drawer>
    </div>
  );
};

export default TransactionList;
