import React from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { X, Calendar } from '../ui/IconlyIcons';
import { Button } from '../ui/Button';
import { Input } from '../ui/Input';
import type { UpdateFlashSaleTimeBulkInput } from '../../types/flash-sale.types';

const bulkTimeSchema = z.object({
  startsAt: z.string().min(1, 'Thời gian bắt đầu là bắt buộc'),
  expiresAt: z.string().min(1, 'Thời gian kết thúc là bắt buộc'),
});

type FormValues = z.infer<typeof bulkTimeSchema>;

interface BulkEditTimeModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: Omit<UpdateFlashSaleTimeBulkInput, 'ids'>) => void;
  isSaving: boolean;
  selectedCount: number;
}

export const BulkEditTimeModal: React.FC<BulkEditTimeModalProps> = ({
  isOpen,
  onClose,
  onSave,
  isSaving,
  selectedCount,
}) => {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(bulkTimeSchema),
    defaultValues: {
      startsAt: '',
      expiresAt: '',
    },
  });

  if (!isOpen) return null;

  const handleFormSubmit = (values: FormValues) => {
    onSave({
      startsAt: new Date(values.startsAt).toISOString(),
      expiresAt: new Date(values.expiresAt).toISOString(),
    });
  };

  return (
    <div className="fixed inset-0 z-[190] flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white w-full max-w-md rounded-[24px] shadow-2xl overflow-hidden flex flex-col animate-in zoom-in-95 duration-200 border border-white">
        {/* Header */}
        <div className="px-6 py-5 border-b border-slate-100 flex items-center justify-between">
          <div>
            <h3 className="text-lg font-black text-slate-900 uppercase tracking-tight">
              Sửa thời gian hàng loạt
            </h3>
            <p className="text-xs font-semibold text-slate-400 mt-0.5">
              Đang chỉnh sửa cho {selectedCount} sản phẩm Flash Sale đã chọn
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
        <form onSubmit={handleSubmit(handleFormSubmit)} className="p-6 space-y-4">
          <Input
            label="Thời gian bắt đầu mới"
            type="datetime-local"
            icon={Calendar}
            error={errors.startsAt?.message}
            {...register('startsAt')}
          />

          <Input
            label="Thời gian kết thúc mới"
            type="datetime-local"
            icon={Calendar}
            error={errors.expiresAt?.message}
            {...register('expiresAt')}
          />

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
              Lưu thời gian
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
};
