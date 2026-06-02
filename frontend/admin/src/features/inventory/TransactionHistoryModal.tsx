import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { X, ArrowUp, ArrowDown, Package, User, Calendar, Hash, History } from '../../components/ui/IconlyIcons';
import { inventoryService, type InventoryTransaction } from '../../services/inventory.service';
import { cn } from '../../utils/cn';

interface Props {
  variantId: string;
  variantName: string;
  onClose: () => void;
}

const typeConfig: Record<string, { label: string; icon: typeof ArrowUp }> = {
  INITIAL_IMPORT: { label: 'Khởi tạo', icon: Package },
  IMPORT: { label: 'Nhập hàng', icon: ArrowUp },
  SALE: { label: 'Bán hàng', icon: ArrowDown },
  ORDER_CANCEL: { label: 'Hủy đơn', icon: ArrowUp },
  RETURN: { label: 'Hoàn trả', icon: ArrowUp },
  DAMAGED: { label: 'Hư hỏng', icon: ArrowDown },
  ADJUSTMENT: { label: 'Điều chỉnh', icon: Package },
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
    <div className="fixed inset-0 bg-slate-900/45 backdrop-blur-[2px] z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-white rounded-[14px] shadow-[0_18px_45px_rgba(15,23,42,0.18)] border border-slate-200 w-full max-w-3xl max-h-[84vh] flex flex-col animate-in zoom-in-95 fade-in duration-200" onClick={(event) => event.stopPropagation()}>
        <div className="flex items-start justify-between gap-4 px-6 py-5 border-b border-slate-100 flex-shrink-0">
          <div>
            <p className="text-[11px] font-extrabold uppercase tracking-wider text-slate-400">Inventory Ledger</p>
            <h2 className="text-xl font-extrabold text-[#25396f] mt-1">Lịch sử tồn kho</h2>
            <p className="text-sm font-semibold text-slate-500 mt-1">{variantName}</p>
          </div>
          <button type="button" onClick={onClose} className="h-9 w-9 inline-flex items-center justify-center hover:bg-slate-100 rounded-[8px] transition-colors">
            <X className="w-5 h-5 text-slate-400" />
          </button>
        </div>

        <div className="px-6 py-4 border-b border-slate-100 flex-shrink-0">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div className="rounded-[10px] border border-slate-200 bg-white px-4 py-3">
              <p className="text-[10px] font-black uppercase text-slate-400 mb-1">Tồn hiện tại</p>
              <p className="text-2xl font-black text-[#25396f]">{currentStock}</p>
            </div>
            <div className="rounded-[10px] border border-slate-200 bg-white px-4 py-3">
              <p className="text-[10px] font-black uppercase text-slate-400 mb-1">Số giao dịch</p>
              <p className="text-2xl font-black text-[#25396f]">{meta.total}</p>
            </div>
            <div className="rounded-[10px] border border-slate-200 bg-white px-4 py-3">
              <p className="text-[10px] font-black uppercase text-slate-400 mb-1">Trang</p>
              <p className="text-2xl font-black text-[#25396f]">{meta.page}/{meta.lastPage}</p>
            </div>
          </div>
        </div>

        <div className="px-6 py-4 overflow-y-auto flex-1 custom-scrollbar">
          {isLoading ? (
            <div className="flex justify-center py-16">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
            </div>
          ) : transactions.length === 0 ? (
            <div className="text-center py-16 rounded-[12px] border border-dashed border-slate-200 bg-slate-50">
              <History className="w-10 h-10 text-slate-300 mx-auto mb-3" />
              <p className="font-extrabold text-[#25396f] text-sm">Chưa có lịch sử giao dịch</p>
              <p className="text-xs font-semibold text-slate-400 mt-1">Các lần nhập, bán hoặc điều chỉnh kho sẽ hiển thị tại đây.</p>
            </div>
          ) : (
            <div className="rounded-[12px] border border-slate-200 overflow-hidden">
              <div className="grid grid-cols-[1.35fr_120px_150px] gap-4 bg-slate-50 px-4 py-3 text-[10px] font-black uppercase tracking-wider text-slate-500">
                <span>Giao dịch</span>
                <span className="text-right">Biến động</span>
                <span>Thời gian</span>
              </div>
              <div className="divide-y divide-slate-100 bg-white">
                {transactions.map((transaction) => {
                  const config = typeConfig[transaction.type] || typeConfig.ADJUSTMENT;
                  const Icon = config.icon;
                  const delta = transaction.afterStock - transaction.beforeStock;

                  return (
                    <div key={transaction.id} className="grid grid-cols-1 md:grid-cols-[1.35fr_120px_150px] gap-3 md:gap-4 px-4 py-4 hover:bg-slate-50/70 transition-colors">
                      <div className="flex items-start gap-3 min-w-0">
                        <div className="h-9 w-9 rounded-[8px] border border-slate-200 bg-white inline-flex items-center justify-center shrink-0">
                          <Icon className="w-4 h-4 text-primary" />
                        </div>
                        <div className="min-w-0">
                          <div className="flex items-center gap-2 flex-wrap">
                            <span className="px-2 py-1 rounded-[6px] bg-[#f2f7ff] text-[10px] font-black uppercase text-[#25396f]">
                              {config.label}
                            </span>
                            <span className="text-[10px] font-bold text-slate-400">({transaction.beforeStock} → {transaction.afterStock})</span>
                          </div>
                          {transaction.reason && <p className="text-xs font-semibold text-slate-500 mt-1 truncate">{transaction.reason}</p>}
                          <div className="flex items-center gap-3 text-[10px] font-bold text-slate-400 mt-2 flex-wrap">
                            {transaction.createdBy && (
                              <span className="flex items-center gap-1 min-w-0">
                                <User className="w-3 h-3" />
                                <span className="truncate">{transaction.createdBy.profile?.fullName || transaction.createdBy.email}</span>
                              </span>
                            )}
                            {transaction.referenceId && (
                              <span className="flex items-center gap-1">
                                <Hash className="w-3 h-3" />
                                {transaction.referenceId.slice(0, 8)}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>

                      <div className="md:text-right">
                        <p className={cn('text-sm font-black', delta < 0 ? 'text-red-600' : 'text-[#25396f]')}>
                          {delta >= 0 ? '+' : ''}{delta}
                        </p>
                        <p className="text-[10px] font-bold text-slate-400">số lượng</p>
                      </div>

                      <div className="text-xs font-bold text-slate-500 flex md:block items-center gap-1">
                        <Calendar className="w-3 h-3 inline md:hidden" />
                        {new Date(transaction.createdAt).toLocaleString('vi-VN')}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        {meta.lastPage > 1 && (
          <div className="px-6 py-4 border-t border-slate-100 flex items-center justify-between flex-shrink-0">
            <p className="text-[11px] font-bold text-slate-500">Trang {meta.page}/{meta.lastPage}</p>
            <div className="flex gap-2">
              <button type="button" disabled={page <= 1} onClick={() => setPage((currentPage) => currentPage - 1)} className="h-9 px-3 text-[11px] font-extrabold rounded-[8px] border border-slate-200 bg-white text-slate-600 hover:bg-slate-50 disabled:opacity-40 disabled:pointer-events-none">
                Trước
              </button>
              <button type="button" disabled={page >= meta.lastPage} onClick={() => setPage((currentPage) => currentPage + 1)} className="h-9 px-3 text-[11px] font-extrabold rounded-[8px] border border-slate-200 bg-white text-slate-600 hover:bg-slate-50 disabled:opacity-40 disabled:pointer-events-none">
                Sau
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
