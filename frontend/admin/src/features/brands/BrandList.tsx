import React, { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  AlertCircle,
  CheckCircle2,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Edit,
  EyeOff,
  FileSpreadsheet,
  FileText,
  Filter,
  Image as ImageIcon,
  Plus,
  Download,
  Search,
  Star as StarIcon,
  Trash2,
} from '../../components/ui/IconlyIcons';
import {
  Bag as IconlyBag,
  Star as IconlyStar,
  TickSquare as IconlyTickSquare,
  Work as IconlyWork,
} from 'react-iconly';
import { toast } from 'sonner';
import { brandService } from '../../services/brand.service';
import { Badge } from '../../components/ui/Badge';
import { Button } from '../../components/ui/Button';
import { Card, CardContent } from '../../components/ui/Card';
import { ConfirmModal } from '../../components/ui/ConfirmModal';
import { Input } from '../../components/ui/Input';
import { cn } from '../../utils/cn';
import type { Brand } from '../../types';
import { BrandFormModal } from './BrandFormModal';

type StatusFilter = 'all' | 'active' | 'inactive';
type FeaturedFilter = 'all' | 'featured' | 'regular';
type SortKey = 'name' | 'products' | 'updatedAt';

const pageSizeOptions = [10, 50, 100] as const;

const getProductCount = (brand: Brand) => brand._count?.products ?? 0;

const formatDate = (value?: string) => {
  if (!value) return 'Chưa cập nhật';
  return new Intl.DateTimeFormat('vi-VN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(new Date(value));
};

const escapeHtml = (value: unknown) =>
  String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');

const getMutationErrorMessage = (error: unknown, fallback: string) => {
  const response = (error as { response?: { data?: { message?: string } } }).response;
  return response?.data?.message || fallback;
};

type MutationMessage = {
  message?: string;
};

export const BrandList: React.FC = () => {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [featuredFilter, setFeaturedFilter] = useState<FeaturedFilter>('all');
  const [sortKey, setSortKey] = useState<SortKey>('name');
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState<(typeof pageSizeOptions)[number]>(10);
  const [isExportOpen, setIsExportOpen] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingBrand, setEditingBrand] = useState<Brand | null>(null);
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [brandToDelete, setBrandToDelete] = useState<{ id: string; name: string } | null>(null);

  const queryClient = useQueryClient();

  const { data, isLoading, isError } = useQuery({
    queryKey: ['brands'],
    queryFn: () => brandService.getAllBrands(),
  });

  const brands: Brand[] = useMemo(() => (Array.isArray(data) ? data : data?.data ?? []), [data]);

  const createMutation = useMutation({
    mutationFn: (formData: FormData) => brandService.createBrand(formData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['brands'] });
      toast.success('Đã thêm thương hiệu mới');
      closeModal();
    },
    onError: (error: unknown) => {
      toast.error(getMutationErrorMessage(error, 'Không thể thêm thương hiệu'));
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, formData }: { id: string; formData: FormData }) => brandService.updateBrand(id, formData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['brands'] });
      toast.success('Đã cập nhật thương hiệu');
      closeModal();
    },
    onError: (error: unknown) => {
      toast.error(getMutationErrorMessage(error, 'Không thể cập nhật thương hiệu'));
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => brandService.deleteBrand(id),
    onSuccess: (res: MutationMessage) => {
      queryClient.invalidateQueries({ queryKey: ['brands'] });
      toast.success(res.message || 'Đã xử lý thương hiệu');
      setIsConfirmOpen(false);
      setBrandToDelete(null);
    },
    onError: (error: unknown) => {
      toast.error(getMutationErrorMessage(error, 'Không thể thực hiện thao tác này'));
    },
  });

  const toggleStatusMutation = useMutation({
    mutationFn: (id: string) => brandService.toggleBrand(id),
    onSuccess: (res: MutationMessage) => {
      queryClient.invalidateQueries({ queryKey: ['brands'] });
      toast.success(res.message || 'Đã cập nhật trạng thái');
    },
    onError: (error: unknown) => {
      toast.error(getMutationErrorMessage(error, 'Không thể đổi trạng thái thương hiệu'));
    },
  });

  const toggleFeaturedMutation = useMutation({
    mutationFn: (id: string) => brandService.toggleFeaturedBrand(id),
    onSuccess: (res: MutationMessage) => {
      queryClient.invalidateQueries({ queryKey: ['brands'] });
      toast.success(res.message || 'Đã cập nhật thương hiệu nổi bật');
    },
    onError: (error: unknown) => {
      toast.error(getMutationErrorMessage(error, 'Không thể cập nhật nổi bật'));
    },
  });

  const filteredBrands = useMemo(() => {
    const keyword = search.trim().toLowerCase();

    return brands
      .filter((brand) => {
        const matchesKeyword =
          !keyword ||
          brand.name.toLowerCase().includes(keyword) ||
          brand.slug.toLowerCase().includes(keyword);
        const matchesStatus =
          statusFilter === 'all' ||
          (statusFilter === 'active' && brand.isActive) ||
          (statusFilter === 'inactive' && !brand.isActive);
        const matchesFeatured =
          featuredFilter === 'all' ||
          (featuredFilter === 'featured' && brand.isFeatured) ||
          (featuredFilter === 'regular' && !brand.isFeatured);

        return matchesKeyword && matchesStatus && matchesFeatured;
      })
      .sort((first, second) => {
        if (sortKey === 'products') return getProductCount(second) - getProductCount(first);
        if (sortKey === 'updatedAt') {
          return new Date(second.updatedAt || 0).getTime() - new Date(first.updatedAt || 0).getTime();
        }
        return first.name.localeCompare(second.name, 'vi');
      });
  }, [brands, featuredFilter, search, sortKey, statusFilter]);

  const totalPages = Math.max(1, Math.ceil(filteredBrands.length / pageSize));
  const currentPage = Math.min(page, totalPages);
  const paginatedBrands = filteredBrands.slice((currentPage - 1) * pageSize, currentPage * pageSize);
  const rangeStart = filteredBrands.length === 0 ? 0 : (currentPage - 1) * pageSize + 1;
  const rangeEnd = Math.min(currentPage * pageSize, filteredBrands.length);
  const visiblePages = Array.from({ length: Math.min(totalPages, 5) }, (_, index) => {
    if (totalPages <= 5) return index + 1;
    if (currentPage <= 3) return index + 1;
    if (currentPage >= totalPages - 2) return totalPages - 4 + index;
    return currentPage - 2 + index;
  });
  const totalProducts = brands.reduce((total, brand) => total + getProductCount(brand), 0);
  const activeBrands = brands.filter((brand) => brand.isActive).length;
  const featuredBrands = brands.filter((brand) => brand.isFeatured).length;
  const hasActiveFilters = Boolean(search || statusFilter !== 'all' || featuredFilter !== 'all');

  const statCards = [
    {
      label: 'Tổng thương hiệu',
      value: brands.length,
      icon: IconlyWork,
      bgClass: 'bg-[#9694ff]',
      active: statusFilter === 'all' && featuredFilter === 'all',
      onClick: () => {
        setStatusFilter('all');
        setFeaturedFilter('all');
        setPage(1);
      },
    },
    {
      label: 'Đang hoạt động',
      value: activeBrands,
      icon: IconlyTickSquare,
      bgClass: 'bg-[#5ddc97]',
      active: statusFilter === 'active',
      onClick: () => {
        setStatusFilter('active');
        setPage(1);
      },
    },
    {
      label: 'Nổi bật',
      value: featuredBrands,
      icon: IconlyStar,
      bgClass: 'bg-[#eaca4a]',
      active: featuredFilter === 'featured',
      onClick: () => {
        setFeaturedFilter('featured');
        setPage(1);
      },
    },
    {
      label: 'Tổng sản phẩm',
      value: totalProducts,
      icon: IconlyBag,
      bgClass: 'bg-[#57caeb]',
      active: sortKey === 'products',
      onClick: () => {
        setSortKey('products');
        setPage(1);
      },
    },
  ];

  const openModal = (brand?: Brand) => {
    setEditingBrand(brand || null);
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setEditingBrand(null);
  };

  const handleDelete = (brand: Brand) => {
    setBrandToDelete({ id: brand.id, name: brand.name });
    setIsConfirmOpen(true);
  };

  const clearFilters = () => {
    setSearch('');
    setStatusFilter('all');
    setFeaturedFilter('all');
    setPage(1);
  };

  const exportExcel = () => {
    const header = ['ID', 'Tên thương hiệu', 'Slug', 'Trạng thái', 'Nổi bật', 'Số sản phẩm', 'Cập nhật'];
    const rows = filteredBrands.map((brand) => [
      brand.id,
      brand.name,
      brand.slug,
      brand.isActive ? 'Đang hoạt động' : 'Tạm ngưng',
      brand.isFeatured ? 'Có' : 'Không',
      getProductCount(brand),
      formatDate(brand.updatedAt),
    ]);

    const csv = [header, ...rows]
      .map((row) => row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(','))
      .join('\n');
    const blob = new Blob([`\uFEFF${csv}`], { type: 'application/vnd.ms-excel;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `brands-${new Date().toISOString().slice(0, 10)}.csv`;
    link.click();
    URL.revokeObjectURL(url);
    setIsExportOpen(false);
  };

  const exportPdf = () => {
    const rows = filteredBrands.map((brand) => `
      <tr>
        <td>${escapeHtml(brand.id)}</td>
        <td>${escapeHtml(brand.name)}</td>
        <td>/${escapeHtml(brand.slug)}</td>
        <td>${brand.isActive ? 'Đang hoạt động' : 'Tạm ngưng'}</td>
        <td>${brand.isFeatured ? 'Có' : 'Không'}</td>
        <td>${getProductCount(brand)}</td>
        <td>${escapeHtml(formatDate(brand.updatedAt))}</td>
      </tr>
    `).join('');

    const printWindow = window.open('', '_blank');
    if (!printWindow) return;

    printWindow.document.write(`
      <html>
        <head>
          <title>Danh sách thương hiệu</title>
          <style>
            body { font-family: Arial, sans-serif; color: #25396f; padding: 24px; }
            h1 { font-size: 22px; margin-bottom: 16px; }
            table { width: 100%; border-collapse: collapse; font-size: 12px; }
            th, td { border: 1px solid #dce7f1; padding: 8px; text-align: left; }
            th { background: #f2f7ff; }
          </style>
        </head>
        <body>
          <h1>Danh sách thương hiệu</h1>
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Tên thương hiệu</th>
                <th>Slug</th>
                <th>Trạng thái</th>
                <th>Nổi bật</th>
                <th>Sản phẩm</th>
                <th>Cập nhật</th>
              </tr>
            </thead>
            <tbody>${rows}</tbody>
          </table>
        </body>
      </html>
    `);
    printWindow.document.close();
    printWindow.focus();
    printWindow.print();
    setIsExportOpen(false);
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-4">
        {statCards.map((stat) => {
          const Icon = stat.icon;
          return (
            <button
              key={stat.label}
              type="button"
              onClick={stat.onClick}
              className={cn(
                'group flex items-center gap-4 rounded-[12px] bg-white px-6 py-6 text-left shadow-[0_5px_15px_rgba(25,42,70,0.06)] transition-all duration-300 hover:-translate-y-0.5 hover:shadow-[0_8px_20px_rgba(25,42,70,0.08)]',
                stat.active && 'ring-2 ring-primary/15'
              )}
            >
              <span className={cn('flex h-12 w-12 shrink-0 items-center justify-center rounded-[10px] text-white shadow-xs transition-transform duration-300 group-hover:scale-105', stat.bgClass)}>
                <Icon set="bold" primaryColor="currentColor" size={24} />
              </span>
              <span>
                <span className="block text-sm font-semibold text-[#7e83b4]">{stat.label}</span>
                <span className="mt-1 block text-2xl font-black leading-none text-primary">{stat.value}</span>
              </span>
            </button>
          );
        })}
      </div>

      <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
        <div className="flex flex-col gap-3 sm:flex-row">
          <div className="relative">
            <Button onClick={() => openModal()} className="h-10 rounded-[6px] bg-primary px-4 text-sm font-extrabold text-white shadow-[0_5px_12px_rgba(67,94,190,0.18)] hover:bg-primary/90">
              <Plus className="mr-2 h-5 w-5" />
              Thêm brand
            </Button>
            <button
              type="button"
              onClick={() => setIsExportOpen(!isExportOpen)}
              className="h-10 rounded-[5px] bg-[#f2f7ff] px-4 text-sm font-extrabold text-[#607080] inline-flex items-center gap-2 hover:bg-[#e9f1ff] transition-colors"
            >
              <Download className="w-4 h-4" />
              Xuất file
              <ChevronDown className="w-4 h-4" />
            </button>
            {isExportOpen && (
              <div className="absolute right-0 top-12 z-30 w-44 rounded-[8px] border border-[#dce7f1] bg-white shadow-[0_12px_24px_rgba(25,42,70,0.12)] p-1">
                <button
                  type="button"
                  onClick={exportExcel}
                  className="w-full h-9 rounded-[6px] px-3 text-left text-[12px] font-extrabold text-[#25396f] hover:bg-[#f2f7ff] inline-flex items-center gap-2"
                >
                  <FileSpreadsheet className="w-4 h-4 text-[#4fbe87]" />
                  Xuất Excel
                </button>
                <button
                  type="button"
                  onClick={exportPdf}
                  className="w-full h-9 rounded-[6px] px-3 text-left text-[12px] font-extrabold text-[#25396f] hover:bg-[#f2f7ff] inline-flex items-center gap-2"
                >
                  <FileText className="w-4 h-4 text-[#f3616d]" />
                  Xuất PDF
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      <Card className="rounded-[12px] border-[#f2f7ff] shadow-[0_5px_15px_rgba(25,42,70,0.06)]">
        <CardContent className="p-5">
          <div className="grid gap-4 xl:grid-cols-[1fr_180px_180px_180px_auto]">
            <Input
              icon={Search}
              placeholder="Tìm theo tên hoặc slug..."
              value={search}
              onChange={(event) => {
                setSearch(event.target.value);
                setPage(1);
              }}
              className="h-10 rounded-[5px] border-[#dce7f1] font-semibold text-[#25396f]"
            />
            <select
              value={statusFilter}
              onChange={(event) => {
                setStatusFilter(event.target.value as StatusFilter);
                setPage(1);
              }}
              className="h-10 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#607080] outline-none focus:border-primary focus:ring-4 focus:ring-primary/10"
            >
              <option value="all">Tất cả trạng thái</option>
              <option value="active">Đang hoạt động</option>
              <option value="inactive">Tạm ngưng</option>
            </select>
            <select
              value={featuredFilter}
              onChange={(event) => {
                setFeaturedFilter(event.target.value as FeaturedFilter);
                setPage(1);
              }}
              className="h-10 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#607080] outline-none focus:border-primary focus:ring-4 focus:ring-primary/10"
            >
              <option value="all">Tất cả hiển thị</option>
              <option value="featured">Nổi bật</option>
              <option value="regular">Thường</option>
            </select>
            <select
              value={sortKey}
              onChange={(event) => {
                setSortKey(event.target.value as SortKey);
                setPage(1);
              }}
              className="h-10 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#607080] outline-none focus:border-primary focus:ring-4 focus:ring-primary/10"
            >
              <option value="name">Sắp xếp theo tên</option>
              <option value="products">Nhiều sản phẩm</option>
              <option value="updatedAt">Mới cập nhật</option>
            </select>
            <div className="flex gap-2">
              <select
                value={pageSize}
                onChange={(event) => {
                  setPageSize(Number(event.target.value) as (typeof pageSizeOptions)[number]);
                  setPage(1);
                }}
                className="h-10 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#607080] outline-none"
              >
                {pageSizeOptions.map((size) => (
                  <option key={size} value={size}>
                    {size}
                  </option>
                ))}
              </select>
              <button
                type="button"
                className="h-10 rounded-[5px] bg-[#f2f7ff] px-4 text-sm font-extrabold text-[#607080] inline-flex items-center gap-2 hover:bg-[#e9f1ff] disabled:opacity-50"
                onClick={clearFilters}
                disabled={!hasActiveFilters}
              >
                <Filter className="w-4 h-4" />
                Xoá lọc
              </button>
            </div>
          </div>
        </CardContent>
      </Card>

      {isError && (
        <div className="flex items-center gap-4 rounded-[12px] border border-red-100 bg-red-50 p-6 text-red-600">
          <AlertCircle className="h-6 w-6" />
          <p className="font-bold">Không thể tải danh sách thương hiệu. Vui lòng thử lại.</p>
        </div>
      )}

      <div className="rounded-[12px] border border-[#f2f7ff] bg-white shadow-[0_5px_15px_rgba(25,42,70,0.06)] overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[980px] text-left">
            <thead className="bg-[#f8fbff] border-b border-[#f2f7ff]">
              <tr>
                <th className="px-6 py-4 text-xs font-black uppercase tracking-widest text-[#607080]">Thương hiệu</th>
                <th className="px-4 py-4 text-xs font-black uppercase tracking-widest text-[#607080]">Slug</th>
                <th className="px-4 py-4 text-center text-xs font-black uppercase tracking-widest text-[#607080]">Sản phẩm</th>
                <th className="px-4 py-4 text-center text-xs font-black uppercase tracking-widest text-[#607080]">Điểm</th>
                <th className="px-4 py-4 text-center text-xs font-black uppercase tracking-widest text-[#607080]">Trạng thái</th>
                <th className="px-4 py-4 text-center text-xs font-black uppercase tracking-widest text-[#607080]">Cập nhật</th>
                <th className="px-6 py-4 text-right text-xs font-black uppercase tracking-widest text-[#607080]">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#f2f7ff]">
              {isLoading ? (
                Array.from({ length: 5 }).map((_, index) => (
                  <tr key={index} className="animate-pulse">
                    <td colSpan={7} className="px-6 py-5">
                      <div className="h-12 rounded bg-[#f2f7ff]" />
                    </td>
                  </tr>
                ))
              ) : paginatedBrands.length > 0 ? (
                paginatedBrands.map((brand) => (
                  <tr key={brand.id} className="transition-colors hover:bg-[#fbfcff]">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-11 h-11 rounded-[10px] border border-[#dce7f1] bg-[#f2f7ff] flex items-center justify-center overflow-hidden shrink-0">
                          {brand.logoUrl ? (
                            <img src={brand.logoUrl} alt={brand.name} className="w-full h-full object-contain p-2" />
                          ) : (
                            <ImageIcon className="w-5 h-5 text-[#7c8db5]" />
                          )}
                        </div>
                        <div className="min-w-0">
                          <div className="flex items-center gap-2">
                            <p className="truncate text-sm font-black text-[#25396f]">{brand.name}</p>
                            {brand.isFeatured && <StarIcon className="w-4 h-4 shrink-0 text-[#eaca4a]" />}
                          </div>
                          <p className="text-xs font-bold text-[#7c8db5]">ID: {brand.id.slice(0, 8)}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <span className="inline-flex rounded-[6px] bg-[#f2f7ff] px-2.5 py-1 text-[12px] font-bold text-[#607080]">/{brand.slug}</span>
                    </td>
                    <td className="px-4 py-4 text-center text-sm font-black text-primary">{getProductCount(brand)}</td>
                    <td className="px-4 py-4 text-center">
                      <span className="inline-flex items-center gap-1 text-sm font-bold text-[#607080]">
                        {Math.round(brand.score ?? 0)}
                      </span>
                    </td>
                    <td className="px-4 py-4 text-center">
                      {brand.isActive ? (
                        <Badge variant="success" className="rounded-[6px] px-2.5 py-1 text-[10px] uppercase tracking-widest">

                          Hoạt động
                        </Badge>
                      ) : (
                        <Badge variant="danger" className="rounded-[6px] px-2.5 py-1 text-[10px] uppercase tracking-widest">

                          Tạm ngưng
                        </Badge>
                      )}
                    </td>
                    <td className="px-4 py-4 text-center text-xs font-bold text-[#607080]">{formatDate(brand.updatedAt)}</td>
                    <td className="px-6 py-4">
                      <div className="flex justify-end gap-2">
                        <button
                          type="button"
                          className={cn(
                            'w-9 h-9 rounded-[6px] inline-flex items-center justify-center transition-colors',
                            brand.isFeatured ? 'bg-amber-50 text-amber-600 hover:bg-amber-100' : 'text-[#607080] hover:bg-amber-50 hover:text-amber-600'
                          )}
                          onClick={() => toggleFeaturedMutation.mutate(brand.id)}
                          disabled={toggleFeaturedMutation.isPending && toggleFeaturedMutation.variables === brand.id}
                          title={brand.isFeatured ? 'Bỏ nổi bật' : 'Đánh dấu nổi bật'}
                        >
                          <StarIcon className="w-4 h-4" />
                        </button>
                        <button
                          type="button"
                          className={cn(
                            'w-9 h-9 rounded-[6px] inline-flex items-center justify-center transition-colors',
                            brand.isActive ? 'text-orange-500 hover:bg-orange-50' : 'text-green-600 hover:bg-green-50'
                          )}
                          onClick={() => toggleStatusMutation.mutate(brand.id)}
                          disabled={toggleStatusMutation.isPending && toggleStatusMutation.variables === brand.id}
                          title={brand.isActive ? 'Tạm ngưng' : 'Kích hoạt'}
                        >
                          {brand.isActive ? <EyeOff className="w-4 h-4" /> : <CheckCircle2 className="w-4 h-4" />}
                        </button>
                        <button
                          type="button"
                          className="w-9 h-9 rounded-[6px] inline-flex items-center justify-center bg-primary/10 text-primary hover:bg-primary/20 transition-colors"
                          onClick={() => openModal(brand)}
                          title="Sửa"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        <button
                          type="button"
                          className="w-9 h-9 rounded-[6px] inline-flex items-center justify-center text-red-500 hover:bg-red-50 transition-colors"
                          onClick={() => handleDelete(brand)}
                          title="Xoá"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="px-6 py-16 text-center">
                    <div className="mx-auto mb-4 w-16 h-16 rounded-[14px] bg-[#f2f7ff] flex items-center justify-center">
                      <ImageIcon className="w-8 h-8 text-[#7c8db5]" />
                    </div>
                    <p className="text-lg font-black text-[#25396f]">Không có thương hiệu phù hợp</p>
                    <p className="mt-1 text-sm font-semibold text-[#7c8db5]">Thử xoá bộ lọc hoặc thêm thương hiệu mới.</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <div className="flex flex-col gap-4 rounded-b-[12px] bg-white px-6 py-5 shadow-[0_5px_15px_rgba(25,42,70,0.06)] md:flex-row md:items-center md:justify-between">
        <p className="text-sm font-semibold text-[#a0a8c3]">
          Hiển thị {rangeStart} tới {rangeEnd} của {filteredBrands.length} thương hiệu
        </p>
        <div className="flex items-center gap-2">
          <button
            type="button"
            disabled={currentPage === 1}
            onClick={() => setPage(Math.max(currentPage - 1, 1))}
            className="w-11 h-11 rounded-[6px] border border-[#dce7f1] bg-white text-[#7c8db5] inline-flex items-center justify-center hover:text-primary hover:border-primary disabled:opacity-40 disabled:pointer-events-none"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>
          {visiblePages.map((visiblePage) => (
            <button
              key={visiblePage}
              type="button"
              onClick={() => setPage(visiblePage)}
              className={cn(
                'w-11 h-11 rounded-[6px] text-sm font-extrabold transition-all',
                visiblePage === currentPage
                  ? 'bg-primary text-white shadow-[0_5px_12px_rgba(67,94,190,0.18)]'
                  : 'bg-white border border-[#dce7f1] text-[#607080] hover:text-primary hover:border-primary'
              )}
            >
              {visiblePage}
            </button>
          ))}
          <button
            type="button"
            disabled={currentPage === totalPages}
            onClick={() => setPage(Math.min(currentPage + 1, totalPages))}
            className="w-11 h-11 rounded-[6px] border border-[#dce7f1] bg-white text-[#7c8db5] inline-flex items-center justify-center hover:text-primary hover:border-primary disabled:opacity-40 disabled:pointer-events-none"
          >
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>

      {isModalOpen && (
        <BrandFormModal
          brand={editingBrand}
          isSaving={createMutation.isPending || updateMutation.isPending}
          onClose={closeModal}
          onSave={(formData) => {
            if (editingBrand) {
              updateMutation.mutate({ id: editingBrand.id, formData });
              return;
            }
            createMutation.mutate(formData);
          }}
        />
      )}

      <ConfirmModal
        isOpen={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={() => brandToDelete && deleteMutation.mutate(brandToDelete.id)}
        title="Xác nhận xử lý thương hiệu"
        message={`Bạn muốn xoá hoặc tạm ngưng thương hiệu "${brandToDelete?.name}"? Nếu thương hiệu còn sản phẩm, hệ thống sẽ tạm ngưng để tránh mất dữ liệu liên kết.`}
        confirmText="Xác nhận"
        cancelText="Huỷ"
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
};
