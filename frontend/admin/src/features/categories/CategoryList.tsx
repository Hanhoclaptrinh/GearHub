import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  Plus, 
  Search, 
  Edit, 
  Trash2, 
  RefreshCcw,
  AlertCircle,
  Hash,
  X,
} from 'lucide-react';
import { categoryService } from '../../services/category.service';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Card, CardContent } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';
import { cn } from '../../utils/cn';
import type { Category } from '../../types';

export const CategoryList: React.FC = () => {
  const [search, setSearch] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  
  const queryClient = useQueryClient();

  const { data: categories, isLoading, isError } = useQuery({
    queryKey: ['categories'],
    queryFn: categoryService.getAllCategories,
  });

  const createMutation = useMutation({
    mutationFn: (formData: FormData) => categoryService.createCategory(formData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] });
      closeModal();
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, formData }: { id: string, formData: FormData }) => categoryService.updateCategory(id, formData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] });
      closeModal();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => categoryService.deleteCategory(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] });
    },
    onError: (error: any) => {
        alert(error.response?.data?.message || 'Không thể xoá danh mục này. Vui lòng kiểm tra các danh mục con hoặc sản phẩm liên quan.');
    }
  });

  const filteredCategories = categories?.filter((c: Category) => 
    c.name.toLowerCase().includes(search.toLowerCase())
  ) || [];

  const openModal = (category?: Category) => {
    if (category) setEditingCategory(category);
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setEditingCategory(null);
  };

  const handleDelete = (id: string, name: string) => {
    if (window.confirm(`Bạn có chắc muốn xóa danh mục "${name}"? Thao tác này không thể hoàn tác.`)) {
      deleteMutation.mutate(id);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 font-heading leading-tight">Quản lý danh mục</h1>
          <p className="text-sm font-bold text-slate-400 uppercase tracking-widest italic">Cấu trúc phân loại hệ thống ({filteredCategories.length})</p>
        </div>
        <Button onClick={() => openModal()} className="md:w-auto w-full group h-12 rounded-2xl shadow-lg shadow-primary/20">
          <Plus className="w-5 h-5 mr-2 group-hover:rotate-90 transition-transform" />
          Thiết lập nhóm mới
        </Button>
      </div>

      <Card className="border-none shadow-xl shadow-slate-200/50 rounded-3xl">
        <CardContent className="p-4">
           <div className="flex flex-col md:flex-row gap-4 items-center">
             <div className="relative flex-1 w-full group">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-primary transition-colors" />
                <Input 
                  placeholder="Tìm kiếm phân loại..." 
                  className="pl-12 py-3 h-12 rounded-2xl bg-slate-50 border-none ring-0 focus:ring-4 focus:ring-primary/5 transition-all text-sm font-bold"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                />
             </div>
             <Button 
               variant="outline" 
               className="px-6 h-12 rounded-2xl border-slate-100 hover:border-primary transition-all bg-white shadow-sm" 
               onClick={() => queryClient.invalidateQueries({ queryKey: ['categories'] })}
               isLoading={isLoading}
             >
                <RefreshCcw className={cn("w-5 h-5", isLoading && "animate-spin")} />
             </Button>
           </div>
        </CardContent>
      </Card>

      <div className="bg-white rounded-[40px] shadow-2xl shadow-slate-200/50 border border-slate-100/50 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[800px]">
            <thead className="bg-slate-50/50 border-b border-slate-100">
              <tr>
                <th className="px-10 py-6 text-xs font-black text-slate-500 uppercase tracking-tighter pl-12">Visual</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-tighter">Tên Phân Loại</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-tighter">Slug</th>
                <th className="px-6 py-6 text-xs font-black text-slate-500 uppercase tracking-tighter text-center">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 font-body">
              {isLoading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td colSpan={4} className="px-12 py-8 bg-slate-50/20" />
                  </tr>
                ))
              ) : filteredCategories.length > 0 ? (
                filteredCategories.map((category: Category) => (
                  <tr key={category.id} className="hover:bg-slate-50/50 transition-all group">
                    <td className="px-10 py-6 pl-12">
                       <div className="w-14 h-14 bg-white rounded-2xl border border-slate-200 flex items-center justify-center p-2 group-hover:scale-110 transition-transform shadow-sm group-hover:shadow-md overflow-hidden">
                          {category.iconUrl ? (
                             <img src={category.iconUrl} alt={category.name} className="w-full h-full object-contain" />
                          ) : (
                             <span className="text-2xl drop-shadow-sm">{category.icon || <Hash size={24} className="text-slate-200" />}</span>
                          )}
                       </div>
                    </td>
                    <td className="px-6 py-6">
                       <div className="flex flex-col">
                          <span className="font-black text-slate-900 group-hover:text-primary transition-colors text-lg italic tracking-tighter">{category.name}</span>
                          <span className="text-[10px] font-black text-slate-300 uppercase mt-0.5">Hash ID: {category.id.slice(-8).toUpperCase()}</span>
                       </div>
                    </td>
                    <td className="px-6 py-6">
                       <Badge variant="default" className="bg-slate-50 text-slate-400 border border-slate-100 font-black h-8 px-4 rounded-full flex items-center w-fit shadow-sm">
                          {category.slug}
                       </Badge>
                    </td>
                    <td className="px-6 py-6">
                       <div className="flex items-center justify-center gap-3">
                          <Button 
                            variant="ghost" 
                            className="p-3 h-12 w-12 text-blue-500 hover:bg-blue-50 rounded-2xl border-none transition-all" 
                            onClick={() => openModal(category)}
                          >
                            <Edit className="w-5 h-5" />
                          </Button>
                          <Button 
                            variant="ghost" 
                            className="p-3 h-12 w-12 text-red-500 hover:bg-red-50 rounded-2xl border-none transition-all"
                            onClick={() => handleDelete(category.id, category.name)}
                            isLoading={deleteMutation.isPending && deleteMutation.variables === category.id}
                          >
                            <Trash2 className="w-5 h-5" />
                          </Button>
                       </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={4} className="px-10 py-32 text-center opacity-30 grayscale font-black uppercase italic tracking-widest text-slate-300">
                    Empty Category Library
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
          <div>
              <p className="text-xl font-black text-red-700 uppercase italic">Tài nguyên không sẵn sàng</p>
              <p className="text-sm font-bold opacity-70">Có lỗi khi kết nối với máy chủ dữ liệu.</p>
          </div>
        </div>
      )}

      {isModalOpen && (
        <CategoryFormModal 
          category={editingCategory} 
          onClose={closeModal} 
          onSave={(fd) => editingCategory ? updateMutation.mutate({ id: editingCategory.id, formData: fd }) : createMutation.mutate(fd)}
          isSaving={createMutation.isPending || updateMutation.isPending}
        />
      )}
    </div>
  );
};

interface FormProps {
  category: Category | null;
  onClose: () => void;
  onSave: (fd: FormData) => void;
  isSaving: boolean;
}

const CategoryFormModal: React.FC<FormProps> = ({ category, onClose, onSave, isSaving }) => {
  const [name, setName] = useState(category?.name || '');
  const [slug, setSlug] = useState(category?.slug || '');
  const [icon, setIcon] = useState(category?.icon || '');
  const [description, setDescription] = useState(category?.description || '');
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(category?.iconUrl || null);

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
    if (description) fd.append('description', description);
    // parentId can be added here if needed, but current UI doesn't have it
    // Icon text is removed to avoid 400 Bad Request
    if (file) fd.append('file', file);
    onSave(fd);
  };

  const generateSlug = () => {
    setSlug(name.toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[đĐ]/g, 'd')
      .replace(/([^a-z0-9\s])/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-+|-+$/g, '')
    );
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-xl animate-in fade-in duration-300">
      <div className="bg-white w-full max-w-lg rounded-[48px] shadow-2xl overflow-hidden animate-in zoom-in-95 duration-300 border border-white">
        <div className="p-10 border-b border-slate-50 flex items-center justify-between">
            <h2 className="text-2xl font-black text-slate-900 font-heading italic tracking-tighter uppercase">{category ? 'Cập nhật phân loại' : 'Thiết lập danh mục mới'}</h2>
            <button onClick={onClose} className="p-3 rounded-full hover:bg-slate-50 transition-all">
               <X className="w-7 h-7 text-slate-300" />
            </button>
        </div>
        <form onSubmit={handleSubmit} className="p-10 space-y-8">
           <div className="flex justify-center">
              <div 
                className="relative w-24 h-24 rounded-3xl bg-slate-50 border-2 border-dashed border-slate-200 flex items-center justify-center cursor-pointer hover:border-primary transition-all overflow-hidden group shadow-inner"
                onClick={() => document.getElementById('icon-upload')?.click()}
              >
                  {preview ? (
                     <img src={preview} alt="Icon" className="w-full h-full object-contain" />
                  ) : (
                     <div className="flex flex-col items-center">
                        <UploadIcon className="w-6 h-6 text-slate-300 group-hover:text-primary transition-colors" />
                        <span className="text-[8px] font-black text-slate-400 mt-1 uppercase">Upload Image</span>
                     </div>
                  )}
                  <input id="icon-upload" type="file" className="hidden" accept="image/*" onChange={handleFileChange} />
              </div>
           </div>

           <div className="space-y-6">
              <div className="grid grid-cols-4 gap-4">
                 <div className="col-span-1">
                    <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1 mb-2 block">Icon Text</label>
                    <input 
                      className="w-full h-14 text-center text-2xl bg-slate-50 border-none rounded-2xl outline-none focus:ring-4 focus:ring-primary/10 transition-all shadow-inner font-black" 
                      placeholder="💻"
                      value={icon}
                      maxLength={2}
                      onChange={(e) => setIcon(e.target.value)}
                    />
                 </div>
                 <div className="col-span-3">
                    <Input label="Tên danh mục" placeholder="Laptop, Keyboard..." value={name} onChange={(e) => setName(e.target.value)} required 
                      className="h-14 rounded-2xl bg-slate-50 border-none shadow-inner font-black" 
                    />
                 </div>
              </div>
              
              <div className="relative group">
                 <Input label="Slug" placeholder="laptop-gaming" value={slug} onChange={(e) => setSlug(e.target.value)} required 
                   className="h-14 rounded-2xl bg-slate-50 border-none shadow-inner font-bold"
                 />
                 <button 
                   type="button" 
                   onClick={generateSlug} 
                   className="absolute right-4 top-[42px] text-[10px] font-black text-primary hover:text-primary-600 transition-colors uppercase tracking-widest"
                 >
                    Auto Generate
                 </button>
              </div>

              <div className="space-y-2">
                <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Mô tả (Tùy chọn)</label>
                <textarea 
                  className="w-full h-24 p-4 border-none bg-slate-50 rounded-2xl outline-none focus:ring-4 focus:ring-primary/10 transition-all font-body text-sm font-bold shadow-inner resize-none" 
                  placeholder="Nhập ghi chú hoặc mô tả..."
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                />
              </div>
           </div>

           <div className="flex gap-4 pt-4">
              <Button type="button" variant="outline" className="flex-1 h-14 rounded-2xl font-black uppercase text-xs" onClick={onClose}>Huỷ bỏ</Button>
              <Button type="submit" className="flex-1 h-14 rounded-2xl font-black uppercase text-xs shadow-xl shadow-primary/20" isLoading={isSaving}>
                 {category ? 'Lưu thay đổi' : 'Tạo phân loại'}
              </Button>
           </div>
        </form>
      </div>
    </div>
  );
};

const UploadIcon = ({ className }: { className?: string }) => (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
    </svg>
);
