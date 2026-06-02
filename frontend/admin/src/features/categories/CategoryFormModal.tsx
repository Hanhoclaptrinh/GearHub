import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ChevronDown, FolderTree, Hash, ImagePlus, Layers, UploadCloud, Wand2, X } from '../../components/ui/IconlyIcons';
import { Button } from '../../components/ui/Button';
import { categoryService } from '../../services/category.service';
import type { Category } from '../../types';

interface CategoryFormModalProps {
  category: Category | null;
  onClose: () => void;
  onSave: (fd: FormData) => void;
  isSaving: boolean;
}

const fieldLabelClass = 'text-[11px] font-extrabold text-[#7c8db5] uppercase tracking-wide';
const fieldClass =
  'w-full rounded-[8px] border border-[#dce7f1] bg-white text-sm font-bold text-[#25396f] outline-none transition-all placeholder:text-[#a8b4c7] focus:border-primary focus:ring-4 focus:ring-primary/10';

const buildSlug = (value: string) =>
  value
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[đĐ]/g, 'd')
    .replace(/([^a-z0-9\s])/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-+|-+$/g, '');

export const CategoryFormModal: React.FC<CategoryFormModalProps> = ({ category, onClose, onSave, isSaving }) => {
  const [name, setName] = useState(category?.name || '');
  const [description, setDescription] = useState(category?.description || '');
  const [parentId, setParentId] = useState(category?.parentId || '');
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(category?.iconUrl || null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const isEditing = Boolean(category);

  const { data: parentCategories = [] } = useQuery({
    queryKey: ['categories'],
    queryFn: categoryService.getAllCategories,
  });

  const slugPreview = useMemo(() => buildSlug(name || category?.slug || ''), [category?.slug, name]);
  const selectedParent = parentCategories.find((item) => item.id === parentId);
  const currentProductCount = category?._count?.products ?? 0;

  useEffect(() => {
    return () => {
      if (preview?.startsWith('blob:')) URL.revokeObjectURL(preview);
    };
  }, [preview]);

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const selected = event.target.files?.[0];
    if (!selected) return;

    setFile(selected);
    setPreview(URL.createObjectURL(selected));
  };

  const handleSubmit = (event: React.FormEvent) => {
    event.preventDefault();

    const formData = new FormData();
    formData.append('name', name.trim());
    if (description.trim()) formData.append('description', description.trim());
    if (parentId) formData.append('parentId', parentId);
    if (file) formData.append('file', file);
    onSave(formData);
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-[#172033]/45 p-4 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="flex max-h-[92vh] w-full max-w-3xl flex-col overflow-hidden rounded-[14px] border border-[#dce7f1] bg-white shadow-[0_24px_70px_rgba(25,42,70,0.24)] animate-in zoom-in-95 duration-200">
        <div className="flex shrink-0 items-start justify-between gap-4 border-b border-[#edf2f7] bg-[#fbfcff] px-6 py-5">
          <div className="flex min-w-0 items-start gap-4">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[10px] bg-primary/10 text-primary">
              <FolderTree className="h-5 w-5" />
            </div>
            <div className="min-w-0">
              <div className="mb-1 flex flex-wrap items-center gap-2">
                <h2 className="text-[20px] font-extrabold leading-tight text-[#25396f]">
                  {isEditing ? 'Cập nhật danh mục' : 'Tạo danh mục mới'}
                </h2>
                <span className="rounded-[6px] bg-white px-2.5 py-1 text-[11px] font-extrabold text-[#7c8db5] ring-1 ring-[#dce7f1]">
                  {isEditing ? 'EDIT' : 'NEW'}
                </span>
              </div>
              <p className="text-sm font-semibold text-[#7c8db5]">
                Slug sẽ tự đồng bộ theo tên danh mục khi lưu.
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

        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto">
          <div className="grid grid-cols-1 gap-0 lg:grid-cols-[260px_1fr]">
            <aside className="border-b border-[#edf2f7] bg-[#fbfcff] p-6 lg:border-b-0 lg:border-r">
              <div className="space-y-4">
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="group flex aspect-square w-full items-center justify-center overflow-hidden rounded-[12px] border border-dashed border-[#c8d5e5] bg-white transition-all hover:border-primary hover:bg-primary/5"
                >
                  {preview ? (
                    <img src={preview} alt="Category icon preview" className="h-full w-full object-contain p-5" />
                  ) : (
                    <div className="flex flex-col items-center gap-3 text-center">
                      <span className="flex h-12 w-12 items-center justify-center rounded-[10px] bg-[#f2f7ff] text-primary transition-transform group-hover:scale-105">
                        <ImagePlus className="h-6 w-6" />
                      </span>
                      <span className="text-xs font-extrabold uppercase tracking-wide text-[#7c8db5]">Tải icon</span>
                    </div>
                  )}
                </button>
                <input ref={fileInputRef} type="file" className="hidden" accept="image/*" onChange={handleFileChange} />

                <Button
                  type="button"
                  variant="outline"
                  onClick={() => fileInputRef.current?.click()}
                  className="h-10 w-full rounded-[8px] border border-[#dce7f1] bg-white text-sm font-extrabold text-primary shadow-none hover:bg-primary/5"
                >
                  <UploadCloud className="mr-2 h-4 w-4" />
                  Chọn ảnh
                </Button>

                <div className="rounded-[10px] border border-[#edf2f7] bg-white p-4">
                  <p className="mb-2 text-[11px] font-extrabold uppercase tracking-wide text-[#7c8db5]">Preview</p>
                  <div className="flex items-center gap-3">
                    <div className="flex h-11 w-11 shrink-0 items-center justify-center overflow-hidden rounded-[10px] border border-[#dce7f1] bg-[#f2f7ff]">
                      {preview ? (
                        <img src={preview} alt="" className="h-full w-full object-contain" />
                      ) : (
                        <Hash className="h-5 w-5 text-[#a8b4c7]" />
                      )}
                    </div>
                    <div className="min-w-0">
                      <p className="mb-1 truncate text-sm font-extrabold text-[#25396f]">{name || 'Tên danh mục'}</p>
                      <p className="mb-0 truncate text-xs font-bold text-[#7c8db5]">/{slugPreview || 'slug-tu-dong'}</p>
                    </div>
                  </div>
                </div>

                {isEditing && (
                  <div className="grid grid-cols-2 gap-3">
                    <div className="rounded-[10px] border border-[#edf2f7] bg-white p-3">
                      <p className="mb-1 text-[10px] font-extrabold uppercase text-[#7c8db5]">Sản phẩm</p>
                      <p className="text-lg font-extrabold leading-none text-[#25396f]">{currentProductCount}</p>
                    </div>
                    <div className="rounded-[10px] border border-[#edf2f7] bg-white p-3">
                      <p className="mb-1 text-[10px] font-extrabold uppercase text-[#7c8db5]">Cấp</p>
                      <p className="truncate text-sm font-extrabold text-[#25396f]">{parentId ? 'Con' : 'Gốc'}</p>
                    </div>
                  </div>
                )}
              </div>
            </aside>

            <div className="space-y-5 p-6">
              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div className="md:col-span-2">
                  <label className={fieldLabelClass}>Tên danh mục</label>
                  <input
                    value={name}
                    onChange={(event) => setName(event.target.value)}
                    required
                    maxLength={100}
                    placeholder="Laptop gaming, Bàn phím cơ..."
                    className={`${fieldClass} mt-2 h-11 px-4`}
                  />
                </div>

                <div className="md:col-span-2">
                  <label className={fieldLabelClass}>Danh mục cấp cha</label>
                  <div className="relative mt-2">
                    <select
                      className={`${fieldClass} h-11 appearance-none px-4 pr-10 cursor-pointer`}
                      value={parentId}
                      onChange={(event) => setParentId(event.target.value)}
                    >
                      <option value="">Là danh mục gốc</option>
                      {parentCategories.filter((item) => item.id !== category?.id).map((item) => (
                        <option key={item.id} value={item.id}>{item.name}</option>
                      ))}
                    </select>
                    <ChevronDown className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[#7c8db5]" />
                  </div>
                </div>

                <div className="md:col-span-2">
                  <div className="flex items-center justify-between gap-3">
                    <label className={fieldLabelClass}>Slug tự sinh</label>
                    <button
                      type="button"
                      onClick={() => setName(name.trim())}
                      className="inline-flex h-8 items-center gap-1.5 rounded-[6px] bg-[#f2f7ff] px-3 text-[11px] font-extrabold text-primary transition-colors hover:bg-primary/10"
                    >
                      <Wand2 className="h-3.5 w-3.5" />
                      Làm gọn
                    </button>
                  </div>
                  <div className="mt-2 flex h-11 items-center gap-2 rounded-[8px] border border-[#dce7f1] bg-[#f8fbff] px-4 text-sm font-extrabold text-[#607080]">
                    <Hash className="h-4 w-4 text-[#a8b4c7]" />
                    <span className="truncate">/{slugPreview || 'slug-tu-dong'}</span>
                  </div>
                </div>

                <div className="md:col-span-2">
                  <label className={fieldLabelClass}>Mô tả</label>
                  <textarea
                    className={`${fieldClass} mt-2 min-h-[118px] resize-none p-4 font-semibold leading-6`}
                    placeholder="Mô tả ngắn giúp đội vận hành nhận diện nhóm sản phẩm nhanh hơn..."
                    value={description}
                    onChange={(event) => setDescription(event.target.value)}
                  />
                </div>
              </div>

              <div className="rounded-[10px] border border-[#edf2f7] bg-[#fbfcff] p-4">
                <div className="flex gap-3">
                  <div className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-[8px] bg-primary/10 text-primary">
                    <Layers className="h-4 w-4" />
                  </div>
                  <div className="min-w-0">
                    <p className="mb-1 text-sm font-extrabold text-[#25396f]">
                      {parentId ? `Nằm trong ${selectedParent?.name || 'danh mục đã chọn'}` : 'Hiển thị như danh mục gốc'}
                    </p>
                    <p className="mb-0 text-xs font-semibold leading-5 text-[#7c8db5]">
                      Danh mục gốc sẽ gom nhóm các danh mục con trên bảng quản trị. Danh mục con nên dùng cho nhóm sản phẩm cụ thể.
                    </p>
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
              disabled={!name.trim()}
            >
              {isEditing ? 'Lưu thay đổi' : 'Tạo danh mục'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
};
