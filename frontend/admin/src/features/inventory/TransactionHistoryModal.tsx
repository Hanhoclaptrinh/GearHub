import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { X, ArrowUp, ArrowDown, Package, User, Calendar, Hash } from 'lucide-react';
import { inventoryService, type InventoryTransaction } from '../../services/inventory.service';
import { cn } from '../../utils/cn';

interface Props {
  variantId: string;
  variantName: string;
  onClose: () => void;
}

const typeConfig: Record<string, { label: string; color: string; icon: typeof ArrowUp }> = {
  INITIAL_IMPORT: { label: 'Khởi tạo', color: 'bg-blue-50 text-blue-700 border-blue-200', icon: Package },
  IMPORT: { label: 'Nhập hàng', color: 'bg-emerald-50 text-emerald-700 border-emerald-200', icon: ArrowUp },
  SALE: { label: 'Bán hàng', color: 'bg-orange-50 text-orange-700 border-orange-200', icon: ArrowDown },
  ORDER_CANCEL: { label: 'Hủy đơn', color: 'bg-amber-50 text-amber-700 border-amber-200', icon: ArrowUp },
  RETURN: { label: 'Hoàn trả', color: 'bg-teal-50 text-teal-700 border-teal-200', icon: ArrowUp },
  DAMAGED: { label: 'Hư hỏng', color: 'bg-red-50 text-red-700 border-red-200', icon: ArrowDown },
  ADJUSTMENT: { label: 'Điều chỉnh', color: 'bg-slate-100 text-slate-700 border-slate-200', icon: Package },
};

export const TransactionHistoryModal: React.FC<Props> = ({ variantId, variantName, onClose }) => {
  const [page, setPage] = useState(1);

  const { data, isLoading } = useQuery({
    queryKey: ['inventory-history', variantId, page],
    queryFn: () => inventoryService.getTransactionHistory(variantId, { page, limit: 15 }),
  });

  const transactions: InventoryTransaction[] = data?.data || [];
  const meta = data?.meta || { total: 0, page: 1, lastPage: 1 };
  const currentStock = data?.variant?.stock ?? '-';

  return (
    <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-white rounded-3xl shadow-2xl w-full max-w-2xl max-h-[80vh] flex flex-col animate-in zoom-in-95 fade-in duration-200" onClick={e => e.stopPropagation()}>
        {/* Header */}
        <div className="flex items-center justify-between px-8 pt-8 pb-4 flex-shrink-0">
          <div>
            <h2 className="text-xl font-black text-slate-900">Lịch sử tồn kho</h2>
            <p className="text-xs font-bold text-slate-400 mt-0.5">{variantName} · Tồn hiện tại: <span className="text-primary font-black">{currentStock}</span></p>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-slate-100 rounded-xl transition-colors"><X className="w-5 h-5 text-slate-400" /></button>
        </div>

        {/* Content */}
        <div className="px-8 pb-8 overflow-y-auto flex-1 space-y-3">
          {isLoading ? (
            <div className="flex justify-center py-12"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" /></div>
          ) : transactions.length === 0 ? (
            <div className="text-center py-12"><Package className="w-10 h-10 text-slate-300 mx-auto mb-2" /><p className="font-bold text-slate-400 text-sm">Chưa có lịch sử giao dịch</p></div>
          ) : (
            transactions.map(tx => {
              const config = typeConfig[tx.type] || typeConfig.ADJUSTMENT;
              const Icon = config.icon;
              const delta = tx.afterStock - tx.beforeStock;
              return (
                <div key={tx.id} className="flex items-start gap-4 p-4 bg-slate-50/50 rounded-2xl border border-slate-100 hover:bg-slate-50 transition-colors">
                  <div className={cn("p-2 rounded-xl border flex-shrink-0", config.color)}>
                    <Icon className="w-4 h-4" />
                  </div>
                  <div className="flex-1 min-w-0 space-y-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className={cn("px-2 py-0.5 rounded-full text-[10px] font-black uppercase border", config.color)}>{config.label}</span>
                      <span className={cn("text-sm font-black", delta >= 0 ? 'text-emerald-600' : 'text-red-500')}>{delta >= 0 ? '+' : ''}{delta}</span>
                      <span className="text-[10px] font-bold text-slate-400">({tx.beforeStock} → {tx.afterStock})</span>
                    </div>
                    {tx.reason && <p className="text-xs font-medium text-slate-500 truncate">{tx.reason}</p>}
                    <div className="flex items-center gap-3 text-[10px] font-bold text-slate-400">
                      {tx.createdBy && (
                        <span className="flex items-center gap-1"><User className="w-3 h-3" />{tx.createdBy.profile?.fullName || tx.createdBy.email}</span>
                      )}
                      <span className="flex items-center gap-1"><Calendar className="w-3 h-3" />{new Date(tx.createdAt).toLocaleString('vi-VN')}</span>
                      {tx.referenceId && <span className="flex items-center gap-1"><Hash className="w-3 h-3" />{tx.referenceId.slice(0, 8)}</span>}
                    </div>
                  </div>
                </div>
              );
            })
          )}

          {meta.lastPage > 1 && (
            <div className="flex items-center justify-between pt-2">
              <p className="text-[10px] font-bold text-slate-400">Trang {meta.page}/{meta.lastPage}</p>
              <div className="flex gap-2">
                <button disabled={page <= 1} onClick={() => setPage(p => p - 1)} className="px-3 py-1.5 text-[10px] font-bold rounded-lg border border-slate-200 disabled:opacity-40">Trước</button>
                <button disabled={page >= meta.lastPage} onClick={() => setPage(p => p + 1)} className="px-3 py-1.5 text-[10px] font-bold rounded-lg border border-slate-200 disabled:opacity-40">Sau</button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
