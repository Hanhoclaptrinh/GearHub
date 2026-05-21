import React, { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Plus, Search, Edit, Trash2, RefreshCcw, AlertCircle, Eye, 
  Tag, Clock, CheckCircle2, EyeOff, ShieldCheck, Ticket
} from 'lucide-react';
import { toast } from 'sonner';
import { voucherService } from '../../services/voucher.service';
import { authService } from '../../services/auth.service';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Card, CardContent } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';
import { ConfirmModal } from '../../components/ui/ConfirmModal';
import { VoucherFormModal } from './VoucherFormModal';
import { VoucherDetailModal } from './VoucherDetailModal';
import { cn } from '../../utils/cn';
import { VoucherType, Role } from '../../types';
import type { Voucher } from '../../types';

export const VoucherList: React.FC = () => {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'DISABLED' | 'EXPIRED' | 'UPCOMING'>('ALL');
  const [typeFilter, setTypeFilter] = useState<'ALL' | VoucherType>('ALL');
  
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingVoucher, setEditingVoucher] = useState<Voucher | null>(null);
  
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [viewingVoucher, setViewingVoucher] = useState<Voucher | null>(null);
  
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [voucherToDelete, setVoucherToDelete] = useState<{ id: string; code: string } | null>(null);

  const queryClient = useQueryClient();
  const user = authService.getCurrentUser();
  const isAdmin = user?.role === Role.ADMIN;

  const { data: vouchers, isLoading, isError } = useQuery({
    queryKey: ['vouchers'],
    queryFn: voucherService.getAllVouchers,
  });

  const createMutation = useMutation({
    mutationFn: voucherService.createVoucher,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vouchers'] });
      toast.success('Ưu đãi mới đã được tạo thành công!');
      closeForm();
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Có lỗi khi tạo ưu đãi');
    }
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string, payload: any }) => voucherService.updateVoucher(id, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vouchers'] });
      toast.success('Cập nhật ưu đãi thành công!');
      closeForm();
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Có lỗi khi cập nhật ưu đãi');
    }
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, isActive }: { id: string, isActive: boolean }) => voucherService.toggleVoucherStatus(id, isActive),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vouchers'] });
      toast.success('Cập nhật trạng thái thành công!');
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Có lỗi khi cập nhật trạng thái');
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => voucherService.deleteVoucher(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vouchers'] });
      toast.success('Đã xóa ưu đãi thành công!');
      setIsConfirmOpen(false);
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Có lỗi khi xóa ưu đãi');
    }
  });

  const getVoucherStatus = (v: Voucher) => {
    const now = new Date();
    if (!v.isActive) return 'DISABLED';
    if (v.expiresAt && new Date(v.expiresAt) < now) return 'EXPIRED';
    if (v.startsAt && new Date(v.startsAt) > now) return 'UPCOMING';
    return 'ACTIVE';
  };

  const filteredVouchers = useMemo(() => {
    if (!vouchers) return [];
    return vouchers.filter(v => {
      const matchSearch = v.code.toLowerCase().includes(search.toLowerCase()) || v.name.toLowerCase().includes(search.toLowerCase());
      const matchType = typeFilter === 'ALL' || v.type === typeFilter;
      const matchStatus = statusFilter === 'ALL' || getVoucherStatus(v) === statusFilter;
      return matchSearch && matchType && matchStatus;
    });
  }, [vouchers, search, typeFilter, statusFilter]);

  const stats = useMemo(() => {
    if (!vouchers) return { total: 0, active: 0, disabled: 0, expired: 0 };
    return vouchers.reduce((acc, v) => {
      acc.total++;
      const status = getVoucherStatus(v);
      if (status === 'ACTIVE') acc.active++;
      else if (status === 'DISABLED') acc.disabled++;
      else if (status === 'EXPIRED') acc.expired++;
      return acc;
    }, { total: 0, active: 0, disabled: 0, expired: 0 });
  }, [vouchers]);

  const openForm = (voucher?: Voucher) => {
    if (voucher) setEditingVoucher(voucher);
    setIsFormOpen(true);
  };

  const closeForm = () => {
    setIsFormOpen(false);
    setEditingVoucher(null);
  };

  const openDetail = (voucher: Voucher) => {
    setViewingVoucher(voucher);
    setIsDetailOpen(true);
  };

  const formatCurrency = (val: number) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {[
          { label: 'Tổng số ưu đãi', value: stats.total, icon: Ticket, color: 'slate', trend: 'Tất cả' },
          { label: 'Đang hoạt động', value: stats.active, icon: CheckCircle2, color: 'green', trend: 'Khả dụng' },
          { label: 'Tạm ngưng', value: stats.disabled, icon: EyeOff, color: 'orange', trend: 'Đã tắt' },
          { label: 'Đã hết hạn', value: stats.expired, icon: Clock, color: 'red', trend: 'Hết hạn' }
        ].map((stat, i) => (
          <Card key={i} className="border-none shadow-xl shadow-slate-200/40 rounded-[28px] overflow-hidden group transition-all bg-white hover:shadow-2xl hover:shadow-slate-200/60">
            <CardContent className="p-6">
              <div className="flex justify-between items-start mb-6">
                <div className={cn(
                  "w-12 h-12 rounded-2xl flex items-center justify-center transition-transform group-hover:rotate-12 duration-300",
                  stat.color === 'slate' ? "bg-slate-50 text-slate-400" :
                  stat.color === 'green' ? "bg-green-50 text-green-500" :
                  stat.color === 'red' ? "bg-red-50 text-red-500" :
                  "bg-orange-50 text-orange-500"
                )}>
                  <stat.icon size={24} />
                </div>
                <span className={cn(
                  "text-[9px] font-black px-2.5 py-1 rounded-full uppercase tracking-tighter shadow-sm",
                  stat.color === 'slate' ? "bg-slate-50 text-slate-400" :
                  stat.color === 'green' ? "bg-green-50 text-green-500" :
                  stat.color === 'red' ? "bg-red-50 text-red-500" :
                  "bg-orange-50 text-orange-500"
                )}>
                  {stat.trend}
                </span>
              </div>
              <div className="space-y-1">
                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{stat.label}</p>
                <div className="flex items-baseline gap-2">
                  <h3 className="text-2xl font-black text-slate-900 tracking-tight">{stat.value}</h3>
                  <span className="text-[10px] font-bold text-slate-300 uppercase">Mã</span>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-black text-slate-900 font-heading leading-tight tracking-tight">Quản lý Ưu đãi</h1>
          <p className="text-sm font-bold text-slate-400 uppercase tracking-widest">Hiển thị {filteredVouchers.length} ưu đãi theo bộ lọc</p>
        </div>
        {isAdmin && (
          <Button onClick={() => openForm()} className="md:w-auto w-full group h-14 px-8 rounded-2xl shadow-xl shadow-primary/20">
            <Plus className="w-6 h-6 mr-2 group-hover:rotate-90 transition-transform" />
            Tạo Voucher mới
          </Button>
        )}
      </div>

      <Card className="border-none shadow-xl shadow-slate-200/50 rounded-3xl">
        <CardContent className="p-4">
          <div className="flex flex-col lg:flex-row gap-4 items-center">
            <div className="relative flex-1 w-full group">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-primary transition-colors" />
              <Input
                placeholder="Tra cứu theo mã, tên ưu đãi..."
                className="pl-12 py-3 h-12 rounded-2xl bg-slate-50 border-none ring-0 focus:ring-4 focus:ring-primary/5 transition-all text-sm font-bold shadow-inner"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <div className="flex gap-4 w-full lg:w-auto">
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value as any)}
                className="h-12 px-4 rounded-2xl bg-slate-50 border-none focus:ring-4 focus:ring-primary/10 transition-all font-bold text-sm shadow-inner outline-none text-slate-700 min-w-[150px]"
              >
                <option value="ALL">Tất cả Trạng thái</option>
                <option value="ACTIVE">Đang hoạt động</option>
                <option value="DISABLED">Tạm ngưng</option>
                <option value="EXPIRED">Đã hết hạn</option>
                <option value="UPCOMING">Sắp tới</option>
              </select>
              <select
                value={typeFilter}
                onChange={(e) => setTypeFilter(e.target.value as any)}
                className="h-12 px-4 rounded-2xl bg-slate-50 border-none focus:ring-4 focus:ring-primary/10 transition-all font-bold text-sm shadow-inner outline-none text-slate-700 min-w-[150px]"
              >
                <option value="ALL">Tất cả Loại</option>
                <option value={VoucherType.PERCENT}>Giảm theo %</option>
                <option value={VoucherType.FIXED_AMOUNT}>Giảm tiền mặt</option>
              </select>
              <Button variant="outline" className="px-6 h-12 rounded-2xl border-slate-100 hover:border-primary transition-all bg-white" onClick={() => queryClient.invalidateQueries({ queryKey: ['vouchers'] })}>
                <RefreshCcw className={cn("w-5 h-5", isLoading && "animate-spin")} />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="bg-white rounded-[40px] shadow-2xl shadow-slate-200/50 border border-slate-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1000px]">
            <thead className="bg-slate-50/50 border-b border-slate-100">
              <tr>
                <th className="px-10 py-6 text-xs font-black text-slate-500 uppercase tracking-widest pl-10">Mã / Tên</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-widest text-center">Giảm giá</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-widest text-center">Số lượng</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-widest text-center">Trạng thái</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-widest text-center">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 font-body">
              {isLoading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td colSpan={5} className="px-12 py-8 bg-slate-50/20" />
                  </tr>
                ))
              ) : filteredVouchers.length > 0 ? (
                filteredVouchers.map((voucher: Voucher) => {
                  const status = getVoucherStatus(voucher);
                  const remaining = Math.max(0, voucher.quantity - voucher.claimedCount);
                  return (
                    <tr key={voucher.id} className="hover:bg-slate-50 transition-all group">
                      <td className="px-10 py-6">
                        <div className="flex items-center gap-4">
                          <div className="w-12 h-12 bg-primary/5 rounded-2xl border border-primary/10 flex items-center justify-center p-3 group-hover:scale-110 transition-transform shadow-sm overflow-hidden shrink-0">
                            <Tag className="w-6 h-6 text-primary" />
                          </div>
                          <div>
                            <span className="font-black text-slate-900 group-hover:text-primary transition-colors text-lg tracking-tighter block">{voucher.code}</span>
                            <span className="text-xs font-bold text-slate-400 block line-clamp-1 max-w-[250px]" title={voucher.name}>{voucher.name}</span>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-6 text-center">
                        <div className="flex flex-col items-center">
                          <span className="text-lg font-black text-slate-900 tracking-tighter">
                            {voucher.type === VoucherType.PERCENT ? `${voucher.value}%` : formatCurrency(voucher.value)}
                          </span>
                          <span className="text-[10px] font-bold text-slate-400 uppercase">
                            Đơn từ {formatCurrency(voucher.minOrderAmount)}
                          </span>
                        </div>
                      </td>
                      <td className="px-6 py-6 text-center">
                        <div className="flex flex-col items-center">
                          <span className="text-lg font-black text-slate-900 tracking-tighter">{remaining}</span>
                          <span className="text-[10px] font-bold text-slate-400 uppercase">Còn lại / {voucher.quantity}</span>
                        </div>
                      </td>
                      <td className="px-6 py-6 text-center">
                        <div className="flex justify-center">
                          {status === 'ACTIVE' ? (
                            <Badge variant="success" className="gap-1.5 h-8 px-4 rounded-full font-black uppercase text-[10px] tracking-widest shadow-sm">
                              <CheckCircle2 className="w-3.5 h-3.5" /> Hoạt động
                            </Badge>
                          ) : status === 'DISABLED' ? (
                            <Badge variant="danger" className="gap-1.5 h-8 px-4 rounded-full font-black uppercase text-[10px] tracking-widest shadow-sm">
                              <EyeOff className="w-3.5 h-3.5" /> Tạm ngưng
                            </Badge>
                          ) : status === 'UPCOMING' ? (
                            <Badge variant="info" className="gap-1.5 h-8 px-4 rounded-full font-black uppercase text-[10px] tracking-widest shadow-sm">
                              <Clock className="w-3.5 h-3.5" /> Sắp tới
                            </Badge>
                          ) : (
                            <Badge variant="warning" className="gap-1.5 h-8 px-4 rounded-full font-black uppercase text-[10px] tracking-widest shadow-sm">
                              <Clock className="w-3.5 h-3.5" /> Hết hạn
                            </Badge>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-6 text-center">
                        <div className="flex items-center justify-center gap-2">
                          <Button variant="ghost" className="p-3 h-12 w-12 text-blue-500 hover:bg-blue-50 rounded-2xl border-none transition-all shadow-sm" onClick={() => openDetail(voucher)}>
                            <Eye className="w-5 h-5" />
                          </Button>
                          
                          {isAdmin && (
                            <>
                              <Button
                                variant="ghost"
                                className={cn(
                                  "p-3 h-12 w-12 rounded-2xl border-none transition-all shadow-sm",
                                  voucher.isActive ? "text-orange-500 hover:bg-orange-50" : "text-green-500 hover:bg-green-50"
                                )}
                                onClick={() => toggleMutation.mutate({ id: voucher.id, isActive: !voucher.isActive })}
                                isLoading={toggleMutation.isPending && toggleMutation.variables?.id === voucher.id}
                                title={voucher.isActive ? "Ngưng hoạt động" : "Kích hoạt lại"}
                              >
                                {voucher.isActive ? <EyeOff className="w-5 h-5" /> : <ShieldCheck className="w-5 h-5" />}
                              </Button>
                              <Button variant="ghost" className="p-3 h-12 w-12 text-primary hover:bg-primary/5 rounded-2xl border-none transition-all shadow-sm" onClick={() => openForm(voucher)}>
                                <Edit className="w-5 h-5" />
                              </Button>
                              <Button
                                variant="ghost"
                                className="p-3 h-12 w-12 text-red-500 hover:bg-red-50 rounded-2xl border-none transition-all shadow-sm"
                                onClick={() => {
                                  setVoucherToDelete({ id: voucher.id, code: voucher.code });
                                  setIsConfirmOpen(true);
                                }}
                                isLoading={deleteMutation.isPending && deleteMutation.variables === voucher.id}
                              >
                                <Trash2 className="w-5 h-5" />
                              </Button>
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={5} className="px-6 py-32 text-center text-slate-300 font-black uppercase tracking-widest text-xl opacity-40">
                    Không tìm thấy ưu đãi
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {isError && (
        <div className="p-8 bg-red-50 border-2 border-red-100 rounded-[40px] flex items-center gap-6 text-red-600 shadow-2xl shadow-red-100/50">
          <AlertCircle className="w-10 h-10" />
          <p className="text-xl font-black uppercase">Lỗi lấy danh sách ưu đãi</p>
        </div>
      )}

      {isFormOpen && (
        <VoucherFormModal
          voucher={editingVoucher}
          onClose={closeForm}
          onSave={(payload) => editingVoucher ? updateMutation.mutate({ id: editingVoucher.id, payload }) : createMutation.mutate(payload as any)}
          isSaving={createMutation.isPending || updateMutation.isPending}
        />
      )}

      {isDetailOpen && viewingVoucher && (
        <VoucherDetailModal
          voucher={viewingVoucher}
          onClose={() => {
            setIsDetailOpen(false);
            setViewingVoucher(null);
          }}
        />
      )}

      <ConfirmModal
        isOpen={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={() => voucherToDelete && deleteMutation.mutate(voucherToDelete.id)}
        title="Xác nhận xử lý"
        message={`Bạn có chắn chắn muốn xóa ưu đãi "${voucherToDelete?.code}"? Thao tác này sẽ vô hiệu hóa ưu đãi đối với các đơn hàng trong tương lai.`}
        confirmText="Xác nhận"
        cancelText="Để tôi xem lại"
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
};
