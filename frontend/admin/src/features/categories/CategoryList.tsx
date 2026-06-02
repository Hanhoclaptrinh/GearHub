import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  AlertCircle,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Download,
  Edit,
  FileSpreadsheet,
  FileText,
  Filter,
  Hash,
  Layers,
  Plus,
  RotateCcw,
  Search,
  Trash2,
} from '../../components/ui/IconlyIcons';
import ApexCharts from 'apexcharts';
import {
  Category as IconlyCategory,
  Folder as IconlyFolder,
  Graph as IconlyGraph,
  Paper as IconlyPaper,
  PaperFail as IconlyPaperFail,
} from 'react-iconly';
import { toast } from 'sonner';
import { categoryService } from '../../services/category.service';
import { Button } from '../../components/ui/Button';
import { ConfirmModal } from '../../components/ui/ConfirmModal';
import { cn } from '../../utils/cn';
import type { Category } from '../../types';
import { CategoryFormModal } from './CategoryFormModal';

type ProductFilter = 'all' | 'with_products' | 'empty';
type SortKey = 'name' | 'products_desc' | 'newest';
type CategoryRow = Category & { level: 0 | 1; parentName?: string | null };

const pageSizeOptions = [10, 50, 100] as const;

const formatDate = (value?: string) => {
  if (!value) return 'N/A';
  return new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(new Date(value));
};

const escapeHtml = (value: unknown) =>
  String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');

const getProductCount = (category: Category) => category._count?.products ?? 0;

const getMutationErrorMessage = (error: unknown, fallback: string) => {
  const response = (error as { response?: { data?: { message?: string } } }).response;
  return response?.data?.message || fallback;
};

const TopCategoryChart: React.FC<{ data: Array<{ name: string; count: number }> }> = ({ data }) => {
  const chartRef = useRef<HTMLDivElement>(null);
  const instanceRef = useRef<ApexCharts | null>(null);

  useEffect(() => {
    if (!chartRef.current) return;

    const chartData = data.length > 0 ? data : [{ name: 'Chưa có dữ liệu', count: 0 }];
    const options: ApexCharts.ApexOptions = {
      chart: { type: 'bar', height: 230, toolbar: { show: false }, fontFamily: 'inherit' },
      series: [{ name: 'Sản phẩm', data: chartData.map((item) => item.count) }],
      xaxis: {
        categories: chartData.map((item) => item.name),
        labels: { style: { colors: '#7c8db5', fontSize: '12px', fontWeight: 700 } },
        axisBorder: { show: false },
        axisTicks: { show: false },
      },
      yaxis: { labels: { style: { colors: '#7c8db5', fontSize: '12px', fontWeight: 700 } } },
      colors: ['#435ebe'],
      plotOptions: { bar: { borderRadius: 6, columnWidth: '44%', distributed: true } },
      dataLabels: { enabled: true, style: { colors: ['#25396f'], fontWeight: 800 }, offsetY: -18 },
      grid: { borderColor: '#f2f7ff', strokeDashArray: 4 },
      legend: { show: false },
      tooltip: { theme: 'light', y: { formatter: (value) => `${value} sản phẩm` } },
    };

    if (instanceRef.current) {
      instanceRef.current.updateOptions(options, true, true);
    } else {
      instanceRef.current = new ApexCharts(chartRef.current, options);
      instanceRef.current.render();
    }

    return () => {
      instanceRef.current?.destroy();
      instanceRef.current = null;
    };
  }, [data]);

  return <div ref={chartRef} className="min-h-[230px]" />;
};

export const CategoryList: React.FC = () => {
  const [search, setSearch] = useState('');
  const [productFilter, setProductFilter] = useState<ProductFilter>('all');
  const [sortKey, setSortKey] = useState<SortKey>('name');
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState<(typeof pageSizeOptions)[number]>(10);
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [isExportOpen, setIsExportOpen] = useState(false);
  const [expandedGroups, setExpandedGroups] = useState<Record<string, boolean>>({});
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [categoryToDelete, setCategoryToDelete] = useState<{ id: string; name: string } | null>(null);

  const queryClient = useQueryClient();

  const { data: categories = [], isLoading, isError } = useQuery({
    queryKey: ['categories'],
    queryFn: categoryService.getAllCategories,
  });

  const createMutation = useMutation({
    mutationFn: (formData: FormData) => categoryService.createCategory(formData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] });
      toast.success('Thiết lập danh mục mới thành công!');
      closeModal();
    },
    onError: (error: unknown) => {
      toast.error(getMutationErrorMessage(error, 'Có lỗi xảy ra khi tạo danh mục'));
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, formData }: { id: string; formData: FormData }) => categoryService.updateCategory(id, formData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] });
      toast.success('Cập nhật thông tin danh mục thành công!');
      closeModal();
    },
    onError: (error: unknown) => {
      toast.error(getMutationErrorMessage(error, 'Có lỗi xảy ra khi cập nhật'));
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => categoryService.deleteCategory(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] });
      toast.success('Đã gỡ bỏ danh mục khỏi hệ thống');
      setIsConfirmOpen(false);
    },
    onError: (error: unknown) => {
      toast.error(getMutationErrorMessage(error, 'Không thể xoá danh mục này. Vui lòng kiểm tra các danh mục con hoặc sản phẩm liên quan.'));
    },
  });

  const flatCategories = useMemo<CategoryRow[]>(() => {
    return categories.flatMap((category: Category) => [
      { ...category, level: 0 as const, parentName: null },
      ...(category.children || []).map((child) => ({ ...child, level: 1 as const, parentName: category.name })),
    ]);
  }, [categories]);

  const stats = useMemo(() => {
    const total = flatCategories.length;
    const root = categories.length;
    const children = flatCategories.filter((category) => category.level === 1).length;
    const withProducts = flatCategories.filter((category) => getProductCount(category) > 0).length;
    return { total, root, children, withProducts, empty: total - withProducts };
  }, [categories.length, flatCategories]);

  const keyword = search.trim().toLowerCase();
  const matchesKeyword = useCallback((category: Category) =>
    !keyword || category.name.toLowerCase().includes(keyword) || category.slug.toLowerCase().includes(keyword), [keyword]);
  const matchesProductFilter = useCallback((category: Category) => {
    const count = getProductCount(category);
    return productFilter === 'all' || (productFilter === 'with_products' && count > 0) || (productFilter === 'empty' && count === 0);
  }, [productFilter]);

  const filteredCategories = useMemo(() => {
    return flatCategories
      .filter((category) => {
        const textMatch = matchesKeyword(category) || Boolean(category.parentName?.toLowerCase().includes(keyword));
        return textMatch && matchesProductFilter(category);
      })
      .sort((a, b) => {
        if (sortKey === 'products_desc') return getProductCount(b) - getProductCount(a);
        if (sortKey === 'newest') return new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime();
        return a.name.localeCompare(b.name, 'vi');
      });
  }, [flatCategories, keyword, matchesKeyword, matchesProductFilter, sortKey]);

  const groupedCategories = useMemo(() => {
    return categories
      .map((category: Category) => {
        const children = category.children || [];
        const matchingChildren = children.filter((child) => matchesKeyword(child) && matchesProductFilter(child));
        const parentMatches = matchesKeyword(category) && matchesProductFilter(category);
        const totalProductCount = getProductCount(category) + children.reduce((sum, child) => sum + getProductCount(child), 0);
        const visible =
          parentMatches ||
          matchingChildren.length > 0 ||
          (!keyword && productFilter === 'all');

        return {
          ...category,
          matchingChildren,
          totalProductCount,
          visible,
        };
      })
      .filter((category) => {
        if (!category.visible) return false;
        if (productFilter === 'with_products') return category.totalProductCount > 0;
        if (productFilter === 'empty') return category.totalProductCount === 0 || category.matchingChildren.length > 0 || getProductCount(category) === 0;
        return true;
      })
      .sort((a, b) => {
        if (sortKey === 'products_desc') return b.totalProductCount - a.totalProductCount;
        if (sortKey === 'newest') return new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime();
        return a.name.localeCompare(b.name, 'vi');
      });
  }, [categories, keyword, matchesKeyword, matchesProductFilter, productFilter, sortKey]);

  const totalPages = Math.max(1, Math.ceil(groupedCategories.length / pageSize));
  const paginatedCategories = groupedCategories.slice((page - 1) * pageSize, page * pageSize);
  const visiblePages = Array.from({ length: Math.min(totalPages, 5) }, (_, index) => {
    if (totalPages <= 5) return index + 1;
    if (page <= 3) return index + 1;
    if (page >= totalPages - 2) return totalPages - 4 + index;
    return page - 2 + index;
  });

  const topCategoryChartData = useMemo(() => {
    return [...flatCategories]
      .filter((category) => getProductCount(category) > 0)
      .sort((a, b) => getProductCount(b) - getProductCount(a))
      .slice(0, 7)
      .map((category) => ({ name: category.name, count: getProductCount(category) }));
  }, [flatCategories]);

  const hasActiveFilters = Boolean(search || productFilter !== 'all' || sortKey !== 'name');

  const statCards = [
    { label: 'Tổng danh mục', value: stats.total, icon: IconlyCategory, bgClass: 'bg-[#9694ff]' },
    { label: 'Danh mục gốc', value: stats.root, icon: IconlyFolder, bgClass: 'bg-[#57caeb]' },
    { label: 'Danh mục con', value: stats.children, icon: IconlyPaper, bgClass: 'bg-[#5ddc97]' },
    { label: 'Có sản phẩm', value: stats.withProducts, icon: IconlyGraph, bgClass: 'bg-[#eaca4a]' },
    { label: 'Danh mục trống', value: stats.empty, icon: IconlyPaperFail, bgClass: 'bg-[#ff7976]' },
  ];

  const resetFilters = () => {
    setSearch('');
    setProductFilter('all');
    setSortKey('name');
    setPage(1);
  };

  const openModal = (category?: Category) => {
    if (category) setEditingCategory(category);
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setEditingCategory(null);
  };

  const handleDelete = (id: string, name: string) => {
    setCategoryToDelete({ id, name });
    setIsConfirmOpen(true);
  };

  const exportRows = filteredCategories.map((category) => ({
    id: category.id,
    name: category.name,
    slug: category.slug,
    parent: category.parentName || 'Danh mục gốc',
    productCount: getProductCount(category),
    createdAt: formatDate(category.createdAt),
    updatedAt: formatDate(category.updatedAt),
  }));

  const exportExcel = () => {
    const header = ['ID', 'Tên danh mục', 'Slug', 'Cấp cha', 'Số sản phẩm', 'Ngày tạo', 'Cập nhật'];
    const rows = exportRows.map((row) => [row.id, row.name, row.slug, row.parent, row.productCount, row.createdAt, row.updatedAt]);
    const csv = [header, ...rows]
      .map((row) => row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(','))
      .join('\n');
    const blob = new Blob([`\uFEFF${csv}`], { type: 'application/vnd.ms-excel;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `categories-${new Date().toISOString().slice(0, 10)}.csv`;
    link.click();
    URL.revokeObjectURL(url);
    setIsExportOpen(false);
  };

  const exportPdf = () => {
    const printWindow = window.open('', '_blank');
    if (!printWindow) {
      toast.error('Trình duyệt đang chặn cửa sổ xuất PDF');
      return;
    }

    printWindow.document.write(`
      <html>
        <head>
          <title>Danh sách danh mục</title>
          <style>
            body { font-family: Arial, sans-serif; color: #25396f; padding: 24px; }
            h1 { font-size: 20px; margin-bottom: 16px; }
            table { width: 100%; border-collapse: collapse; font-size: 12px; }
            th, td { border: 1px solid #dce7f1; padding: 8px; text-align: left; }
            th { background: #f2f7ff; text-transform: uppercase; font-size: 10px; }
          </style>
        </head>
        <body>
          <h1>Danh sách danh mục</h1>
          <table>
            <thead><tr><th>Tên danh mục</th><th>Slug</th><th>Cấp cha</th><th>Số sản phẩm</th><th>Cập nhật</th></tr></thead>
            <tbody>
              ${exportRows.map((row) => `
                <tr>
                  <td>${escapeHtml(row.name)}</td>
                  <td>${escapeHtml(row.slug)}</td>
                  <td>${escapeHtml(row.parent)}</td>
                  <td>${escapeHtml(row.productCount)}</td>
                  <td>${escapeHtml(row.updatedAt)}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>
          <script>window.onload = () => { window.print(); };</script>
        </body>
      </html>
    `);
    printWindow.document.close();
    setIsExportOpen(false);
  };

  return (
    <div className="space-y-6 pb-10 animate-in fade-in slide-in-from-bottom-3 duration-500">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <Button
          onClick={() => openModal()}
          className="h-10 rounded-[6px] bg-primary px-4 text-sm font-extrabold text-white shadow-[0_5px_12px_rgba(67,94,190,0.18)] hover:bg-primary/90"
        >
          <Plus className="w-4 h-4 mr-2" />
          Thêm danh mục
        </Button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-6">
        {statCards.map((stat) => {
          const Icon = stat.icon;
          return (
            <div key={stat.label} className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white transition-all duration-300 group py-6 px-6 flex items-center gap-4">
              <div className={cn('w-12 h-12 rounded-[10px] flex items-center justify-center transition-transform duration-300 group-hover:scale-105 shadow-xs shrink-0 text-white', stat.bgClass)}>
                <Icon set="bold" primaryColor="white" size={24} />
              </div>
              <div className="flex-1 min-w-0">
                <h6 className="text-[15px] font-semibold text-[#7c8db5] leading-tight mb-1 truncate">{stat.label}</h6>
                <h6 className="text-[24px] font-extrabold text-[#25396f] leading-none mb-0 font-heading truncate">{stat.value}</h6>
              </div>
            </div>
          );
        })}
      </div>

      <div className="bg-white rounded-[12px] shadow-[0_5px_15px_rgba(25,42,70,0.06)] border border-[#f2f7ff] p-6">
        <div className="mb-4 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-2">
          <div>
            <h4 className="text-[18px] font-extrabold text-[#25396f] mb-1">Top danh mục</h4>
            <p className="text-[12px] font-semibold text-[#7c8db5] mb-0">Theo số lượng sản phẩm đang gắn</p>
          </div>
          <span className="inline-flex w-fit rounded-[6px] bg-[#f2f7ff] px-3 py-1.5 text-[12px] font-extrabold text-[#607080]">
            Top {topCategoryChartData.length || 0} danh mục
          </span>
        </div>
        <TopCategoryChart data={topCategoryChartData} />
      </div>

      <div className="bg-white rounded-[12px] shadow-[0_5px_15px_rgba(25,42,70,0.06)] border border-[#f2f7ff] overflow-hidden">
          <div className="px-5 py-5 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 border-b border-[#f2f7ff]">
            <div className="relative w-full lg:max-w-[320px]">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#a8b4c7]" />
              <input
                value={search}
                onChange={(event) => { setSearch(event.target.value); setPage(1); }}
                placeholder="Tìm theo tên, slug hoặc danh mục cha..."
                className="w-full h-10 pl-11 pr-4 rounded-[5px] border border-[#dce7f1] bg-white text-sm font-semibold text-[#25396f] outline-none transition-all focus:border-primary focus:ring-4 focus:ring-primary/10"
              />
            </div>

            <div className="flex flex-wrap items-center gap-3">
              <button
                type="button"
                onClick={() => setIsFilterOpen(!isFilterOpen)}
                className={cn(
                  'h-10 rounded-[5px] px-4 text-sm font-extrabold inline-flex items-center gap-2 transition-colors',
                  isFilterOpen || hasActiveFilters ? 'bg-primary text-white shadow-sm' : 'bg-[#f2f7ff] text-[#607080] hover:bg-[#e9f1ff]',
                )}
              >
                <Filter className="w-4 h-4" />
                Bộ lọc
              </button>

              <select
                value={pageSize}
                onChange={(event) => { setPageSize(Number(event.target.value) as (typeof pageSizeOptions)[number]); setPage(1); }}
                className="h-10 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#607080] outline-none"
              >
                {pageSizeOptions.map((option) => <option key={option} value={option}>{option}</option>)}
              </select>

              <div className="relative">
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
                  <div className="absolute right-0 z-20 mt-2 w-44 rounded-[8px] border border-[#dce7f1] bg-white shadow-lg overflow-hidden">
                    <button type="button" onClick={exportExcel} className="w-full px-4 py-3 text-left text-sm font-bold text-[#25396f] hover:bg-[#f2f7ff] inline-flex items-center gap-2">
                      <FileSpreadsheet className="w-4 h-4 text-[#2f8f5b]" />
                      Excel CSV
                    </button>
                    <button type="button" onClick={exportPdf} className="w-full px-4 py-3 text-left text-sm font-bold text-[#25396f] hover:bg-[#f2f7ff] inline-flex items-center gap-2">
                      <FileText className="w-4 h-4 text-[#f3616d]" />
                      PDF
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>

          {isFilterOpen && (
            <div className="px-5 py-4 border-b border-[#f2f7ff] bg-[#fbfcff] grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="block text-[11px] font-extrabold text-[#607080] uppercase mb-2">Sản phẩm</label>
                <select
                  value={productFilter}
                  onChange={(event) => { setProductFilter(event.target.value as ProductFilter); setPage(1); }}
                  className="w-full h-10 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-semibold text-[#25396f] outline-none focus:border-primary focus:ring-4 focus:ring-primary/10"
                >
                  <option value="all">Tất cả</option>
                  <option value="with_products">Có sản phẩm</option>
                  <option value="empty">Danh mục trống</option>
                </select>
              </div>
              <div>
                <label className="block text-[11px] font-extrabold text-[#607080] uppercase mb-2">Sắp xếp</label>
                <select
                  value={sortKey}
                  onChange={(event) => { setSortKey(event.target.value as SortKey); setPage(1); }}
                  className="w-full h-10 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-semibold text-[#25396f] outline-none focus:border-primary focus:ring-4 focus:ring-primary/10"
                >
                  <option value="name">Tên A-Z</option>
                  <option value="products_desc">Nhiều sản phẩm nhất</option>
                  <option value="newest">Mới nhất</option>
                </select>
              </div>
              <div className="flex items-end">
                <button type="button" onClick={resetFilters} className="h-10 rounded-[5px] border border-[#dce7f1] bg-white px-4 text-sm font-extrabold text-[#607080] hover:text-primary hover:border-primary inline-flex items-center gap-2">
                  <RotateCcw className="w-4 h-4" />
                  Xóa lọc
                </button>
              </div>
            </div>
          )}

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse min-w-[960px]">
              <thead>
                <tr className="border-b border-[#dce7f1] bg-[#fbfcff] text-[#607080] text-[11px] font-extrabold uppercase">
                  <th className="px-5 py-4">Danh mục cha</th>
                  <th className="px-5 py-4">Danh mục con</th>
                  <th className="px-5 py-4 text-right">Sản phẩm</th>
                  <th className="px-5 py-4">Cập nhật</th>
                  <th className="px-5 py-4 text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#dce7f1] bg-white text-sm">
                {isLoading ? (
                  Array.from({ length: pageSize > 10 ? 10 : pageSize }).map((_, index) => (
                    <tr key={index} className="animate-pulse">
                      <td colSpan={5} className="px-5 py-6">
                        <div className="h-5 rounded bg-[#f2f7ff]" />
                      </td>
                    </tr>
                  ))
                ) : paginatedCategories.length > 0 ? (
                  paginatedCategories.map((category) => {
                    const childSource = hasActiveFilters ? category.matchingChildren : (category.children || []);
                    const isExpanded = expandedGroups[category.id];
                    const previewChildren = isExpanded ? childSource : childSource.slice(0, 3);

                    return (
                      <React.Fragment key={category.id}>
                        <tr className="hover:bg-[#fbfcff] transition-colors group align-top">
                          <td className="px-5 py-4">
                            <div className="flex items-start gap-3">
                              <button
                                type="button"
                                onClick={() => setExpandedGroups((current) => ({ ...current, [category.id]: !current[category.id] }))}
                                className={cn(
                                  'mt-1 w-8 h-8 rounded-[6px] inline-flex items-center justify-center border transition-colors',
                                  childSource.length > 0 ? 'border-[#dce7f1] text-[#607080] hover:text-primary hover:border-primary' : 'border-transparent text-[#dce7f1] cursor-default',
                                )}
                                disabled={childSource.length === 0}
                              >
                                {isExpanded ? <ChevronDown className="w-4 h-4" /> : <ChevronRight className="w-4 h-4" />}
                              </button>
                              <div className="w-11 h-11 rounded-[10px] border border-[#dce7f1] bg-[#f2f7ff] flex items-center justify-center overflow-hidden shrink-0">
                                {category.iconUrl ? (
                                  <img src={category.iconUrl} alt={category.name} className="w-full h-full object-contain" />
                                ) : (
                                  <Hash className="w-5 h-5 text-[#a8b4c7]" />
                                )}
                              </div>
                              <div className="min-w-0">
                                <p className="font-extrabold text-[#25396f] mb-0 truncate max-w-[240px]">{category.name}</p>
                                <p className="text-[10px] font-bold text-[#a8b4c7] mb-1 uppercase">ID: {category.id.slice(-8).toUpperCase()}</p>
                                <span className="inline-flex rounded-[6px] bg-[#f2f7ff] px-2.5 py-1 text-[12px] font-bold text-[#607080]">/{category.slug}</span>
                              </div>
                            </div>
                          </td>
                          <td className="px-5 py-4">
                            {childSource.length > 0 ? (
                              <div className="flex flex-wrap gap-2">
                                {previewChildren.map((child) => (
                                  <button
                                    key={child.id}
                                    type="button"
                                    onClick={() => openModal(child)}
                                    className="inline-flex items-center gap-1.5 rounded-[6px] bg-[#f2f7ff] px-2.5 py-1 text-[12px] font-bold text-[#607080] hover:text-primary hover:bg-primary/10"
                                  >
                                    <Layers className="w-3.5 h-3.5" />
                                    {child.name}
                                    <span className="text-[#a8b4c7]">({getProductCount(child)})</span>
                                  </button>
                                ))}
                                {childSource.length > previewChildren.length && (
                                  <button
                                    type="button"
                                    onClick={() => setExpandedGroups((current) => ({ ...current, [category.id]: true }))}
                                    className="inline-flex rounded-[6px] bg-white border border-[#dce7f1] px-2.5 py-1 text-[12px] font-extrabold text-primary"
                                  >
                                    +{childSource.length - previewChildren.length} nữa
                                  </button>
                                )}
                              </div>
                            ) : (
                              <span className="text-sm font-semibold text-[#a8b4c7]">Chưa có danh mục con</span>
                            )}
                          </td>
                          <td className="px-5 py-4 text-right">
                            <span className="font-extrabold text-[#25396f]">{category.totalProductCount}</span>
                            <span className="ml-1 text-[11px] font-semibold text-[#7c8db5]">sp</span>
                            <p className="text-[10px] font-bold text-[#a8b4c7] mb-0 mt-1">Trực tiếp: {getProductCount(category)}</p>
                          </td>
                          <td className="px-5 py-4 text-sm font-semibold text-[#607080]">{formatDate(category.updatedAt || category.createdAt)}</td>
                          <td className="px-5 py-4">
                            <div className="flex items-center justify-end gap-2">
                              <button type="button" onClick={() => openModal(category)} className="w-9 h-9 rounded-[6px] inline-flex items-center justify-center text-primary bg-primary/10 hover:bg-primary/20 transition-colors">
                                <Edit className="w-4 h-4" />
                              </button>
                              <button
                                type="button"
                                onClick={() => handleDelete(category.id, category.name)}
                                className="w-9 h-9 rounded-[6px] inline-flex items-center justify-center text-red-500 hover:bg-red-50 transition-colors"
                                disabled={deleteMutation.isPending && deleteMutation.variables === category.id}
                              >
                                <Trash2 className="w-4 h-4" />
                              </button>
                            </div>
                          </td>
                        </tr>
                        {isExpanded && childSource.length > 0 && (
                          <tr className="bg-[#fbfcff]">
                            <td colSpan={5} className="px-5 py-4">
                              <div className="ml-11 grid grid-cols-1 lg:grid-cols-2 2xl:grid-cols-3 gap-3">
                                {childSource.map((child) => (
                                  <div key={child.id} className="rounded-[10px] border border-[#dce7f1] bg-white p-3 flex items-center justify-between gap-3">
                                    <div className="min-w-0">
                                      <p className="font-extrabold text-[#25396f] mb-1 truncate">{child.name}</p>
                                      <p className="text-[11px] font-semibold text-[#7c8db5] mb-0 truncate">/{child.slug} · {getProductCount(child)} sản phẩm</p>
                                    </div>
                                    <div className="flex items-center gap-1 shrink-0">
                                      <button type="button" onClick={() => openModal(child)} className="w-8 h-8 rounded-[6px] inline-flex items-center justify-center text-primary hover:bg-primary/10">
                                        <Edit className="w-4 h-4" />
                                      </button>
                                      <button type="button" onClick={() => handleDelete(child.id, child.name)} className="w-8 h-8 rounded-[6px] inline-flex items-center justify-center text-red-500 hover:bg-red-50">
                                        <Trash2 className="w-4 h-4" />
                                      </button>
                                    </div>
                                  </div>
                                ))}
                              </div>
                            </td>
                          </tr>
                        )}
                      </React.Fragment>
                    );
                  })
                ) : (
                  <tr>
                    <td colSpan={5} className="px-6 py-20 text-center">
                      <div className="mx-auto w-16 h-16 rounded-[14px] bg-[#f2f7ff] flex items-center justify-center mb-4">
                        <IconlyCategory set="bold" primaryColor="#435ebe" size={30} />
                      </div>
                      <h6 className="text-[18px] font-extrabold text-[#25396f] mb-1">Không tìm thấy danh mục nào</h6>
                      <p className="text-sm font-semibold text-[#7c8db5] mb-5">Thử thay đổi từ khóa hoặc xóa bộ lọc hiện tại.</p>
                      <button type="button" onClick={resetFilters} className="h-9 rounded-[8px] border border-[#dce7f1] bg-white px-4 text-sm font-extrabold text-[#607080] hover:text-primary hover:border-primary">
                        Xóa bộ lọc
                      </button>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          <div className="px-5 py-4 border-t border-[#dce7f1] bg-white flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <p className="text-[13px] font-semibold text-[#a8b4c7] mb-0">
              Hiển thị {(page - 1) * pageSize + (paginatedCategories.length > 0 ? 1 : 0)} tới {(page - 1) * pageSize + paginatedCategories.length} của {groupedCategories.length} nhóm danh mục
            </p>
            {totalPages > 1 && (
              <nav aria-label="Category pagination">
                <ul className="flex items-center gap-1.5">
                  <li>
                    <button type="button" disabled={page === 1} onClick={() => setPage(page - 1)} className="w-9 h-9 rounded-[6px] border border-[#dce7f1] bg-white text-[#7c8db5] inline-flex items-center justify-center hover:text-primary hover:border-primary disabled:opacity-40 disabled:pointer-events-none">
                      <ChevronLeft className="w-4 h-4" />
                    </button>
                  </li>
                  {visiblePages.map((visiblePage) => (
                    <li key={visiblePage}>
                      <button
                        type="button"
                        onClick={() => setPage(visiblePage)}
                        className={cn('w-9 h-9 rounded-[6px] text-sm font-extrabold transition-all', visiblePage === page ? 'bg-primary text-white shadow-sm' : 'bg-white border border-[#dce7f1] text-[#607080] hover:text-primary hover:border-primary')}
                      >
                        {visiblePage}
                      </button>
                    </li>
                  ))}
                  <li>
                    <button type="button" disabled={page === totalPages} onClick={() => setPage(page + 1)} className="w-9 h-9 rounded-[6px] border border-[#dce7f1] bg-white text-[#7c8db5] inline-flex items-center justify-center hover:text-primary hover:border-primary disabled:opacity-40 disabled:pointer-events-none">
                      <ChevronRight className="w-4 h-4" />
                    </button>
                  </li>
                </ul>
              </nav>
            )}
          </div>
      </div>

      {isError && (
        <div className="p-6 bg-red-50 border border-red-100 rounded-[12px] flex items-center gap-4 text-red-600 shadow-[0_5px_15px_rgba(25,42,70,0.04)]">
          <AlertCircle className="w-6 h-6" />
          <div>
            <p className="text-base font-extrabold text-red-700 mb-0">Không thể kết nối tới máy chủ</p>
            <p className="text-sm font-semibold opacity-80 mb-0">Máy chủ hiện không phản hồi. Vui lòng thử lại.</p>
          </div>
        </div>
      )}

      {isModalOpen && (
        <CategoryFormModal
          category={editingCategory}
          onClose={closeModal}
          onSave={(formData) => editingCategory ? updateMutation.mutate({ id: editingCategory.id, formData }) : createMutation.mutate(formData)}
          isSaving={createMutation.isPending || updateMutation.isPending}
        />
      )}

      <ConfirmModal
        isOpen={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={() => categoryToDelete && deleteMutation.mutate(categoryToDelete.id)}
        title="Xác nhận gỡ bỏ"
        message={`Bạn có chắc muốn xóa danh mục "${categoryToDelete?.name}"? Thao tác này sẽ gỡ bỏ hoàn toàn dữ liệu và không thể hoàn tác.`}
        confirmText="Đồng ý xóa"
        cancelText="Để tôi xem lại"
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
};
