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
  AlertCircle
} from 'lucide-react';
import { transactionService } from '../../services/transaction.service';
import { cn } from '../../utils/cn';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Card, CardContent } from '../../components/ui/Card';
import { Link } from 'react-router-dom';

export const TransactionList: React.FC = () => {
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ['transactions', search, page],
    queryFn: () => transactionService.getAllTransactions({ search, page, limit: 10 }),
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

  const getPaymentMethodLabel = (method: string) => {
    switch (method) {
      case 'PAYMENT_GATEWAY': return 'Cổng thanh toán (VNPay)';
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
          <div className="flex flex-col md:flex-row gap-4 items-center">
            <div className="relative flex-1 w-full group">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-primary transition-colors" />
              <Input
                placeholder="Tìm kiếm theo mã GD hoặc mã đơn hàng..."
                className="pl-11 py-2.5 h-11 border-slate-200 focus:border-primary transition-all rounded-2xl"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
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
                      <span className="font-mono text-xs font-bold text-slate-500 line-clamp-1 max-w-[150px]">
                        {tx.transactionCode || tx.id}
                      </span>
                    </td>
                    <td className="px-8 py-6">
                      <Link 
                        to={`/orders?search=${tx.orderId}`}
                        className="inline-flex items-center gap-2 group/link"
                      >
                        <span className="font-black text-slate-900 group-hover/link:text-primary transition-colors underline decoration-dotted decoration-slate-300 underline-offset-4">
                          #{tx.orderId.slice(-8).toUpperCase()}
                        </span>
                        <ExternalLink size={12} className="text-slate-300 group-hover/link:text-primary transition-colors" />
                      </Link>
                    </td>
                    <td className="px-8 py-6">
                       <span className="font-bold text-slate-600">{getPaymentMethodLabel(tx.paymentMethod)}</span>
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
    </div>
  );
};

export default TransactionList;
