import React, { useState, useEffect } from 'react';
import { useForm, useFieldArray } from 'react-hook-form';
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
  TrendingUp
} from 'lucide-react';
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
  sku: z.string().min(1, 'SKU là bắt buộc'),
  price: z.preprocess((v) => Number(v), z.number().min(0, 'Giá không hợp lệ')),
  stock: z.preprocess((v) => Number(v), z.number().min(0, 'Tồn kho không hợp lệ')),
  attributes: z.record(z.string(), z.any()).optional(),
});

const productSchema = z.object({
  name: z.string().min(3, 'Tên sản phẩm ít nhất 3 ký tự'),
  description: z.string().min(10, 'Mô tả ít nhất 10 ký tự'),
  categoryId: z.string().min(1, 'Vui lòng chọn danh mục'),
  brandId: z.string().min(1, 'Vui lòng chọn thương hiệu'),
  variants: z.array(variantSchema).min(1, 'Ít nhất 1 phân loại sản phẩm'),
});

type FormValues = z.infer<typeof productSchema>;

export const ProductPage: React.FC = () => {
  const { slug } = useParams();
  const isEdit = !!slug;
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const [files, setFiles] = useState<File[]>([]);
  const [previews, setPreviews] = useState<string[]>([]);
  const [primaryIndex, setPrimaryIndex] = useState(0);
  const [error, setError] = useState<string | null>(null);

  const { data: categories } = useQuery<Category[]>({ queryKey: ['categories'], queryFn: categoryService.getAllCategories });
  const { data: brands } = useQuery<Brand[]>({ queryKey: ['brands'], queryFn: brandService.getAllBrands });
  
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
    formState: { errors, isValid },
  } = useForm<FormValues>({
    resolver: zodResolver(productSchema) as any,
    defaultValues: {
      name: '',
      description: '',
      categoryId: '',
      brandId: '',
      variants: [{ sku: '', price: 0, stock: 0 }],
    },
  });

  const { fields, append, remove } = useFieldArray({
    control,
    name: "variants" as any,
  });

  useEffect(() => {
    if (editProduct) {
      reset({
        name: editProduct.name,
        description: editProduct.description,
        categoryId: editProduct.categoryId,
        brandId: editProduct.brandId,
        variants: editProduct.variants.map((v: any) => ({
          sku: v.sku,
          price: v.price,
          stock: v.stock,
          attributes: v.attributes
        })) as any,
      });
      
      if (editProduct.assets?.length) {
        setPreviews(editProduct.assets.map((a: any) => a.url));
        const pIdx = editProduct.assets.findIndex((a: any) => a.isPrimary);
        setPrimaryIndex(pIdx >= 0 ? pIdx : 0);
      }
    }
  }, [editProduct, reset]);

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
    setPreviews(prev => prev.filter((_, i) => i !== index));
    if (index < files.length) {
       setFiles(prev => prev.filter((_, i) => i !== index));
    }
    if (primaryIndex === index) setPrimaryIndex(0);
    else if (primaryIndex > index) setPrimaryIndex(primaryIndex - 1);
  };

  const onSubmit: SubmitHandler<FormValues> = (values) => {
    setError(null);
    const formData = new FormData();
    formData.append('name', values.name);
    formData.append('description', values.description);
    formData.append('categoryId', values.categoryId);
    formData.append('brandId', values.brandId);
    formData.append('primaryIndex', primaryIndex.toString());
    formData.append('variants', JSON.stringify(values.variants));
    
    files.forEach(file => {
      formData.append('files', file);
    });

    mutation.mutate(formData);
  };

  if (isEdit && isEditLoading) return <div className="text-center py-20 font-bold text-primary animate-pulse font-heading">Đang tải dữ liệu sản phẩm...</div>;

  return (
    <div className="max-w-5xl mx-auto space-y-8 animate-in fade-in duration-300 pb-20">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="outline" onClick={() => navigate('/products')} className="p-3 bg-white rounded-2xl border border-slate-200 hover:bg-slate-100 transition-colors h-14 w-14">
            <ArrowLeft className="w-6 h-6 text-slate-600" />
          </Button>
          <div className="space-y-1">
            <h1 className="text-3xl font-black text-slate-900 font-heading leading-none">{isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm'}</h1>
            <p className="text-sm font-bold text-slate-400 uppercase tracking-widest">{isEdit ? 'Cập nhật lại thông tin & kho' : 'Thiết lập nội dung & thuộc tính'}</p>
          </div>
        </div>
        <Button onClick={handleSubmit(onSubmit)} isLoading={mutation.isPending} className="py-4 px-8 min-w-[200px] shadow-primary/20 shadow-2xl h-14">
           <Save className="w-5 h-5 mr-3" />
           {isEdit ? 'Lưu thay đổi' : 'Đăng bán ngay'}
        </Button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 space-y-8">
          <Card className="rounded-3xl border-none shadow-2xl shadow-slate-200/50">
            <CardHeader className="pl-10 pt-8 border-none">
               <CardTitle className="text-xl flex items-center gap-2">
                  <FileText className="text-primary w-6 h-6" /> Thông tin cơ bản
               </CardTitle>
            </CardHeader>
            <CardContent className="px-10 pb-10 space-y-6">
              <Input label="Tên sản phẩm" placeholder="Samsung Galaxy S24 Ultra..." {...register('name')} error={errors.name?.message} />
              
              <div className="space-y-1.5">
                <label className="text-sm font-bold text-slate-700 ml-1 flex items-center gap-2">
                   <Package className="w-4 h-4 text-primary/60" /> Mô tả chi tiết
                </label>
                <textarea 
                  {...register('description')} 
                  className={cn(
                    "w-full h-40 p-4 border border-slate-200 rounded-2xl outline-none focus:border-primary focus:ring-3 focus:ring-primary/20 transition-all font-body text-slate-700 resize-none",
                    errors.description && "border-red-400 focus:border-red-500 focus:ring-red-100"
                  )}
                  placeholder="Mô tả các đặc điểm nổi bật của sản phẩm..."
                />
                {errors.description && <span className="text-xs font-bold text-red-500 ml-1">{errors.description.message}</span>}
              </div>

              <div className="grid grid-cols-2 gap-6">
                 <div className="space-y-1.5 flex flex-col">
                    <label className="text-sm font-bold text-slate-700 ml-1">Danh mục</label>
                    <div className="relative">
                      <select 
                        {...register('categoryId')} 
                        className="w-full h-12 px-4 bg-white border border-slate-200 rounded-xl outline-none focus:border-primary focus:ring-3 focus:ring-primary/20 appearance-none font-bold text-slate-700 transition-all cursor-pointer"
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
                      <Layers className="absolute right-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none" />
                    </div>
                    {errors.categoryId && <span className="text-xs font-bold text-red-500 ml-1">{errors.categoryId.message}</span>}
                 </div>
                 <div className="space-y-1.5 flex flex-col">
                    <label className="text-sm font-bold text-slate-700 ml-1">Thương hiệu</label>
                    <div className="relative">
                      <select 
                        {...register('brandId')} 
                        className="w-full h-12 px-4 bg-white border border-slate-200 rounded-xl outline-none focus:border-primary focus:ring-3 focus:ring-primary/20 appearance-none font-bold text-slate-700 transition-all cursor-pointer"
                      >
                        <option value="">Chọn thương hiệu</option>
                        {brands?.map((b: any) => <option key={b.id} value={b.id}>{b.name}</option>)}
                      </select>
                      <Plus className="absolute right-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none" />
                    </div>
                    {errors.brandId && <span className="text-xs font-bold text-red-500 ml-1">{errors.brandId.message}</span>}
                 </div>
              </div>
            </CardContent>
          </Card>

          <Card className="rounded-3xl border-none shadow-2xl shadow-slate-200/50">
             <CardHeader className="pl-10 pt-8 border-none flex flex-row items-center justify-between">
                 <CardTitle className="text-xl flex items-center gap-2">
                    <Layers className="text-primary w-6 h-6" /> Phân loại & Kho
                 </CardTitle>
                 <Button type="button" variant="outline" size="sm" className="rounded-full shadow-none" onClick={() => append({ sku: '', price: 0, stock: 0 })}>
                    <Plus className="w-4 h-4 mr-1.5" /> Thêm SKU
                 </Button>
             </CardHeader>
             <CardContent className="px-10 pb-10 space-y-4">
                {fields.map((field, idx) => (
                  <div key={field.id} className="relative p-6 bg-slate-50/50 rounded-2xl border border-slate-100 animate-in slide-in-from-right-2 duration-300">
                    <div className="absolute -top-3 left-4 px-3 bg-white border border-slate-100 rounded-full text-[10px] font-black text-primary shadow-sm">BIẾN THỂ #{idx + 1}</div>
                    
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
                        <Input icon={Package} type="number" placeholder="0" {...register(`variants.${idx}.stock` as const)} error={(errors.variants as any)?.[idx]?.stock?.message} />
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
                  </div>
                ))}
             </CardContent>
          </Card>
        </div>

        <div className="space-y-8">
           <Card className="rounded-3xl border-none shadow-2xl shadow-slate-200/50">
              <CardHeader className="pt-8 border-none">
                 <CardTitle className="text-xl flex items-center gap-2">
                    <Plus className="text-primary w-6 h-6" /> Hình ảnh sản phẩm
                 </CardTitle>
                 <p className="text-xs font-bold text-slate-400">Chọn tối đa 10 hình ảnh chất lượng cao</p>
              </CardHeader>
              <CardContent className="pb-10 pt-2">
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
             <div className="p-6 bg-red-50 border-2 border-red-100 rounded-3xl flex items-start gap-4 text-red-600 animate-in slide-in-from-bottom-4">
                <AlertCircle className="w-6 h-6 flex-shrink-0 mt-0.5" />
                <div>
                   <h4 className="font-black text-red-700">Lỗi thực hiện</h4>
                   <p className="text-sm font-bold opacity-80">{error}</p>
                </div>
             </div>
           )}

           <div className="p-10 bg-gradient-to-br from-primary to-secondary rounded-[40px] text-white shadow-2xl shadow-primary/30 relative overflow-hidden group">
              <div className="absolute top-0 left-0 w-full h-full opacity-10 bg-[radial-gradient(circle_at_2px_2px,_white_1px,_transparent_0)] bg-[length:24px_24px] group-hover:scale-110 transition-transform duration-500" />
              <div className="relative z-10 space-y-4">
                 <TrendingUp className="w-10 h-10 group-hover:rotate-12 transition-transform h-min" />
                 <h3 className="text-2xl font-black font-heading leading-tight">Yêu cầu đăng bán</h3>
                 <p className="text-sm font-bold opacity-70 leading-relaxed">Hãy chắc chắn rằng dòng sản phẩm này đã đầy đủ SKU và hình ảnh minh hoạ trước khi đăng.</p>
                 <div className="pt-4">
                    <div className="h-1.5 w-full bg-white/20 rounded-full overflow-hidden">
                       <div className={cn("h-full bg-cta transition-all duration-500", isValid ? "w-full" : "w-1/3")} />
                    </div>
                    <p className="text-[10px] font-black uppercase mt-2 tracking-widest">{isValid ? 'Đủ điều kiện xuất bản' : 'Nội dung chưa hợp lệ'}</p>
                 </div>
              </div>
           </div>
        </div>
      </div>
    </div>
  );
};
