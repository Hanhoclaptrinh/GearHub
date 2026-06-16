import React, { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { X, Calendar, DollarSign, Box } from '../ui/IconlyIcons';
import { Button } from '../ui/Button';
import { Input } from '../ui/Input';
import { VariantSelectModal } from './VariantSelectModal';
import type { Product, ProductVariant } from '../../types';
import type { CreateFlashSaleBulkInput } from '../../types/flash-sale.types';

const bulkFlashSaleSchema = z.object({
  discountType: z.enum(['PERCENT', 'FIXED_AMOUNT', 'PRICE']),
  discountValue: z.preprocess(
    (v) => (v === '' || v === undefined ? undefined : Number(v)),
    z.number({ message: 'Giá trị giảm là bắt buộc' }).min(0, 'Giá trị không hợp lệ')
  ),
  stockLimit: z.preprocess(
    (v) => (v === '' || v === undefined ? undefined : Number(v)),
    z.number({ message: 'Số lượng giới hạn là bắt buộc' }).min(1, 'Giới hạn tối thiểu là 1')
  ),
  startsAt: z.string().min(1, 'Thời gian bắt đầu là bắt buộc'),
  expiresAt: z.string().min(1, 'Thời gian kết thúc là bắt buộc'),
});

type FormValues = z.infer<typeof bulkFlashSaleSchema>;

interface CreateFlashSaleModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSaveBulk: (data: CreateFlashSaleBulkInput) => void;
  isSaving: boolean;
}

export const CreateFlashSaleModal: React.FC<CreateFlashSaleModalProps> = ({
  isOpen,
  onClose,
  onSaveBulk,
  isSaving,
}) => {
  const [isSelectVariantOpen, setIsSelectVariantOpen] = useState(false);
  const [selectedItems, setSelectedItems] = useState<
    Array<{ variant: ProductVariant; product: Product }>
  >([]);
  const [variantError, setVariantError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    watch,
    reset,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(bulkFlashSaleSchema) as any,
    defaultValues: {
      discountType: 'PERCENT',
      discountValue: undefined,
      stockLimit: undefined,
      startsAt: '',
      expiresAt: '',
    },
  });

  const watchDiscountType = watch('discountType');

  // Clear state and form values when modal opens or closes
  useEffect(() => {
    if (isOpen) {
      setSelectedItems([]);
      setVariantError(null);
      reset({
        discountType: 'PERCENT',
        discountValue: undefined,
        stockLimit: undefined,
        startsAt: '',
        expiresAt: '',
      });
    }
  }, [isOpen, reset]);

  if (!isOpen) return null;

  const handleMultipleVariantsSelected = (
    newItems: Array<{ variant: ProductVariant; product: Product }>
  ) => {
    setSelectedItems((prev) => {
      const merged = [...prev];
      newItems.forEach((item) => {
        if (!merged.some((x) => x.variant.id === item.variant.id)) {
          merged.push(item);
        }
      });
      if (merged.length > 0) setVariantError(null);
      return merged;
    });
  };

  const handleRemoveItem = (variantId: string) => {
    setSelectedItems((prev) => prev.filter((x) => x.variant.id !== variantId));
  };

  const handleFormSubmit = (values: FormValues) => {
    if (selectedItems.length === 0) {
      setVariantError('Vui lòng chọn ít nhất một biến thể sản phẩm');
      return;
    }

    onSaveBulk({
      productVariantIds: selectedItems.map((x) => x.variant.id),
      discountType: values.discountType,
      discountValue: values.discountValue,
      stockLimit: values.stockLimit,
      startsAt: new Date(values.startsAt).toISOString(),
      expiresAt: new Date(values.expiresAt).toISOString(),
    });
  };

  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
      maximumFractionDigits: 0,
    }).format(value);

  return (
    <>
      <div className="fixed inset-0 z-[190] flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm animate-in fade-in duration-200">
        <div className="bg-white w-full max-w-2xl rounded-[24px] shadow-2xl overflow-hidden flex flex-col max-h-[90vh] animate-in zoom-in-95 duration-200 border border-white">
          {/* Header */}
          <div className="px-6 py-5 border-b border-slate-100 flex items-center justify-between">
            <div>
              <h3 className="text-lg font-black text-slate-900 uppercase tracking-tight">
                Tạo Flash Sale hàng loạt
              </h3>
              <p className="text-xs font-semibold text-slate-400 mt-0.5">
                Thiết lập giảm giá hàng loạt theo phần trăm, số tiền hoặc giá cố định
              </p>
            </div>
            <button
              onClick={onClose}
              className="p-2 rounded-full hover:bg-slate-50 transition-all text-slate-400 hover:text-slate-600"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Form Content */}
          <form
            onSubmit={handleSubmit(handleFormSubmit) as any}
            className="flex-1 overflow-y-auto p-6 space-y-5 custom-scrollbar"
          >
            {/* Multi Product Picker */}
            <div className="flex flex-col gap-2">
              <div className="flex items-center justify-between">
                <label className="text-sm font-semibold text-slate-700 ml-1">
                  Biến thể đã chọn ({selectedItems.length})
                </label>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => setIsSelectVariantOpen(true)}
                  className="h-8 text-xs rounded-lg border-slate-200"
                >
                  + Chọn biến thể
                </Button>
              </div>

              {selectedItems.length > 0 ? (
                <div className="border border-slate-100 rounded-xl bg-slate-50/50 max-h-48 overflow-y-auto p-3 space-y-2 custom-scrollbar">
                  {selectedItems.map((item) => (
                    <div
                      key={item.variant.id}
                      className="flex items-center justify-between p-2.5 bg-white border border-slate-100 rounded-lg hover:shadow-xs transition-shadow"
                    >
                      <div className="min-w-0 pr-3">
                        <p className="font-extrabold text-xs text-[#25396f] truncate">
                          {item.product.name}
                        </p>
                        <p className="font-mono text-[9px] font-bold text-slate-400 mt-0.5">
                          SKU: {item.variant.sku} · Giá gốc: {formatCurrency(Number(item.variant.price))}
                        </p>
                      </div>
                      <button
                        type="button"
                        onClick={() => handleRemoveItem(item.variant.id)}
                        className="p-1 rounded-full text-slate-300 hover:text-red-500 transition-colors"
                      >
                        <X className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                </div>
              ) : (
                <button
                  type="button"
                  onClick={() => setIsSelectVariantOpen(true)}
                  className="w-full h-24 px-4 rounded-xl border border-dashed border-slate-300 text-slate-400 font-semibold text-xs hover:border-primary hover:text-primary transition-all flex flex-col items-center justify-center gap-2"
                >
                  <Box className="w-5 h-5 text-slate-300" />
                  Nhấn vào đây để chọn một hoặc nhiều sản phẩm cần Flash Sale...
                </button>
              )}
              {variantError && (
                <span className="text-xs font-medium text-red-500 ml-1 mt-0.5">
                  {variantError}
                </span>
              )}
            </div>

            {/* Discount config */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="flex flex-col gap-1.5">
                <label className="text-sm font-semibold text-slate-700 ml-1">
                  Hình thức giảm giá
                </label>
                <select
                  {...register('discountType')}
                  className="w-full h-12 px-4 bg-white border border-slate-200 rounded-lg outline-none focus:border-primary focus:ring-3 focus:ring-primary/20 appearance-none font-bold text-[#25396f] transition-all cursor-pointer"
                >
                  <option value="PERCENT">Giảm theo phần trăm (%)</option>
                  <option value="FIXED_AMOUNT">Giảm số tiền cụ thể (₫)</option>
                  <option value="PRICE">Giá bán Flash Sale cố định (₫)</option>
                </select>
              </div>

              <Input
                label={
                  watchDiscountType === 'PERCENT'
                    ? 'Giá trị giảm (%)'
                    : watchDiscountType === 'FIXED_AMOUNT'
                    ? 'Mức giảm (VND)'
                    : 'Giá Flash Sale (VND)'
                }
                type="number"
                placeholder={watchDiscountType === 'PERCENT' ? 'Ví dụ: 10' : 'Ví dụ: 500000'}
                icon={DollarSign}
                error={errors.discountValue?.message}
                {...register('discountValue')}
              />
            </div>

            {/* stock limit */}
            <div className="grid grid-cols-1 gap-4">
              <Input
                label="Số lượng giới hạn bán (mỗi sản phẩm)"
                type="number"
                placeholder="Ví dụ: 5"
                icon={Box}
                error={errors.stockLimit?.message}
                {...register('stockLimit')}
              />
            </div>

            {/* Date Time Picker Section */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input
                label="Thời gian bắt đầu"
                type="datetime-local"
                icon={Calendar}
                error={errors.startsAt?.message}
                {...register('startsAt')}
              />

              <Input
                label="Thời gian kết thúc"
                type="datetime-local"
                icon={Calendar}
                error={errors.expiresAt?.message}
                {...register('expiresAt')}
              />
            </div>

            {/* Footer Buttons */}
            <div className="flex gap-3 pt-4 border-t border-slate-100 mt-6">
              <Button
                type="button"
                variant="outline"
                onClick={onClose}
                disabled={isSaving}
                className="flex-1 h-11 rounded-xl font-bold uppercase text-[10px] tracking-wider border-slate-100"
              >
                Hủy bỏ
              </Button>
              <Button
                type="submit"
                isLoading={isSaving}
                className="flex-1 h-11 rounded-xl font-bold uppercase text-[10px] tracking-wider bg-primary text-white"
              >
                Áp dụng Flash Sale
              </Button>
            </div>
          </form>
        </div>
      </div>

      {/* Select Variant Sub-Modal */}
      <VariantSelectModal
        isOpen={isSelectVariantOpen}
        onClose={() => setIsSelectVariantOpen(false)}
        onSelectMultiple={handleMultipleVariantsSelected}
        initialSelectedIds={selectedItems.map((x) => x.variant.id)}
      />
    </>
  );
};
