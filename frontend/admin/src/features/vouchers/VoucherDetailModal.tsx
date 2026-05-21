import React from 'react';
import { X, CalendarDays, Tag, ShoppingBag, Clock, Activity, CheckCircle2, EyeOff } from 'lucide-react';
import { Badge } from '../../components/ui/Badge';
import { VoucherType } from '../../types';
import type { Voucher } from '../../types';

interface VoucherDetailModalProps {
  voucher: Voucher;
  onClose: () => void;
}

export const VoucherDetailModal: React.FC<VoucherDetailModalProps> = ({ voucher, onClose }) => {
  const formatCurrency = (val: number) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);
  const formatDate = (dateStr?: string) => {
    if (!dateStr) return 'Không giới hạn';
    return new Date(dateStr).toLocaleString('vi-VN', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit', year: 'numeric' });
  };

  const getStatusInfo = (v: Voucher) => {
    const now = new Date();
    if (!v.isActive) return { label: 'Tạm ngưng', variant: 'danger' as const, icon: EyeOff };
    if (v.expiresAt && new Date(v.expiresAt) < now) return { label: 'Đã hết hạn', variant: 'warning' as const, icon: Clock };
    if (v.startsAt && new Date(v.startsAt) > now) return { label: 'Sắp tới', variant: 'info' as const, icon: CalendarDays };
    if (v.claimedCount >= v.quantity) return { label: 'Hết lượt claim', variant: 'warning' as const, icon: ShoppingBag };
    return { label: 'Đang hoạt động', variant: 'success' as const, icon: CheckCircle2 };
  };

  const statusInfo = getStatusInfo(voucher);
  const remaining = Math.max(0, voucher.quantity - voucher.claimedCount);
  const claimRate = voucher.quantity > 0 ? (voucher.claimedCount / voucher.quantity) * 100 : 0;
  const usageRate = voucher.claimedCount > 0 ? (voucher.usedCount / voucher.claimedCount) * 100 : 0;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-xl animate-in fade-in duration-300">
      <div className="bg-white w-full max-w-3xl rounded-[48px] shadow-2xl overflow-hidden animate-in zoom-in-95 duration-300 border border-white flex flex-col max-h-[90vh]">
        <div className="p-8 border-b border-slate-50 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-primary/10 rounded-2xl flex items-center justify-center">
              <Tag className="text-primary w-6 h-6" />
            </div>
            <div>
              <h2 className="text-2xl font-black text-slate-900 font-heading tracking-tighter uppercase">{voucher.code}</h2>
              <p className="text-sm font-bold text-slate-400">{voucher.name}</p>
            </div>
          </div>
          <button onClick={onClose} className="p-3 rounded-full hover:bg-slate-50 transition-all border border-transparent hover:border-slate-100">
            <X className="w-7 h-7 text-slate-400" />
          </button>
        </div>
        
        <div className="flex-1 overflow-y-auto custom-scrollbar p-8 space-y-8">
          <div className="flex justify-between items-center bg-slate-50 p-6 rounded-3xl">
            <div>
              <Badge variant={statusInfo.variant} className="gap-1.5 px-4 h-8 rounded-full font-black uppercase text-[10px] tracking-widest">
                <statusInfo.icon className="w-3.5 h-3.5" />
                {statusInfo.label}
              </Badge>
              {remaining === 0 && <p className="text-red-500 text-xs font-bold mt-2">Đã hết lượt claim!</p>}
            </div>
            <div className="text-right">
              <p className="text-sm font-bold text-slate-400 uppercase tracking-widest mb-1">Mức giảm</p>
              <p className="text-3xl font-black text-primary">
                {voucher.type === VoucherType.PERCENT ? `${voucher.value}%` : formatCurrency(voucher.value)}
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <h3 className="text-sm font-black text-slate-900 uppercase tracking-widest flex items-center gap-2">
                <Activity className="w-4 h-4 text-slate-400" />
                Thông tin cơ bản
              </h3>
              <div className="bg-white border border-slate-100 rounded-3xl p-5 space-y-4 shadow-sm">
                <div className="flex justify-between items-center">
                  <span className="text-xs font-bold text-slate-500 uppercase">Đơn tối thiểu</span>
                  <span className="text-sm font-black text-slate-900">{formatCurrency(voucher.minOrderAmount)}</span>
                </div>
                {voucher.type === VoucherType.PERCENT && voucher.maxDiscountAmount && (
                  <div className="flex justify-between items-center">
                    <span className="text-xs font-bold text-slate-500 uppercase">Giảm tối đa</span>
                    <span className="text-sm font-black text-slate-900">{formatCurrency(voucher.maxDiscountAmount)}</span>
                  </div>
                )}
                <div className="flex justify-between items-center">
                  <span className="text-xs font-bold text-slate-500 uppercase">Bắt đầu</span>
                  <span className="text-sm font-black text-slate-900">{formatDate(voucher.startsAt)}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs font-bold text-slate-500 uppercase">Kết thúc</span>
                  <span className="text-sm font-black text-slate-900">{formatDate(voucher.expiresAt)}</span>
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <h3 className="text-sm font-black text-slate-900 uppercase tracking-widest flex items-center gap-2">
                <Activity className="w-4 h-4 text-slate-400" />
                Thống kê sử dụng
              </h3>
              <div className="bg-white border border-slate-100 rounded-3xl p-5 space-y-5 shadow-sm">
                <div className="flex justify-between items-center">
                  <span className="text-xs font-bold text-slate-500 uppercase">Tổng số lượng</span>
                  <span className="text-sm font-black text-slate-900">{voucher.quantity}</span>
                </div>
                
                <div>
                  <div className="flex justify-between items-center mb-2">
                    <span className="text-xs font-bold text-slate-500 uppercase">Đã thu thập (Claimed)</span>
                    <span className="text-sm font-black text-slate-900">{voucher.claimedCount} / {voucher.quantity}</span>
                  </div>
                  <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden">
                    <div className="bg-blue-500 h-full transition-all" style={{ width: `${Math.min(100, claimRate)}%` }} />
                  </div>
                </div>

                <div>
                  <div className="flex justify-between items-center mb-2">
                    <span className="text-xs font-bold text-slate-500 uppercase">Đã sử dụng / Đã thu thập</span>
                    <span className="text-sm font-black text-slate-900">{voucher.usedCount} / {voucher.claimedCount}</span>
                  </div>
                  <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden">
                    <div className="bg-green-500 h-full transition-all" style={{ width: `${Math.min(100, usageRate)}%` }} />
                  </div>
                </div>
                
                <div className="flex justify-between items-center pt-2 border-t border-slate-50">
                  <span className="text-xs font-bold text-slate-500 uppercase">Còn lại</span>
                  <span className="text-lg font-black text-slate-900">{remaining}</span>
                </div>
              </div>
            </div>
          </div>
          
          {voucher.description && (
             <div className="space-y-2">
               <h3 className="text-sm font-black text-slate-900 uppercase tracking-widest">Mô tả</h3>
               <p className="text-sm font-medium text-slate-600 bg-slate-50 p-4 rounded-2xl">{voucher.description}</p>
             </div>
          )}
        </div>
      </div>
    </div>
  );
};
