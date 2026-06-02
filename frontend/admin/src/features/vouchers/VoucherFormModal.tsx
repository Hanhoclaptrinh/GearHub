import React, { useMemo, useState } from 'react';
import { CalendarDays, CheckCircle2, ChevronDown, Hash, Percent, ReceiptText, Ticket, ToggleRight, X } from '../../components/ui/IconlyIcons';
import { toast } from 'sonner';
import { Button } from '../../components/ui/Button';
import { VoucherType } from '../../types';
import type { Voucher } from '../../types';
import type { CreateVoucherPayload, UpdateVoucherPayload } from '../../services/voucher.service';

interface VoucherFormModalProps {
  voucher: Voucher | null;
  onClose: () => void;
  onSave: (payload: CreateVoucherPayload | UpdateVoucherPayload) => void;
  isSaving: boolean;
}

type VoucherSubmitPayload = Omit<CreateVoucherPayload, 'startsAt' | 'expiresAt' | 'maxDiscountAmount'> & {
  startsAt?: string | null;
  expiresAt?: string | null;
  maxDiscountAmount?: number | null;
};

const fieldLabelClass = 'text-[11px] font-extrabold text-[#7c8db5] uppercase tracking-wide';
const fieldClass =
  'w-full rounded-[8px] border border-[#dce7f1] bg-white text-sm font-bold text-[#25396f] outline-none transition-all placeholder:text-[#a8b4c7] focus:border-primary focus:ring-4 focus:ring-primary/10 disabled:cursor-not-allowed disabled:bg-[#f2f7ff] disabled:text-[#a8b4c7]';

const formatDateTime = (dateStr?: string) => {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  return new Date(date.getTime() - date.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
};

const formatCurrency = (value: number) =>
  new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(value || 0);

const formatCompactCurrency = (value: number) =>
  new Intl.NumberFormat('vi-VN', { notation: 'compact', maximumFractionDigits: 1 }).format(value || 0);

export const VoucherFormModal: React.FC<VoucherFormModalProps> = ({ voucher, onClose, onSave, isSaving }) => {
  const [code, setCode] = useState(voucher?.code || '');
  const [name, setName] = useState(voucher?.name || '');
  const [description, setDescription] = useState(voucher?.description || '');
  const [type, setType] = useState<VoucherType>(voucher?.type || VoucherType.PERCENT);
  const [value, setValue] = useState<string>(voucher?.value?.toString() || '');
  const [minOrderAmount, setMinOrderAmount] = useState<string>(voucher?.minOrderAmount?.toString() || '');
  const [maxDiscountAmount, setMaxDiscountAmount] = useState<string>(voucher?.maxDiscountAmount?.toString() || '');
  const [quantity, setQuantity] = useState<string>(voucher?.quantity?.toString() || '1');
  const [startsAt, setStartsAt] = useState<string>(formatDateTime(voucher?.startsAt));
  const [expiresAt, setExpiresAt] = useState<string>(formatDateTime(voucher?.expiresAt));
  const [isActive, setIsActive] = useState<boolean>(voucher?.isActive ?? true);

  const isEditing = Boolean(voucher);
  const hasUsage = voucher ? voucher.claimedCount > 0 || voucher.usedCount > 0 : false;
  const valueNum = Number(value) || 0;
  const minOrderNum = Number(minOrderAmount) || 0;
  const maxDiscountNum = Number(maxDiscountAmount) || 0;

  const previewText = useMemo(() => {
    if (type === VoucherType.PERCENT) {
      return `Giảm ${valueNum}% tối đa ${formatCurrency(maxDiscountNum)} cho đơn từ ${formatCurrency(minOrderNum)}`;
    }
    return `Giảm ${formatCurrency(valueNum)} cho đơn từ ${formatCurrency(minOrderNum)}`;
  }, [maxDiscountNum, minOrderNum, type, valueNum]);

  const usageRate = voucher && voucher.quantity > 0 ? Math.round((voucher.usedCount / voucher.quantity) * 100) : 0;

  const handleSubmit = (event: React.FormEvent) => {
    event.preventDefault();

    const parsedValue = Number(value);
    const parsedMinOrder = Number(minOrderAmount);
    const parsedMaxDiscount = Number(maxDiscountAmount);
    const parsedQuantity = Number(quantity);

    if (Number.isNaN(parsedValue) || parsedValue <= 0) {
      toast.error('Giá trị giảm phải lớn hơn 0');
      return;
    }

    if (type === VoucherType.PERCENT) {
      if (parsedValue < 1 || parsedValue > 100) {
        toast.error('Giá trị giảm phần trăm phải từ 1% đến 100%');
        return;
      }
      if (!minOrderAmount || parsedMinOrder <= 0) {
        toast.error('Đơn tối thiểu bắt buộc và phải lớn hơn 0');
        return;
      }
      if (!maxDiscountAmount || parsedMaxDiscount <= 0) {
        toast.error('Giá trị giảm tối đa bắt buộc và phải lớn hơn 0');
        return;
      }
      if (parsedMaxDiscount > parsedMinOrder) {
        toast.error('Giá trị giảm tối đa không được vượt quá Đơn tối thiểu');
        return;
      }
    }

    if (type === VoucherType.FIXED_AMOUNT) {
      if (!minOrderAmount || parsedMinOrder <= 0) {
        toast.error('Đơn tối thiểu bắt buộc và phải lớn hơn 0');
        return;
      }
      if (parsedMinOrder < parsedValue) {
        toast.error('Đơn tối thiểu phải lớn hơn hoặc bằng giá trị giảm');
        return;
      }
    }

    if (Number.isNaN(parsedQuantity) || parsedQuantity <= 0) {
      toast.error('Số lượt phát hành phải lớn hơn 0');
      return;
    }

    if (voucher && parsedQuantity < voucher.claimedCount) {
      toast.error(`Số lượt phát hành không được nhỏ hơn số lượt đã nhận (${voucher.claimedCount})`);
      return;
    }

    const payload: VoucherSubmitPayload = {
      code: code.trim().toUpperCase(),
      name: name.trim(),
      description: description.trim(),
      type,
      value: parsedValue,
      minOrderAmount: parsedMinOrder,
      quantity: parsedQuantity,
      isActive,
      maxDiscountAmount: type === VoucherType.PERCENT ? parsedMaxDiscount : null,
      startsAt: startsAt ? new Date(startsAt).toISOString() : null,
      expiresAt: expiresAt ? new Date(expiresAt).toISOString() : null,
    };

    onSave(payload as CreateVoucherPayload | UpdateVoucherPayload);
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-[#172033]/45 p-4 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="flex max-h-[92vh] w-full max-w-5xl flex-col overflow-hidden rounded-[14px] border border-[#dce7f1] bg-white shadow-[0_24px_70px_rgba(25,42,70,0.24)] animate-in zoom-in-95 duration-200">
        <div className="flex shrink-0 items-start justify-between gap-4 border-b border-[#edf2f7] bg-[#fbfcff] px-6 py-5">
          <div className="flex min-w-0 items-start gap-4">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[10px] bg-primary/10 text-primary">
              <Ticket className="h-5 w-5" />
            </div>
            <div className="min-w-0">
              <div className="mb-1 flex flex-wrap items-center gap-2">
                <h2 className="text-[20px] font-extrabold leading-tight text-[#25396f]">
                  {isEditing ? 'Cập nhật voucher' : 'Tạo voucher mới'}
                </h2>
                <span className="rounded-[6px] bg-white px-2.5 py-1 text-[11px] font-extrabold text-[#7c8db5] ring-1 ring-[#dce7f1]">
                  {isActive ? 'Đang bật' : 'Tạm ngưng'}
                </span>
              </div>
              <p className="text-sm font-semibold text-[#7c8db5]">
                Thiết lập điều kiện, thời gian và số lượt phát hành cho ưu đãi.
              </p>
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

        <form id="voucher-form" onSubmit={handleSubmit} className="flex-1 overflow-y-auto">
          <div className="grid grid-cols-1 gap-0 xl:grid-cols-[340px_1fr]">
            <aside className="border-b border-[#edf2f7] bg-[#fbfcff] p-6 xl:border-b-0 xl:border-r">
              <div className="space-y-4">
                <div className="relative overflow-hidden rounded-[14px] border border-[#dce7f1] bg-white shadow-[0_8px_24px_rgba(25,42,70,0.08)]">
                  <div className="absolute -left-4 top-1/2 z-10 h-8 w-8 -translate-y-1/2 rounded-full bg-[#fbfcff]" />
                  <div className="absolute -right-4 top-1/2 z-10 h-8 w-8 -translate-y-1/2 rounded-full bg-[#fbfcff]" />
                  <div className="grid grid-cols-[112px_1fr]">
                    <div className="flex min-h-40 flex-col items-center justify-center border-r-2 border-dashed border-[#dce7f1] bg-primary/10 p-4 text-primary">
                      <span className="text-[30px] font-extrabold leading-none">
                        {type === VoucherType.PERCENT ? `${value || 0}%` : 'GIẢM'}
                      </span>
                      {type === VoucherType.FIXED_AMOUNT && (
                        <span className="mt-1 text-sm font-extrabold">{formatCompactCurrency(valueNum)}đ</span>
                      )}
                    </div>
                    <div className="min-w-0 p-4">
                      <p className="mb-2 line-clamp-2 text-base font-extrabold leading-tight text-[#25396f]">{name || 'Tên ưu đãi'}</p>
                      <span className="inline-flex rounded-[6px] bg-[#f2f7ff] px-2.5 py-1 text-[11px] font-extrabold uppercase text-primary">
                        {code || 'MA-VOUCHER'}
                      </span>
                      <p className="mt-3 line-clamp-3 text-xs font-semibold leading-5 text-[#7c8db5]">{previewText}</p>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="rounded-[10px] border border-[#edf2f7] bg-white p-3">
                    <p className="mb-1 text-[10px] font-extrabold uppercase text-[#7c8db5]">Phát hành</p>
                    <p className="text-lg font-extrabold leading-none text-[#25396f]">{quantity || 0}</p>
                  </div>
                  <div className="rounded-[10px] border border-[#edf2f7] bg-white p-3">
                    <p className="mb-1 text-[10px] font-extrabold uppercase text-[#7c8db5]">Đã dùng</p>
                    <p className="text-lg font-extrabold leading-none text-[#25396f]">{voucher?.usedCount ?? 0}</p>
                  </div>
                </div>

                {isEditing && voucher && (
                  <div className="rounded-[10px] border border-[#edf2f7] bg-white p-4">
                    <div className="mb-2 flex items-center justify-between">
                      <p className="mb-0 text-[11px] font-extrabold uppercase tracking-wide text-[#7c8db5]">Tỉ lệ dùng</p>
                      <p className="mb-0 text-xs font-extrabold text-[#25396f]">{usageRate}%</p>
                    </div>
                    <div className="h-2 overflow-hidden rounded-full bg-[#f2f7ff]">
                      <div className="h-full bg-primary transition-all" style={{ width: `${Math.min(100, usageRate)}%` }} />
                    </div>
                    {hasUsage && (
                      <p className="mb-0 mt-3 text-xs font-semibold leading-5 text-[#7c8db5]">
                        Mã hoặc loại giảm bị khóa vì voucher đã có lượt nhận/sử dụng.
                      </p>
                    )}
                  </div>
                )}

                <button
                  type="button"
                  onClick={() => setIsActive((current) => !current)}
                  className={`flex w-full items-center justify-between rounded-[10px] border p-4 text-left transition-all ${
                    isActive ? 'border-[#d9f0e2] bg-[#edf9f1] text-[#2f8f5b]' : 'border-red-100 bg-red-50 text-red-600'
                  }`}
                >
                  <span>
                    <span className="block text-sm font-extrabold">{isActive ? 'Đang hoạt động' : 'Tạm ngưng'}</span>
                    <span className="mt-1 block text-xs font-semibold opacity-80">Trạng thái áp dụng voucher</span>
                  </span>
                  {isActive ? <CheckCircle2 className="h-5 w-5" /> : <ToggleRight className="h-5 w-5" />}
                </button>
              </div>
            </aside>

            <div className="space-y-6 p-6">
              <section className="space-y-4">
                <div className="flex items-center gap-2">
                  <Hash className="h-4 w-4 text-primary" />
                  <h3 className="text-sm font-extrabold text-[#25396f]">Thông tin định danh</h3>
                </div>
                <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                  <div>
                    <label className={fieldLabelClass}>Mã voucher</label>
                    <input
                      value={code}
                      onChange={(event) => setCode(event.target.value.toUpperCase())}
                      required
                      maxLength={50}
                      disabled={hasUsage && isEditing}
                      placeholder="SUMMER2026"
                      className={`${fieldClass} mt-2 h-11 px-4 uppercase`}
                    />
                  </div>
                  <div>
                    <label className={fieldLabelClass}>Tên voucher</label>
                    <input
                      value={name}
                      onChange={(event) => setName(event.target.value)}
                      required
                      maxLength={255}
                      placeholder="Khuyến mãi mùa hè"
                      className={`${fieldClass} mt-2 h-11 px-4`}
                    />
                  </div>
                  <div className="md:col-span-2">
                    <label className={fieldLabelClass}>Mô tả</label>
                    <textarea
                      value={description}
                      onChange={(event) => setDescription(event.target.value)}
                      placeholder="Nội dung ngắn mô tả ưu đãi..."
                      className={`${fieldClass} mt-2 min-h-[92px] resize-none p-4 font-semibold leading-6`}
                    />
                  </div>
                </div>
              </section>

              <section className="space-y-4">
                <div className="flex items-center gap-2">
                  <Percent className="h-4 w-4 text-primary" />
                  <h3 className="text-sm font-extrabold text-[#25396f]">Giá trị và điều kiện</h3>
                </div>
                <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                  <div>
                    <label className={fieldLabelClass}>Loại giảm giá</label>
                    <div className="relative mt-2">
                      <select
                        value={type}
                        onChange={(event) => setType(event.target.value as VoucherType)}
                        disabled={hasUsage && isEditing}
                        className={`${fieldClass} h-11 cursor-pointer appearance-none px-4 pr-10`}
                      >
                        <option value={VoucherType.PERCENT}>Giảm theo %</option>
                        <option value={VoucherType.FIXED_AMOUNT}>Giảm tiền mặt</option>
                      </select>
                      <ChevronDown className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[#7c8db5]" />
                    </div>
                  </div>
                  <div>
                    <label className={fieldLabelClass}>Giá trị giảm {type === VoucherType.PERCENT ? '(%)' : '(VNĐ)'}</label>
                    <input
                      type="number"
                      value={value}
                      onChange={(event) => setValue(event.target.value)}
                      required
                      min={1}
                      max={type === VoucherType.PERCENT ? 100 : undefined}
                      placeholder={type === VoucherType.PERCENT ? '10' : '100000'}
                      className={`${fieldClass} mt-2 h-11 px-4`}
                    />
                  </div>
                  <div>
                    <label className={fieldLabelClass}>Đơn tối thiểu (VNĐ)</label>
                    <input
                      type="number"
                      value={minOrderAmount}
                      onChange={(event) => setMinOrderAmount(event.target.value)}
                      required
                      min={1}
                      placeholder="500000"
                      className={`${fieldClass} mt-2 h-11 px-4`}
                    />
                  </div>
                  <div>
                    <label className={fieldLabelClass}>Giảm tối đa (VNĐ)</label>
                    <input
                      type={type === VoucherType.PERCENT ? 'number' : 'text'}
                      value={type === VoucherType.PERCENT ? maxDiscountAmount : 'Không áp dụng'}
                      onChange={(event) => setMaxDiscountAmount(event.target.value)}
                      required={type === VoucherType.PERCENT}
                      min={1}
                      disabled={type !== VoucherType.PERCENT}
                      placeholder="200000"
                      className={`${fieldClass} mt-2 h-11 px-4`}
                    />
                  </div>
                </div>
              </section>

              <section className="space-y-4">
                <div className="flex items-center gap-2">
                  <CalendarDays className="h-4 w-4 text-primary" />
                  <h3 className="text-sm font-extrabold text-[#25396f]">Phát hành và thời gian</h3>
                </div>
                <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
                  <div>
                    <label className={fieldLabelClass}>Số lượt phát hành</label>
                    <input
                      type="number"
                      value={quantity}
                      onChange={(event) => setQuantity(event.target.value)}
                      required
                      min={voucher ? Math.max(1, voucher.claimedCount) : 1}
                      placeholder="100"
                      className={`${fieldClass} mt-2 h-11 px-4`}
                    />
                  </div>
                  <div>
                    <label className={fieldLabelClass}>Ngày bắt đầu</label>
                    <input
                      type="datetime-local"
                      value={startsAt}
                      onChange={(event) => setStartsAt(event.target.value)}
                      className={`${fieldClass} mt-2 h-11 px-4`}
                    />
                  </div>
                  <div>
                    <label className={fieldLabelClass}>Ngày kết thúc</label>
                    <input
                      type="datetime-local"
                      value={expiresAt}
                      onChange={(event) => setExpiresAt(event.target.value)}
                      min={startsAt}
                      className={`${fieldClass} mt-2 h-11 px-4`}
                    />
                  </div>
                </div>
              </section>

              <div className="rounded-[10px] border border-[#edf2f7] bg-[#fbfcff] p-4">
                <div className="flex gap-3">
                  <div className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-[8px] bg-primary/10 text-primary">
                    <ReceiptText className="h-4 w-4" />
                  </div>
                  <div className="min-w-0">
                    <p className="mb-1 text-sm font-extrabold text-[#25396f]">Điều kiện đang hiển thị</p>
                    <p className="mb-0 text-xs font-semibold leading-5 text-[#7c8db5]">{previewText}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="flex shrink-0 flex-col-reverse gap-3 border-t border-[#edf2f7] bg-white px-6 py-4 sm:flex-row sm:justify-end">
            <Button
              type="button"
              variant="outline"
              className="h-10 rounded-[8px] border border-[#dce7f1] bg-white px-5 text-sm font-extrabold text-[#607080] shadow-none hover:border-primary hover:bg-primary/5 hover:text-primary"
              onClick={onClose}
            >
              Hủy
            </Button>
            <Button
              type="submit"
              className="h-10 rounded-[8px] bg-primary px-5 text-sm font-extrabold text-white shadow-[0_5px_12px_rgba(67,94,190,0.18)] hover:bg-primary/90"
              isLoading={isSaving}
              disabled={!code.trim() || !name.trim() || !value.trim() || !quantity.trim()}
            >
              {isEditing ? 'Lưu thay đổi' : 'Tạo voucher'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
};
