import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Plus,
  Search,
  Trash2,
  Calendar,
  AlertCircle,
} from '../../components/ui/IconlyIcons';
import {
  Ticket as IconlyTicket,
  Activity as IconlyActivity,
  CloseSquare as IconlyCloseSquare,
} from 'react-iconly';
import { toast } from 'sonner';
import { flashSaleService } from '../../services/flash-sale.service';
import { authService } from '../../services/auth.service';
import { CreateFlashSaleModal } from '../../components/products/CreateFlashSaleModal';
import { BulkEditTimeModal } from '../../components/products/BulkEditTimeModal';
import { ConfirmModal } from '../../components/ui/ConfirmModal';
import { Badge } from '../../components/ui/Badge';
import { Button } from '../../components/ui/Button';
import { Card, CardContent } from '../../components/ui/Card';
import { cn } from '../../utils/cn';
import type { FlashSaleProduct } from '../../types';

export const FlashSaleList: React.FC = () => {
  const user = authService.getCurrentUser();
  const isAdmin = user?.role === 'ADMIN';

  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'upcoming' | 'expired'>('all');

  // Modal control
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isBulkTimeOpen, setIsBulkTimeOpen] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  const queryClient = useQueryClient();

  const { data, isLoading, isError } = useQuery({
    queryKey: ['admin-flash-sales', search, page],
    queryFn: () =>
      flashSaleService.getFlashSales({
        page,
        limit: 10,
        search: search || undefined,
      }),
  });

  const createBulkMutation = useMutation({
    mutationFn: flashSaleService.createFlashSaleBulk,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-flash-sales'] });
      toast.success('Đã thêm sản phẩm vào Flash Sale thành công!');
      setIsCreateOpen(false);
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Có lỗi xảy ra khi tạo Flash Sale');
    },
  });


  const updateBulkTimeMutation = useMutation({
    mutationFn: flashSaleService.updateTimeBulk,
    onSuccess: (res) => {
      queryClient.invalidateQueries({ queryKey: ['admin-flash-sales'] });
      toast.success(res.message || 'Cập nhật thời gian hàng loạt thành công!');
      setIsBulkTimeOpen(false);
      setSelectedIds([]);
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Có lỗi xảy ra khi sửa thời gian hàng loạt');
    },
  });

  const deleteMutation = useMutation({
    mutationFn: flashSaleService.deleteFlashSale,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-flash-sales'] });
      toast.success('Đã gỡ sản phẩm khỏi danh sách Flash Sale!');
      setDeletingId(null);
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Có lỗi xảy ra khi xóa Flash Sale');
    },
  });

  const allFlashSales: FlashSaleProduct[] = data?.data || [];
  const meta = data?.meta || { total: 0, lastPage: 1, limit: 10 };

  const getFlashSaleStatus = (item: FlashSaleProduct) => {
    const now = new Date();
    const starts = new Date(item.startsAt);
    const expires = new Date(item.expiresAt);

    if (now < starts) return 'upcoming';
    if (now > expires) return 'expired';
    return 'active';
  };

  const filteredData = allFlashSales.filter((item) => {
    if (statusFilter === 'all') return true;
    return getFlashSaleStatus(item) === statusFilter;
  });

  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
      maximumFractionDigits: 0,
    }).format(value);

  const formatDateTime = (isoString: string) => {
    return new Intl.DateTimeFormat('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(new Date(isoString));
  };

  const getStatusBadge = (status: 'active' | 'upcoming' | 'expired') => {
    const baseClass = 'rounded-[6px] border-none px-2.5 py-1 text-[10px] font-extrabold uppercase';
    if (status === 'active') {
      return (
        <Badge variant="success" className={cn(baseClass, 'bg-[#edf9f1] text-[#2f8f5b]')}>
          Đang diễn ra
        </Badge>
      );
    }
    if (status === 'upcoming') {
      return (
        <Badge variant="info" className={cn(baseClass, 'bg-primary/10 text-primary')}>
          Sắp diễn ra
        </Badge>
      );
    }
    return (
      <Badge variant="danger" className={cn(baseClass, 'bg-red-50 text-red-600')}>
        Đã kết thúc
      </Badge>
    );
  };

  const toggleSelect = (id: string) => {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]
    );
  };

  const toggleSelectAll = () => {
    if (selectedIds.length === filteredData.length) {
      setSelectedIds([]);
    } else {
      setSelectedIds(filteredData.map((item) => item.id));
    }
  };

  const handleBulkTimeSave = (times: { startsAt: string; expiresAt: string }) => {
    updateBulkTimeMutation.mutate({
      ids: selectedIds,
      ...times,
    });
  };

  // Stats calculation
  const totalCount = meta.total;
  const activeCount = allFlashSales.filter((x) => getFlashSaleStatus(x) === 'active').length;
  const upcomingCount = allFlashSales.filter((x) => getFlashSaleStatus(x) === 'upcoming').length;
  const expiredCount = allFlashSales.filter((x) => getFlashSaleStatus(x) === 'expired').length;

  const statCards = [
    {
      label: 'Tổng sản phẩm Sale',
      value: totalCount,
      icon: IconlyTicket,
      bgClass: 'bg-[#9694ff]',
      onClick: () => setStatusFilter('all'),
      active: statusFilter === 'all',
    },
    {
      label: 'Đang diễn ra',
      value: activeCount,
      icon: IconlyActivity,
      bgClass: 'bg-[#5ddc97]',
      onClick: () => setStatusFilter('active'),
      active: statusFilter === 'active',
    },
    {
      label: 'Sắp diễn ra',
      value: upcomingCount,
      icon: IconlyActivity, // replaced TimeCircle with IconlyActivity for quick fix
      bgClass: 'bg-[#57caeb]',
      onClick: () => setStatusFilter('upcoming'),
      active: statusFilter === 'upcoming',
    },
    {
      label: 'Đã kết thúc',
      value: expiredCount,
      icon: IconlyCloseSquare,
      bgClass: 'bg-[#ff7976]',
      onClick: () => setStatusFilter('expired'),
      active: statusFilter === 'expired',
    },
  ];

  return (
    <div className="space-y-6 pb-10 animate-in fade-in slide-in-from-bottom-3 duration-500">
      {/* Stats row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6">
        {statCards.map((stat) => {
          const Icon = stat.icon;
          return (
            <Card
              key={stat.label}
              onClick={stat.onClick}
              className={cn(
                'border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white transition-all duration-300 cursor-pointer group hover:scale-[1.02]',
                stat.active && 'ring-2 ring-primary'
              )}
            >
              <CardContent className="py-6 px-6 flex items-center gap-4">
                <div
                  className={cn(
                    'w-12 h-12 rounded-[10px] flex items-center justify-center transition-transform duration-300 group-hover:scale-105 shadow-xs shrink-0 text-white',
                    stat.bgClass
                  )}
                >
                  <Icon set="bold" primaryColor="white" size={24} />
                </div>
                <div className="flex-1 min-w-0">
                  <h6 className="text-[15px] font-semibold text-[#7c8db5] leading-tight mb-1 truncate">
                    {stat.label}
                  </h6>
                  <div className="text-[24px] font-extrabold text-[#25396f] leading-none font-heading truncate">
                    {stat.value}
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Main card */}
      <div className="bg-white rounded-[12px] shadow-[0_5px_15px_rgba(25,42,70,0.06)] border border-[#f2f7ff] overflow-hidden">
        {/* Header Actions */}
        <div className="px-5 py-5 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 border-b border-[#f2f7ff]">
          <div className="relative w-full lg:max-w-[360px]">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#a8b4c7]" />
            <input
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              placeholder="Tìm theo tên sản phẩm hoặc SKU..."
              className="w-full h-10 pl-11 pr-4 rounded-[5px] border border-[#dce7f1] bg-white text-sm font-semibold text-[#25396f] outline-none transition-all focus:border-primary focus:ring-4 focus:ring-primary/10"
            />
          </div>

          {isAdmin && (
            <div className="flex flex-wrap items-center gap-3">
              <Button
                type="button"
                variant="outline"
                onClick={() => setIsBulkTimeOpen(true)}
                disabled={selectedIds.length === 0}
                className="rounded-[6px] text-xs font-bold gap-2 border-slate-200"
              >
                <Calendar className="w-4 h-4" />
                Sửa giờ hàng loạt ({selectedIds.length})
              </Button>
              <Button
                type="button"
                onClick={() => setIsCreateOpen(true)}
                className="h-10 rounded-[6px] bg-primary px-4 text-sm font-extrabold text-white shadow-[0_5px_12px_rgba(67,94,190,0.18)] hover:bg-primary/90"
              >
                <Plus className="w-4 h-4 mr-2" />
                Tạo Flash Sale mới
              </Button>
            </div>
          )}
        </div>

        {/* Selected bar */}
        {isAdmin && selectedIds.length > 0 && (
          <div className="px-5 py-3 border-b border-[#f2f7ff] bg-primary/5 flex items-center justify-between">
            <span className="text-[12px] font-extrabold text-primary">
              Đã chọn {selectedIds.length} sản phẩm
            </span>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={() => setSelectedIds([])}
              className="text-xs font-bold text-slate-400 hover:text-slate-600"
            >
              Bỏ chọn tất cả
            </Button>
          </div>
        )}

        {/* Table list */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1100px]">
            <thead className="bg-[#f8faff] border-b border-[#f2f7ff]">
              <tr>
                {isAdmin && (
                  <th className="px-5 py-4 w-12">
                    <input
                      type="checkbox"
                      checked={
                        filteredData.length > 0 && selectedIds.length === filteredData.length
                      }
                      onChange={toggleSelectAll}
                      className="h-4 w-4 rounded border-[#dce7f1] text-primary focus:ring-primary"
                    />
                  </th>
                )}
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase">
                  Sản phẩm
                </th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase">
                  Giá gốc / Giá Sale
                </th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase">
                  Hạn mức / Đã bán
                </th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase">
                  Thời gian
                </th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase text-center">
                  Trạng thái
                </th>
                {isAdmin && (
                  <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase text-right">
                    Thao tác
                  </th>
                )}
              </tr>
            </thead>
            <tbody className="divide-y divide-[#f2f7ff] font-body">
              {isLoading ? (
                <tr>
                  <td colSpan={isAdmin ? 7 : 5} className="px-6 py-16 text-center">
                    <div className="inline-flex flex-col items-center gap-3">
                      <div className="w-8 h-8 rounded-full border-3 border-primary/20 border-t-primary animate-spin" />
                      <p className="text-xs font-bold text-slate-400">Đang tải dữ liệu...</p>
                    </div>
                  </td>
                </tr>
              ) : filteredData.length > 0 ? (
                filteredData.map((item) => {
                  const status = getFlashSaleStatus(item);
                  return (
                    <tr key={item.id} className="hover:bg-[#fbfcff] transition-colors group">
                      {isAdmin && (
                        <td className="px-5 py-4">
                          <input
                            type="checkbox"
                            checked={selectedIds.includes(item.id)}
                            onChange={() => toggleSelect(item.id)}
                            className="h-4 w-4 rounded border-[#dce7f1] text-primary focus:ring-primary"
                          />
                        </td>
                      )}
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-3">
                          <img
                            src={item.productVariant.product.thumbnailUrl || '/placeholder.png'}
                            alt={item.productVariant.product.name}
                            className="w-10 h-10 rounded-lg object-cover bg-slate-50 border border-slate-100 shrink-0"
                            onError={(e) => {
                              (e.target as HTMLImageElement).src =
                                'https://placehold.co/100x100?text=GearHub';
                            }}
                          />
                          <div className="min-w-0">
                            <p className="font-extrabold text-[#25396f] mb-0.5 truncate max-w-[280px]">
                              {item.productVariant.product.name}
                            </p>
                            <p className="font-mono text-[10px] font-extrabold text-[#7c8db5] bg-[#f2f7ff] px-2 py-0.5 rounded-[5px] inline-block">
                              {item.productVariant.sku}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td className="px-5 py-4">
                        <p className="text-xs text-slate-400 line-through">
                          {formatCurrency(Number(item.productVariant.price))}
                        </p>
                        <p className="font-extrabold text-[#f97316]">
                          {formatCurrency(Number(item.flashPrice))}
                        </p>
                      </td>
                      <td className="px-5 py-4">
                        <p className="font-extrabold text-[#25396f] mb-0.5">
                          Limit: {item.stockLimit}
                        </p>
                        <p className="text-xs text-slate-400 font-semibold">
                          Đã bán: {item.soldCount}
                        </p>
                      </td>
                      <td className="px-5 py-4">
                        <p className="text-xs text-[#25396f] font-bold">
                          Bắt đầu: {formatDateTime(item.startsAt)}
                        </p>
                        <p className="text-xs text-slate-400 font-semibold mt-0.5">
                          Kết thúc: {formatDateTime(item.expiresAt)}
                        </p>
                      </td>
                      <td className="px-5 py-4 text-center">{getStatusBadge(status)}</td>
                      {isAdmin && (
                        <td className="px-5 py-4 text-right">
                          <button
                            type="button"
                            onClick={() => setDeletingId(item.id)}
                            className="w-9 h-9 rounded-lg inline-flex items-center justify-center text-red-500 hover:bg-red-50 transition-colors"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </td>
                      )}
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={isAdmin ? 7 : 5} className="px-6 py-20 text-center">
                    <div className="mx-auto w-12 h-12 rounded-[12px] bg-[#f2f7ff] flex items-center justify-center mb-4 text-primary">
                      <IconlyTicket set="bold" size={24} />
                    </div>
                    <h6 className="text-[16px] font-extrabold text-[#25396f] mb-1">
                      Không có sản phẩm Flash Sale nào
                    </h6>
                    {isAdmin ? (
                      <p className="text-xs font-semibold text-[#7c8db5]">
                        Nhấp vào "Tạo Flash Sale mới" để thêm biến thể vào chương trình.
                      </p>
                    ) : (
                      <p className="text-xs font-semibold text-[#7c8db5]">
                        Vui lòng quay lại sau hoặc liên hệ Admin để tạo Flash Sale.
                      </p>
                    )}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Footer Pagination */}
        {meta.lastPage > 1 && (
          <div className="px-5 py-4 border-t border-[#dce7f1] bg-white flex items-center justify-between">
            <p className="text-xs font-semibold text-slate-400">
              Hiển thị {(page - 1) * meta.limit + (filteredData.length > 0 ? 1 : 0)} tới{' '}
              {(page - 1) * meta.limit + filteredData.length} của {meta.total} dòng
            </p>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="h-9 rounded-xl text-xs"
              >
                Trước
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage((p) => Math.min(meta.lastPage, p + 1))}
                disabled={page === meta.lastPage}
                className="h-9 rounded-xl text-xs"
              >
                Sau
              </Button>
            </div>
          </div>
        )}
      </div>

      {isError && (
        <div className="p-6 bg-red-50 border border-red-100 rounded-[12px] flex items-center gap-4 text-red-600 shadow-[0_5px_15px_rgba(25,42,70,0.04)]">
          <AlertCircle className="w-6 h-6" />
          <div>
            <p className="text-base font-extrabold text-red-700 mb-0">Không thể kết nối tới máy chủ</p>
            <p className="text-sm font-semibold opacity-80 mb-0">
              Vui lòng kiểm tra lại kết nối.
            </p>
          </div>
        </div>
      )}

      {/* Modals */}
      <CreateFlashSaleModal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        onSaveBulk={(input) => createBulkMutation.mutate(input)}
        isSaving={createBulkMutation.isPending}
      />


      <BulkEditTimeModal
        isOpen={isBulkTimeOpen}
        onClose={() => setIsBulkTimeOpen(false)}
        onSave={handleBulkTimeSave}
        isSaving={updateBulkTimeMutation.isPending}
        selectedCount={selectedIds.length}
      />

      <ConfirmModal
        isOpen={!!deletingId}
        onClose={() => setDeletingId(null)}
        onConfirm={() => deletingId && deleteMutation.mutate(deletingId)}
        title="Xác nhận xóa Flash Sale"
        message="Bạn có chắc chắn muốn gỡ sản phẩm này khỏi chương trình Flash Sale không? Hành động này không thể hoàn tác."
        confirmText="Xác nhận gỡ"
        cancelText="Hủy bỏ"
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
};
