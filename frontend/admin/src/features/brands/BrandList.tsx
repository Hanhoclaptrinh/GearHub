import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Plus,
  Search,
  Edit,
  Trash2,
  RefreshCcw,
  AlertCircle,
  Image as ImageIcon,
  X,
  Upload,
  Loader2,
  CheckCircle2,
  EyeOff,
  ShieldCheck,
  LayoutGrid,
  Package
} from 'lucide-react';
import { toast } from 'sonner';
import { brandService } from '../../services/brand.service';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Card, CardContent } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';
import { ConfirmModal } from '../../components/ui/ConfirmModal';
import { cn } from '../../utils/cn';
import type { Brand } from '../../types';

export const BrandList: React.FC = () => {
  const [search, setSearch] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingBrand, setEditingBrand] = useState<Brand | null>(null);
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [brandToDelete, setBrandToDelete] = useState<{ id: string; name: string } | null>(null);

  const queryClient = useQueryClient();

  const { data: brands, isLoading, isError } = useQuery({
    queryKey: ['brands'],
    queryFn: brandService.getAllBrands,
  });

  const createMutation = useMutation({
    mutationFn: (formData: FormData) => brandService.createBrand(formData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['brands'] });
      toast.success('Hệ sinh thái đối tác đã được mở rộng!');
      closeModal();
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Lỗi khi kích hoạt thương hiệu');
    }
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, formData }: { id: string, formData: FormData }) => brandService.updateBrand(id, formData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['brands'] });
      toast.success('Cập nhật dữ liệu đối tác thành công');
      closeModal();
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Có lỗi khi đồng bộ dữ liệu');
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => brandService.deleteBrand(id),
    onSuccess: (res: any) => {
      queryClient.invalidateQueries({ queryKey: ['brands'] });
      toast.success(res.message || 'Thay đổi trạng thái thương hiệu thành công');
      setIsConfirmOpen(false);
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Không thể thực hiện thao tác này');
    }
  });

  const toggleMutation = useMutation({
    mutationFn: (id: string) => brandService.toggleBrand(id),
    onSuccess: (res: any) => {
      queryClient.invalidateQueries({ queryKey: ['brands'] });
      toast.success(res.message || 'Cập nhật trạng thái thành công');
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Lỗi khi chuyển đổi trạng thái');
    }
  });

  const filteredBrands = brands?.filter((b: Brand) =>
    b.name.toLowerCase().includes(search.toLowerCase())
  ) || [];

  const openModal = (brand?: Brand) => {
    if (brand) setEditingBrand(brand);
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setEditingBrand(null);
  };

  const handleDelete = (id: string, name: string) => {
    setBrandToDelete({ id, name });
    setIsConfirmOpen(true);
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {[
          { label: 'Tổng thương hiệu', value: brands?.length || 0, icon: LayoutGrid, color: 'slate', trend: 'Hệ sinh thái' },
          { label: 'Đang hoạt động', value: brands?.filter((b: Brand) => b.isActive).length || 0, icon: CheckCircle2, color: 'green', trend: 'Sẵn sàng' },
          { label: 'Tạm ngưng', value: brands?.filter((b: Brand) => !b.isActive).length || 0, icon: EyeOff, color: 'orange', trend: 'Lưu trữ' },
          { label: 'Tổng sản phẩm', value: brands?.reduce((acc: number, curr: Brand) => acc + (curr._count?.products || 0), 0) || 0, icon: Package, color: 'blue', trend: 'Sản lượng' }
        ].map((stat, i) => (
          <Card key={i} className="border-none shadow-xl shadow-slate-200/40 rounded-[28px] overflow-hidden group transition-all bg-white hover:shadow-2xl hover:shadow-slate-200/60">
            <CardContent className="p-6">
              <div className="flex justify-between items-start mb-6">
                <div className={cn(
                  "w-12 h-12 rounded-2xl flex items-center justify-center transition-transform group-hover:rotate-12 duration-300",
                  stat.color === 'slate' ? "bg-slate-50 text-slate-400" :
                    stat.color === 'green' ? "bg-green-50 text-green-500" :
                      stat.color === 'blue' ? "bg-blue-50 text-blue-500" :
                        "bg-orange-50 text-orange-500"
                )}>
                  <stat.icon size={24} />
                </div>
                <span className={cn(
                  "text-[9px] font-black px-2.5 py-1 rounded-full uppercase tracking-tighter shadow-sm",
                  stat.color === 'slate' ? "bg-slate-50 text-slate-400" :
                    stat.color === 'green' ? "bg-green-50 text-green-500" :
                      stat.color === 'blue' ? "bg-blue-50 text-blue-500" :
                        "bg-orange-50 text-orange-500"
                )}>
                  {stat.trend}
                </span>
              </div>
              <div className="space-y-1">
                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{stat.label}</p>
                <div className="flex items-baseline gap-2">
                  <h3 className="text-2xl font-black text-slate-900 tracking-tight">{stat.value}</h3>
                  <span className="text-[10px] font-bold text-slate-300 uppercase">{stat.color === 'blue' ? 'Món' : 'Brands'}</span>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-black text-slate-900 font-heading leading-tight tracking-tight">Đối tác thương hiệu</h1>
          <p className="text-sm font-bold text-slate-400 uppercase tracking-widest">Hiển thị {filteredBrands.length} thương hiệu theo bộ lọc</p>
        </div>
        <Button onClick={() => openModal()} className="md:w-auto w-full group h-14 px-8 rounded-2xl shadow-xl shadow-primary/20">
          <Plus className="w-6 h-6 mr-2 group-hover:rotate-90 transition-transform" />
          Kích hoạt Brand mới
        </Button>
      </div>

      <Card className="border-none shadow-xl shadow-slate-200/50 rounded-3xl">
        <CardContent className="p-4">
          <div className="flex flex-col md:flex-row gap-4 items-center">
            <div className="relative flex-1 w-full group">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-primary transition-colors" />
              <Input
                placeholder="Tra cứu thương hiệu..."
                className="pl-12 py-3 h-12 rounded-2xl bg-slate-50 border-none ring-0 focus:ring-4 focus:ring-primary/5 transition-all text-sm font-bold shadow-inner"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <Button variant="outline" className="px-6 h-12 rounded-2xl border-slate-100 hover:border-primary transition-all bg-white" onClick={() => queryClient.invalidateQueries({ queryKey: ['brands'] })}>
              <RefreshCcw className={cn("w-5 h-5", isLoading && "animate-spin")} />
            </Button>
          </div>
        </CardContent>
      </Card>

      <div className="bg-white rounded-[40px] shadow-2xl shadow-slate-200/50 border border-slate-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[800px]">
            <thead className="bg-slate-50/50 border-b border-slate-100">
              <tr>
                <th className="px-10 py-6 text-xs font-black text-slate-500 uppercase tracking-widest pl-12">Logo</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-widest">Thương hiệu</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-widest text-center">Sản lượng</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-widest text-center">Trạng thái</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-widest text-center">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 font-body">
              {isLoading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td colSpan={4} className="px-12 py-8 bg-slate-50/20" />
                  </tr>
                ))
              ) : filteredBrands.length > 0 ? (
                filteredBrands.map((brand: Brand) => (
                  <tr key={brand.id} className="hover:bg-slate-50 transition-all group">
                    <td className="px-10 py-6 pl-12">
                      <div className="w-14 h-14 bg-white rounded-2xl border border-slate-200 flex items-center justify-center p-3 group-hover:scale-110 transition-transform shadow-sm overflow-hidden">
                        {brand.logoUrl ? <img src={brand.logoUrl} alt={brand.name} className="w-full h-full object-contain" /> : <ImageIcon size={24} className="text-slate-200" />}
                      </div>
                    </td>
                    <td className="px-6 py-6">
                      <span className="font-black text-slate-900 group-hover:text-primary transition-colors text-lg tracking-tighter">{brand.name}</span>
                    </td>
                    <td className="px-6 py-6 text-center">
                      <div className="flex flex-col items-center">
                        <span className="text-xl font-black text-slate-900 tracking-tighter">{brand._count?.products || 0}</span>
                        <span className="text-[10px] font-bold text-slate-300 uppercase">Sản phẩm</span>
                      </div>
                    </td>
                    <td className="px-6 py-6 text-center">
                      <div className="flex justify-center">
                        {brand.isActive ? (
                          <Badge variant="success" className="gap-1.5 h-8 px-4 rounded-full font-black uppercase text-[10px] tracking-widest shadow-sm">
                            <CheckCircle2 className="w-3.5 h-3.5" /> Hoạt động
                          </Badge>
                        ) : (
                          <Badge variant="danger" className="gap-1.5 h-8 px-4 rounded-full font-black uppercase text-[10px] tracking-widest shadow-sm">
                            <EyeOff className="w-3.5 h-3.5" /> Tạm ngưng
                          </Badge>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-6 text-center">
                      <div className="flex items-center justify-center gap-2">
                        <Button
                          variant="ghost"
                          className={cn(
                            "p-3 h-12 w-12 rounded-2xl border-none transition-all shadow-sm",
                            brand.isActive ? "text-orange-500 hover:bg-orange-50" : "text-green-500 hover:bg-green-50"
                          )}
                          onClick={() => toggleMutation.mutate(brand.id)}
                          isLoading={toggleMutation.isPending && toggleMutation.variables === brand.id}
                          title={brand.isActive ? "Ngưng hoạt động" : "Kích hoạt lại"}
                        >
                          {brand.isActive ? <EyeOff className="w-5 h-5" /> : <ShieldCheck className="w-5 h-5" />}
                        </Button>
                        <Button variant="ghost" className="p-3 h-12 w-12 text-primary hover:bg-primary/5 rounded-2xl border-none transition-all shadow-sm" onClick={() => openModal(brand)}>
                          <Edit className="w-5 h-5" />
                        </Button>
                        <Button
                          variant="ghost"
                          className="p-3 h-12 w-12 text-red-500 hover:bg-red-50 rounded-2xl border-none transition-all shadow-sm"
                          onClick={() => handleDelete(brand.id, brand.name)}
                          isLoading={deleteMutation.isPending && deleteMutation.variables === brand.id}
                        >
                          <Trash2 className="w-5 h-5" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} className="px-6 py-32 text-center text-slate-300 font-black uppercase tracking-widest text-xl opacity-40">
                    Empty Brand Library
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
          <p className="text-xl font-black uppercase">Lỗi đồng bộ dữ liệu đối tác</p>
        </div>
      )}

      {isModalOpen && (
        <BrandFormModal
          brand={editingBrand}
          onClose={closeModal}
          onSave={(fd) => editingBrand ? updateMutation.mutate({ id: editingBrand.id, formData: fd }) : createMutation.mutate(fd)}
          isSaving={createMutation.isPending || updateMutation.isPending}
        />
      )}

      <ConfirmModal
        isOpen={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={() => brandToDelete && deleteMutation.mutate(brandToDelete.id)}
        title="Xác nhận xử lý"
        message={`Bạn có chắn chắn muốn thực hiện thao tác với thương hiệu "${brandToDelete?.name}"? Hệ thống sẽ ưu tiên ngưng kinh doanh nếu đang còn sản phẩm liên kết.`}
        confirmText="Xác nhận"
        cancelText="Để tôi xem lại"
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
};

interface ModalProps {
  brand: Brand | null;
  onClose: () => void;
  onSave: (fd: FormData) => void;
  isSaving: boolean;
}

const BrandFormModal: React.FC<ModalProps> = ({ brand, onClose, onSave, isSaving }) => {
  const [name, setName] = useState(brand?.name || '');
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(brand?.logoUrl || null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selected = e.target.files?.[0];
    if (selected) {
      setFile(selected);
      setPreview(URL.createObjectURL(selected));
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const fd = new FormData();
    fd.append('name', name);
    // Removed Slug & Description as they are handled/not-present in backend Brand DTO
    if (file) fd.append('file', file);
    onSave(fd);
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-xl animate-in fade-in duration-300">
      <div className="bg-white w-full max-w-md rounded-[48px] shadow-2xl overflow-hidden animate-in zoom-in-95 duration-300 border border-white">
        <div className="p-10 border-b border-slate-50 flex items-center justify-between">
          <h2 className="text-2xl font-black text-slate-900 font-heading tracking-tighter uppercase">{brand ? 'Cập nhật đối tác' : 'Thiết lập brand'}</h2>
          <button onClick={onClose} className="p-3 rounded-full hover:bg-slate-50 transition-all border border-transparent hover:border-slate-100">
            <X className="w-7 h-7 text-slate-400" />
          </button>
        </div>
        <form onSubmit={handleSubmit} className="p-10 space-y-8">
          <div className="flex justify-center">
            <div
              className="relative w-32 h-32 rounded-[32px] border-2 border-dashed border-slate-200 bg-slate-50 flex flex-col items-center justify-center overflow-hidden cursor-pointer hover:border-primary transition-all group shadow-inner"
              onClick={() => document.getElementById('logo-upload')?.click()}
            >
              {preview ? (
                <img src={preview} alt="Preview" className="w-full h-full object-contain p-2" />
              ) : (
                <div className="flex flex-col items-center">
                  <Upload className="w-8 h-8 text-slate-300 group-hover:text-primary transition-colors" />
                  <span className="text-[10px] font-black text-slate-400 uppercase mt-2 shadow-sm">Add Logo</span>
                </div>
              )}
              <input id="logo-upload" type="file" className="hidden" accept=".svg,.png,.jpg,.jpeg,.webp,image/svg+xml,image/png,image/jpeg,image/webp" onChange={handleFileChange} />
            </div>
          </div>

          <div className="space-y-4">
            <Input label="Tên thương hiệu" placeholder="Ví dụ: Logitech, Samsung..." value={name} onChange={(e) => setName(e.target.value)} required
              className="h-14 rounded-2xl bg-slate-50 border-none shadow-inner font-black text-lg"
            />
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">*Slug và Metadata sẽ được khởi tạo tự động</p>
          </div>

          <div className="flex gap-4 pt-4">
            <Button type="button" variant="outline" className="flex-1 h-14 rounded-2xl font-black uppercase text-xs border-slate-100 shadow-sm" onClick={onClose}>Huỷ bỏ</Button>
            <Button type="submit" className="flex-1 h-14 rounded-2xl font-black uppercase text-xs shadow-xl shadow-primary/20" isLoading={isSaving}>
              {isSaving ? <Loader2 className="w-6 h-6 animate-spin" /> : (brand ? 'Cập nhật' : 'Kick-off Brand')}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
};
