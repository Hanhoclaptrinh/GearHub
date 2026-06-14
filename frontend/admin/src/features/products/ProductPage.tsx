import React, { useState, useEffect } from 'react';
import { useForm, useFieldArray, Controller } from 'react-hook-form';
import type { SubmitHandler } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useNavigate, useParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Package,
  ArrowLeft,
  Save,
  Plus,
  Trash2,
  AlertCircle,
  Hash,
  DollarSign,
  Layers,
  FileText,
  TrendingUp,
  Wand2,
  Barcode,
  Settings2,
  UploadCloud,
} from '../../components/ui/IconlyIcons';
import { productService } from '../../services/product.service';
import { brandService } from '../../services/brand.service';
import { categoryService } from '../../services/category.service';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Card, CardContent, CardHeader, CardTitle } from '../../components/ui/Card';
import { ImageUpload } from '../../components/products/ImageUpload';
import { cn } from '../../utils/cn';
import type { Product, Category, Brand } from '../../types';

const variantSchema = z.object({
  id: z.string().optional(),
  sku: z.string().min(1, 'SKU là bắt buộc'),
  price: z.preprocess((v) => Number(v), z.number().min(0, 'Giá không hợp lệ')),
  stock: z.preprocess((v) => Number(v), z.number().min(0, 'Tồn kho không hợp lệ')),
  attributes: z.record(z.string(), z.any()).optional(),
  imageUrl: z.string().optional(),
  barcode: z.string().optional(),
  assets: z.array(z.any()).optional(),
});

const productSchema = z.object({
  name: z.string().min(3, 'Tên sản phẩm ít nhất 3 ký tự'),
  tagline: z.string().max(100, 'Tagline tối đa 100 ký tự').optional(),
  description: z.string().min(10, 'Mô tả ít nhất 10 ký tự'),
  categoryId: z.string().min(1, 'Vui lòng chọn danh mục'),
  brandId: z.string().min(1, 'Vui lòng chọn thương hiệu'),
  attributeConfig: z.array(z.string()).optional(),
  variants: z.array(variantSchema).min(1, 'Ít nhất 1 phân loại sản phẩm'),
});

type FormValues = z.infer<typeof productSchema>;

const AttributeManager: React.FC<{
  value: Record<string, any>;
  onChange: (val: Record<string, any>) => void
}> = ({ value, onChange }) => {
  const attributeList = Object.entries(value || {}).map(([key, val]) => ({ key, val }));
  const [items, setItems] = useState(attributeList.length > 0 ? attributeList : [{ key: '', val: '' }]);

  const updateItems = (newItems: typeof items) => {
    setItems(newItems);
    const result: Record<string, any> = {};
    newItems.forEach(item => {
      if (item.key.trim()) {
        result[item.key.trim()] = item.val;
      }
    });
    onChange(result);
  };

  useEffect(() => {
    const newList = Object.entries(value || {}).map(([key, val]) => ({ key, val }));
    const currentClean = items.filter(i => i.key.trim() !== '').map(i => ({ key: i.key.trim(), val: i.val }));

    if (JSON.stringify(newList) !== JSON.stringify(currentClean)) {
      if (newList.length > 0) {
        setItems(newList);
      } else if (items.length === 0) {
        setItems([{ key: '', val: '' }]);
      }
    }
  }, [value]);

  return (
    <div className="mt-6 pt-6 border-t border-slate-100 space-y-4">
      <div className="flex items-center justify-between">
        <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest flex items-center gap-2">
          <Layers className="w-3 h-3" /> Thuộc tính chi tiết (Màu, Dung lượng...)
        </label>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          className="h-8 text-[10px] px-3 rounded-xl border border-slate-200 hover:bg-slate-100"
          onClick={() => updateItems([...items, { key: '', val: '' }])}
        >
          <Plus className="w-3 h-3 mr-1.5" /> Thêm key
        </Button>
      </div>

      <div className="grid grid-cols-1 gap-3">
        {items.map((item, idx) => (
          <div key={idx} className="flex gap-3 items-center group/attr animate-in fade-in slide-in-from-top-1 duration-200">
            <div className="flex-1 relative">
              <input
                className="w-full h-10 px-4 bg-white border border-slate-200 rounded-xl outline-none focus:border-primary focus:ring-4 focus:ring-primary/5 transition-all font-bold text-slate-700 text-xs"
                placeholder="Tên (VD: Màu sắc)"
                value={item.key}
                onChange={(e) => {
                  const next = [...items];
                  next[idx].key = e.target.value;
                  updateItems(next);
                }}
              />
            </div>
            <div className="flex-1 relative">
              <input
                className="w-full h-10 px-4 bg-white border border-slate-200 rounded-xl outline-none focus:border-primary focus:ring-4 focus:ring-primary/5 transition-all font-bold text-slate-700 text-xs"
                placeholder="Giá trị (VD: Bạc)"
                value={item.val}
                onChange={(e) => {
                  const next = [...items];
                  next[idx].val = e.target.value;
                  updateItems(next);
                }}
              />
            </div>
            {items.length > 1 && (
              <button
                type="button"
                className="p-2.5 text-slate-300 hover:text-red-500 transition-colors opacity-0 group-hover/attr:opacity-100"
                onClick={() => updateItems(items.filter((_, i) => i !== idx))}
              >
                <Trash2 className="w-4 h-4" />
              </button>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

const AttributeConfigManager: React.FC<{
  value: string[];
  onChange: (val: string[]) => void;
}> = ({ value, onChange }) => {
  const [items, setItems] = useState<string[]>(value?.length > 0 ? value : ['']);

  const updateItems = (next: string[]) => {
    setItems(next);
    onChange(next);
  };

  useEffect(() => {
    const cleanItems = items.filter(i => i.trim() !== '');
    const cleanValue = (value || []).filter(i => i.trim() !== '');

    if (JSON.stringify(cleanItems) !== JSON.stringify(cleanValue)) {
      if (value && value.length > 0) {
        setItems(value);
      } else if (items.length === 0) {
        setItems(['']);
      }
    }
  }, [value]);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <label className="text-sm font-bold text-slate-700 ml-1 flex items-center gap-2">
          <Layers className="w-4 h-4 text-primary/60" /> Các phím thuộc tính biến thể (Màu sắc, Cấu hình...)
        </label>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          className="h-8 text-[10px] px-3 rounded-xl border border-slate-200"
          onClick={() => updateItems([...items, ''])}
        >
          <Plus className="w-3 h-3 mr-1.5" /> Thêm key
        </Button>
      </div>

      <div className="flex flex-wrap gap-3">
        {items.map((item, idx) => (
          <div key={idx} className="flex gap-2 items-center animate-in fade-in zoom-in duration-200">
            <input
              className="w-32 h-10 px-4 bg-white border border-slate-200 rounded-xl outline-none focus:border-primary focus:ring-4 focus:ring-primary/5 transition-all font-bold text-slate-700 text-xs"
              placeholder="VD: Màu sắc"
              value={item}
              onChange={(e) => {
                const next = [...items];
                next[idx] = e.target.value;
                updateItems(next);
              }}
            />
            {items.length > 1 && (
              <button
                type="button"
                className="p-2 text-slate-300 hover:text-red-500 transition-colors"
                onClick={() => updateItems(items.filter((_, i) => i !== idx))}
              >
                <Trash2 className="w-3 h-3" />
              </button>
            )}
          </div>
        ))}
      </div>
      <p className="text-[10px] font-medium text-slate-400 italic mt-2">
        * Các key này sẽ được dùng để tạo ma trận chọn biến thể.
      </p>
    </div>
  );
};


export const ProductPage: React.FC = () => {
  const { slug } = useParams();
  const isEdit = !!slug;
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const [files, setFiles] = useState<File[]>([]);
  const [previews, setPreviews] = useState<string[]>([]);
  const [primaryIndex, setPrimaryIndex] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [variantFiles, setVariantFiles] = useState<Record<number, File[]>>({});

  const [commonSpecs, setCommonSpecs] = useState<{ key: string; val: string }[]>([]);
  const [generatorAxes, setGeneratorAxes] = useState<Record<string, string>>({});
  const [isGenerating, setIsGenerating] = useState(false);

  const { data: categories } = useQuery<Category[]>({ queryKey: ['categories'], queryFn: categoryService.getAllCategories });
  const { data: brands } = useQuery<Brand[]>({ queryKey: ['brands'], queryFn: () => brandService.getAllBrands() });

  const { data: editProduct, isLoading: isEditLoading } = useQuery<Product>({
    queryKey: ['product', slug],
    queryFn: () => productService.getProductBySlug(slug!),
    enabled: isEdit,
  });

  const {
    register,
    handleSubmit,
    control,
    reset,
    watch,
    setValue,
    formState: { errors, isValid },
  } = useForm<FormValues>({
    resolver: zodResolver(productSchema) as any,
    defaultValues: {
      name: '',
      tagline: '',
      description: '',
      categoryId: '',
      brandId: '',
      attributeConfig: [],
      variants: [{ sku: '', price: 0, stock: 0 }],
    },
  });

  const watchName = watch('name');

  const { fields, append, remove } = useFieldArray({
    control,
    name: "variants" as any,
  });

  useEffect(() => {
    if (editProduct) {
      reset({
        name: editProduct.name,
        tagline: editProduct.tagline || '',
        description: editProduct.description,
        categoryId: editProduct.categoryId,
        brandId: editProduct.brandId,
        attributeConfig: editProduct.attributeConfig || [],
        variants: editProduct.variants.map((v: any) => ({
          id: v.id,
          sku: v.sku,
          price: v.price,
          stock: v.stock,
          attributes: v.attributes,
          imageUrl: v.imageUrl || '',
          barcode: v.barcode || '',
          assets: v.assets || [],
        })) as any,
      });

      // load common specs from metadata
      const meta = (editProduct as any).metadata;
      if (meta?.common_specs) {
        setCommonSpecs(Object.entries(meta.common_specs).map(([key, val]) => ({ key, val: String(val) })));
      } else {
        setCommonSpecs([]);
      }

      if (editProduct.assets?.length) {
        const prodAssets = editProduct.assets.filter((a: any) => !a.variantId);
        setPreviews(prodAssets.map((a: any) => a.url));
        const pIdx = prodAssets.findIndex((a: any) => a.isPrimary);
        setPrimaryIndex(pIdx >= 0 ? pIdx : 0);
      } else {
        setPreviews([]);
        setPrimaryIndex(0);
      }
      setFiles([]);

      if (editProduct.attributeConfig && editProduct.variants) {
        const axes: Record<string, string> = {};
        editProduct.attributeConfig.forEach((key: string) => {
          const values = editProduct.variants
            ?.map(v => v.attributes?.[key])
            .filter(Boolean)
            .map(v => String(v).trim());
          if (values && values.length > 0) {
            axes[key] = Array.from(new Set(values)).join(', ');
          }
        });
        setGeneratorAxes(axes);
      }
    } else if (!isEdit) {
      reset({
        name: '',
        tagline: '',
        description: '',
        categoryId: '',
        brandId: '',
        attributeConfig: [],
        variants: [{ sku: '', price: 0, stock: 0 }],
      });
      setPreviews([]);
      setFiles([]);
      setPrimaryIndex(0);
    }
  }, [editProduct, reset, isEdit]);

  const mutation = useMutation({
    mutationFn: (formData: FormData) =>
      isEdit ? productService.updateProduct(editProduct!.id, formData) : productService.createProduct(formData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      navigate('/products');
    },
    onError: (err: any) => {
      setError(err.response?.data?.message || 'Có lỗi xảy ra khi lưu sản phẩm.');
    }
  });

  const onUpload = (newFiles: File[]) => {
    setFiles(prev => [...prev, ...newFiles]);
    const newPreviews = newFiles.map(f => URL.createObjectURL(f));
    setPreviews(prev => [...prev, ...newPreviews]);
  };

  const onRemoveImage = (index: number) => {
    const oldAssetsCount = isEdit ? (editProduct?.assets?.length || 0) : 0;

    setPreviews(prev => prev.filter((_, i) => i !== index));

    if (index >= oldAssetsCount) {
      const fileIndex = index - oldAssetsCount;
      setFiles(prev => prev.filter((_, i) => i !== fileIndex));
    } else if (isEdit && editProduct?.assets?.[index]) {
      productService.removeAsset(editProduct.assets[index].id).catch(console.error);
    }

    if (primaryIndex === index) setPrimaryIndex(0);
    else if (primaryIndex > index) setPrimaryIndex(primaryIndex - 1);
  };

  const is2DImage = (fileName: string) => {
    const ext = fileName.toLowerCase().split('.').pop();
    return ['jpg', 'jpeg', 'png', 'webp'].includes(ext || '');
  };

  const handleGenerateVariants = async () => {
    const configKeys = watch('attributeConfig') || [];
    const cleanKeys = configKeys.filter(k => k.trim() !== '');
    if (cleanKeys.length === 0) {
      setError('Vui lòng thêm ít nhất 1 key vào "Các phím thuộc tính biến thể" trước khi Generate.');
      return;
    }

    // build truc thuoc tinh
    const axes: Record<string, string[]> = {};
    for (const key of cleanKeys) {
      const valuesStr = generatorAxes[key] || '';
      const values = valuesStr.split(',').map(v => v.trim()).filter(v => v !== '');
      if (values.length === 0) {
        setError(`Vui lòng nhập giá trị cho trục "${key}" (phân cách bằng dấu phẩy).`);
        return;
      }
      axes[key] = values;
    }

    setIsGenerating(true);
    setError(null);
    try {
      const slug = watchName ? watchName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') : undefined;
      const matrix = await productService.generateVariants(axes, slug);
      // thay the bien the hien tai bang ma tran thuoc tinh
      setValue('variants', matrix.map((v: any) => ({
        sku: v.sku,
        price: v.price,
        stock: v.stock,
        attributes: v.attributes,
        imageUrl: '',
        barcode: '',
      })));
    } catch (err: any) {
      setError(err.response?.data?.message || 'Lỗi khi tạo ma trận biến thể.');
    } finally {
      setIsGenerating(false);
    }
  };

  const onSubmit: SubmitHandler<FormValues> = (values) => {
    setError(null);

    const has2DImage = files.some(f => is2DImage(f.name)) ||
      (isEdit && editProduct?.assets?.some((a: any) => a.type === 'IMAGE'));

    if (!has2DImage) {
      setError('Sản phẩm bắt buộc phải có ít nhất một ảnh 2D (JPG, PNG, WEBP).');
      return;
    }

    const formData = new FormData();
    formData.append('name', values.name);
    if (values.tagline) formData.append('tagline', values.tagline);
    formData.append('description', values.description);
    formData.append('categoryId', values.categoryId);
    formData.append('brandId', values.brandId);
    formData.append('primaryIndex', primaryIndex.toString());

    const cleanConfig = (values.attributeConfig || []).filter(k => k.trim() !== '');
    formData.append('attributeConfig', JSON.stringify(cleanConfig));

    // Common Specs
    if (commonSpecs.length > 0) {
      const csObj: Record<string, string> = {};
      commonSpecs.forEach(s => { if (s.key.trim()) csObj[s.key.trim()] = s.val; });
      if (Object.keys(csObj).length > 0) {
        formData.append('commonSpecs', JSON.stringify(csObj));
      }
    }

    const cleanVariants = values.variants.map(v => {
      const cleanAttrs: Record<string, any> = {};
      if (v.attributes) {
        Object.entries(v.attributes).forEach(([k, val]) => {
          if (k.trim()) cleanAttrs[k.trim()] = val;
        });
      }
      return { ...v, attributes: cleanAttrs, imageUrl: v.imageUrl || null, barcode: v.barcode || null };
    });
    formData.append('variants', JSON.stringify(cleanVariants));

    files.forEach(file => {
      formData.append('files', file);
    });

    Object.entries(variantFiles).forEach(([idx, vFiles]) => {
      vFiles.forEach(file => {
        formData.append(`variant_files_${idx}`, file);
      });
    });

    mutation.mutate(formData);
  };

  const onInvalid = (errors: any) => {
    console.error('Form Validation Errors:', errors);
    setError('Vui lòng kiểm tra lại các trường thông tin đỏ.');
  };

  if (isEdit && isEditLoading) return <div className="text-center py-20 font-bold text-primary animate-pulse font-heading">Đang tải dữ liệu sản phẩm...</div>;

  const watchedVariants = watch('variants') || [];
  const watchedCategoryId = watch('categoryId');
  const watchedBrandId = watch('brandId');
  const watchedDescription = watch('description') || '';
  const flatCategories = categories?.flatMap((category: Category) => [category, ...(category.children || [])]) || [];
  const selectedCategory = flatCategories.find((category: Category) => category.id === watchedCategoryId);
  const selectedBrand = brands?.find((brand: Brand) => brand.id === watchedBrandId);
  const validVariantCount = watchedVariants.filter((variant: any) => variant?.sku && Number(variant?.price) >= 0).length;
  const totalStock = watchedVariants.reduce((sum: number, variant: any) => sum + Number(variant?.stock || 0), 0);

  return (
    <div className="space-y-6 pb-10 animate-in fade-in slide-in-from-bottom-3 duration-500">
      <div className="rounded-[12px] bg-white border border-[#edf2f7] shadow-[0_5px_15px_rgba(25,42,70,0.06)] p-5 md:p-6">
        <div className="flex flex-col gap-5 xl:flex-row xl:items-center xl:justify-between">
          <div className="flex items-start gap-4">
            <Button variant="ghost" onClick={() => navigate('/products')} className="h-11 w-11 rounded-[10px] bg-[#f2f7ff] p-0 text-[#25396f] hover:bg-primary/10">
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div className="space-y-2">
              <p className="text-[12px] font-extrabold uppercase tracking-wider text-[#7c8db5]">Quản lý sản phẩm / {isEdit ? 'Cập nhật' : 'Tạo mới'}</p>
              <div>
                <h1 className="text-[28px] md:text-[32px] font-extrabold text-[#25396f] font-heading leading-tight">{isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm'}</h1>
                <p className="text-sm font-semibold text-[#7c8db5] mt-1">{isEdit ? 'Cập nhật nội dung, hình ảnh và cấu hình SKU.' : 'Thiết lập thông tin bán hàng, hình ảnh và biến thể.'}</p>
              </div>
            </div>
          </div>
          <div className="flex flex-col sm:flex-row gap-3 xl:items-center">
            <Button type="button" variant="outline" onClick={() => navigate('/products')} className="rounded-[8px] border-[#dce7f1] text-[#607080] hover:border-primary">
              Hủy
            </Button>
            <Button onClick={handleSubmit(onSubmit, onInvalid)} isLoading={mutation.isPending} className="h-11 rounded-[8px] bg-primary px-6 shadow-[0_8px_18px_rgba(67,94,190,0.18)] hover:bg-primary/90">
              <Save className="w-4 h-4 mr-2" />
              {isEdit ? 'Lưu thay đổi' : 'Tạo sản phẩm'}
            </Button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-[minmax(0,1fr)_380px] gap-6 items-start">
        <div className="space-y-6">
          <Card className="rounded-[12px] border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] bg-white">
            <CardHeader className="px-6 pt-6 pb-3 border-none">
              <CardTitle className="text-[20px] text-[#25396f] flex items-center gap-3">
                <span className="w-10 h-10 rounded-[10px] bg-primary/10 text-primary inline-flex items-center justify-center">
                  <FileText className="w-5 h-5" />
                </span>
                Thông tin cơ bản
              </CardTitle>
              <p className="text-sm font-semibold text-[#7c8db5]">Nội dung hiển thị chính trên trang chi tiết sản phẩm.</p>
            </CardHeader>
            <CardContent className="px-6 pb-6 space-y-5">
              <Input label="Tên sản phẩm" placeholder="Samsung Galaxy S24 Ultra..." {...register('name')} error={errors.name?.message} />

              <Input
                label="Tagline (Dòng giới thiệu ngắn)"
                placeholder="Sức mạnh đỉnh cao, thiết kế sang trọng..."
                {...register('tagline')}
                error={errors.tagline?.message}
                maxLength={100}
              />

              <div className="space-y-1.5">
                <label className="text-sm font-bold text-[#25396f] ml-1 flex items-center gap-2">
                  <Package className="w-4 h-4 text-primary/60" /> Mô tả chi tiết
                </label>
                <textarea
                  {...register('description')}
                  className={cn(
                    "w-full h-40 p-4 border border-[#dce7f1] rounded-[10px] outline-none focus:border-primary focus:ring-3 focus:ring-primary/20 transition-all font-body text-[#25396f] resize-none bg-white",
                    errors.description && "border-red-400 focus:border-red-500 focus:ring-red-100"
                  )}
                  placeholder="Mô tả các đặc điểm nổi bật của sản phẩm..."
                />
                {errors.description && <span className="text-xs font-bold text-red-500 ml-1">{errors.description.message}</span>}
              </div>

              <Controller
                name="attributeConfig"
                control={control}
                render={({ field }) => (
                  <AttributeConfigManager
                    value={field.value || []}
                    onChange={field.onChange}
                  />
                )}
              />

              <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div className="space-y-1.5 flex flex-col">
                  <label className="text-sm font-bold text-[#25396f] ml-1">Danh mục</label>
                  <div className="relative">
                    <select
                      {...register('categoryId')}
                      className="w-full h-12 px-4 bg-white border border-[#dce7f1] rounded-[10px] outline-none focus:border-primary focus:ring-3 focus:ring-primary/20 appearance-none font-bold text-[#25396f] transition-all cursor-pointer"
                    >
                      <option value="">Chọn danh mục</option>
                      {categories?.map((c: Category) => (
                        <React.Fragment key={c.id}>
                          <option value={c.id} className="font-bold">{c.name}</option>
                          {c.children?.map((sub: Category) => (
                            <option key={sub.id} value={sub.id}>&nbsp;&nbsp;&nbsp;↳ {sub.name}</option>
                          ))}
                        </React.Fragment>
                      ))}
                    </select>
                    <Layers className="absolute right-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#a8b4c7] pointer-events-none" />
                  </div>
                  {errors.categoryId && <span className="text-xs font-bold text-red-500 ml-1">{errors.categoryId.message}</span>}
                </div>
                <div className="space-y-1.5 flex flex-col">
                  <label className="text-sm font-bold text-[#25396f] ml-1">Thương hiệu</label>
                  <div className="relative">
                    <select
                      {...register('brandId')}
                      className="w-full h-12 px-4 bg-white border border-[#dce7f1] rounded-[10px] outline-none focus:border-primary focus:ring-3 focus:ring-primary/20 appearance-none font-bold text-[#25396f] transition-all cursor-pointer"
                    >
                      <option value="">Chọn thương hiệu</option>
                      {brands?.map((b: any) => <option key={b.id} value={b.id}>{b.name}</option>)}
                    </select>
                    <Plus className="absolute right-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#a8b4c7] pointer-events-none" />
                  </div>
                  {errors.brandId && <span className="text-xs font-bold text-red-500 ml-1">{errors.brandId.message}</span>}
                </div>
              </div>
            </CardContent>
          </Card>

          {/* === COMMON SPECS === */}
          <Card className="rounded-[12px] border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] bg-white">
            <CardHeader className="px-6 pt-6 pb-3 border-none flex flex-row items-center justify-between gap-4">
              <CardTitle className="text-[20px] text-[#25396f] flex items-center gap-3">
                <span className="w-10 h-10 rounded-[10px] bg-[#f2f7ff] text-primary inline-flex items-center justify-center">
                  <Settings2 className="w-5 h-5" />
                </span>
                Thông số kỹ thuật chung
              </CardTitle>
              <Button type="button" variant="ghost" size="sm" className="h-8 text-[10px] px-3 rounded-[8px] border border-[#dce7f1]"
                onClick={() => setCommonSpecs([...commonSpecs, { key: '', val: '' }])}>
                <Plus className="w-3 h-3 mr-1.5" /> Thêm spec
              </Button>
            </CardHeader>
            <CardContent className="px-6 pb-6 space-y-3">
              <p className="text-xs font-semibold text-[#7c8db5]">
                Thông số chung cho mọi biến thể, ví dụ chip, màn hình, pin.
              </p>
              {commonSpecs.length === 0 && (
                <div className="rounded-[10px] border border-dashed border-[#dce7f1] bg-[#fbfcff] text-center py-6 text-sm text-[#7c8db5] font-bold">Chưa có thông số nào</div>
              )}
              {commonSpecs.map((item, idx) => (
                <div key={idx} className="flex gap-3 items-center group/spec animate-in fade-in duration-200">
                  <input className="flex-1 h-10 px-4 bg-white border border-[#dce7f1] rounded-[10px] outline-none focus:border-primary focus:ring-4 focus:ring-primary/5 transition-all font-bold text-[#25396f] text-xs"
                    placeholder="Tên (VD: chip)" value={item.key}
                    onChange={e => { const next = [...commonSpecs]; next[idx].key = e.target.value; setCommonSpecs(next); }} />
                  <input className="flex-[2] h-10 px-4 bg-white border border-[#dce7f1] rounded-[10px] outline-none focus:border-primary focus:ring-4 focus:ring-primary/5 transition-all font-bold text-[#25396f] text-xs"
                    placeholder="Giá trị (VD: Apple A16 Bionic)" value={item.val}
                    onChange={e => { const next = [...commonSpecs]; next[idx].val = e.target.value; setCommonSpecs(next); }} />
                  <button type="button" className="p-2 text-slate-300 hover:text-red-500 transition-colors opacity-0 group-hover/spec:opacity-100"
                    onClick={() => setCommonSpecs(commonSpecs.filter((_, i) => i !== idx))}>
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              ))}
            </CardContent>
          </Card>

          {/* === VARIANT GENERATOR === */}
          <Card className="rounded-[12px] border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] bg-white">
            <CardHeader className="px-6 pt-6 pb-3 border-none">
              <CardTitle className="text-[20px] text-[#25396f] flex items-center gap-3">
                <span className="w-10 h-10 rounded-[10px] bg-[#f2f7ff] text-primary inline-flex items-center justify-center">
                  <Wand2 className="w-5 h-5" />
                </span>
                Tạo ma trận biến thể
              </CardTitle>
              <p className="text-sm font-semibold text-[#7c8db5]">Nhập giá trị cho từng trục thuộc tính, phân cách bằng dấu phẩy.</p>
            </CardHeader>
            <CardContent className="px-6 pb-6 space-y-4">
              {(watch('attributeConfig') || []).filter(k => k.trim()).map(key => (
                <div key={key} className="flex gap-3 items-center">
                  <span className="min-w-[120px] text-xs font-black text-[#607080] uppercase">{key}</span>
                  <input className="flex-1 h-10 px-4 bg-white border border-[#dce7f1] rounded-[10px] outline-none focus:border-primary focus:ring-4 focus:ring-primary/5 transition-all font-bold text-[#25396f] text-xs"
                    placeholder={`VD: Đen, Trắng, Xanh (phân cách bằng dấu phẩy)`}
                    value={generatorAxes[key] || ''}
                    onChange={e => setGeneratorAxes({ ...generatorAxes, [key]: e.target.value })} />
                </div>
              ))}
              {(watch('attributeConfig') || []).filter(k => k.trim()).length === 0 && (
                <p className="rounded-[10px] border border-dashed border-[#dce7f1] bg-[#fbfcff] text-sm text-[#7c8db5] font-bold text-center py-4">Vui lòng thêm key ở mục "Các phím thuộc tính biến thể" phía trên trước.</p>
              )}
              <Button type="button" className="w-full py-3 rounded-[8px] bg-primary" onClick={handleGenerateVariants} isLoading={isGenerating}
                disabled={(watch('attributeConfig') || []).filter(k => k.trim()).length === 0}>
                <Wand2 className="w-4 h-4 mr-2" /> Tạo ma trận
              </Button>
            </CardContent>
          </Card>

          {/* === VARIANTS TABLE === */}
          <Card className="rounded-[12px] border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] bg-white">
            <CardHeader className="px-6 pt-6 pb-3 border-none flex flex-row items-center justify-between gap-4">
              <div>
                <CardTitle className="text-[20px] text-[#25396f] flex items-center gap-3">
                  <span className="w-10 h-10 rounded-[10px] bg-[#f2f7ff] text-primary inline-flex items-center justify-center">
                    <Layers className="w-5 h-5" />
                  </span>
                  Phân loại & Kho
                </CardTitle>
                <p className="text-sm font-semibold text-[#7c8db5] mt-1">{fields.length} biến thể đang được cấu hình.</p>
              </div>
              <Button type="button" variant="outline" size="sm" className="rounded-[8px] border-[#dce7f1] shadow-none" onClick={() => append({ sku: '', price: 0, stock: 0 })}>
                <Plus className="w-4 h-4 mr-1.5" /> Thêm SKU
              </Button>
            </CardHeader>
            <CardContent className="px-6 pb-6 space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div className="rounded-[10px] border border-[#edf2f7] bg-white px-4 py-3">
                  <p className="text-[11px] font-extrabold uppercase text-[#7c8db5] mb-1">Biến thể</p>
                  <p className="text-xl font-extrabold text-[#25396f]">{fields.length}</p>
                </div>
                <div className="rounded-[10px] border border-[#edf2f7] bg-white px-4 py-3">
                  <p className="text-[11px] font-extrabold uppercase text-[#7c8db5] mb-1">SKU hợp lệ</p>
                  <p className="text-xl font-extrabold text-[#25396f]">{validVariantCount}</p>
                </div>
                <div className="rounded-[10px] border border-[#edf2f7] bg-white px-4 py-3">
                  <p className="text-[11px] font-extrabold uppercase text-[#7c8db5] mb-1">Tổng tồn</p>
                  <p className="text-xl font-extrabold text-[#25396f]">{totalStock}</p>
                </div>
              </div>
              {/* === BULK ACTION TOOLBAR === */}
              <div className="bg-[#fbfcff] border border-[#dce7f1] p-5 rounded-[12px] mb-6 space-y-4">
                <div className="flex items-center gap-2">
                  <Wand2 className="w-5 h-5 text-primary" />
                  <span className="text-xs font-black text-[#25396f] uppercase tracking-wide">Gán nhanh hàng loạt</span>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-4 gap-4 items-end">
                  <div>
                    <label className="text-[10px] font-black text-slate-400 uppercase ml-1 flex items-center gap-1">Lọc theo Thuộc tính</label>
                    <select
                      id="bulk-attr-filter-key"
                      className="w-full h-10 px-3 bg-white border border-[#dce7f1] rounded-[10px] outline-none focus:border-primary transition-all font-bold text-[#25396f] text-xs cursor-pointer"
                    >
                      <option value="">-- Tất cả thuộc tính --</option>
                      {Array.from(new Set(
                        (watch('variants') || []).flatMap((v: any) => v.attributes ? Object.keys(v.attributes) : [])
                      )).map(k => (
                        <option key={k} value={k}>{k}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="text-[10px] font-black text-slate-400 uppercase ml-1 flex items-center gap-1">Lọc theo Giá trị</label>
                    <input
                      id="bulk-attr-filter-val"
                      type="text"
                      placeholder="VD: Đen, 512GB"
                      className="w-full h-10 px-3 bg-white border border-[#dce7f1] rounded-[10px] outline-none focus:border-primary transition-all font-bold text-[#25396f] text-xs"
                    />
                  </div>

                  <div className="md:col-span-2 flex items-center gap-2">
                    <div className="flex-1">
                      <label className="text-[10px] font-black text-slate-400 uppercase ml-1 flex items-center gap-1">Hành động áp dụng</label>
                      <div className="grid grid-cols-3 gap-2">
                        <input id="bulk-price-val" type="number" placeholder="Giá" className="h-10 px-3 bg-white border border-[#dce7f1] rounded-[10px] outline-none text-xs font-bold w-full" />
                        <input id="bulk-stock-val" type="number" placeholder={isEdit ? 'Không đổi' : 'Kho'} disabled={isEdit} className={cn("h-10 px-3 bg-white border border-[#dce7f1] rounded-[10px] outline-none text-xs font-bold w-full", isEdit && "opacity-50 cursor-not-allowed")} />
                        <input id="bulk-barcode-val" type="text" placeholder="Barcode" className="h-10 px-3 bg-white border border-[#dce7f1] rounded-[10px] outline-none text-xs font-bold w-full" />
                      </div>
                    </div>

                    <button
                      type="button"
                      onClick={() => {
                        const filterKey = (document.getElementById('bulk-attr-filter-key') as HTMLSelectElement)?.value;
                        const filterVal = (document.getElementById('bulk-attr-filter-val') as HTMLInputElement)?.value.trim();
                        const newPrice = (document.getElementById('bulk-price-val') as HTMLInputElement)?.value;
                        const newStock = (document.getElementById('bulk-stock-val') as HTMLInputElement)?.value;
                        const newBarcode = (document.getElementById('bulk-barcode-val') as HTMLInputElement)?.value;

                        if (!filterKey && !filterVal && !newPrice && !newStock && !newBarcode) {
                          alert('Vui lòng nhập thông tin lọc và gán.');
                          return;
                        }

                        const currentVariants = watch('variants') || [];
                        const updatedVariants = currentVariants.map((v: any) => {
                          let matches = true;
                          if (filterKey && filterVal) {
                            matches = v.attributes && v.attributes[filterKey] === filterVal;
                          } else if (filterVal) {
                            matches = v.attributes && Object.values(v.attributes).includes(filterVal);
                          }

                          if (matches) {
                            return {
                              ...v,
                              price: newPrice !== '' ? parseFloat(newPrice) : v.price,
                              stock: newStock !== '' ? parseInt(newStock) : v.stock,
                              barcode: newBarcode !== '' ? newBarcode : v.barcode
                            };
                          }
                          return v;
                        });

                        setValue('variants', updatedVariants, { shouldDirty: true });
                      }}
                      className="h-10 px-4 bg-primary text-white font-black text-xs uppercase tracking-wider rounded-[8px] hover:bg-primary/90 active:scale-95 transition-all shadow-md cursor-pointer flex items-center justify-center min-w-[90px]"
                    >
                      Áp dụng
                    </button>
                  </div>
                </div>

                <div className="border-t border-slate-200/40 pt-3 flex flex-wrap items-center gap-3">
                  <span className="text-[10px] font-black text-slate-400 uppercase">Hoặc gán thêm thuộc tính ẩn</span>
                  <input id="bulk-attr-key" type="text" placeholder="Key (VD: Driver)" className="h-9 px-3 bg-white border border-[#dce7f1] rounded-[10px] outline-none text-xs font-bold min-w-[140px]" />
                  <input id="bulk-attr-val" type="text" placeholder="Value (VD: 30mm fiber)" className="h-9 px-3 bg-white border border-[#dce7f1] rounded-[10px] outline-none text-xs font-bold min-w-[140px]" />
                  <button
                    type="button"
                    onClick={() => {
                      const filterKey = (document.getElementById('bulk-attr-filter-key') as HTMLSelectElement)?.value;
                      const filterVal = (document.getElementById('bulk-attr-filter-val') as HTMLInputElement)?.value.trim();
                      const extraKey = (document.getElementById('bulk-attr-key') as HTMLInputElement)?.value.trim();
                      const extraVal = (document.getElementById('bulk-attr-val') as HTMLInputElement)?.value.trim();

                      if (!extraKey || !extraVal) {
                        alert('Vui lòng điền Key và Value thuộc tính ẩn cần thêm.');
                        return;
                      }

                      const currentVariants = watch('variants') || [];
                      const updatedVariants = currentVariants.map((v: any) => {
                        let matches = true;
                        if (filterKey && filterVal) {
                          matches = v.attributes && v.attributes[filterKey] === filterVal;
                        } else if (filterVal) {
                          matches = v.attributes && Object.values(v.attributes).includes(filterVal);
                        }

                        if (matches) {
                          const attrs = { ...v.attributes, [extraKey]: extraVal };
                          return { ...v, attributes: attrs };
                        }
                        return v;
                      });

                      setValue('variants', updatedVariants, { shouldDirty: true });
                    }}
                    className="h-9 px-4 bg-primary hover:bg-primary/90 text-white font-black text-xs uppercase tracking-wider rounded-[8px] transition-all shadow-md active:scale-95 cursor-pointer"
                  >
                    Thêm Thuộc Tính
                  </button>
                </div>
              </div>

              {fields.map((field, idx) => (
                <div key={field.id} className="relative p-5 md:p-6 bg-white rounded-[12px] border border-[#edf2f7] shadow-[0_4px_12px_rgba(25,42,70,0.04)] animate-in slide-in-from-right-2 duration-300">
                  <div className="absolute -top-3 left-4 px-3 py-1 bg-primary text-white rounded-full text-[10px] font-black shadow-sm">BIẾN THỂ #{idx + 1}</div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div className="relative">
                      <label className="text-[10px] font-black text-slate-400 uppercase ml-1">SKU</label>
                      <Input icon={Hash} placeholder="IPH-15-BLU" {...register(`variants.${idx}.sku` as const)} error={(errors.variants as any)?.[idx]?.sku?.message} />
                    </div>
                    <div className="relative">
                      <label className="text-[10px] font-black text-slate-400 uppercase ml-1">Giá bán</label>
                      <Input icon={DollarSign} type="number" placeholder="0" {...register(`variants.${idx}.price` as const)} error={(errors.variants as any)?.[idx]?.price?.message} />
                    </div>
                    <div className="relative">
                      <label className="text-[10px] font-black text-slate-400 uppercase ml-1">Số lượng tồn</label>
                      {isEdit ? (
                        <div className="relative">
                          <Input icon={Package} type="number" value={watch(`variants.${idx}.stock`)} disabled className="opacity-60 cursor-not-allowed" />
                          <span className="absolute -bottom-4 left-1 text-[9px] font-bold text-[#7c8db5]">Không thể chỉnh sửa trực tiếp ở đây</span>
                        </div>
                      ) : (
                        <Input icon={Package} type="number" placeholder="0" {...register(`variants.${idx}.stock` as const)} error={(errors.variants as any)?.[idx]?.stock?.message} />
                      )}
                      {fields.length > 1 && (
                        <button
                          type="button"
                          onClick={() => remove(idx)}
                          className="absolute -top-1 -right-1 bg-red-500 text-white p-1 rounded-full shadow-lg hover:bg-red-600 transition-colors cursor-pointer"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      )}
                    </div>
                  </div>

                  {/* image upload + barcode */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
                    <div>
                      <label className="text-[10px] font-black text-slate-400 uppercase ml-1 flex items-center gap-1">
                        <UploadCloud className="w-3 h-3" /> Tải ảnh riêng cho SKU này
                      </label>
                      <div className="flex flex-wrap gap-2 mt-2 items-center bg-[#fbfcff] p-3 rounded-[10px] border border-[#dce7f1] min-h-[64px]">
                        <input
                          type="file"
                          multiple
                          accept="image/*,.glb,.usdz"
                          className="hidden"
                          id={`variant-file-${idx}`}
                          onChange={(e) => {
                            if (e.target.files) {
                              const addedFiles = Array.from(e.target.files);
                              const currentFiles = variantFiles[idx] || [];
                              const newFiles = [...currentFiles, ...addedFiles];
                              setVariantFiles({ ...variantFiles, [idx]: newFiles });
                            }
                          }}
                        />
                        <button
                          type="button"
                          onClick={() => document.getElementById(`variant-file-${idx}`)?.click()}
                          className="px-3 py-2 bg-white hover:bg-[#f2f7ff] text-[#607080] font-bold text-xs rounded-[8px] border border-[#dce7f1] flex items-center gap-1.5 transition-all active:scale-95 cursor-pointer"
                        >
                          <UploadCloud className="w-3.5 h-3.5" /> Chọn File
                        </button>

                        {watch(`variants.${idx}.assets`)?.length ? (
                          (watch(`variants.${idx}.assets`) || []).map((a: any, aIdx: number) => (
                            <div key={aIdx} className="relative w-12 h-12 rounded-[8px] overflow-hidden border border-[#dce7f1] flex items-center justify-center bg-[#f2f7ff] animate-in fade-in group">
                              <img src={a.url} alt="existing asset preview" className="w-full h-full object-cover" />
                              <button
                                type="button"
                                onClick={() => {
                                  const currentAssets = watch(`variants.${idx}.assets`) || [];
                                  const updatedAssets = currentAssets.filter((_: any, i: number) => i !== aIdx);
                                  setValue(`variants.${idx}.assets` as any, updatedAssets);
                                  if (a.url === watch(`variants.${idx}.imageUrl`)) {
                                    setValue(`variants.${idx}.imageUrl` as any, updatedAssets[0]?.url || '');
                                  }
                                }}
                                className="absolute top-1 right-1 bg-red-500 text-white rounded-full p-0.5 hover:bg-red-600 opacity-0 group-hover:opacity-100 transition-all cursor-pointer backdrop-blur-sm"
                              >
                                <Trash2 className="w-2.5 h-2.5" />
                              </button>
                            </div>
                          ))
                        ) : watch(`variants.${idx}.imageUrl`) && !(variantFiles[idx]?.length) && (
                          <div className="relative w-12 h-12 rounded-[8px] overflow-hidden border border-[#dce7f1] flex items-center justify-center bg-[#f2f7ff] animate-in fade-in group">
                            <img src={watch(`variants.${idx}.imageUrl`)} alt="existing preview" className="w-full h-full object-cover" />
                            <button
                              type="button"
                              onClick={() => setValue(`variants.${idx}.imageUrl` as any, '')}
                              className="absolute top-1 right-1 bg-red-500 text-white rounded-full p-0.5 hover:bg-red-600 opacity-0 group-hover:opacity-100 transition-all cursor-pointer backdrop-blur-sm"
                            >
                              <Trash2 className="w-2.5 h-2.5" />
                            </button>
                          </div>
                        )}

                        {(variantFiles[idx] || []).map((file, fileIdx) => {
                          const fileUrl = URL.createObjectURL(file);
                          const is3D = file.name.toLowerCase().endsWith('.glb') || file.name.toLowerCase().endsWith('.usdz');
                          return (
                            <div key={fileIdx} className="relative w-12 h-12 rounded-[8px] overflow-hidden border border-[#dce7f1] group flex items-center justify-center bg-[#f2f7ff] animate-in fade-in">
                              {is3D ? (
                                <span className="text-[9px] font-black uppercase text-primary">3D</span>
                              ) : (
                                <img src={fileUrl} alt="preview" className="w-full h-full object-cover" />
                              )}
                              <button
                                type="button"
                                onClick={() => {
                                  const currentFiles = variantFiles[idx] || [];
                                  const updatedFiles = currentFiles.filter((_, fIdx) => fIdx !== fileIdx);
                                  setVariantFiles({ ...variantFiles, [idx]: updatedFiles });
                                }}
                                className="absolute top-1 right-1 bg-red-500 text-white rounded-full p-0.5 hover:bg-red-600 transition-colors opacity-0 group-hover:opacity-100 backdrop-blur-sm cursor-pointer"
                              >
                                <Trash2 className="w-2.5 h-2.5" />
                              </button>
                            </div>
                          );
                        })}

                        <button
                          type="button"
                          onClick={() => {
                            const currentVariantAttributes = watch(`variants.${idx}.attributes`);
                            if (!currentVariantAttributes) {
                              alert('Vui lòng nhập thuộc tính màu sắc cho biến thể này trước.');
                              return;
                            }

                            const colorKey = Object.keys(currentVariantAttributes).find(
                              key => key.toLowerCase().includes('màu') || key.toLowerCase().includes('color')
                            );
                            if (!colorKey) {
                              alert('Vui lòng điền màu sắc vào thuộc tính trước khi áp dụng hàng loạt.');
                              return;
                            }
                            const colorValue = currentVariantAttributes[colorKey];
                            if (!colorValue) return;

                            const updatedVariantFiles = { ...variantFiles };
                            const allVariants = watch('variants');
                            allVariants.forEach((v: any, vIdx: number) => {
                              if (v.attributes && v.attributes[colorKey] === colorValue) {
                                updatedVariantFiles[vIdx] = variantFiles[idx] || [];
                              }
                            });
                            setVariantFiles(updatedVariantFiles);
                          }}
                          className="ml-auto px-2.5 py-1.5 bg-[#f2f7ff] hover:bg-primary/10 text-primary border border-[#dce7f1] rounded-[8px] text-[10px] font-black uppercase tracking-wider transition-colors cursor-pointer"
                        >
                          Áp dụng cho toàn bộ màu tương ứng
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="text-[10px] font-black text-slate-400 uppercase ml-1 flex items-center gap-1"><Barcode className="w-3 h-3" /> Barcode</label>
                      <input className="w-full h-14 px-4 bg-white border border-[#dce7f1] rounded-[10px] outline-none focus:border-primary focus:ring-4 focus:ring-primary/5 transition-all font-bold text-[#25396f] text-xs mt-2"
                        placeholder="Mã vạch (tùy chọn)" {...register(`variants.${idx}.barcode` as const)} />
                    </div>
                  </div>

                  <Controller
                    name={`variants.${idx}.attributes` as any}
                    control={control}
                    render={({ field }) => (
                      <AttributeManager
                        value={field.value || {}}
                        onChange={field.onChange}
                      />
                    )}
                  />
                </div>
              ))}
            </CardContent>
          </Card>
        </div>

        <div className="space-y-6 xl:sticky xl:top-6">
          <Card className="rounded-[12px] border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] bg-white">
            <CardHeader className="px-6 pt-6 pb-3 border-none">
              <CardTitle className="text-[20px] text-[#25396f] flex items-center gap-3">
                <span className="w-10 h-10 rounded-[10px] bg-primary/10 text-primary inline-flex items-center justify-center">
                  <UploadCloud className="w-5 h-5" />
                </span>
                Hình ảnh sản phẩm
              </CardTitle>
              <p className="text-sm font-semibold text-[#7c8db5]">Ảnh 2D là bắt buộc, có thể thêm GLB/USDZ cho trải nghiệm 3D.</p>
            </CardHeader>
            <CardContent className="px-6 pb-6 pt-2">
              <ImageUpload
                previews={previews}
                onUpload={onUpload}
                onRemove={onRemoveImage}
                primaryIndex={primaryIndex}
                setPrimaryIndex={setPrimaryIndex}
              />
            </CardContent>
          </Card>

          {error && (
            <div className="p-5 bg-red-50 border border-red-100 rounded-[12px] flex items-start gap-4 text-red-600 animate-in slide-in-from-bottom-4">
              <AlertCircle className="w-6 h-6 flex-shrink-0 mt-0.5" />
              <div>
                <h4 className="font-black text-red-700">Lỗi thực hiện</h4>
                <p className="text-sm font-bold opacity-80">{error}</p>
              </div>
            </div>
          )}

          <Card className="rounded-[12px] border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] bg-white">
            <CardHeader className="px-6 pt-6 pb-3 border-none">
              <CardTitle className="text-[20px] text-[#25396f] flex items-center gap-3">
                <span className="w-10 h-10 rounded-[10px] bg-[#f2f7ff] text-primary inline-flex items-center justify-center">
                  <TrendingUp className="w-5 h-5" />
                </span>
                Tóm tắt đăng bán
              </CardTitle>
            </CardHeader>
            <CardContent className="px-6 pb-6 space-y-5">
              <div className="rounded-[12px] border border-[#edf2f7] bg-[#fbfcff] p-5">
                <div>
                  <p className="text-[11px] font-black uppercase tracking-widest text-[#7c8db5] mb-2">Thông tin hiển thị</p>
                  <h3 className="text-xl font-black text-[#25396f] font-heading leading-tight line-clamp-2">{watchName || 'Tên sản phẩm mới'}</h3>
                  <p className="text-xs font-bold text-[#7c8db5] mt-2 line-clamp-2">{watchedDescription || 'Mô tả ngắn sẽ giúp đội vận hành kiểm tra nội dung nhanh hơn.'}</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="rounded-[10px] border border-[#edf2f7] p-3">
                  <p className="text-[10px] font-black uppercase text-[#7c8db5] mb-1">Danh mục</p>
                  <p className="text-sm font-extrabold text-[#25396f] truncate">{selectedCategory?.name || 'Chưa chọn'}</p>
                </div>
                <div className="rounded-[10px] border border-[#edf2f7] p-3">
                  <p className="text-[10px] font-black uppercase text-[#7c8db5] mb-1">Thương hiệu</p>
                  <p className="text-sm font-extrabold text-[#25396f] truncate">{selectedBrand?.name || 'Chưa chọn'}</p>
                </div>
                <div className="rounded-[10px] border border-[#edf2f7] p-3">
                  <p className="text-[10px] font-black uppercase text-[#7c8db5] mb-1">Media</p>
                  <p className="text-sm font-extrabold text-[#25396f]">{previews.length} file</p>
                </div>
              </div>

              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-[11px] font-black uppercase tracking-wider text-[#7c8db5]">Mức sẵn sàng</span>
                  <span className="text-[11px] font-black uppercase text-[#25396f]">{isValid ? 'Đủ điều kiện' : 'Cần kiểm tra'}</span>
                </div>
                <div className="h-2 w-full bg-[#f2f7ff] rounded-full overflow-hidden">
                  <div className={cn("h-full bg-primary transition-all duration-500", isValid ? "w-full" : "w-1/2")} />
                </div>
              </div>

              <Button onClick={handleSubmit(onSubmit, onInvalid)} isLoading={mutation.isPending} className="w-full h-11 rounded-[8px] bg-primary hover:bg-primary/90">
                <Save className="w-4 h-4 mr-2" />
                {isEdit ? 'Lưu thay đổi' : 'Tạo sản phẩm'}
              </Button>
            </CardContent>
          </Card>

          <div className="rounded-[12px] border border-[#edf2f7] bg-[#fbfcff] p-4">
            <div className="flex gap-3">
              <AlertCircle className="w-5 h-5 text-[#7c8db5] shrink-0 mt-0.5" />
              <div>
                <h4 className="text-sm font-extrabold text-[#25396f]">Checklist nhanh</h4>
                <p className="text-xs font-semibold text-[#7c8db5] mt-1">Đảm bảo có ảnh chính, SKU, giá và danh mục trước khi tạo sản phẩm.</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
