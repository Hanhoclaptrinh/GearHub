import React from 'react';
import { Activity, CalendarDays, CheckCircle2, Clock, EyeOff, ReceiptText, ShoppingBag, Ticket, X } from '../../components/ui/IconlyIcons';
import { Badge } from '../../components/ui/Badge';
import { VoucherType } from '../../types';
import type { Voucher } from '../../types';

interface VoucherDetailModalProps {
  voucher: Voucher;
  onClose: () => void;
}

const formatCurrency = (value: number) =>
  new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(value || 0);

const formatDate = (dateStr?: string) => {
  if (!dateStr) return 'Không giới hạn';
  return new Date(dateStr).toLocaleString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
};

const getStatusInfo = (voucher: Voucher) => {
  const now = new Date();
  if (!voucher.isActive) return { label: 'Tạm ngưng', variant: 'danger' as const, icon: EyeOff, tone: 'bg-red-50 text-red-600' };
  if (voucher.expiresAt && new Date(voucher.expiresAt) < now) return { label: 'Đã hết hạn', variant: 'warning' as const, icon: Clock, tone: 'bg-[#fff7e6] text-[#946200]' };
  if (voucher.startsAt && new Date(voucher.startsAt) > now) return { label: 'Sắp tới', variant: 'info' as const, icon: CalendarDays, tone: 'bg-primary/10 text-primary' };
  if (voucher.claimedCount >= voucher.quantity) return { label: 'Hết lượt nhận', variant: 'warning' as const, icon: ShoppingBag, tone: 'bg-[#fff7e6] text-[#946200]' };
  return { label: 'Đang hoạt động', variant: 'success' as const, icon: CheckCircle2, tone: 'bg-[#edf9f1] text-[#2f8f5b]' };
};

export const VoucherDetailModal: React.FC<VoucherDetailModalProps> = ({ voucher, onClose }) => {
  const statusInfo = getStatusInfo(voucher);
  const StatusIcon = statusInfo.icon;
  const remaining = Math.max(0, voucher.quantity - voucher.claimedCount);
  const claimRate = voucher.quantity > 0 ? Math.round((voucher.claimedCount / voucher.quantity) * 100) : 0;
  const usageRate = voucher.claimedCount > 0 ? Math.round((voucher.usedCount / voucher.claimedCount) * 100) : 0;
  const discountText = voucher.type === VoucherType.PERCENT ? `${voucher.value}%` : formatCurrency(voucher.value);
  const conditionText = voucher.type === VoucherType.PERCENT
    ? `Giảm ${voucher.value}% tối đa ${formatCurrency(voucher.maxDiscountAmount || 0)} cho đơn từ ${formatCurrency(voucher.minOrderAmount)}`
    : `Giảm ${formatCurrency(voucher.value)} cho đơn từ ${formatCurrency(voucher.minOrderAmount)}`;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-[#172033]/45 p-4 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="flex max-h-[92vh] w-full max-w-4xl flex-col overflow-hidden rounded-[14px] border border-[#dce7f1] bg-white shadow-[0_24px_70px_rgba(25,42,70,0.24)] animate-in zoom-in-95 duration-200">
        <div className="flex shrink-0 items-start justify-between gap-4 border-b border-[#edf2f7] bg-[#fbfcff] px-6 py-5">
          <div className="flex min-w-0 items-start gap-4">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[10px] bg-primary/10 text-primary">
              <Ticket className="h-5 w-5" />
            </div>
            <div className="min-w-0">
              <div className="mb-1 flex flex-wrap items-center gap-2">
                <h2 className="text-[20px] font-extrabold leading-tight text-[#25396f]">{voucher.code}</h2>
                <Badge variant={statusInfo.variant} className={`rounded-[6px] border-none px-2.5 py-1 text-[10px] font-extrabold uppercase ${statusInfo.tone}`}>
                  <StatusIcon className="mr-1 h-3.5 w-3.5" />
                  {statusInfo.label}
                </Badge>
              </div>
              <p className="text-sm font-semibold text-[#7c8db5]">{voucher.name}</p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="flex h-9 w-9 shrink-0 items-center justify-center rounded-[8px] text-[#7c8db5] transition-colors hover:bg-white hover:text-[#25396f]"
            aria-label="Đóng modal"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto">
          <div className="grid grid-cols-1 gap-0 lg:grid-cols-[300px_1fr]">
            <aside className="border-b border-[#edf2f7] bg-[#fbfcff] p-6 lg:border-b-0 lg:border-r">
              <div className="space-y-4">
                <div className="relative overflow-hidden rounded-[14px] border border-[#dce7f1] bg-white shadow-[0_8px_24px_rgba(25,42,70,0.08)]">
                  <div className="absolute -left-4 top-1/2 z-10 h-8 w-8 -translate-y-1/2 rounded-full bg-[#fbfcff]" />
                  <div className="absolute -right-4 top-1/2 z-10 h-8 w-8 -translate-y-1/2 rounded-full bg-[#fbfcff]" />
                  <div className="grid grid-cols-[110px_1fr]">
                    <div className="flex min-h-40 flex-col items-center justify-center border-r-2 border-dashed border-[#dce7f1] bg-primary/10 p-4 text-primary">
                      <span className="text-[32px] font-extrabold leading-none">{voucher.type === VoucherType.PERCENT ? `${voucher.value}%` : 'GIẢM'}</span>
                      {voucher.type === VoucherType.FIXED_AMOUNT && (
                        <span className="mt-1 text-sm font-extrabold">{formatCurrency(voucher.value)}</span>
                      )}
                    </div>
                    <div className="min-w-0 p-4">
                      <p className="mb-2 line-clamp-2 text-base font-extrabold leading-tight text-[#25396f]">{voucher.name}</p>
                      <span className="inline-flex rounded-[6px] bg-[#f2f7ff] px-2.5 py-1 text-[11px] font-extrabold uppercase text-primary">
                        {voucher.code}
                      </span>
                      <p className="mt-3 line-clamp-3 text-xs font-semibold leading-5 text-[#7c8db5]">{conditionText}</p>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="rounded-[10px] border border-[#edf2f7] bg-white p-3">
                    <p className="mb-1 text-[10px] font-extrabold uppercase text-[#7c8db5]">Mức giảm</p>
                    <p className="truncate text-lg font-extrabold leading-none text-[#25396f]">{discountText}</p>
                  </div>
                  <div className="rounded-[10px] border border-[#edf2f7] bg-white p-3">
                    <p className="mb-1 text-[10px] font-extrabold uppercase text-[#7c8db5]">Còn lại</p>
                    <p className="text-lg font-extrabold leading-none text-[#25396f]">{remaining}</p>
                  </div>
                </div>

                {voucher.description && (
                  <div className="rounded-[10px] border border-[#edf2f7] bg-white p-4">
                    <p className="mb-2 text-[11px] font-extrabold uppercase tracking-wide text-[#7c8db5]">Mô tả</p>
                    <p className="mb-0 text-xs font-semibold leading-5 text-[#607080]">{voucher.description}</p>
                  </div>
                )}
              </div>
            </aside>

            <div className="space-y-6 p-6">
              <section className="space-y-3">
                <div className="flex items-center gap-2">
                  <ReceiptText className="h-4 w-4 text-primary" />
                  <h3 className="text-sm font-extrabold text-[#25396f]">Điều kiện áp dụng</h3>
                </div>
                <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                  <InfoRow label="Loại ưu đãi" value={voucher.type === VoucherType.PERCENT ? 'Giảm theo phần trăm' : 'Giảm tiền mặt'} />
                  <InfoRow label="Đơn tối thiểu" value={formatCurrency(voucher.minOrderAmount)} />
                  {voucher.type === VoucherType.PERCENT && (
                    <InfoRow label="Giảm tối đa" value={formatCurrency(voucher.maxDiscountAmount || 0)} />
                  )}
                  <InfoRow label="Trạng thái" value={statusInfo.label} />
                </div>
              </section>

              <section className="space-y-3">
                <div className="flex items-center gap-2">
                  <CalendarDays className="h-4 w-4 text-primary" />
                  <h3 className="text-sm font-extrabold text-[#25396f]">Thời gian hiệu lực</h3>
                </div>
                <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                  <InfoRow label="Bắt đầu" value={formatDate(voucher.startsAt)} />
                  <InfoRow label="Kết thúc" value={formatDate(voucher.expiresAt)} />
                </div>
              </section>

              <section className="space-y-3">
                <div className="flex items-center gap-2">
                  <Activity className="h-4 w-4 text-primary" />
                  <h3 className="text-sm font-extrabold text-[#25396f]">Thống kê sử dụng</h3>
                </div>
                <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
                  <MetricCard label="Phát hành" value={voucher.quantity} />
                  <MetricCard label="Đã nhận" value={voucher.claimedCount} />
                  <MetricCard label="Đã dùng" value={voucher.usedCount} />
                </div>

                <ProgressBlock
                  label="Tỉ lệ nhận"
                  value={`${voucher.claimedCount} / ${voucher.quantity}`}
                  percent={claimRate}
                  colorClass="bg-primary"
                />
                <ProgressBlock
                  label="Tỉ lệ sử dụng"
                  value={`${voucher.usedCount} / ${voucher.claimedCount}`}
                  percent={usageRate}
                  colorClass="bg-[#5ddc97]"
                />
              </section>

              {remaining === 0 && (
                <div className="rounded-[10px] border border-red-100 bg-red-50 p-4">
                  <div className="flex gap-3">
                    <ShoppingBag className="mt-0.5 h-5 w-5 shrink-0 text-red-600" />
                    <div>
                      <p className="mb-1 text-sm font-extrabold text-red-700">Voucher đã hết lượt nhận</p>
                      <p className="mb-0 text-xs font-semibold text-red-600">Tăng số lượt phát hành nếu muốn tiếp tục cho khách nhận mã này.</p>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const InfoRow: React.FC<{ label: string; value: string }> = ({ label, value }) => (
  <div className="rounded-[10px] border border-[#edf2f7] bg-white p-4">
    <p className="mb-1 text-[10px] font-extrabold uppercase tracking-wide text-[#7c8db5]">{label}</p>
    <p className="mb-0 text-sm font-extrabold text-[#25396f]">{value}</p>
  </div>
);

const MetricCard: React.FC<{ label: string; value: number }> = ({ label, value }) => (
  <div className="rounded-[10px] border border-[#edf2f7] bg-[#fbfcff] p-4">
    <p className="mb-1 text-[10px] font-extrabold uppercase tracking-wide text-[#7c8db5]">{label}</p>
    <p className="mb-0 text-2xl font-extrabold leading-none text-[#25396f]">{value}</p>
  </div>
);

const ProgressBlock: React.FC<{ label: string; value: string; percent: number; colorClass: string }> = ({ label, value, percent, colorClass }) => (
  <div className="rounded-[10px] border border-[#edf2f7] bg-white p-4">
    <div className="mb-2 flex items-center justify-between gap-3">
      <p className="mb-0 text-xs font-extrabold uppercase text-[#7c8db5]">{label}</p>
      <p className="mb-0 text-sm font-extrabold text-[#25396f]">{value}</p>
    </div>
    <div className="h-2 overflow-hidden rounded-full bg-[#f2f7ff]">
      <div className={`h-full transition-all ${colorClass}`} style={{ width: `${Math.min(100, percent)}%` }} />
    </div>
  </div>
);
