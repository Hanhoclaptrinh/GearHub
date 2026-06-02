import React, { useEffect, useMemo, useRef, useState } from 'react';
import { ChevronRight, Image as ImageIcon, Quote, Sparkles, UploadCloud, X } from '../../components/ui/IconlyIcons';
import { Button } from '../../components/ui/Button';
import type { Brand } from '../../types';

interface BrandFormModalProps {
  brand: Brand | null;
  isSaving: boolean;
  onClose: () => void;
  onSave: (formData: FormData) => void;
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

const getProductCount = (brand: Brand) => brand._count?.products ?? 0;

export const BrandFormModal: React.FC<BrandFormModalProps> = ({ brand, isSaving, onClose, onSave }) => {
  const [name, setName] = useState(brand?.name || '');
  const [quote, setQuote] = useState(brand?.quote || '');
  const [philosophy, setPhilosophy] = useState(brand?.philosophy || '');
  const [logoFile, setLogoFile] = useState<File | null>(null);
  const [logoPreview, setLogoPreview] = useState<string | null>(brand?.logoUrl || null);
  const [bannerFile, setBannerFile] = useState<File | null>(null);
  const [bannerPreview, setBannerPreview] = useState<string | null>(brand?.bannerUrl || null);
  const logoInputRef = useRef<HTMLInputElement>(null);
  const bannerInputRef = useRef<HTMLInputElement>(null);
  const isEditing = Boolean(brand);

  const slugPreview = useMemo(() => buildSlug(name || brand?.slug || ''), [brand?.slug, name]);
  const score = Math.round(brand?.score ?? 0);

  useEffect(() => {
    return () => {
      if (logoPreview?.startsWith('blob:')) URL.revokeObjectURL(logoPreview);
      if (bannerPreview?.startsWith('blob:')) URL.revokeObjectURL(bannerPreview);
    };
  }, [bannerPreview, logoPreview]);

  const handleLogoChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const selected = event.target.files?.[0];
    if (!selected) return;
    setLogoFile(selected);
    setLogoPreview(URL.createObjectURL(selected));
  };

  const handleBannerChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const selected = event.target.files?.[0];
    if (!selected) return;
    setBannerFile(selected);
    setBannerPreview(URL.createObjectURL(selected));
  };

  const handleSubmit = (event: React.FormEvent) => {
    event.preventDefault();

    const formData = new FormData();
    formData.append('name', name.trim());
    formData.append('quote', quote.trim());
    formData.append('philosophy', philosophy.trim());
    if (logoFile) formData.append('logo', logoFile);
    if (bannerFile) formData.append('banner', bannerFile);
    onSave(formData);
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-[#172033]/45 p-4 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="flex max-h-[92vh] w-full max-w-4xl flex-col overflow-hidden rounded-[14px] border border-[#dce7f1] bg-white shadow-[0_24px_70px_rgba(25,42,70,0.24)] animate-in zoom-in-95 duration-200">
        <div className="flex shrink-0 items-start justify-between gap-4 border-b border-[#edf2f7] bg-[#fbfcff] px-6 py-5">
          <div className="flex min-w-0 items-start gap-4">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[10px] bg-primary/10 text-primary">
              <Sparkles className="h-5 w-5" />
            </div>
            <div className="min-w-0">
              <div className="mb-1 flex flex-wrap items-center gap-2">
                <h2 className="text-[20px] font-extrabold leading-tight text-[#25396f]">
                  {isEditing ? 'Cập nhật thương hiệu' : 'Thêm thương hiệu'}
                </h2>
                <span className="rounded-[6px] bg-white px-2.5 py-1 text-[11px] font-extrabold text-[#7c8db5] ring-1 ring-[#dce7f1]">
                  {isEditing ? 'EDIT' : 'NEW'}
                </span>
              </div>
              <p className="text-sm font-semibold text-[#7c8db5]">
                Quản lý logo, banner và nội dung nhận diện thương hiệu.
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
          <div className="grid grid-cols-1 gap-0 lg:grid-cols-[300px_1fr]">
            <aside className="border-b border-[#edf2f7] bg-[#fbfcff] p-6 lg:border-b-0 lg:border-r">
              <div className="space-y-4">
                <button
                  type="button"
                  onClick={() => logoInputRef.current?.click()}
                  className="group flex aspect-[4/3] w-full items-center justify-center overflow-hidden rounded-[12px] border border-dashed border-[#c8d5e5] bg-white transition-all hover:border-primary hover:bg-primary/5"
                >
                  {logoPreview ? (
                    <img src={logoPreview} alt="Brand logo preview" className="h-full w-full object-contain p-5" />
                  ) : (
                    <div className="flex flex-col items-center gap-3 text-center">
                      <span className="flex h-12 w-12 items-center justify-center rounded-[10px] bg-[#f2f7ff] text-primary transition-transform group-hover:scale-105">
                        <ImageIcon className="h-6 w-6" />
                      </span>
                      <span className="text-xs font-extrabold uppercase tracking-wide text-[#7c8db5]">Logo</span>
                    </div>
                  )}
                </button>
                <input ref={logoInputRef} type="file" className="hidden" accept=".svg,.png,.jpg,.jpeg,.webp" onChange={handleLogoChange} />

                <Button
                  type="button"
                  variant="outline"
                  onClick={() => logoInputRef.current?.click()}
                  className="h-10 w-full rounded-[8px] border border-[#dce7f1] bg-white text-sm font-extrabold text-primary shadow-none hover:bg-primary/5"
                >
                  <UploadCloud className="mr-2 h-4 w-4" />
                  Chọn logo
                </Button>

                <div className="rounded-[10px] border border-[#edf2f7] bg-white p-4">
                  <p className="mb-2 text-[11px] font-extrabold uppercase tracking-wide text-[#7c8db5]">Preview</p>
                  <div className="overflow-hidden rounded-[10px] border border-[#edf2f7] bg-[#f2f7ff]">
                    <div className="aspect-[16/7] bg-[#dce7f1]">
                      {bannerPreview ? (
                        <img src={bannerPreview} alt="Brand banner preview" className="h-full w-full object-cover" />
                      ) : (
                        <div className="flex h-full items-center justify-center text-xs font-extrabold uppercase text-[#7c8db5]">Banner</div>
                      )}
                    </div>
                    <div className="flex items-center gap-3 bg-white p-3">
                      <div className="flex h-11 w-11 shrink-0 items-center justify-center overflow-hidden rounded-[10px] border border-[#dce7f1] bg-[#f2f7ff]">
                        {logoPreview ? (
                          <img src={logoPreview} alt="" className="h-full w-full object-contain p-1.5" />
                        ) : (
                          <ImageIcon className="h-5 w-5 text-[#a8b4c7]" />
                        )}
                      </div>
                      <div className="min-w-0">
                        <p className="mb-1 truncate text-sm font-extrabold text-[#25396f]">{name || 'Tên thương hiệu'}</p>
                        <p className="mb-0 truncate text-xs font-bold text-[#7c8db5]">/{slugPreview || 'slug-tu-dong'}</p>
                      </div>
                    </div>
                  </div>
                </div>

                {isEditing && brand && (
                  <div className="grid grid-cols-3 gap-3">
                    <div className="rounded-[10px] border border-[#edf2f7] bg-white p-3">
                      <p className="mb-1 text-[10px] font-extrabold uppercase text-[#7c8db5]">SP</p>
                      <p className="text-lg font-extrabold leading-none text-[#25396f]">{getProductCount(brand)}</p>
                    </div>
                    <div className="rounded-[10px] border border-[#edf2f7] bg-white p-3">
                      <p className="mb-1 text-[10px] font-extrabold uppercase text-[#7c8db5]">Điểm</p>
                      <p className="text-lg font-extrabold leading-none text-[#25396f]">{score}</p>
                    </div>
                    <div className="rounded-[10px] border border-[#edf2f7] bg-white p-3">
                      <p className="mb-1 text-[10px] font-extrabold uppercase text-[#7c8db5]">Nổi bật</p>
                      <p className="truncate text-sm font-extrabold text-[#25396f]">{brand.isFeatured ? 'Có' : 'Không'}</p>
                    </div>
                  </div>
                )}
              </div>
            </aside>

            <div className="space-y-5 p-6">
              <div>
                <label className={fieldLabelClass}>Banner thương hiệu</label>
                <button
                  type="button"
                  onClick={() => bannerInputRef.current?.click()}
                  className="mt-2 flex aspect-[21/7] w-full items-center justify-center overflow-hidden rounded-[12px] border border-dashed border-[#c8d5e5] bg-[#fbfcff] transition-all hover:border-primary hover:bg-primary/5"
                >
                  {bannerPreview ? (
                    <img src={bannerPreview} alt="Brand banner preview" className="h-full w-full object-cover" />
                  ) : (
                    <span className="flex items-center gap-2 text-sm font-extrabold text-[#7c8db5]">
                      <UploadCloud className="h-4 w-4" />
                      Chọn banner
                    </span>
                  )}
                </button>
                <input ref={bannerInputRef} type="file" className="hidden" accept=".png,.jpg,.jpeg,.webp" onChange={handleBannerChange} />
              </div>

              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div className="md:col-span-2">
                  <label className={fieldLabelClass}>Tên thương hiệu</label>
                  <input
                    value={name}
                    onChange={(event) => setName(event.target.value)}
                    required
                    placeholder="Logitech, Samsung, Razer..."
                    className={`${fieldClass} mt-2 h-11 px-4`}
                  />
                </div>

                <div className="md:col-span-2">
                  <label className={fieldLabelClass}>Slug tự sinh</label>
                  <div className="mt-2 flex h-11 items-center gap-2 rounded-[8px] border border-[#dce7f1] bg-[#f8fbff] px-4 text-sm font-extrabold text-[#607080]">
                    <ChevronRight className="h-4 w-4 text-[#a8b4c7]" />
                    <span className="truncate">/{slugPreview || 'slug-tu-dong'}</span>
                  </div>
                </div>

                <div className="md:col-span-2">
                  <label className={fieldLabelClass}>Quote thương hiệu</label>
                  <div className="relative mt-2">
                    <Quote className="absolute left-4 top-3.5 h-4 w-4 text-[#a8b4c7]" />
                    <input
                      value={quote}
                      onChange={(event) => setQuote(event.target.value)}
                      placeholder="For Gamers. By Gamers."
                      className={`${fieldClass} h-11 pl-11 pr-4`}
                    />
                  </div>
                </div>

                <div className="md:col-span-2">
                  <label className={fieldLabelClass}>Triết lý thương hiệu</label>
                  <textarea
                    value={philosophy}
                    onChange={(event) => setPhilosophy(event.target.value)}
                    placeholder="Kể câu chuyện, định vị hoặc cam kết của thương hiệu..."
                    className={`${fieldClass} mt-2 min-h-[128px] resize-none p-4 font-semibold leading-6`}
                  />
                </div>
              </div>

              <div className="rounded-[10px] border border-[#edf2f7] bg-[#fbfcff] p-4">
                <div className="flex gap-3">
                  <div className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-[8px] bg-primary/10 text-primary">
                    <Sparkles className="h-4 w-4" />
                  </div>
                  <div className="min-w-0">
                    <p className="mb-1 text-sm font-extrabold text-[#25396f]">Hiển thị trên storefront</p>
                    <p className="mb-0 text-xs font-semibold leading-5 text-[#7c8db5]">
                      Logo nên dùng nền trong suốt; banner nên dùng ảnh ngang rõ sản phẩm hoặc nhận diện thương hiệu.
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
              {isEditing ? 'Lưu thay đổi' : 'Tạo brand'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
};
