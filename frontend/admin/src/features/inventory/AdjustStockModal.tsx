import React, { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { X, ArrowUp, ArrowDown, Package, AlertCircle } from 'lucide-react';
import { inventoryService, type InventoryVariant, type AdjustStockPayload } from '../../services/inventory.service';
import { cn } from '../../utils/cn';
import { toast } from 'sonner';

interface Props {
  variant: InventoryVariant & { productName: string };
  onClose: () => void;
  onSuccess: () => void;
}

const typeOptions = [
  { value: 'IMPORT', label: 'Nhập thêm hàng', icon: ArrowUp, color: 'text-emerald-600 bg-emerald-50 border-emerald-200' },
  { value: 'DAMAGED', label: 'Hàng lỗi / Hư hỏng', icon: ArrowDown, color: 'text-red-600 bg-red-50 border-red-200' },
  { value: 'ADJUSTMENT', label: 'Điều chỉnh kiểm kê', icon: Package, color: 'text-blue-600 bg-blue-50 border-blue-200' },
  { value: 'RETURN', label: 'Hoàn trả hàng', icon: ArrowUp, color: 'text-amber-600 bg-amber-50 border-amber-200' },
] as const;

export const AdjustStockModal: React.FC<Props> = ({ variant, onClose, onSuccess }) => {
  const [type, setType] = useState<AdjustStockPayload['type']>('IMPORT');
  const [quantity, setQuantity] = useState<number>(0);
  const [reason, setReason] = useState('');
  const [mode, setMode] = useState<'INCREASE' | 'DECREASE'>('INCREASE');

  const isDeduct = type === 'DAMAGED' || (type === 'ADJUSTMENT' && mode === 'DECREASE');
  const afterStock = isDeduct ? variant.currentStock - quantity : variant.currentStock + quantity;
  const isValid = quantity > 0 && afterStock >= 0 && (['DAMAGED', 'ADJUSTMENT'].includes(type) ? reason.trim().length > 0 : true);

  const mutation = useMutation({
    mutationFn: () => {
      const payload: AdjustStockPayload = { type, quantity, reason: reason || undefined };
      if (type === 'ADJUSTMENT') payload.mode = mode;
      return inventoryService.adjustStock(variant.variantId, payload);
    },
    onSuccess: () => {
      toast.success('Điều chỉnh tồn kho thành công');
      onSuccess();
    },
    onError: (err: any) => {
      toast.error(err.response?.data?.message || 'Có lỗi xảy ra');
    },
  });

  return (
    <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-white rounded-3xl shadow-2xl w-full max-w-lg animate-in zoom-in-95 fade-in duration-200" onClick={e => e.stopPropagation()}>
        {/* Header */}
        <div className="flex items-center justify-between px-8 pt-8 pb-4">
          <div>
            <h2 className="text-xl font-black text-slate-900">Điều chỉnh tồn kho</h2>
            <p className="text-xs font-bold text-slate-400 mt-0.5">{variant.productName} · {variant.sku}</p>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-slate-100 rounded-xl transition-colors"><X className="w-5 h-5 text-slate-400" /></button>
        </div>

        <div className="px-8 pb-8 space-y-5">
          {/* Type Selection */}
          <div className="space-y-2">
            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Loại điều chỉnh</label>
            <div className="grid grid-cols-2 gap-2">
              {typeOptions.map(opt => (
                <button key={opt.value} onClick={() => setType(opt.value as AdjustStockPayload['type'])}
                  className={cn("flex items-center gap-2 px-4 py-3 rounded-xl border-2 text-xs font-bold transition-all", type === opt.value ? opt.color + ' border-current' : 'bg-white border-slate-200 text-slate-500 hover:border-slate-300')}>
                  <opt.icon className="w-4 h-4" />{opt.label}
                </button>
              ))}
            </div>
          </div>

          {/* Adjustment Mode */}
          {type === 'ADJUSTMENT' && (
            <div className="space-y-2">
              <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Hướng điều chỉnh</label>
              <div className="grid grid-cols-2 gap-2">
                <button onClick={() => setMode('INCREASE')} className={cn("px-4 py-2.5 rounded-xl border-2 text-xs font-bold transition-all", mode === 'INCREASE' ? 'bg-emerald-50 text-emerald-700 border-emerald-300' : 'border-slate-200 text-slate-500')}>
                  <ArrowUp className="w-3 h-3 inline mr-1" />Tăng
                </button>
                <button onClick={() => setMode('DECREASE')} className={cn("px-4 py-2.5 rounded-xl border-2 text-xs font-bold transition-all", mode === 'DECREASE' ? 'bg-red-50 text-red-700 border-red-300' : 'border-slate-200 text-slate-500')}>
                  <ArrowDown className="w-3 h-3 inline mr-1" />Giảm
                </button>
              </div>
            </div>
          )}

          {/* Quantity */}
          <div className="space-y-2">
            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Số lượng</label>
            <input type="number" min={1} value={quantity || ''} onChange={e => setQuantity(parseInt(e.target.value) || 0)}
              className="w-full h-12 px-4 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:border-primary focus:ring-4 focus:ring-primary/5 font-bold text-slate-700 text-lg transition-all" placeholder="Nhập số lượng" />
          </div>

          {/* Reason */}
          <div className="space-y-2">
            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
              Lý do {['DAMAGED', 'ADJUSTMENT'].includes(type) && <span className="text-red-500">*</span>}
            </label>
            <textarea value={reason} onChange={e => setReason(e.target.value)} rows={2}
              className="w-full p-4 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:border-primary focus:ring-4 focus:ring-primary/5 font-bold text-slate-700 text-xs resize-none transition-all" placeholder="Ghi chú lý do điều chỉnh..." />
          </div>

          {/* Preview */}
          <div className="bg-slate-50 rounded-2xl p-5 border border-slate-100">
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-3">Xem trước thay đổi</p>
            <div className="flex items-center justify-between">
              <div className="text-center">
                <p className="text-[10px] font-bold text-slate-400 uppercase">Trước</p>
                <p className="text-2xl font-black text-slate-700">{variant.currentStock}</p>
              </div>
              <div className="text-center px-4">
                <span className={cn("text-lg font-black", isDeduct ? 'text-red-500' : 'text-emerald-500')}>{isDeduct ? '-' : '+'}{quantity || 0}</span>
              </div>
              <div className="text-center">
                <p className="text-[10px] font-bold text-slate-400 uppercase">Sau</p>
                <p className={cn("text-2xl font-black", afterStock < 0 ? 'text-red-500' : 'text-emerald-600')}>{quantity > 0 ? afterStock : variant.currentStock}</p>
              </div>
            </div>
          </div>

          {afterStock < 0 && quantity > 0 && (
            <div className="flex items-center gap-2 p-3 bg-red-50 rounded-xl border border-red-100">
              <AlertCircle className="w-4 h-4 text-red-500 flex-shrink-0" />
              <p className="text-xs font-bold text-red-600">Tồn kho không thể âm. Vui lòng giảm số lượng.</p>
            </div>
          )}

          {/* Submit */}
          <button onClick={() => mutation.mutate()} disabled={!isValid || mutation.isPending}
            className={cn("w-full py-3.5 rounded-2xl font-black text-sm uppercase tracking-wider transition-all", isValid && !mutation.isPending ? 'bg-primary text-white hover:bg-primary/90 shadow-lg shadow-primary/20 active:scale-[0.98]' : 'bg-slate-100 text-slate-400 cursor-not-allowed')}>
            {mutation.isPending ? 'Đang xử lý...' : 'Xác nhận điều chỉnh'}
          </button>
        </div>
      </div>
    </div>
  );
};
