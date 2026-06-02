import React, { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  AlertCircle,
  Calendar,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Clock,
  Download,
  FileSpreadsheet,
  FileText,
  Filter,
  Globe,
  History,
  Laptop,
  RotateCcw,
  Search,
  ShieldCheck,
  User,
  XCircle,
} from '../../components/ui/IconlyIcons';
import {
  Activity as IconlyActivity,
  Danger as IconlyDanger,
  Document as IconlyDocument,
  TimeCircle as IconlyTimeCircle,
} from 'react-iconly';
import { toast } from 'sonner';
import { activityLogService } from '../../services/activity-log.service';
import { Button } from '../../components/ui/Button';
import { Drawer } from '../../components/ui/Drawer';
import { cn } from '../../utils/cn';

type ActivityLogUser = {
  id: string;
  email?: string;
  role?: string;
  profile?: {
    fullName?: string;
    avatarUrl?: string;
  };
};

type ActivityLog = {
  id: string;
  userId?: string | null;
  action: string;
  metadata?: {
    ip?: string;
    userAgent?: string;
    [key: string]: unknown;
  };
  createdAt: string;
  user?: ActivityLogUser | null;
};

type ActionGroup = 'all' | 'account' | 'catalog' | 'order' | 'payment' | 'security';

const pageSizeOptions = [10, 50, 100] as const;

const actionLabels: Record<string, string> = {
  USER_REGISTER: 'Đăng ký tài khoản',
  USER_LOGIN: 'Đăng nhập',
  USER_LOGOUT: 'Đăng xuất',
  USER_CHANGE_PASSWORD: 'Đổi mật khẩu',
  USER_FORGOT_PASSWORD: 'Yêu cầu khôi phục mật khẩu',
  USER_RESET_PASSWORD: 'Đặt lại mật khẩu',
  USER_STATUS_UPDATED: 'Cập nhật trạng thái tài khoản',
  USER_ROLE_UPDATED: 'Cập nhật quyền tài khoản',
  PROFILE_UPDATED: 'Cập nhật hồ sơ',
  PRODUCT_VIEWED: 'Xem sản phẩm',
  PRODUCT_CREATED: 'Tạo sản phẩm',
  PRODUCT_UPDATED: 'Cập nhật sản phẩm',
  PRODUCT_DELETED: 'Xóa sản phẩm',
  PRODUCT_RESTORED: 'Khôi phục sản phẩm',
  PRODUCT_TOGGLED: 'Bật/tắt sản phẩm',
  VARIANT_CREATED: 'Tạo biến thể',
  VARIANT_UPDATED: 'Cập nhật biến thể',
  VARIANT_TOGGLED: 'Bật/tắt biến thể',
  ASSET_UPLOADED: 'Tải tài nguyên',
  ASSET_DELETED: 'Xóa tài nguyên',
  ASSET_SET_PRIMARY: 'Đặt ảnh chính',
  BRAND_CREATED: 'Tạo thương hiệu',
  BRAND_UPDATED: 'Cập nhật thương hiệu',
  BRAND_TOGGLED: 'Bật/tắt thương hiệu',
  BRAND_DELETED: 'Xóa thương hiệu',
  CATEGORY_CREATED: 'Tạo danh mục',
  CATEGORY_UPDATED: 'Cập nhật danh mục',
  CATEGORY_DELETED: 'Xóa danh mục',
  CART_ITEM_ADDED: 'Thêm vào giỏ',
  CART_ITEM_UPDATED: 'Cập nhật giỏ',
  CART_ITEM_REMOVED: 'Xóa khỏi giỏ',
  CART_CLEARED: 'Xóa giỏ hàng',
  CART_SYNCED: 'Đồng bộ giỏ hàng',
  WISHLIST_ADDED: 'Thêm yêu thích',
  WISHLIST_REMOVED: 'Xóa yêu thích',
  ORDER_PLACED: 'Đặt hàng',
  ORDER_CANCELLED: 'Hủy đơn hàng',
  ORDER_STATUS_UPDATED: 'Cập nhật trạng thái đơn',
  ORDER_REORDERED: 'Đặt lại đơn hàng',
  PAYMENT_INITIATED: 'Khởi tạo thanh toán',
  PAYMENT_SUCCESS: 'Thanh toán thành công',
  PAYMENT_FAILED: 'Thanh toán thất bại',
};

const actionOptions = [
  { value: '', label: 'Tất cả hành động' },
  { value: 'USER_LOGIN', label: 'Đăng nhập' },
  { value: 'USER_LOGOUT', label: 'Đăng xuất' },
  { value: 'USER_CHANGE_PASSWORD', label: 'Đổi mật khẩu' },
  { value: 'USER_ROLE_UPDATED', label: 'Cập nhật quyền' },
  { value: 'USER_STATUS_UPDATED', label: 'Cập nhật trạng thái tài khoản' },
  { value: 'PRODUCT_CREATED', label: 'Tạo sản phẩm' },
  { value: 'PRODUCT_UPDATED', label: 'Cập nhật sản phẩm' },
  { value: 'PRODUCT_DELETED', label: 'Xóa sản phẩm' },
  { value: 'CATEGORY_CREATED', label: 'Tạo danh mục' },
  { value: 'CATEGORY_UPDATED', label: 'Cập nhật danh mục' },
  { value: 'BRAND_CREATED', label: 'Tạo thương hiệu' },
  { value: 'BRAND_UPDATED', label: 'Cập nhật thương hiệu' },
  { value: 'ORDER_STATUS_UPDATED', label: 'Cập nhật trạng thái đơn' },
  { value: 'ORDER_CANCELLED', label: 'Hủy đơn hàng' },
  { value: 'PAYMENT_SUCCESS', label: 'Thanh toán thành công' },
  { value: 'PAYMENT_FAILED', label: 'Thanh toán thất bại' },
];

const actionGroupLabels: Record<ActionGroup, string> = {
  all: 'Tất cả module',
  account: 'Tài khoản',
  catalog: 'Catalog',
  order: 'Đơn hàng',
  payment: 'Thanh toán',
  security: 'Bảo mật',
};

const formatDateTime = (value?: string) => {
  if (!value) return 'N/A';
  return new Intl.DateTimeFormat('vi-VN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value));
};

const toDateValue = (date: Date) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

const parseDateValue = (value: string) => {
  if (!value) return null;
  const [year, month, day] = value.split('-').map(Number);
  if (!year || !month || !day) return null;
  return new Date(year, month - 1, day);
};

const addDays = (date: Date, days: number) => {
  const nextDate = new Date(date);
  nextDate.setDate(nextDate.getDate() + days);
  return nextDate;
};

const addMonths = (date: Date, months: number) => {
  const nextDate = new Date(date);
  nextDate.setMonth(nextDate.getMonth() + months);
  return nextDate;
};

const formatShortDate = (value?: string) => {
  if (!value) return '';
  return new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(new Date(`${value}T00:00:00`));
};

const formatRangeLabel = (startDate: string, endDate: string) => {
  if (!startDate && !endDate) return 'Tất cả thời gian';
  if (startDate && endDate) return `${formatShortDate(startDate)} - ${formatShortDate(endDate)}`;
  if (startDate) return `Từ ${formatShortDate(startDate)}`;
  return `Đến ${formatShortDate(endDate)}`;
};

const escapeCsvCell = (value: unknown) => `"${String(value ?? '').replace(/"/g, '""')}"`;

const getActionLabel = (action: string) => actionLabels[action] || action.replace(/_/g, ' ');

const getActorName = (log: ActivityLog) => log.user?.profile?.fullName || log.user?.email || 'Hệ thống';

const getActionGroup = (action: string): Exclude<ActionGroup, 'all'> => {
  if (action.startsWith('USER_') || action.startsWith('PROFILE_')) return 'account';
  if (action.startsWith('PRODUCT_') || action.startsWith('VARIANT_') || action.startsWith('ASSET_') || action.startsWith('BRAND_') || action.startsWith('CATEGORY_')) return 'catalog';
  if (action.startsWith('ORDER_') || action.startsWith('CART_') || action.startsWith('WISHLIST_')) return 'order';
  if (action.startsWith('PAYMENT_')) return 'payment';
  return 'security';
};

const getSeverity = (action: string) => {
  if (action.includes('DELETED') || action.includes('FAILED') || action.includes('CANCELLED')) return 'high';
  if (action.includes('UPDATED') || action.includes('ROLE') || action.includes('STATUS')) return 'medium';
  return 'normal';
};

const downloadTextFile = (content: string, filename: string, type: string) => {
  const blob = new Blob([content], { type });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
};

interface DateRangePickerProps {
  startDate: string;
  endDate: string;
  onApply: (range: { startDate: string; endDate: string }) => void;
}

const DateRangePicker: React.FC<DateRangePickerProps> = ({ startDate, endDate, onApply }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [draftStart, setDraftStart] = useState(startDate);
  const [draftEnd, setDraftEnd] = useState(endDate);
  const [visibleMonth, setVisibleMonth] = useState(() => parseDateValue(startDate) || new Date());

  const monthLabel = (date: Date) =>
    new Intl.DateTimeFormat('vi-VN', { month: 'long', year: 'numeric' }).format(date);

  const buildMonthDays = (monthDate: Date) => {
    const firstDay = new Date(monthDate.getFullYear(), monthDate.getMonth(), 1);
    const startOffset = (firstDay.getDay() + 6) % 7;
    const calendarStart = addDays(firstDay, -startOffset);

    return Array.from({ length: 42 }, (_, index) => {
      const date = addDays(calendarStart, index);
      return {
        date,
        value: toDateValue(date),
        inMonth: date.getMonth() === monthDate.getMonth(),
      };
    });
  };

  const selectDate = (value: string) => {
    if (!draftStart || draftEnd) {
      setDraftStart(value);
      setDraftEnd('');
      return;
    }

    if (value < draftStart) {
      setDraftStart(value);
      setDraftEnd(draftStart);
      return;
    }

    setDraftEnd(value);
  };

  const applyPreset = (preset: string) => {
    const today = new Date();
    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    const startOfYear = new Date(today.getFullYear(), 0, 1);

    if (preset === 'all') {
      setDraftStart('');
      setDraftEnd('');
      return;
    }

    const ranges: Record<string, { start: Date; end: Date }> = {
      today: { start: today, end: today },
      '7d': { start: addDays(today, -6), end: today },
      '30d': { start: addDays(today, -29), end: today },
      '3m': { start: addMonths(today, -3), end: today },
      month_to_date: { start: startOfMonth, end: today },
      year_to_date: { start: startOfYear, end: today },
    };

    const range = ranges[preset];
    if (!range) return;
    setDraftStart(toDateValue(range.start));
    setDraftEnd(toDateValue(range.end));
    setVisibleMonth(range.start);
  };

  const cancel = () => {
    setDraftStart(startDate);
    setDraftEnd(endDate);
    setIsOpen(false);
  };

  const apply = () => {
    onApply({ startDate: draftStart, endDate: draftEnd || draftStart });
    setIsOpen(false);
  };

  const renderMonth = (monthDate: Date) => (
    <div className="min-w-0 flex-1">
      <div className="h-11 rounded-[8px] bg-[#fbfcff] flex items-center justify-center text-sm font-extrabold text-[#25396f] mb-3 capitalize">
        {monthLabel(monthDate)}
      </div>
      <div className="grid grid-cols-7 gap-1 text-center mb-2">
        {['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map((day) => (
          <span key={day} className="text-[11px] font-extrabold text-[#a8b4c7] py-1">{day}</span>
        ))}
      </div>
      <div className="grid grid-cols-7 gap-1">
        {buildMonthDays(monthDate).map((day) => {
          const isStart = day.value === draftStart;
          const isEnd = day.value === draftEnd;
          const isInRange = Boolean(draftStart && draftEnd && day.value > draftStart && day.value < draftEnd);

          return (
            <button
              key={day.value}
              type="button"
              onClick={() => selectDate(day.value)}
              className={cn(
                'h-9 rounded-[7px] text-sm font-extrabold transition-colors',
                day.inMonth ? 'text-[#25396f]' : 'text-[#c8d1df]',
                isInRange && 'bg-primary/10 text-primary',
                (isStart || isEnd) && 'bg-primary text-white shadow-sm',
                !isStart && !isEnd && !isInRange && 'hover:bg-[#f2f7ff] hover:text-primary',
              )}
            >
              {day.date.getDate()}
            </button>
          );
        })}
      </div>
    </div>
  );

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => {
          setDraftStart(startDate);
          setDraftEnd(endDate);
          setVisibleMonth(parseDateValue(startDate) || new Date());
          setIsOpen(!isOpen);
        }}
        className={cn(
          'h-10 w-full rounded-[5px] border px-3 text-sm font-bold inline-flex items-center gap-2 outline-none transition-colors',
          startDate || endDate
            ? 'border-primary bg-primary/10 text-primary'
            : 'border-[#dce7f1] bg-white text-[#25396f] hover:border-primary',
        )}
      >
        <Calendar className="w-4 h-4 shrink-0" />
        <span className="truncate">{formatRangeLabel(startDate, endDate)}</span>
        <ChevronDown className={cn('w-4 h-4 ml-auto shrink-0 transition-transform', isOpen && 'rotate-180')} />
      </button>

      {isOpen && (
        <div className="absolute right-0 z-30 mt-2 w-[calc(100vw-2rem)] max-w-[860px] origin-top-right rounded-[12px] border border-[#dce7f1] bg-white shadow-2xl overflow-hidden">
          <div className="grid grid-cols-1 md:grid-cols-[200px_minmax(0,1fr)]">
            <div className="border-b md:border-b-0 md:border-r border-[#f2f7ff] p-4 space-y-1 bg-[#fbfcff]">
              {[
                ['today', 'Hôm nay'],
                ['7d', '7 ngày qua'],
                ['30d', '30 ngày qua'],
                ['3m', '3 tháng qua'],
                ['month_to_date', 'Tháng hiện tại'],
                ['year_to_date', 'Năm hiện tại'],
                ['all', 'Tất cả thời gian'],
              ].map(([value, label]) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => applyPreset(value)}
                  className="w-full rounded-[7px] px-3 py-2.5 text-left text-sm font-bold text-[#607080] hover:bg-white hover:text-primary transition-colors"
                >
                  {label}
                </button>
              ))}
            </div>

            <div>
              <div className="flex items-center justify-between border-b border-[#f2f7ff] px-5 py-3">
                <button type="button" onClick={() => setVisibleMonth(addMonths(visibleMonth, -1))} className="w-8 h-8 rounded-[6px] text-[#607080] hover:bg-[#f2f7ff] inline-flex items-center justify-center">
                  <ChevronLeft className="w-4 h-4" />
                </button>
                <p className="text-sm font-extrabold text-[#25396f] mb-0">{formatRangeLabel(draftStart, draftEnd)}</p>
                <button type="button" onClick={() => setVisibleMonth(addMonths(visibleMonth, 1))} className="w-8 h-8 rounded-[6px] text-[#607080] hover:bg-[#f2f7ff] inline-flex items-center justify-center">
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>

              <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 p-4 sm:p-6">
                {renderMonth(visibleMonth)}
                {renderMonth(addMonths(visibleMonth, 1))}
              </div>

              <div className="border-t border-[#f2f7ff] px-5 py-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <p className="min-w-0 text-sm font-semibold text-[#7c8db5] mb-0">Khoảng thời gian: <span className="font-extrabold text-[#25396f] break-words">{formatRangeLabel(draftStart, draftEnd)}</span></p>
                <div className="flex items-center justify-end gap-3">
                  <button type="button" onClick={cancel} className="h-10 rounded-[7px] border border-[#dce7f1] px-5 text-sm font-extrabold text-[#607080] hover:text-primary hover:border-primary">
                    Hủy
                  </button>
                  <button type="button" onClick={apply} className="h-10 rounded-[7px] bg-primary px-5 text-sm font-extrabold text-white shadow-sm hover:bg-primary/90">
                    Áp dụng
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export const ActivityLogList: React.FC = () => {
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState<(typeof pageSizeOptions)[number]>(10);
  const [selectedLog, setSelectedLog] = useState<ActivityLog | null>(null);
  const [actionFilter, setActionFilter] = useState('');
  const [actionGroup, setActionGroup] = useState<ActionGroup>('all');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [isExportOpen, setIsExportOpen] = useState(false);

  const queryParams = useMemo(() => ({
    search: search.trim() || undefined,
    action: actionFilter || undefined,
    actionGroup: actionGroup !== 'all' ? actionGroup : undefined,
    from: startDate ? new Date(`${startDate}T00:00:00`).toISOString() : undefined,
    to: endDate ? new Date(`${endDate}T23:59:59.999`).toISOString() : undefined,
  }), [actionFilter, actionGroup, endDate, search, startDate]);

  const { data, isLoading, isError } = useQuery({
    queryKey: ['activity-logs', page, pageSize, queryParams],
    queryFn: () => activityLogService.getAllLogs({
      page,
      limit: pageSize,
      ...queryParams,
    }),
  });

  const { data: statsData } = useQuery({
    queryKey: ['activity-logs', 'stats', queryParams],
    queryFn: () => activityLogService.getStats(queryParams),
  });

  const logs: ActivityLog[] = data?.data || [];
  const meta = data?.meta || { total: 0, page: 1, limit: pageSize, lastPage: 1 };
  const totalLogs = statsData?.totalLogs ?? meta.total;
  const todayLogs = statsData?.todayLogs ?? 0;
  const highRiskLogs = statsData?.highRiskLogs ?? 0;
  const adminLogs = statsData?.adminLogs ?? 0;
  const hasActiveFilters = Boolean(search || actionFilter || actionGroup !== 'all' || startDate || endDate);

  const statCards = [
    { label: 'Tổng nhật ký', value: totalLogs, icon: IconlyDocument, bgClass: 'bg-[#9694ff]' },
    { label: 'Hôm nay', value: todayLogs, icon: IconlyTimeCircle, bgClass: 'bg-[#57caeb]' },
    { label: 'Rủi ro cao', value: highRiskLogs, icon: IconlyDanger, bgClass: 'bg-[#ff7976]' },
    { label: 'Admin thực hiện', value: adminLogs, icon: IconlyActivity, bgClass: 'bg-[#5ddc97]' },
  ];

  const visiblePages = Array.from({ length: Math.min(meta.lastPage, 5) }, (_, index) => {
    if (meta.lastPage <= 5) return index + 1;
    if (page <= 3) return index + 1;
    if (page >= meta.lastPage - 2) return meta.lastPage - 4 + index;
    return page - 2 + index;
  });

  const resetFilters = () => {
    setSearch('');
    setActionFilter('');
    setActionGroup('all');
    setStartDate('');
    setEndDate('');
    setPage(1);
  };

  const fetchExportLogs = async () => {
    const exportTotal = Math.max(1, totalLogs);
    const result = await activityLogService.getAllLogs({
      page: 1,
      limit: exportTotal,
      ...queryParams,
    });
    return (result?.data || []) as ActivityLog[];
  };

  const exportExcel = async () => {
    const exportLogs = await fetchExportLogs();
    if (exportLogs.length === 0) {
      toast.error('Không có nhật ký để xuất');
      return;
    }

    const header = ['Thời gian', 'Người thực hiện', 'Email', 'Vai trò', 'Hành động', 'Module', 'Mức độ', 'IP', 'Thiết bị'];
    const rows = exportLogs.map((log) => [
      formatDateTime(log.createdAt),
      getActorName(log),
      log.user?.email || '',
      log.user?.role || 'SYSTEM',
      getActionLabel(log.action),
      actionGroupLabels[getActionGroup(log.action)],
      getSeverity(log.action),
      log.metadata?.ip || '',
      log.metadata?.userAgent || '',
    ]);

    const csv = [header, ...rows].map((row) => row.map(escapeCsvCell).join(',')).join('\n');
    downloadTextFile(`\uFEFF${csv}`, `activity-logs-${new Date().toISOString().slice(0, 10)}.csv`, 'text/csv;charset=utf-8;');
    setIsExportOpen(false);
  };

  const exportTxt = async () => {
    const exportLogs = await fetchExportLogs();
    if (exportLogs.length === 0) {
      toast.error('Không có nhật ký để xuất');
      return;
    }

    const text = exportLogs
      .map((log) => `[${formatDateTime(log.createdAt)}] ${log.user?.role || 'SYSTEM'} ${getActorName(log)} | ${getActionLabel(log.action)} | IP: ${log.metadata?.ip || 'N/A'}`)
      .join('\n');
    downloadTextFile(text, `activity-logs-${new Date().toISOString().slice(0, 10)}.txt`, 'text/plain;charset=utf-8;');
    setIsExportOpen(false);
  };

  const renderActionBadge = (action: string) => {
    const group = getActionGroup(action);
    const groupClass = {
      account: 'bg-primary/10 text-primary',
      catalog: 'bg-[#fff7e6] text-[#946200]',
      order: 'bg-[#edf9f1] text-[#2f8f5b]',
      payment: 'bg-[#e6fdff] text-[#008c9e]',
      security: 'bg-red-50 text-red-600',
    }[group];

    return (
      <span className={cn('inline-flex rounded-[6px] px-2.5 py-1 text-[11px] font-extrabold uppercase', groupClass)}>
        {getActionLabel(action)}
      </span>
    );
  };

  const renderSeverityBadge = (action: string) => {
    const severity = getSeverity(action);
    const config = {
      high: ['Cao', 'bg-red-50 text-red-600'],
      medium: ['Trung bình', 'bg-[#fff7e6] text-[#946200]'],
      normal: ['Bình thường', 'bg-[#edf9f1] text-[#2f8f5b]'],
    }[severity];

    return <span className={cn('rounded-[6px] px-2.5 py-1 text-[11px] font-extrabold', config[1])}>{config[0]}</span>;
  };

  return (
    <div className="space-y-6 pb-10 animate-in fade-in slide-in-from-bottom-3 duration-500">
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6">
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

      <div className="bg-white rounded-[12px] shadow-[0_5px_15px_rgba(25,42,70,0.06)] border border-[#f2f7ff] overflow-hidden">
        <div className="px-5 py-5 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 border-b border-[#f2f7ff]">
          <div className="relative w-full lg:max-w-[360px]">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#a8b4c7]" />
            <input
              value={search}
              onChange={(event) => { setSearch(event.target.value); setPage(1); }}
              placeholder="Tìm theo người dùng, email, IP, hành động..."
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
              className="h-10 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
              aria-label="Số nhật ký trên mỗi trang"
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
                <div className="absolute right-0 top-12 z-30 w-44 rounded-[8px] border border-[#dce7f1] bg-white shadow-[0_12px_24px_rgba(25,42,70,0.12)] p-1">
                  <button type="button" onClick={exportExcel} className="w-full h-9 rounded-[6px] px-3 text-left text-[12px] font-extrabold text-[#25396f] hover:bg-[#f2f7ff] inline-flex items-center gap-2">
                    <FileSpreadsheet className="w-4 h-4 text-[#4fbe87]" />
                    Excel CSV
                  </button>
                  <button type="button" onClick={exportTxt} className="w-full h-9 rounded-[6px] px-3 text-left text-[12px] font-extrabold text-[#25396f] hover:bg-[#f2f7ff] inline-flex items-center gap-2">
                    <FileText className="w-4 h-4 text-[#57caeb]" />
                    TXT log
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>

        {isFilterOpen && (
          <div className="px-5 py-4 border-b border-[#f2f7ff] bg-[#fbfcff]">
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
              <div>
                <label className="mb-2 block text-[11px] font-extrabold uppercase text-[#7c8db5]">Hành động</label>
                <select
                  value={actionFilter}
                  onChange={(event) => { setActionFilter(event.target.value); setPage(1); }}
                  className="h-10 w-full rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
                >
                  {actionOptions.map((option) => <option key={option.value || 'all'} value={option.value}>{option.label}</option>)}
                </select>
              </div>

              <div>
                <label className="mb-2 block text-[11px] font-extrabold uppercase text-[#7c8db5]">Module</label>
                <select
                  value={actionGroup}
                  onChange={(event) => { setActionGroup(event.target.value as ActionGroup); setPage(1); }}
                  className="h-10 w-full rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
                >
                  {Object.entries(actionGroupLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
                </select>
              </div>

              <div className="xl:col-span-2">
                <label className="mb-2 block text-[11px] font-extrabold uppercase text-[#7c8db5]">Thời gian</label>
                <DateRangePicker
                  startDate={startDate}
                  endDate={endDate}
                  onApply={(range) => {
                    setStartDate(range.startDate);
                    setEndDate(range.endDate);
                    setPage(1);
                  }}
                />
              </div>
            </div>

            <div className="mt-4 flex justify-end">
              <button
                type="button"
                onClick={resetFilters}
                disabled={!hasActiveFilters}
                className="h-9 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-[12px] font-extrabold text-[#607080] inline-flex items-center gap-2 hover:text-primary hover:border-primary disabled:opacity-50 disabled:pointer-events-none"
              >
                <RotateCcw className="w-4 h-4" />
                Xóa bộ lọc
              </button>
            </div>
          </div>
        )}

        {hasActiveFilters && (
          <div className="px-5 pb-5 flex flex-wrap items-center gap-2">
            {search && (
              <button type="button" onClick={() => { setSearch(''); setPage(1); }} className="rounded-full bg-[#f2f7ff] px-3 py-1.5 text-[12px] font-extrabold text-[#435ebe] inline-flex items-center gap-2 hover:bg-[#e9f1ff]">
                Từ khóa: {search}
                <XCircle className="w-3.5 h-3.5" />
              </button>
            )}
            {actionFilter && (
              <button type="button" onClick={() => { setActionFilter(''); setPage(1); }} className="rounded-full bg-[#f2f7ff] px-3 py-1.5 text-[12px] font-extrabold text-[#435ebe] inline-flex items-center gap-2 hover:bg-[#e9f1ff]">
                Hành động: {getActionLabel(actionFilter)}
                <XCircle className="w-3.5 h-3.5" />
              </button>
            )}
            {actionGroup !== 'all' && (
              <button type="button" onClick={() => { setActionGroup('all'); setPage(1); }} className="rounded-full bg-[#f2f7ff] px-3 py-1.5 text-[12px] font-extrabold text-[#435ebe] inline-flex items-center gap-2 hover:bg-[#e9f1ff]">
                Module: {actionGroupLabels[actionGroup]}
                <XCircle className="w-3.5 h-3.5" />
              </button>
            )}
            {(startDate || endDate) && (
              <button type="button" onClick={() => { setStartDate(''); setEndDate(''); setPage(1); }} className="rounded-full bg-[#f2f7ff] px-3 py-1.5 text-[12px] font-extrabold text-[#435ebe] inline-flex items-center gap-2 hover:bg-[#e9f1ff]">
                Ngày: {formatRangeLabel(startDate, endDate)}
                <XCircle className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        )}

        {isError && (
          <div className="mx-5 mt-5 rounded-[8px] border border-red-100 bg-red-50 p-4 flex gap-3 text-red-600">
            <AlertCircle className="w-5 h-5 shrink-0 mt-0.5" />
            <div>
              <h6 className="font-extrabold text-red-700 mb-1">Không thể tải nhật ký hoạt động</h6>
              <p className="text-sm font-semibold text-red-500 mb-0">Máy chủ hiện không phản hồi. Vui lòng thử lại sau.</p>
            </div>
          </div>
        )}

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1120px]">
            <thead>
              <tr className="border-b border-[#dce7f1] bg-[#fbfcff] text-[#607080] text-[11px] font-extrabold uppercase">
                <th className="px-5 py-4">Thời gian</th>
                <th className="px-5 py-4">Người thực hiện</th>
                <th className="px-5 py-4">Hành động</th>
                <th className="px-5 py-4">Module</th>
                <th className="px-5 py-4">Mức độ</th>
                <th className="px-5 py-4">IP / Thiết bị</th>
                <th className="px-5 py-4 text-right">Chi tiết</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#f2f7ff]">
              {isLoading ? (
                Array.from({ length: 6 }).map((_, index) => (
                  <tr key={index} className="animate-pulse">
                    <td colSpan={7} className="px-5 py-5">
                      <div className="h-12 rounded-[8px] bg-[#f2f7ff]" />
                    </td>
                  </tr>
                ))
              ) : logs.length > 0 ? (
                logs.map((log) => (
                  <tr key={log.id} className="hover:bg-[#fbfcff] transition-colors">
                    <td className="px-5 py-4">
                      <div className="flex flex-col gap-1">
                        <span className="text-sm font-extrabold text-[#25396f] inline-flex items-center gap-1.5">
                          <Calendar className="w-3.5 h-3.5 text-[#a8b4c7]" />
                          {new Date(log.createdAt).toLocaleDateString('vi-VN')}
                        </span>
                        <span className="text-[11px] font-bold text-[#7c8db5] inline-flex items-center gap-1.5">
                          <Clock className="w-3.5 h-3.5" />
                          {new Date(log.createdAt).toLocaleTimeString('vi-VN')}
                        </span>
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-[10px] bg-[#f2f7ff] flex items-center justify-center text-primary shrink-0 overflow-hidden">
                          {log.user?.profile?.avatarUrl ? (
                            <img src={log.user.profile.avatarUrl} alt={getActorName(log)} className="w-full h-full object-cover" />
                          ) : (
                            <User className="w-5 h-5" />
                          )}
                        </div>
                        <div className="min-w-0">
                          <p className="font-extrabold text-[#25396f] mb-0 truncate max-w-[220px]">{getActorName(log)}</p>
                          <p className="text-[11px] font-semibold text-[#7c8db5] mb-0 truncate max-w-[220px]">{log.user?.email || 'SYSTEM'}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-4">{renderActionBadge(log.action)}</td>
                    <td className="px-5 py-4">
                      <span className="text-sm font-extrabold text-[#25396f]">{actionGroupLabels[getActionGroup(log.action)]}</span>
                    </td>
                    <td className="px-5 py-4">{renderSeverityBadge(log.action)}</td>
                    <td className="px-5 py-4">
                      <div className="flex flex-col gap-1">
                        <span className="text-sm font-bold text-[#25396f] inline-flex items-center gap-1.5">
                          <Globe className="w-3.5 h-3.5 text-[#a8b4c7]" />
                          {log.metadata?.ip || 'N/A'}
                        </span>
                        <span className="text-[11px] font-semibold text-[#7c8db5] line-clamp-1 max-w-[260px]" title={log.metadata?.userAgent || ''}>
                          {log.metadata?.userAgent || 'Không có user agent'}
                        </span>
                      </div>
                    </td>
                    <td className="px-5 py-4 text-right">
                      <button
                        type="button"
                        onClick={() => setSelectedLog(log)}
                        className="h-9 rounded-[6px] border border-[#dce7f1] bg-white px-3 text-[12px] font-extrabold text-[#607080] hover:text-primary hover:border-primary"
                      >
                        Xem
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="px-6 py-20 text-center">
                    <div className="mx-auto w-16 h-16 rounded-[14px] bg-[#f2f7ff] flex items-center justify-center mb-4">
                      <History className="w-8 h-8 text-primary" />
                    </div>
                    <h6 className="text-[18px] font-extrabold text-[#25396f] mb-1">Không tìm thấy nhật ký nào</h6>
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
            Hiển thị {(page - 1) * pageSize + (logs.length > 0 ? 1 : 0)} tới {(page - 1) * pageSize + logs.length} của {meta.total} nhật ký
          </p>
          {meta.lastPage > 1 && (
            <nav aria-label="Activity log pagination">
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
                  <button type="button" disabled={page === meta.lastPage} onClick={() => setPage(page + 1)} className="w-9 h-9 rounded-[6px] border border-[#dce7f1] bg-white text-[#7c8db5] inline-flex items-center justify-center hover:text-primary hover:border-primary disabled:opacity-40 disabled:pointer-events-none">
                    <ChevronRight className="w-4 h-4" />
                  </button>
                </li>
              </ul>
            </nav>
          )}
        </div>
      </div>

      <Drawer isOpen={!!selectedLog} onClose={() => setSelectedLog(null)} title="Chi tiết hoạt động">
        {selectedLog && (
          <div className="space-y-6">
            <div className="rounded-[16px] border border-primary/10 bg-primary/5 p-5">
              <div className="flex items-start justify-between gap-3 mb-4">
                <div>
                  <p className="text-[11px] font-extrabold uppercase text-primary mb-1">Hành động</p>
                  <h3 className="text-xl font-extrabold text-[#25396f] mb-0">{getActionLabel(selectedLog.action)}</h3>
                </div>
                {renderSeverityBadge(selectedLog.action)}
              </div>
              <div className="flex flex-wrap gap-2">
                {renderActionBadge(selectedLog.action)}
                <span className="rounded-[6px] bg-white px-2.5 py-1 text-[11px] font-extrabold text-[#607080]">{actionGroupLabels[getActionGroup(selectedLog.action)]}</span>
              </div>
            </div>

            <section>
              <h4 className="mb-3 flex items-center gap-2 text-[12px] font-extrabold uppercase text-[#7c8db5]">
                <ShieldCheck className="w-4 h-4" />
                Người thực hiện
              </h4>
              <div className="rounded-[12px] border border-[#f2f7ff] bg-[#fbfcff] p-4 space-y-3">
                <div className="flex justify-between gap-3">
                  <span className="text-sm font-bold text-[#7c8db5]">Tên:</span>
                  <span className="text-sm font-extrabold text-[#25396f] text-right">{getActorName(selectedLog)}</span>
                </div>
                <div className="flex justify-between gap-3">
                  <span className="text-sm font-bold text-[#7c8db5]">Email:</span>
                  <span className="text-sm font-extrabold text-[#25396f] text-right">{selectedLog.user?.email || 'N/A'}</span>
                </div>
                <div className="flex justify-between gap-3">
                  <span className="text-sm font-bold text-[#7c8db5]">Vai trò:</span>
                  <span className="text-sm font-extrabold text-[#25396f] text-right">{selectedLog.user?.role || 'SYSTEM'}</span>
                </div>
                <div className="flex justify-between gap-3">
                  <span className="text-sm font-bold text-[#7c8db5]">Thời gian:</span>
                  <span className="text-sm font-extrabold text-[#25396f] text-right">{formatDateTime(selectedLog.createdAt)}</span>
                </div>
              </div>
            </section>

            <section>
              <h4 className="mb-3 flex items-center gap-2 text-[12px] font-extrabold uppercase text-[#7c8db5]">
                <Laptop className="w-4 h-4" />
                Môi trường
              </h4>
              <div className="rounded-[12px] border border-[#f2f7ff] bg-[#fbfcff] p-4 space-y-3">
                <div className="flex justify-between gap-3">
                  <span className="text-sm font-bold text-[#7c8db5]">IP:</span>
                  <span className="text-sm font-mono font-extrabold text-[#25396f] text-right">{selectedLog.metadata?.ip || 'N/A'}</span>
                </div>
                <div>
                  <span className="text-sm font-bold text-[#7c8db5]">User agent:</span>
                  <p className="mt-2 rounded-[8px] border border-[#dce7f1] bg-white p-3 text-xs font-semibold text-[#607080] break-words">
                    {selectedLog.metadata?.userAgent || 'N/A'}
                  </p>
                </div>
              </div>
            </section>

            <section>
              <h4 className="mb-3 flex items-center gap-2 text-[12px] font-extrabold uppercase text-[#7c8db5]">
                <FileText className="w-4 h-4" />
                Metadata
              </h4>
              <pre className="max-h-[320px] overflow-auto rounded-[12px] bg-[#1f2937] p-4 text-xs font-semibold leading-relaxed text-[#d1fae5]">
                {JSON.stringify(selectedLog.metadata || {}, null, 2)}
              </pre>
            </section>

            <Button variant="outline" className="w-full h-11 rounded-[8px] font-extrabold" onClick={() => setSelectedLog(null)}>
              Đóng chi tiết
            </Button>
          </div>
        )}
      </Drawer>
    </div>
  );
};

export default ActivityLogList;
