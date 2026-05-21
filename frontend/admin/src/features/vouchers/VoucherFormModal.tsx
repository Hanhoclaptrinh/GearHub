import React, { useState } from 'react';
import { X, Loader2, Ticket } from 'lucide-react';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Textarea } from '../../components/ui/Textarea';
import { VoucherType } from '../../types';
import type { Voucher } from '../../types';
import type { CreateVoucherPayload, UpdateVoucherPayload } from '../../services/voucher.service';
import { toast } from 'sonner';

interface VoucherFormModalProps {
  voucher: Voucher | null;
  onClose: () => void;
  onSave: (payload: CreateVoucherPayload | UpdateVoucherPayload) => void;
  isSaving: boolean;
}

export const VoucherFormModal: React.FC<VoucherFormModalProps> = ({ voucher, onClose, onSave, isSaving }) => {
  const [code, setCode] = useState(voucher?.code || '');
  const [name, setName] = useState(voucher?.name || '');
  const [description, setDescription] = useState(voucher?.description || '');
  const [type, setType] = useState<VoucherType>(voucher?.type || VoucherType.PERCENT);
  const [value, setValue] = useState<string>(voucher?.value?.toString() || '');
  const [minOrderAmount, setMinOrderAmount] = useState<string>(voucher?.minOrderAmount?.toString() || '');
  const [maxDiscountAmount, setMaxDiscountAmount] = useState<string>(voucher?.maxDiscountAmount?.toString() || '');
  const [quantity, setQuantity] = useState<string>(voucher?.quantity?.toString() || '1');
  
  // Format for datetime-local is YYYY-MM-DDThh:mm
  const formatDateTime = (dateStr?: string) => {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
  };
  
  const [startsAt, setStartsAt] = useState<string>(formatDateTime(voucher?.startsAt));
  const [expiresAt, setExpiresAt] = useState<string>(formatDateTime(voucher?.expiresAt));
  const [isActive, setIsActive] = useState<boolean>(voucher?.isActive ?? true);
  
  const hasUsage = voucher ? voucher.claimedCount > 0 || voucher.usedCount > 0 : false;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const valNum = Number(value);
    const minOrderNum = Number(minOrderAmount);
    const quantityNum = Number(quantity);

    if (isNaN(valNum) || valNum <= 0) {
      toast.error('Giá trị giảm phải lớn hơn 0');
      return;
    }

    if (type === VoucherType.PERCENT) {
      if (valNum < 1 || valNum > 100) {
        toast.error('Giá trị giảm phần trăm phải từ 1% đến 100%');
        return;
      }
      if (!minOrderAmount || minOrderNum <= 0) {
        toast.error('Đơn tối thiểu bắt buộc và phải lớn hơn 0');
        return;
      }
      if (!maxDiscountAmount || Number(maxDiscountAmount) <= 0) {
        toast.error('Giá trị giảm tối đa bắt buộc và phải lớn hơn 0');
        return;
      }
      if (Number(maxDiscountAmount) > minOrderNum) {
        toast.error('Giá trị giảm tối đa không được vượt quá Đơn tối thiểu');
        return;
      }
    } else if (type === VoucherType.FIXED_AMOUNT) {
      if (!minOrderAmount || minOrderNum <= 0) {
        toast.error('Đơn tối thiểu bắt buộc và phải lớn hơn 0');
        return;
      }
      if (minOrderNum < valNum) {
        toast.error('Đơn tối thiểu phải lớn hơn hoặc bằng giá trị giảm');
        return;
      }
    }

    if (isNaN(quantityNum) || quantityNum <= 0) {
      toast.error('Số lượt phát hành phải lớn hơn 0');
      return;
    }

    if (voucher && quantityNum < voucher.claimedCount) {
      toast.error(`Số lượt phát hành không được nhỏ hơn số lượt đã nhận (${voucher.claimedCount})`);
      return;
    }

    const payload: any = {
      code: code.trim().toUpperCase(),
      name,
      description,
      type,
      value: valNum,
      minOrderAmount: minOrderNum,
      quantity: quantityNum,
      isActive
    };
    
    if (type === VoucherType.PERCENT) {
      payload.maxDiscountAmount = Number(maxDiscountAmount);
    } else {
      payload.maxDiscountAmount = null;
    }

    if (startsAt) {
      payload.startsAt = new Date(startsAt).toISOString();
    } else {
      payload.startsAt = null;
    }
    if (expiresAt) {
      payload.expiresAt = new Date(expiresAt).toISOString();
    } else {
      payload.expiresAt = null;
    }
    
    onSave(payload);
  };

  const getPreviewText = () => {
    const valNum = Number(value) || 0;
    const minOrderNum = Number(minOrderAmount) || 0;
    const maxDiscountNum = Number(maxDiscountAmount) || 0;

    const formatVND = (num: number) => {
      return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(num);
    };

    if (type === VoucherType.PERCENT) {
      return `Giảm ${valNum}% tối đa ${formatVND(maxDiscountNum)} cho đơn từ ${formatVND(minOrderNum)}`;
    } else {
      return `Giảm ${formatVND(valNum)} cho đơn từ ${formatVND(minOrderNum)}`;
    }
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-xl animate-in fade-in duration-300">
      <div className="bg-white w-full max-w-2xl rounded-[48px] shadow-2xl overflow-hidden animate-in zoom-in-95 duration-300 border border-white flex flex-col max-h-[90vh]">
        <div className="p-8 border-b border-slate-50 flex items-center justify-between shrink-0">
          <h2 className="text-2xl font-black text-slate-900 font-heading tracking-tighter uppercase">{voucher ? 'Cập nhật Ưu Đãi' : 'Tạo mới Ưu Đãi'}</h2>
          <button onClick={onClose} className="p-3 rounded-full hover:bg-slate-50 transition-all border border-transparent hover:border-slate-100">
            <X className="w-7 h-7 text-slate-400" />
          </button>
        </div>
        <div className="flex-1 overflow-y-auto custom-scrollbar">
          <form id="voucher-form" onSubmit={handleSubmit} className="p-8 space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <Input 
                label="Mã Voucher" 
                placeholder="Ví dụ: SUMMER2024" 
                value={code} 
                onChange={(e) => setCode(e.target.value.toUpperCase())} 
                required
                maxLength={50}
                disabled={hasUsage && !!voucher}
                className="h-14 rounded-2xl bg-slate-50 border-none shadow-inner font-black text-lg"
              />
              <Input 
                label="Tên Voucher" 
                placeholder="Ví dụ: Khuyến mãi mùa hè" 
                value={name} 
                onChange={(e) => setName(e.target.value)} 
                required
                maxLength={255}
                className="h-14 rounded-2xl bg-slate-50 border-none shadow-inner font-black text-lg"
              />
            </div>

            <Textarea 
              label="Mô tả" 
              placeholder="Nhập mô tả cho ưu đãi này..." 
              value={description} 
              onChange={(e) => setDescription(e.target.value)}
              className="rounded-2xl bg-slate-50 border-none shadow-inner font-bold"
            />

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-2">
                <label className="text-sm font-bold text-slate-700">Loại Giảm Giá</label>
                <select
                  value={type}
                  onChange={(e) => setType(e.target.value as VoucherType)}
                  disabled={hasUsage && !!voucher}
                  className="w-full h-14 px-4 rounded-2xl bg-slate-50 border-none focus:ring-4 focus:ring-primary/10 transition-all font-black text-lg shadow-inner outline-none text-slate-700"
                >
                  <option value={VoucherType.PERCENT}>Giảm theo %</option>
                  <option value={VoucherType.FIXED_AMOUNT}>Giảm tiền mặt</option>
                </select>
              </div>
              <Input 
                label={`Giá trị giảm (${type === VoucherType.PERCENT ? '%' : 'VNĐ'})`} 
                type="number"
                placeholder={type === VoucherType.PERCENT ? '10' : '100000'} 
                value={value} 
                onChange={(e) => setValue(e.target.value)} 
                required
                min={type === VoucherType.PERCENT ? 1 : 1}
                max={type === VoucherType.PERCENT ? 100 : undefined}
                className="h-14 rounded-2xl bg-slate-50 border-none shadow-inner font-black text-lg"
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <Input 
                label="Đơn tối thiểu (VNĐ)" 
                type="number"
                placeholder="Ví dụ: 500000" 
                value={minOrderAmount} 
                onChange={(e) => setMinOrderAmount(e.target.value)} 
                min={1}
                required
                className="h-14 rounded-2xl bg-slate-50 border-none shadow-inner font-black text-lg"
              />
              {type === VoucherType.PERCENT ? (
                <Input 
                  label="Giảm tối đa (VNĐ)" 
                  type="number"
                  placeholder="Ví dụ: 200000" 
                  value={maxDiscountAmount} 
                  onChange={(e) => setMaxDiscountAmount(e.target.value)} 
                  min={1}
                  required
                  className="h-14 rounded-2xl bg-slate-50 border-none shadow-inner font-black text-lg"
                />
              ) : (
                <Input 
                  label="Giảm tối đa (VNĐ)" 
                  type="text"
                  value="N/A (Chỉ áp dụng với giảm %)" 
                  disabled
                  className="h-14 rounded-2xl bg-slate-200 border-none shadow-inner font-bold text-slate-400 cursor-not-allowed"
                />
              )}
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <Input 
                label="Số lượt phát hành" 
                type="number"
                placeholder="Ví dụ: 100" 
                value={quantity} 
                onChange={(e) => setQuantity(e.target.value)} 
                required
                min={voucher ? Math.max(1, voucher.claimedCount) : 1}
                className="h-14 rounded-2xl bg-slate-50 border-none shadow-inner font-black text-lg"
              />
              <div className="flex items-center pt-8">
                <label className="flex items-center gap-3 cursor-pointer group">
                  <input
                    type="checkbox"
                    checked={isActive}
                    onChange={(e) => setIsActive(e.target.checked)}
                    className="w-6 h-6 rounded-lg text-primary bg-slate-100 border-none focus:ring-primary/20 focus:ring-4 transition-all shadow-inner"
                  />
                  <span className="font-bold text-slate-700 group-hover:text-primary transition-colors">Trạng thái hoạt động</span>
                </label>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <Input 
                label="Ngày bắt đầu" 
                type="datetime-local"
                value={startsAt} 
                onChange={(e) => setStartsAt(e.target.value)} 
                className="h-14 rounded-2xl bg-slate-50 border-none shadow-inner font-bold"
              />
              <Input 
                label="Ngày kết thúc" 
                type="datetime-local"
                value={expiresAt} 
                onChange={(e) => setExpiresAt(e.target.value)} 
                min={startsAt}
                className="h-14 rounded-2xl bg-slate-50 border-none shadow-inner font-bold"
              />
            </div>

            <div className="pt-4 border-t border-slate-100">
              <h3 className="text-sm font-black text-slate-900 uppercase tracking-widest mb-6 flex items-center gap-2">
                <Ticket className="w-5 h-5 text-primary" /> Hình ảnh Voucher hiển thị cho khách
              </h3>
              
              <div className="relative flex w-full max-w-lg mx-auto bg-white rounded-2xl shadow-[0_8px_30px_rgb(0,0,0,0.08)] border border-slate-100 overflow-hidden">
                <div className="absolute -left-4 top-1/2 -translate-y-1/2 w-8 h-8 bg-white shadow-[inset_-3px_0_5px_rgba(0,0,0,0.05)] rounded-full z-10" />
                <div className="absolute -right-4 top-1/2 -translate-y-1/2 w-8 h-8 bg-white shadow-[inset_3px_0_5px_rgba(0,0,0,0.05)] rounded-full z-10" />
                
                <div className="w-[140px] bg-gradient-to-br from-primary/10 to-primary/5 border-r-2 border-dashed border-slate-200 flex flex-col items-center justify-center p-4">
                  <span className="text-4xl font-black text-primary tracking-tighter">
                    {type === VoucherType.PERCENT ? `${value || 0}%` : 'GIẢM'}
                  </span>
                  {type === VoucherType.FIXED_AMOUNT && (
                    <span className="text-base font-black text-primary mt-1 tracking-tight">
                      {value ? new Intl.NumberFormat('vi-VN', { notation: 'compact' }).format(Number(value)) : '0'}đ
                    </span>
                  )}
                </div>
                
                <div className="flex-1 p-5 pl-6 relative">
                  <div className="mb-3">
                    <h4 className="text-lg font-black text-slate-900 leading-tight mb-1">
                      {name || 'Tên ưu đãi'}
                    </h4>
                    <span className="inline-block px-2 py-0.5 bg-slate-100 text-slate-600 rounded text-[10px] font-black uppercase tracking-widest">
                      {code || 'MA-VOUCHER'}
                    </span>
                  </div>
                  
                  <p className="text-xs font-semibold text-slate-600 min-h-[32px] line-clamp-2">
                    {getPreviewText()}
                  </p>
                  
                  <div className="mt-4 pt-3 border-t border-slate-100 flex flex-col gap-1">
                    <div className="flex justify-between items-center text-[10px] font-bold text-slate-400 uppercase tracking-wide">
                      <span>Bắt đầu: {startsAt ? new Date(startsAt).toLocaleString('vi-VN') : 'Ngay lập tức'}</span>
                    </div>
                    <div className="flex justify-between items-center text-[10px] font-bold text-slate-400 uppercase tracking-wide">
                      <span>Hết hạn: {expiresAt ? new Date(expiresAt).toLocaleString('vi-VN') : 'Không giới hạn'}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </form>
        </div>
        
        <div className="flex gap-4 p-8 border-t border-slate-50 bg-white shrink-0">
          <Button type="button" variant="outline" className="flex-1 h-14 rounded-2xl font-black uppercase text-xs border-slate-100 shadow-sm hover:bg-slate-50" onClick={onClose}>Huỷ bỏ</Button>
          <Button type="submit" form="voucher-form" className="flex-1 h-14 rounded-2xl font-black uppercase text-xs shadow-xl shadow-primary/20" isLoading={isSaving}>
            {isSaving ? <Loader2 className="w-6 h-6 animate-spin" /> : (voucher ? 'Lưu thay đổi' : 'Tạo Ưu Đãi')}
          </Button>
        </div>
      </div>
    </div>
  );
};
