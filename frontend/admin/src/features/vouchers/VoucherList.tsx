import React, { useEffect, useRef, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import ApexCharts from 'apexcharts';
import {
  AlertCircle,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Download,
  Edit,
  Eye,
  EyeOff,
  FileSpreadsheet,
  FileText,
  Filter,
  Plus,
  Search,
  ShieldCheck,
  Trash2,
} from '../../components/ui/IconlyIcons';
import {
  Activity as IconlyActivity,
  CloseSquare as IconlyCloseSquare,
  Discount as IconlyDiscount,
  PaperFail as IconlyPaperFail,
  Ticket as IconlyTicket,
} from 'react-iconly';
import { toast } from 'sonner';
import { voucherService } from '../../services/voucher.service';
import type { CreateVoucherPayload, UpdateVoucherPayload } from '../../services/voucher.service';
import { authService } from '../../services/auth.service';
import { Button } from '../../components/ui/Button';
import { Badge } from '../../components/ui/Badge';
import { ConfirmModal } from '../../components/ui/ConfirmModal';
import { VoucherFormModal } from './VoucherFormModal';
import { VoucherDetailModal } from './VoucherDetailModal';
import { cn } from '../../utils/cn';
import { Role, VoucherType } from '../../types';
import type { Voucher } from '../../types';

const pageSizeOptions = [10, 50, 100] as const;
type VoucherStatusFilter = '' | 'ACTIVE' | 'DISABLED' | 'EXPIRED' | 'UPCOMING';

const statusLabel: Record<Exclude<VoucherStatusFilter, ''>, string> = {
  ACTIVE: 'Đang hoạt động',
  DISABLED: 'Tạm ngưng',
  EXPIRED: 'Đã hết hạn',
  UPCOMING: 'Sắp diễn ra',
};

const typeLabel: Record<VoucherType, string> = {
  [VoucherType.PERCENT]: 'Giảm theo %',
  [VoucherType.FIXED_AMOUNT]: 'Giảm tiền mặt',
};

const formatCurrency = (value: number) =>
  new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(value || 0);

const formatDate = (value?: string) => {
  if (!value) return 'Không giới hạn';
  return new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(new Date(value));
};

const formatChartDate = (value: string) => {
  const [year, month, day] = value.split('-');
  if (!year || !month || !day) return value;
  return `${day}/${month}/${year}`;
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

const getVoucherStatus = (voucher: Voucher): Exclude<VoucherStatusFilter, ''> => {
  const now = new Date();
  if (!voucher.isActive) return 'DISABLED';
  if (voucher.expiresAt && new Date(voucher.expiresAt) < now) return 'EXPIRED';
  if (voucher.startsAt && new Date(voucher.startsAt) > now) return 'UPCOMING';
  return 'ACTIVE';
};

const getStatusBadge = (status: Exclude<VoucherStatusFilter, ''>) => {
  const baseClass = 'rounded-[6px] border-none px-2.5 py-1 text-[10px] font-extrabold uppercase';
  if (status === 'ACTIVE') {
    return <Badge variant="success" className={cn(baseClass, 'bg-[#edf9f1] text-[#2f8f5b]')}>Đang chạy</Badge>;
  }
  if (status === 'DISABLED') {
    return <Badge variant="danger" className={cn(baseClass, 'bg-red-50 text-red-600')}>Tạm ngưng</Badge>;
  }
  if (status === 'UPCOMING') {
    return <Badge variant="info" className={cn(baseClass, 'bg-primary/10 text-primary')}>Sắp tới</Badge>;
  }
  return <Badge variant="warning" className={cn(baseClass, 'bg-[#fff7e6] text-[#946200]')}>Hết hạn</Badge>;
};

const VoucherUsageChart: React.FC<{ data: Array<{ date: string; usedCount: number; discountAmount: number }> }> = ({ data }) => {
  const chartRef = useRef<HTMLDivElement>(null);
  const instanceRef = useRef<ApexCharts | null>(null);

  useEffect(() => {
    if (!chartRef.current) return;

    const chartData = data.length > 0 ? data : [{ date: new Date().toISOString().slice(0, 10), usedCount: 0, discountAmount: 0 }];
    const series: NonNullable<ApexCharts.ApexOptions['series']> = [
      {
        name: 'Lượt dùng',
        type: 'line',
        data: chartData.map((item) => ({
          x: formatChartDate(item.date),
          y: Number(item.usedCount || 0),
        })),
      },
      {
        name: 'Chi phí ưu đãi',
        type: 'line',
        data: chartData.map((item) => ({
          x: formatChartDate(item.date),
          y: Number(item.discountAmount || 0),
        })),
      },
    ];
    const options: ApexCharts.ApexOptions = {
      chart: {
        type: 'line',
        height: 320,
        toolbar: { show: true },
        zoom: { enabled: true },
        fontFamily: 'inherit',
      },
      series,
      xaxis: {
        type: 'category',
        labels: { style: { colors: '#7c8db5', fontSize: '12px', fontWeight: 700 } },
        axisBorder: { show: false },
        axisTicks: { show: false },
      },
      yaxis: [
        {
          seriesName: 'Lượt dùng',
          min: 0,
          forceNiceScale: true,
          title: { text: 'Lượt dùng', style: { color: '#7c8db5', fontWeight: 800 } },
          labels: {
            style: { colors: '#7c8db5', fontSize: '12px', fontWeight: 700 },
            formatter: (value) => `${Math.round(value)}`,
          },
        },
        {
          seriesName: 'Chi phí ưu đãi',
          opposite: true,
          min: 0,
          forceNiceScale: true,
          title: { text: 'Chi phí', style: { color: '#7c8db5', fontWeight: 800 } },
          labels: {
            style: { colors: '#7c8db5', fontSize: '12px', fontWeight: 700 },
            formatter: (value) => `${Math.round(value / 1000)}k`,
          },
        },
      ],
      stroke: { curve: 'smooth', width: [4, 4], colors: ['#435ebe', '#5ddc97'] },
      colors: ['#435ebe', '#5ddc97'],
      markers: {
        size: 5,
        colors: ['#435ebe', '#5ddc97'],
        strokeColors: '#fff',
        strokeWidth: 3,
        hover: { size: 7 },
      },
      fill: { colors: ['#435ebe', '#5ddc97'], opacity: 1 },
      dataLabels: { enabled: false },
      grid: { borderColor: '#dce7f1', strokeDashArray: 0 },
      legend: {
        position: 'bottom',
        fontSize: '13px',
        fontWeight: 800,
        labels: { colors: '#607080' },
        markers: { size: 7 },
      },
      tooltip: {
        theme: 'light',
        y: [
          { formatter: (value) => `${value} lượt` },
          { formatter: (value) => formatCurrency(value) },
        ],
      },
    };

    if (instanceRef.current) {
      instanceRef.current.updateOptions(options, false, true);
      instanceRef.current.updateSeries(series, true);
    } else {
      instanceRef.current = new ApexCharts(chartRef.current, options);
      instanceRef.current.render();
    }

    return () => {
      instanceRef.current?.destroy();
      instanceRef.current = null;
    };
  }, [data]);

  return <div ref={chartRef} className="min-h-[320px]" />;
};

export const VoucherList: React.FC = () => {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<VoucherStatusFilter>('');
  const [typeFilter, setTypeFilter] = useState<'' | VoucherType>('');
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState<(typeof pageSizeOptions)[number]>(10);
  const [selectedVoucherIds, setSelectedVoucherIds] = useState<string[]>([]);
  const [isExportOpen, setIsExportOpen] = useState(false);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingVoucher, setEditingVoucher] = useState<Voucher | null>(null);
  const [viewingVoucher, setViewingVoucher] = useState<Voucher | null>(null);
  const [voucherToDelete, setVoucherToDelete] = useState<{ id: string; code: string } | null>(null);
  const [bulkAction, setBulkAction] = useState<'disable' | 'delete' | null>(null);

  const queryClient = useQueryClient();
  const user = authService.getCurrentUser();
  const isAdmin = user?.role === Role.ADMIN;

  const { data, isLoading, isError } = useQuery({
    queryKey: ['vouchers', search, statusFilter, typeFilter, page, pageSize],
    queryFn: () => voucherService.getAllVouchers({
      page,
      limit: pageSize,
      search: search || undefined,
      status: statusFilter || undefined,
      type: typeFilter || undefined,
    }),
  });

  const { data: analytics } = useQuery({
    queryKey: ['vouchers', 'analytics'],
    queryFn: voucherService.getVoucherAnalytics,
  });

  const createMutation = useMutation({
    mutationFn: voucherService.createVoucher,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vouchers'] });
      toast.success('Ưu đãi mới đã được tạo thành công');
      closeForm();
    },
    onError: (error: unknown) => {
      toast.error(getMutationErrorMessage(error, 'Có lỗi khi tạo ưu đãi'));
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: UpdateVoucherPayload }) => voucherService.updateVoucher(id, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vouchers'] });
      toast.success('Cập nhật ưu đãi thành công');
      closeForm();
    },
    onError: (error: unknown) => {
      toast.error(getMutationErrorMessage(error, 'Có lỗi khi cập nhật ưu đãi'));
    },
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) => voucherService.toggleVoucherStatus(id, isActive),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vouchers'] });
      toast.success('Cập nhật trạng thái thành công');
    },
    onError: (error: unknown) => {
      toast.error(getMutationErrorMessage(error, 'Có lỗi khi cập nhật trạng thái'));
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => voucherService.deleteVoucher(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vouchers'] });
      toast.success('Đã xóa ưu đãi thành công');
      setVoucherToDelete(null);
    },
    onError: (error: unknown) => {
      toast.error(getMutationErrorMessage(error, 'Có lỗi khi xóa ưu đãi'));
    },
  });

  const bulkMutation = useMutation({
    mutationFn: async ({ action, ids }: { action: 'disable' | 'delete'; ids: string[] }) => {
      await Promise.all(ids.map((id) => action === 'disable'
        ? voucherService.toggleVoucherStatus(id, false)
        : voucherService.deleteVoucher(id)));
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vouchers'] });
      toast.success('Đã xử lý hàng loạt ưu đãi đã chọn');
      setSelectedVoucherIds([]);
      setBulkAction(null);
    },
    onError: (error: unknown) => {
      toast.error(getMutationErrorMessage(error, 'Không thể xử lý hàng loạt'));
    },
  });

  const vouchers = data?.data || [];
  const meta = data?.meta || { total: 0, page: 1, limit: pageSize, lastPage: 1 };
  const totalPages = Math.max(1, meta.lastPage || 1);
  const allVisibleSelected = vouchers.length > 0 && vouchers.every((voucher) => selectedVoucherIds.includes(voucher.id));
  const hasActiveFilters = Boolean(search || statusFilter || typeFilter);
  const visiblePages = Array.from({ length: Math.min(totalPages, 5) }, (_, index) => {
    if (totalPages <= 5) return index + 1;
    if (page <= 3) return index + 1;
    if (page >= totalPages - 2) return totalPages - 4 + index;
    return page - 2 + index;
  });

  const stats = analytics?.stats || {
    total: 0,
    active: 0,
    disabled: 0,
    expired: 0,
    upcoming: 0,
    expiringSoon: 0,
    totalIssued: 0,
    totalClaimed: 0,
    totalUsed: 0,
    totalDiscount: 0,
  };

  const statCards = [
    { label: 'Tổng ưu đãi', value: stats.total, icon: IconlyTicket, bgClass: 'bg-[#9694ff]' },
    { label: 'Đang hoạt động', value: stats.active, icon: IconlyActivity, bgClass: 'bg-[#5ddc97]' },
    { label: 'Sắp hết hạn', value: stats.expiringSoon, icon: IconlyPaperFail, bgClass: 'bg-[#eaca4a]' },
    { label: 'Đã sử dụng', value: stats.totalUsed, icon: IconlyDiscount, bgClass: 'bg-[#57caeb]' },
    { label: 'Tạm ngưng/hết hạn', value: stats.disabled + stats.expired, icon: IconlyCloseSquare, bgClass: 'bg-[#ff7976]' },
  ];

  const openForm = (voucher?: Voucher) => {
    setEditingVoucher(voucher || null);
    setIsFormOpen(true);
  };

  const closeForm = () => {
    setIsFormOpen(false);
    setEditingVoucher(null);
  };

  const resetFilters = () => {
    setSearch('');
    setStatusFilter('');
    setTypeFilter('');
    setPage(1);
  };

  const toggleSelectVoucher = (voucherId: string) => {
    setSelectedVoucherIds((currentIds) =>
      currentIds.includes(voucherId) ? currentIds.filter((id) => id !== voucherId) : [...currentIds, voucherId],
    );
  };

  const toggleSelectVisibleVouchers = () => {
    setSelectedVoucherIds(allVisibleSelected ? [] : vouchers.map((voucher) => voucher.id));
  };

  const fetchExportVouchers = async () => {
    const response = await voucherService.getAllVouchers({
      page: 1,
      limit: Math.max(meta.total || pageSize, pageSize),
      search: search || undefined,
      status: statusFilter || undefined,
      type: typeFilter || undefined,
    });
    return response.data;
  };

  const buildExportRows = (rows: Voucher[]) => rows.map((voucher) => ({
    code: voucher.code,
    name: voucher.name,
    type: typeLabel[voucher.type],
    value: voucher.type === VoucherType.PERCENT ? `${voucher.value}%` : formatCurrency(voucher.value),
    minOrderAmount: formatCurrency(voucher.minOrderAmount),
    validity: `${formatDate(voucher.startsAt)} - ${formatDate(voucher.expiresAt)}`,
    quantity: voucher.quantity,
    claimedCount: voucher.claimedCount,
    usedCount: voucher.usedCount,
    status: statusLabel[getVoucherStatus(voucher)],
  }));

  const exportExcel = async () => {
    const rows = buildExportRows(await fetchExportVouchers());
    const header = ['Mã', 'Tên ưu đãi', 'Loại', 'Giá trị', 'Đơn tối thiểu', 'Hiệu lực', 'Phát hành', 'Đã nhận', 'Đã dùng', 'Trạng thái'];
    const csv = [header, ...rows.map((row) => [
      row.code,
      row.name,
      row.type,
      row.value,
      row.minOrderAmount,
      row.validity,
      row.quantity,
      row.claimedCount,
      row.usedCount,
      row.status,
    ])]
      .map((row) => row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(','))
      .join('\n');
    const blob = new Blob([`\uFEFF${csv}`], { type: 'application/vnd.ms-excel;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `vouchers-${new Date().toISOString().slice(0, 10)}.csv`;
    link.click();
    URL.revokeObjectURL(url);
    setIsExportOpen(false);
  };

  const exportPdf = async () => {
    const rows = buildExportRows(await fetchExportVouchers());
    const printWindow = window.open('', '_blank');
    if (!printWindow) {
      toast.error('Trình duyệt đang chặn cửa sổ xuất PDF');
      return;
    }

    printWindow.document.write(`
      <html>
        <head>
          <title>Danh sách ưu đãi</title>
          <style>
            body { font-family: Arial, sans-serif; color: #25396f; padding: 24px; }
            h1 { font-size: 20px; margin-bottom: 16px; }
            table { width: 100%; border-collapse: collapse; font-size: 12px; }
            th, td { border: 1px solid #dce7f1; padding: 8px; text-align: left; }
            th { background: #f2f7ff; text-transform: uppercase; font-size: 10px; }
          </style>
        </head>
        <body>
          <h1>Danh sách ưu đãi</h1>
          <table>
            <thead><tr><th>Mã</th><th>Tên</th><th>Loại</th><th>Giá trị</th><th>Hiệu lực</th><th>Đã dùng</th><th>Trạng thái</th></tr></thead>
            <tbody>
              ${rows.map((row) => `
                <tr>
                  <td>${escapeHtml(row.code)}</td>
                  <td>${escapeHtml(row.name)}</td>
                  <td>${escapeHtml(row.type)}</td>
                  <td>${escapeHtml(row.value)}</td>
                  <td>${escapeHtml(row.validity)}</td>
                  <td>${escapeHtml(row.usedCount)}</td>
                  <td>${escapeHtml(row.status)}</td>
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

  const activeFilterChips = [
    search && { key: 'search', label: `Từ khóa: ${search}`, onRemove: () => { setSearch(''); setPage(1); } },
    statusFilter && { key: 'status', label: `Trạng thái: ${statusLabel[statusFilter]}`, onRemove: () => { setStatusFilter(''); setPage(1); } },
    typeFilter && { key: 'type', label: `Loại: ${typeLabel[typeFilter]}`, onRemove: () => { setTypeFilter(''); setPage(1); } },
  ].filter(Boolean) as Array<{ key: string; label: string; onRemove: () => void }>;

  return (
    <div className="space-y-6 pb-10 animate-in fade-in slide-in-from-bottom-3 duration-500">
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
        <div className="mb-4 flex flex-col lg:flex-row lg:items-start lg:justify-between gap-3">
          <div>
            <h4 className="text-[18px] font-extrabold text-[#25396f] mb-1">Hiệu quả ưu đãi</h4>
            <p className="text-[12px] font-semibold text-[#7c8db5] mb-0">Theo dõi số lượt dùng và chi phí ưu đãi trong 30 ngày gần nhất</p>
          </div>
          <div className="text-right">
            <p className="text-[11px] font-extrabold text-[#7c8db5] uppercase mb-1">Tổng chi phí ưu đãi</p>
            <p className="text-[20px] font-extrabold text-primary mb-0">{formatCurrency(stats.totalDiscount)}</p>
          </div>
        </div>
        <VoucherUsageChart data={analytics?.chart || []} />
      </div>

      {isAdmin && (
        <div>
          <Button
            onClick={() => openForm()}
            className="h-10 rounded-[6px] bg-primary px-4 text-sm font-extrabold text-white shadow-[0_5px_12px_rgba(67,94,190,0.18)] hover:bg-primary/90"
          >
            <Plus className="w-4 h-4 mr-2" />
            Tạo voucher mới
          </Button>
        </div>
      )}

      <div className="bg-white rounded-[12px] shadow-[0_5px_15px_rgba(25,42,70,0.06)] border border-[#f2f7ff] overflow-hidden">
        <div className="px-5 py-5 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 border-b border-[#f2f7ff]">
          <div className="relative w-full lg:max-w-[360px]">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#a8b4c7]" />
            <input
              value={search}
              onChange={(event) => { setSearch(event.target.value); setPage(1); }}
              placeholder="Tìm theo mã hoặc tên ưu đãi..."
              className="w-full h-10 pl-11 pr-4 rounded-[5px] border border-[#dce7f1] bg-white text-sm font-semibold text-[#25396f] outline-none transition-all focus:border-primary focus:ring-4 focus:ring-primary/10"
            />
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <div className="inline-flex items-center gap-2 h-10 rounded-[5px] bg-[#f2f7ff] px-3 text-sm font-extrabold text-[#607080]">
              <Filter className="w-4 h-4" />
              <select
                value={statusFilter}
                onChange={(event) => { setStatusFilter(event.target.value as VoucherStatusFilter); setPage(1); }}
                className="bg-transparent outline-none font-extrabold"
              >
                <option value="">Tất cả trạng thái</option>
                <option value="ACTIVE">Đang hoạt động</option>
                <option value="DISABLED">Tạm ngưng</option>
                <option value="EXPIRED">Đã hết hạn</option>
                <option value="UPCOMING">Sắp diễn ra</option>
              </select>
            </div>

            <select
              value={typeFilter}
              onChange={(event) => { setTypeFilter(event.target.value as '' | VoucherType); setPage(1); }}
              className="h-10 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#607080] outline-none"
            >
              <option value="">Tất cả loại</option>
              <option value={VoucherType.PERCENT}>Giảm theo %</option>
              <option value={VoucherType.FIXED_AMOUNT}>Giảm tiền mặt</option>
            </select>

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

        {(activeFilterChips.length > 0 || selectedVoucherIds.length > 0) && (
          <div className="px-5 py-3 border-b border-[#f2f7ff] bg-[#fbfcff] flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3">
            <div className="flex flex-wrap gap-2">
              {activeFilterChips.map((chip) => (
                <button key={chip.key} type="button" onClick={chip.onRemove} className="rounded-[6px] bg-white border border-[#dce7f1] px-3 py-1.5 text-[12px] font-bold text-[#607080] hover:text-primary hover:border-primary">
                  {chip.label} ×
                </button>
              ))}
              {hasActiveFilters && (
                <button type="button" onClick={resetFilters} className="rounded-[6px] bg-primary/10 px-3 py-1.5 text-[12px] font-extrabold text-primary">
                  Xóa bộ lọc
                </button>
              )}
            </div>

            {isAdmin && selectedVoucherIds.length > 0 && (
              <div className="flex flex-wrap items-center gap-2">
                <span className="text-[12px] font-extrabold text-[#7c8db5]">{selectedVoucherIds.length} ưu đãi đã chọn</span>
                <button type="button" onClick={() => setBulkAction('disable')} className="h-9 rounded-[6px] px-3 text-[12px] font-extrabold bg-[#fff7e6] text-[#946200] hover:bg-[#ffe8b5]">
                  Ngưng hoạt động
                </button>
                <button type="button" onClick={() => setBulkAction('delete')} className="h-9 rounded-[6px] px-3 text-[12px] font-extrabold bg-red-50 text-red-600 hover:bg-red-100">
                  Xóa đồng loạt
                </button>
              </div>
            )}
          </div>
        )}

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1180px]">
            <thead className="bg-[#f8faff] border-b border-[#f2f7ff]">
              <tr>
                <th className="px-5 py-4 w-12">
                  <input
                    type="checkbox"
                    checked={allVisibleSelected}
                    onChange={toggleSelectVisibleVouchers}
                    className="h-4 w-4 rounded border-[#dce7f1] text-primary focus:ring-primary"
                  />
                </th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase">Mã</th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase">Giá trị</th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase">Hiệu lực</th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase text-right">Phát hành</th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase text-center">Trạng thái</th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#f2f7ff] font-body">
              {isLoading ? (
                Array.from({ length: pageSize }).map((_, index) => (
                  <tr key={index} className="animate-pulse">
                    <td colSpan={7} className="px-5 py-7 bg-slate-50/30" />
                  </tr>
                ))
              ) : vouchers.length > 0 ? (
                vouchers.map((voucher) => {
                  const status = getVoucherStatus(voucher);
                  return (
                    <tr key={voucher.id} className="hover:bg-[#fbfcff] transition-colors group">
                      <td className="px-5 py-4">
                        <input
                          type="checkbox"
                          checked={selectedVoucherIds.includes(voucher.id)}
                          onChange={() => toggleSelectVoucher(voucher.id)}
                          className="h-4 w-4 rounded border-[#dce7f1] text-primary focus:ring-primary"
                        />
                      </td>
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-3">
                          <div className="min-w-0">
                            <p className="font-extrabold text-[#25396f] mb-1 truncate max-w-[260px]">{voucher.code}</p>
                            <p className="text-[12px] font-semibold text-[#7c8db5] mb-0 truncate max-w-[260px]" title={voucher.name}>{voucher.name}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-5 py-4">
                        <p className="font-extrabold text-[#25396f] mb-1">
                          {voucher.type === VoucherType.PERCENT ? `${voucher.value}%` : formatCurrency(voucher.value)}
                        </p>
                        <p className="text-[12px] font-semibold text-[#7c8db5] mb-0">Áp dụng cho đơn từ {formatCurrency(voucher.minOrderAmount)}</p>
                      </td>
                      <td className="px-5 py-4">
                        <p className="text-sm font-extrabold text-[#25396f] mb-1">Từ {formatDate(voucher.startsAt)}</p>
                        <p className="text-[12px] font-semibold text-[#7c8db5] mb-0">Đến {formatDate(voucher.expiresAt)}</p>
                      </td>
                      <td className="px-5 py-4 text-right">
                        <p className="font-extrabold text-[#25396f] mb-1">{voucher.quantity}</p>
                        <p className="text-[12px] font-semibold text-[#7c8db5] mb-0">Đã dùng: {voucher.usedCount}</p>
                      </td>
                      <td className="px-5 py-4 text-center">{getStatusBadge(status)}</td>
                      <td className="px-5 py-4">
                        <div className="flex items-center justify-end gap-2">
                          <button type="button" onClick={() => setViewingVoucher(voucher)} className="w-9 h-9 rounded-[6px] inline-flex items-center justify-center text-blue-500 hover:bg-blue-50 transition-colors">
                            <Eye className="w-4 h-4" />
                          </button>
                          {isAdmin && (
                            <>
                              <button
                                type="button"
                                onClick={() => toggleMutation.mutate({ id: voucher.id, isActive: !voucher.isActive })}
                                className={cn('w-9 h-9 rounded-[6px] inline-flex items-center justify-center transition-colors', voucher.isActive ? 'text-[#946200] hover:bg-[#fff7e6]' : 'text-[#2f8f5b] hover:bg-[#edf9f1]')}
                              >
                                {voucher.isActive ? <EyeOff className="w-4 h-4" /> : <ShieldCheck className="w-4 h-4" />}
                              </button>
                              <button type="button" onClick={() => openForm(voucher)} className="w-9 h-9 rounded-[6px] inline-flex items-center justify-center text-primary hover:bg-primary/10 transition-colors">
                                <Edit className="w-4 h-4" />
                              </button>
                              <button
                                type="button"
                                onClick={() => setVoucherToDelete({ id: voucher.id, code: voucher.code })}
                                className="w-9 h-9 rounded-[6px] inline-flex items-center justify-center text-red-500 hover:bg-red-50 transition-colors"
                              >
                                <Trash2 className="w-4 h-4" />
                              </button>
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={7} className="px-6 py-20 text-center">
                    <div className="mx-auto w-16 h-16 rounded-[14px] bg-[#f2f7ff] flex items-center justify-center mb-4">
                      <IconlyTicket set="bold" primaryColor="#435ebe" size={30} />
                    </div>
                    <h6 className="text-[18px] font-extrabold text-[#25396f] mb-1">Không tìm thấy ưu đãi nào</h6>
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
            Hiển thị {(page - 1) * pageSize + (vouchers.length > 0 ? 1 : 0)} tới {(page - 1) * pageSize + vouchers.length} của {meta.total} dòng
            {selectedVoucherIds.length > 0 && <span> · {selectedVoucherIds.length} ưu đãi đã chọn</span>}
          </p>
          {totalPages > 1 && (
            <nav aria-label="Voucher pagination">
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

      {isFormOpen && (
        <VoucherFormModal
          voucher={editingVoucher}
          onClose={closeForm}
          onSave={(payload) => editingVoucher ? updateMutation.mutate({ id: editingVoucher.id, payload }) : createMutation.mutate(payload as CreateVoucherPayload)}
          isSaving={createMutation.isPending || updateMutation.isPending}
        />
      )}

      {viewingVoucher && (
        <VoucherDetailModal
          voucher={viewingVoucher}
          onClose={() => setViewingVoucher(null)}
        />
      )}

      <ConfirmModal
        isOpen={!!voucherToDelete}
        onClose={() => setVoucherToDelete(null)}
        onConfirm={() => voucherToDelete && deleteMutation.mutate(voucherToDelete.id)}
        title="Xác nhận xóa ưu đãi"
        message={`Bạn có chắc muốn xóa ưu đãi "${voucherToDelete?.code}"? Hệ thống sẽ ngưng hoạt động ưu đãi này cho các đơn trong tương lai.`}
        confirmText="Đồng ý xóa"
        cancelText="Để tôi xem lại"
        isLoading={deleteMutation.isPending}
      />

      <ConfirmModal
        isOpen={!!bulkAction}
        onClose={() => setBulkAction(null)}
        onConfirm={() => bulkAction && bulkMutation.mutate({ action: bulkAction, ids: selectedVoucherIds })}
        title={bulkAction === 'disable' ? 'Ngưng ưu đãi đã chọn' : 'Xóa ưu đãi đã chọn'}
        message={`Bạn đang xử lý ${selectedVoucherIds.length} ưu đãi. Thao tác này sẽ áp dụng cho toàn bộ các dòng đã chọn.`}
        confirmText="Xác nhận"
        cancelText="Để tôi xem lại"
        variant={bulkAction === 'disable' ? 'warning' : 'danger'}
        isLoading={bulkMutation.isPending}
      />
    </div>
  );
};
