import React, { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { X, ArrowUp, ArrowDown, Package, AlertCircle } from '../../components/ui/IconlyIcons';
import { toast } from 'sonner';
import { inventoryService, type InventoryVariant, type AdjustStockPayload } from '../../services/inventory.service';
import { cn } from '../../utils/cn';

interface Props {
  variant: InventoryVariant & { productName: string };
  onClose: () => void;
  onSuccess: () => void;
}

const typeOptions = [
  { value: 'IMPORT', label: 'Nhập thêm hàng', icon: ArrowUp },
  { value: 'DAMAGED', label: 'Hàng lỗi / Hư hỏng', icon: ArrowDown },
  { value: 'ADJUSTMENT', label: 'Điều chỉnh kiểm kê', icon: Package },
  { value: 'RETURN', label: 'Hoàn trả hàng', icon: ArrowUp },
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
    <div className="fixed inset-0 bg-slate-900/45 backdrop-blur-[2px] z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-white rounded-[14px] shadow-[0_18px_45px_rgba(15,23,42,0.18)] border border-slate-200 w-full max-w-xl animate-in zoom-in-95 fade-in duration-200" onClick={(event) => event.stopPropagation()}>
        <div className="flex items-start justify-between gap-4 px-6 py-5 border-b border-slate-100">
          <div>
            <p className="text-[11px] font-extrabold uppercase tracking-wider text-slate-400">Inventory Control</p>
            <h2 className="text-xl font-extrabold text-[#25396f] mt-1">Điều chỉnh tồn kho</h2>
            <p className="text-sm font-semibold text-slate-500 mt-1">{variant.productName} · {variant.sku}</p>
          </div>
          <button type="button" onClick={onClose} className="h-9 w-9 inline-flex items-center justify-center hover:bg-slate-100 rounded-[8px] transition-colors">
            <X className="w-5 h-5 text-slate-400" />
          </button>
        </div>

        <div className="px-6 py-5 space-y-5">
          <div className="grid grid-cols-3 rounded-[12px] border border-slate-200 bg-slate-50 overflow-hidden">
            <div className="px-4 py-3 bg-white border-r border-slate-200">
              <p className="text-[10px] font-black uppercase text-slate-400 mb-1">Hiện tại</p>
              <p className="text-2xl font-black text-[#25396f]">{variant.currentStock}</p>
            </div>
            <div className="px-4 py-3 bg-white border-r border-slate-200">
              <p className="text-[10px] font-black uppercase text-slate-400 mb-1">Thay đổi</p>
              <p className="text-2xl font-black text-[#25396f]">{isDeduct ? '-' : '+'}{quantity || 0}</p>
            </div>
            <div className="px-4 py-3 bg-white">
              <p className="text-[10px] font-black uppercase text-slate-400 mb-1">Sau điều chỉnh</p>
              <p className={cn('text-2xl font-black', afterStock < 0 ? 'text-red-600' : 'text-[#25396f]')}>
                {quantity > 0 ? afterStock : variant.currentStock}
              </p>
            </div>
          </div>

          <div className="space-y-2">
            <label className="text-[11px] font-black text-slate-500 uppercase tracking-wider">Loại điều chỉnh</label>
            <div className="grid grid-cols-2 gap-2">
              {typeOptions.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => setType(option.value as AdjustStockPayload['type'])}
                  className={cn(
                    'flex items-center gap-2 px-4 py-3 rounded-[10px] border text-xs font-extrabold transition-all text-left',
                    type === option.value
                      ? 'bg-[#f2f7ff] border-primary text-[#25396f] shadow-sm'
                      : 'bg-white border-slate-200 text-slate-600 hover:border-slate-300 hover:bg-slate-50',
                  )}
                >
                  <option.icon className="w-4 h-4 text-primary" />
                  {option.label}
                </button>
              ))}
            </div>
          </div>

          {type === 'ADJUSTMENT' && (
            <div className="space-y-2">
              <label className="text-[11px] font-black text-slate-500 uppercase tracking-wider">Hướng điều chỉnh</label>
              <div className="grid grid-cols-2 gap-2">
                <button type="button" onClick={() => setMode('INCREASE')} className={cn('px-4 py-2.5 rounded-[10px] border text-xs font-extrabold transition-all', mode === 'INCREASE' ? 'bg-[#f2f7ff] text-[#25396f] border-primary' : 'border-slate-200 text-slate-500 bg-white hover:bg-slate-50')}>
                  <ArrowUp className="w-3 h-3 inline mr-1" />Tăng
                </button>
                <button type="button" onClick={() => setMode('DECREASE')} className={cn('px-4 py-2.5 rounded-[10px] border text-xs font-extrabold transition-all', mode === 'DECREASE' ? 'bg-[#f2f7ff] text-[#25396f] border-primary' : 'border-slate-200 text-slate-500 bg-white hover:bg-slate-50')}>
                  <ArrowDown className="w-3 h-3 inline mr-1" />Giảm
                </button>
              </div>
            </div>
          )}

          <div className="space-y-2">
            <label className="text-[11px] font-black text-slate-500 uppercase tracking-wider">Số lượng</label>
            <input
              type="number"
              min={1}
              value={quantity || ''}
              onChange={(event) => setQuantity(parseInt(event.target.value) || 0)}
              className="w-full h-12 px-4 bg-white border border-slate-200 rounded-[10px] outline-none focus:border-primary focus:ring-4 focus:ring-primary/5 font-bold text-[#25396f] text-lg transition-all"
              placeholder="Nhập số lượng"
            />
          </div>

          <div className="space-y-2">
            <label className="text-[11px] font-black text-slate-500 uppercase tracking-wider">
              Lý do {['DAMAGED', 'ADJUSTMENT'].includes(type) && <span className="text-red-500">*</span>}
            </label>
            <textarea
              value={reason}
              onChange={(event) => setReason(event.target.value)}
              rows={2}
              className="w-full p-4 bg-white border border-slate-200 rounded-[10px] outline-none focus:border-primary focus:ring-4 focus:ring-primary/5 font-bold text-[#25396f] text-xs resize-none transition-all"
              placeholder="Ghi chú lý do điều chỉnh..."
            />
          </div>

          {afterStock < 0 && quantity > 0 && (
            <div className="flex items-center gap-2 p-3 bg-red-50 rounded-[10px] border border-red-100">
              <AlertCircle className="w-4 h-4 text-red-500 flex-shrink-0" />
              <p className="text-xs font-bold text-red-600">Tồn kho không thể âm. Vui lòng giảm số lượng.</p>
            </div>
          )}

          <div className="flex flex-col-reverse sm:flex-row gap-3 pt-1">
            <button type="button" onClick={onClose} className="flex-1 h-11 rounded-[8px] border border-slate-200 bg-white text-sm font-extrabold text-slate-600 hover:bg-slate-50 transition-all">
              Hủy
            </button>
            <button
              type="button"
              onClick={() => mutation.mutate()}
              disabled={!isValid || mutation.isPending}
              className={cn(
                'flex-1 h-11 rounded-[8px] font-extrabold text-sm transition-all',
                isValid && !mutation.isPending ? 'bg-primary text-white hover:bg-primary/90 shadow-sm active:scale-[0.98]' : 'bg-slate-100 text-slate-400 cursor-not-allowed',
              )}
            >
              {mutation.isPending ? 'Đang xử lý...' : 'Xác nhận điều chỉnh'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
