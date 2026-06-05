import React, { useEffect, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useSearchParams } from 'react-router-dom';
import {
  AlertCircle,
  AlertTriangle,
  Calendar,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Download,
  EllipsisVertical,
  ExternalLink,
  Filter,
  FileSpreadsheet,
  FileText,
  Loader2,
  Package,
  RotateCcw,
  Search,
  ShoppingBag,
  XCircle,
  ReceiptText,
} from '../../components/ui/IconlyIcons';
import {
  CloseSquare as IconlyCloseSquare,
  TickSquare as IconlyTickSquare,
  TimeCircle as IconlyTimeCircle,
  Wallet as IconlyWallet,
} from 'react-iconly';
import { toast } from 'sonner';
import { orderService } from '../../services/order.service';
import { Badge } from '../../components/ui/Badge';
import { Button } from '../../components/ui/Button';
import { cn } from '../../utils/cn';
import { OrderStatus } from '../../types';
import type { Order } from '../../types';

const statusLabel: Record<OrderStatus, string> = {
  PENDING: 'Chờ xác nhận',
  CONFIRMED: 'Đã xác nhận',
  PROCESSING: 'Đang đóng gói',
  SHIPPING: 'Đang giao',
  DELIVERED: 'Đã giao',
  COMPLETED: 'Hoàn tất',
  CANCELLED: 'Đã hủy',
  RETURNED: 'Khách trả hàng',
  FAILED: 'Thất bại',
};

const pageSizeOptions = [10, 50, 100] as const;
type PaymentStatusFilter = '' | 'PENDING' | 'PROCESSING' | 'PAID' | 'FAILED' | 'REFUNDED';
type PaymentMethodFilter = '' | 'COD' | 'E_WALLET' | 'PAYMENT_GATEWAY' | 'BANK_TRANSFER';
type DatePreset = '' | 'today' | '7d' | '30d' | 'this_month' | 'custom';

const paymentStatusLabel: Record<Exclude<PaymentStatusFilter, ''>, string> = {
  PENDING: 'Chờ thanh toán',
  PROCESSING: 'Đang xử lý',
  PAID: 'Đã thanh toán',
  FAILED: 'Thanh toán lỗi',
  REFUNDED: 'Đã hoàn tiền',
};

const paymentMethodLabel: Record<Exclude<PaymentMethodFilter, ''>, string> = {
  COD: 'COD',
  E_WALLET: 'Ví điện tử',
  PAYMENT_GATEWAY: 'Cổng thanh toán',
  BANK_TRANSFER: 'Chuyển khoản',
};

const datePresetLabel: Record<Exclude<DatePreset, ''>, string> = {
  today: 'Hôm nay',
  '7d': '7 ngày gần nhất',
  '30d': '30 ngày gần nhất',
  this_month: 'Tháng này',
  custom: 'Tùy chọn ngày',
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
    <div className="min-w-[280px] flex-1">
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
        <div className="absolute left-0 z-30 mt-2 w-[860px] max-w-[calc(100vw-2rem)] rounded-[12px] border border-[#dce7f1] bg-white shadow-2xl overflow-hidden">
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

              <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 p-6">
                {renderMonth(visibleMonth)}
                {renderMonth(addMonths(visibleMonth, 1))}
              </div>

              <div className="border-t border-[#f2f7ff] px-5 py-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <p className="text-sm font-semibold text-[#7c8db5] mb-0">Range: <span className="font-extrabold text-[#25396f]">{formatRangeLabel(draftStart, draftEnd)}</span></p>
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

export const OrderList: React.FC = () => {
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<OrderStatus | ''>('');
  const [userId, setUserId] = useState('');
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState<(typeof pageSizeOptions)[number]>(10);
  const [paymentStatus, setPaymentStatus] = useState<PaymentStatusFilter>('');
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethodFilter>('');
  const [datePreset, setDatePreset] = useState<DatePreset>('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [minTotal, setMinTotal] = useState('');
  const [maxTotal, setMaxTotal] = useState('');
  const [cancelRequestOnly, setCancelRequestOnly] = useState(false);
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [selectedOrderId, setSelectedOrderId] = useState<string | null>(null);
  const [selectedOrderIds, setSelectedOrderIds] = useState<string[]>([]);
  const [isExportOpen, setIsExportOpen] = useState(false);
  const [showReviewCancelDialog, setShowReviewCancelDialog] = useState(false);
  const [reviewApprove, setReviewApprove] = useState(true);
  const [reviewReason, setReviewReason] = useState('');
  const [showRefundConfirmDialog, setShowRefundConfirmDialog] = useState(false);

  const [searchParams] = useSearchParams();
  const queryClient = useQueryClient();

  const orderIdFromUrl = searchParams.get('orderId');
  const userIdFromUrl = searchParams.get('userId');

  useEffect(() => {
    if (orderIdFromUrl) {
      setSearch(orderIdFromUrl);
      setStatus('');
      setPage(1);
    }

    if (userIdFromUrl) {
      setUserId(userIdFromUrl);
      setPage(1);
    }
  }, [orderIdFromUrl, userIdFromUrl]);

  const getDateRange = () => {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

    if (datePreset === 'today') {
      return { createdFrom: startOfDay.toISOString(), createdTo: endOfDay.toISOString() };
    }

    if (datePreset === '7d' || datePreset === '30d') {
      const days = datePreset === '7d' ? 7 : 30;
      const from = new Date(startOfDay);
      from.setDate(from.getDate() - (days - 1));
      return { createdFrom: from.toISOString(), createdTo: endOfDay.toISOString() };
    }

    if (datePreset === 'this_month') {
      const from = new Date(now.getFullYear(), now.getMonth(), 1);
      return { createdFrom: from.toISOString(), createdTo: endOfDay.toISOString() };
    }

    if (datePreset === 'custom') {
      return {
        createdFrom: dateFrom ? new Date(`${dateFrom}T00:00:00`).toISOString() : undefined,
        createdTo: dateTo ? new Date(`${dateTo}T23:59:59.999`).toISOString() : undefined,
      };
    }

    return { createdFrom: undefined, createdTo: undefined };
  };

  const dateRange = getDateRange();

  const { data, isLoading, isError } = useQuery({
    queryKey: ['orders', search, status, paymentStatus, paymentMethod, datePreset, dateFrom, dateTo, minTotal, maxTotal, cancelRequestOnly, page, pageSize, userId],
    queryFn: () => orderService.getOrders({
      search,
      status: status || undefined,
      paymentStatus: paymentStatus || undefined,
      paymentMethod: paymentMethod || undefined,
      createdFrom: dateRange.createdFrom,
      createdTo: dateRange.createdTo,
      minTotal: minTotal ? Number(minTotal) : undefined,
      maxTotal: maxTotal ? Number(maxTotal) : undefined,
      cancelRequestOnly: cancelRequestOnly ? 'true' : undefined,
      page,
      limit: pageSize,
      userId: userId || undefined,
    }),
  });

  const { data: statsData } = useQuery({
    queryKey: ['orders', 'stats'],
    queryFn: orderService.getAdminStats,
  });

  const { data: orderDetail, isLoading: isLoadingDetail } = useQuery({
    queryKey: ['order-detail', selectedOrderId],
    queryFn: () => selectedOrderId ? orderService.getOrderById(selectedOrderId) : null,
    enabled: !!selectedOrderId,
  });

  const updateStatusMutation = useMutation({
    mutationFn: ({ id, nextStatus }: { id: string; nextStatus: OrderStatus }) =>
      orderService.updateStatus(id, { status: nextStatus }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      toast.success('Cập nhật trạng thái thành công');
    },
    onError: (error: any) => {
      toast.error(error?.response?.data?.message || 'Cập nhật trạng thái thất bại');
    },
  });

  const reviewCancelMutation = useMutation({
    mutationFn: ({ id, approve, reason }: { id: string; approve: boolean; reason?: string }) =>
      orderService.reviewCancelRequest(id, { approve, reason }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      queryClient.invalidateQueries({ queryKey: ['order-detail', selectedOrderId] });
      toast.success('Xử lý yêu cầu hủy đơn thành công');
    },
    onError: (error: any) => {
      toast.error(error?.response?.data?.message || 'Xử lý yêu cầu hủy đơn thất bại');
    },
  });

  const refundOrderMutation = useMutation({
    mutationFn: (id: string) => orderService.refundOrder(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      queryClient.invalidateQueries({ queryKey: ['order-detail', selectedOrderId] });
      toast.success('Yêu cầu hoàn tiền thành công');
    },
    onError: (error: any) => {
      toast.error(error?.response?.data?.message || 'Yêu cầu hoàn tiền thất bại');
    },
  });

  const orders: Order[] = data?.data || [];
  const meta = data?.meta || { total: 0, page: 1, lastPage: 1 };
  const statusStats = statsData?.stats?.ordersByStatus || statsData?.ordersByStatus || {};
  const refundedOrders = statsData?.stats?.refundedOrders ?? statsData?.refundedOrders ?? orders.filter((order) => order.paymentStatus === 'REFUNDED').length;

  const pendingProcessingCount =
    (statusStats[OrderStatus.PENDING] || 0) +
    (statusStats[OrderStatus.CONFIRMED] || 0) +
    (statusStats[OrderStatus.PROCESSING] || 0);

  const deliveredCompletedCount =
    (statusStats[OrderStatus.DELIVERED] || 0) +
    (statusStats[OrderStatus.COMPLETED] || 0);

  const cancelledCount = statusStats[OrderStatus.CANCELLED] || 0;
  const allVisibleSelected = orders.length > 0 && orders.every((order) => selectedOrderIds.includes(order.id));
  const hasActiveFilters = Boolean(search || status || userId || paymentStatus || paymentMethod || datePreset || dateFrom || dateTo || minTotal || maxTotal || cancelRequestOnly);

  const visiblePages = Array.from({ length: Math.min(meta.lastPage, 5) }, (_, index) => {
    if (meta.lastPage <= 5) return index + 1;
    if (page <= 3) return index + 1;
    if (page >= meta.lastPage - 2) return meta.lastPage - 4 + index;
    return page - 2 + index;
  });

  const statCards = [
    {
      label: 'Chờ xử lý',
      value: pendingProcessingCount,
      icon: IconlyTimeCircle,
      bgClass: 'bg-[#57caeb]',
    },
    {
      label: 'Đã giao thành công',
      value: deliveredCompletedCount,
      icon: IconlyTickSquare,
      bgClass: 'bg-[#5ddc97]',
    },
    {
      label: 'Đã hoàn tiền',
      value: refundedOrders,
      icon: IconlyWallet,
      bgClass: 'bg-[#9694ff]',
    },
    {
      label: 'Đã hủy',
      value: cancelledCount,
      icon: IconlyCloseSquare,
      bgClass: 'bg-[#ff7976]',
    },
  ];

  const hasCancelRequest = (order: Order) => (
    (order.status === OrderStatus.PENDING ||
      order.status === OrderStatus.CONFIRMED ||
      order.status === OrderStatus.PROCESSING) &&
    !!order.tracking?.length &&
    order.tracking[0].statusLabel === 'Yêu cầu hủy'
  );

  const getCustomerName = (order: Order) =>
    order.receiverName || order.user?.profile?.fullName || order.user?.fullName || 'Khách hàng';

  const getCustomerContact = (order: Order) =>
    order.receiverPhone || order.phone || order.user?.email || 'N/A';

  const getItemCount = (order: Order) =>
    order.items?.length || (order as any)._count?.items || 0;

  const getStatusBadge = (currentStatus: OrderStatus) => {
    const baseClass = 'rounded-[12px] border-none px-2.5 py-1 text-[10px] font-extrabold uppercase';

    switch (currentStatus) {
      case OrderStatus.PENDING:
        return <Badge variant="warning" className={cn(baseClass, 'bg-[#fff7e6] text-[#946200] rounded-[6px]')}>Chờ xác nhận</Badge>;
      case OrderStatus.CONFIRMED:
        return <Badge variant="info" className={cn(baseClass, 'bg-primary/10 text-primary rounded-[6px]')}>Đã xác nhận</Badge>;
      case OrderStatus.PROCESSING:
        return <Badge variant="info" className={cn(baseClass, 'bg-[#e6fdff] text-[#008c9e] rounded-[6px]')}>Đang đóng gói</Badge>;
      case OrderStatus.SHIPPING:
        return <Badge variant="info" className={cn(baseClass, 'bg-[#e6fdff] text-[#008c9e] rounded-[6px]')}>Đang giao</Badge>;
      case OrderStatus.DELIVERED:
        return <Badge variant="success" className={cn(baseClass, 'bg-[#edf9f1] text-[#2f8f5b] rounded-[6px]')}>Đã giao</Badge>;
      case OrderStatus.COMPLETED:
        return <Badge variant="success" className={cn(baseClass, 'bg-[#edf9f1] text-[#2f8f5b] rounded-[6px]')}>Hoàn tất</Badge>;
      case OrderStatus.CANCELLED:
        return <Badge variant="danger" className={cn(baseClass, 'bg-red-50 text-red-600 rounded-[6px]')}>Đã hủy</Badge>;
      case OrderStatus.RETURNED:
        return <Badge variant="danger" className={cn(baseClass, 'bg-red-50 text-red-600 rounded-[6px]')}>Trả hàng</Badge>;
      case OrderStatus.FAILED:
        return <Badge variant="danger" className={cn(baseClass, 'bg-red-50 text-red-600 rounded-[6px]')}>Thất bại</Badge>;
      default:
        return <Badge className={baseClass}>{currentStatus}</Badge>;
    }
  };

  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(value || 0);

  const activeFilterChips = [
    search && {
      key: 'search',
      label: `Từ khóa: ${search}`,
      onRemove: () => { setSearch(''); setPage(1); },
    },
    userId && {
      key: 'user',
      label: `Khách hàng: ${userId}`,
      onRemove: () => { setUserId(''); setPage(1); },
    },
    status && {
      key: 'status',
      label: `Trạng thái: ${statusLabel[status]}`,
      onRemove: () => { setStatus(''); setPage(1); },
    },
    paymentStatus && {
      key: 'payment-status',
      label: `Thanh toán: ${paymentStatusLabel[paymentStatus]}`,
      onRemove: () => { setPaymentStatus(''); setPage(1); },
    },
    paymentMethod && {
      key: 'payment-method',
      label: `Phương thức: ${paymentMethodLabel[paymentMethod]}`,
      onRemove: () => { setPaymentMethod(''); setPage(1); },
    },
    datePreset && {
      key: 'date',
      label: datePreset === 'custom'
        ? `Ngày: ${formatRangeLabel(dateFrom, dateTo)}`
        : `Ngày: ${datePresetLabel[datePreset]}`,
      onRemove: () => {
        setDatePreset('');
        setDateFrom('');
        setDateTo('');
        setPage(1);
      },
    },
    minTotal && {
      key: 'min-total',
      label: `Từ ${formatCurrency(Number(minTotal))}`,
      onRemove: () => { setMinTotal(''); setPage(1); },
    },
    maxTotal && {
      key: 'max-total',
      label: `Đến ${formatCurrency(Number(maxTotal))}`,
      onRemove: () => { setMaxTotal(''); setPage(1); },
    },
    cancelRequestOnly && {
      key: 'cancel-request',
      label: 'Có yêu cầu hủy',
      onRemove: () => { setCancelRequestOnly(false); setPage(1); },
    },
  ].filter(Boolean) as Array<{ key: string; label: string; onRemove: () => void }>;

  const formatDate = (value?: string) => {
    if (!value) return 'N/A';
    return new Intl.DateTimeFormat('vi-VN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(new Date(value));
  };

  const escapeHtml = (value: unknown) =>
    String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');

  const fetchExportOrders = async () => {
    const exportLimit = Math.max(meta.total || pageSize, pageSize);
    const response = await orderService.getOrders({
      search,
      status: status || undefined,
      paymentStatus: paymentStatus || undefined,
      paymentMethod: paymentMethod || undefined,
      createdFrom: dateRange.createdFrom,
      createdTo: dateRange.createdTo,
      minTotal: minTotal ? Number(minTotal) : undefined,
      maxTotal: maxTotal ? Number(maxTotal) : undefined,
      cancelRequestOnly: cancelRequestOnly ? 'true' : undefined,
      page: 1,
      limit: exportLimit,
      userId: userId || undefined,
    });

    return response?.data || orders;
  };

  // xử lý xuất đơn hàng ra file excel
  const exportExcel = async () => {
    const exportRows = await fetchExportOrders();
    const header: Array<string | number> = ['Mã đơn', 'Ngày tạo', 'Khách hàng', 'Liên hệ', 'Tổng tiền', 'Trạng thái'];
    const rows: Array<Array<string | number>> = exportRows.map((order: Order) => [
      order.orderNumber || order.id,
      formatDate(order.createdAt),
      getCustomerName(order),
      getCustomerContact(order),
      order.totalAmount || 0,
      statusLabel[order.status] || order.status,
    ]);

    const csv = [header, ...rows]
      .map((row: Array<string | number>) => row.map((cell: string | number) => `"${String(cell).replace(/"/g, '""')}"`).join(','))
      .join('\n');

    const blob = new Blob([`\uFEFF${csv}`], { type: 'application/vnd.ms-excel;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `orders-${new Date().toISOString().slice(0, 10)}.csv`;
    link.click();
    URL.revokeObjectURL(url);
    setIsExportOpen(false);
  };

  // xuất pdf
  const exportPdf = async () => {
    const exportRows = await fetchExportOrders();
    const printWindow = window.open('', '_blank');
    if (!printWindow) {
      toast.error('Trình duyệt đang chặn cửa sổ xuất PDF');
      return;
    }

    printWindow.document.write(`
      <html>
        <head>
          <title>Danh sách đơn hàng</title>
          <style>
            body { font-family: Arial, sans-serif; color: #25396f; padding: 24px; }
            h1 { font-size: 20px; margin-bottom: 16px; }
            table { width: 100%; border-collapse: collapse; font-size: 12px; }
            th, td { border: 1px solid #dce7f1; padding: 8px; text-align: left; }
            th { background: #f2f7ff; text-transform: uppercase; font-size: 10px; }
          </style>
        </head>
        <body>
          <h1>Danh sách đơn hàng</h1>
          <table>
            <thead>
              <tr>
                <th>Mã đơn</th>
                <th>Ngày tạo</th>
                <th>Khách hàng</th>
                <th>Liên hệ</th>
                <th>Tổng tiền</th>
                <th>Trạng thái</th>
              </tr>
            </thead>
            <tbody>
              ${exportRows.map((order: Order) => `
                <tr>
                  <td>${escapeHtml(order.orderNumber || order.id)}</td>
                  <td>${escapeHtml(formatDate(order.createdAt))}</td>
                  <td>${escapeHtml(getCustomerName(order))}</td>
                  <td>${escapeHtml(getCustomerContact(order))}</td>
                  <td>${escapeHtml(formatCurrency(order.totalAmount))}</td>
                  <td>${escapeHtml(statusLabel[order.status] || order.status)}</td>
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

  const toggleSelectOrder = (orderId: string) => {
    setSelectedOrderIds((currentIds) =>
      currentIds.includes(orderId) ? currentIds.filter((id) => id !== orderId) : [...currentIds, orderId],
    );
  };

  const toggleSelectVisibleOrders = () => {
    setSelectedOrderIds(allVisibleSelected ? [] : orders.map((order) => order.id));
  };

  const clearFilters = () => {
    setSearch('');
    setStatus('');
    setUserId('');
    setPaymentStatus('');
    setPaymentMethod('');
    setDatePreset('');
    setDateFrom('');
    setDateTo('');
    setMinTotal('');
    setMaxTotal('');
    setCancelRequestOnly(false);
  };

  const handlePrintInvoice = (order: Order) => {
    const printWindow = window.open('', '_blank');
    if (!printWindow) {
      toast.error('Trình duyệt đang chặn cửa sổ xuất hóa đơn');
      return;
    }

    const subtotal = order.items?.reduce((sum: number, item: any) => sum + Number(item.priceAtPurchase || item.price || 0) * item.quantity, 0) || 0;
    const priceTotal = Math.round(subtotal / 1.08);
    const vatAmount = subtotal - priceTotal;

    const itemsHtml = order.items?.map((item: any) => `
      <tr>
        <td style="padding: 12px 8px; border-bottom: 1px solid #edf2f7; vertical-align: top;">
          <div style="font-weight: bold; color: #2d3748; font-size: 13px;">${escapeHtml(item.productName)}</div>
          <div style="font-size: 10px; color: #718096; text-transform: uppercase; margin-top: 4px;">${escapeHtml(item.variantName || item.sku)}</div>
        </td>
        <td style="padding: 12px 8px; border-bottom: 1px solid #edf2f7; text-align: center; vertical-align: top; font-weight: bold;">${item.quantity}</td>
        <td style="padding: 12px 8px; border-bottom: 1px solid #edf2f7; text-align: right; vertical-align: top;">${formatCurrency(Number(item.priceAtPurchase || item.price))}</td>
        <td style="padding: 12px 8px; border-bottom: 1px solid #edf2f7; text-align: right; vertical-align: top; font-weight: bold; color: #2d3748;">${formatCurrency(Number(item.priceAtPurchase || item.price) * item.quantity)}</td>
      </tr>
    `).join('') || '';

    const receiverName = getCustomerName(order);
    const receiverPhone = getCustomerContact(order);
    const paymentMethodText = paymentMethodLabel[order.paymentMethod as Exclude<PaymentMethodFilter, ''>] || order.paymentMethod;

    printWindow.document.write(`
      <html>
        <head>
          <title>Hóa đơn mua hàng #${order.orderNumber || order.id.slice(-8).toUpperCase()}</title>
          <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #2d3748; line-height: 1.5; padding: 40px; margin: 0; background: #fff; }
            .invoice-box { max-width: 800px; margin: auto; padding: 30px; border: 1px solid #edf2f7; border-radius: 8px; font-size: 14px; }
            .header-table { width: 100%; border-collapse: collapse; margin-bottom: 24px; }
            .header-table td { vertical-align: top; }
            .logo { font-size: 28px; font-weight: 800; color: #435ebe; letter-spacing: -1px; }
            .company-info { text-align: right; font-size: 12px; color: #718096; line-height: 1.6; }
            .details-table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
            .details-table td { padding: 16px; border: 1px solid #edf2f7; vertical-align: top; width: 50%; }
            .details-title { font-size: 10px; font-weight: 800; color: #a0aec0; letter-spacing: 1px; margin-bottom: 8px; text-transform: uppercase; }
            .items-table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
            .items-table th { background: #f7fafc; padding: 12px 8px; text-align: left; font-size: 11px; font-weight: 800; color: #718096; text-transform: uppercase; border-bottom: 2px solid #edf2f7; }
            .totals-table { width: 320px; margin-left: auto; border-collapse: collapse; margin-top: 20px; }
            .totals-table td { padding: 8px; font-size: 14px; }
            .footer { text-align: center; margin-top: 60px; font-size: 12px; color: #a0aec0; border-top: 1px solid #edf2f7; padding-top: 20px; line-height: 1.6; }
            @media print {
              body { padding: 0; }
              .invoice-box { border: none; padding: 0; max-width: 100%; }
              .footer { page-break-inside: avoid; }
            }
          </style>
        </head>
        <body>
          <div class="invoice-box">
            <table class="header-table">
              <tr>
                <td>
                  <div class="logo">GEARHUB</div>
                  <div style="font-size: 12px; color: #718096; margin-top: 4px; font-weight: 600;">Hệ thống bán lẻ thiết bị công nghệ hàng đầu</div>
                </td>
                <td class="company-info">
                  <strong style="color: #2d3748; font-size: 13px;">CÔNG TY TNHH THƯƠNG MẠI GEARHUB</strong><br/>
                  Địa chỉ: Tòa nhà GearHub, P. Sài Gòn, TP.Hồ Chí Minh<br/>
                  Điện thoại: 1800 6789 | Email: contact@gearhub.com
                </td>
              </tr>
            </table>

            <div style="border-top: 2px solid #435ebe; margin-bottom: 24px;"></div>

            <table class="header-table" style="margin-bottom: 24px;">
              <tr>
                <td>
                  <div style="font-size: 20px; font-weight: 800; color: #2d3748; letter-spacing: -0.5px;">HÓA ĐƠN BÁN HÀNG</div>
                  <div style="font-size: 13px; color: #718096; margin-top: 6px;">Mã đơn hàng: <strong style="color: #2d3748;">#${order.orderNumber || order.id}</strong></div>
                  <div style="font-size: 13px; color: #718096;">Ngày lập hóa đơn: ${formatDate(order.createdAt)}</div>
                </td>
                <td style="text-align: right;">
                  <div style="font-size: 13px; color: #718096;">Trạng thái đơn: <strong style="color: #2d3748;">${statusLabel[order.status] || order.status}</strong></div>
                  <div style="font-size: 13px; color: #718096; margin-top: 4px;">Hình thức thanh toán: <strong style="color: #2d3748;">${paymentMethodText}</strong></div>
                </td>
              </tr>
            </table>

            <table class="details-table">
              <tr>
                <td>
                  <div class="details-title">Thông tin người mua</div>
                  <strong style="font-size: 15px; color: #2d3748;">${escapeHtml(receiverName)}</strong><br/>
                  <span style="color: #4a5568; display: inline-block; margin-top: 6px;">Điện thoại: ${escapeHtml(receiverPhone)}</span><br/>
                  <span style="color: #4a5568;">Email: ${escapeHtml(order.user?.email || 'N/A')}</span>
                </td>
                <td>
                  <div class="details-title">Địa chỉ giao hàng</div>
                  <span style="color: #4a5568; leading-height: 1.6;">${escapeHtml(order.shippingAddress || 'N/A')}</span><br/>
                  ${order.note ? `<div style="margin-top: 10px; font-style: italic; font-size: 12px; color: #718096; background: #f7fafc; padding: 6px 10px; border-radius: 6px;">Ghi chú: ${escapeHtml(order.note)}</div>` : ''}
                </td>
              </tr>
            </table>

            <table class="items-table">
              <thead>
                <tr>
                  <th style="width: 55%; padding-left: 8px;">Mô tả sản phẩm</th>
                  <th style="text-align: center; width: 10%;">SL</th>
                  <th style="text-align: right; width: 15%;">Đơn giá</th>
                  <th style="text-align: right; width: 20%; padding-right: 8px;">Thành tiền</th>
                </tr>
              </thead>
              <tbody>
                ${itemsHtml}
              </tbody>
            </table>

            <table class="totals-table">
              <tr>
                <td style="color: #718096; padding-left: 0;">Tạm tính:</td>
                <td style="text-align: right; font-weight: 600; color: #2d3748; padding-right: 0;">${formatCurrency(priceTotal)}</td>
              </tr>
              <tr>
                <td style="color: #718096; padding-left: 0;">Thuế VAT (8%):</td>
                <td style="text-align: right; font-weight: 600; color: #2d3748; padding-right: 0;">${formatCurrency(vatAmount)}</td>
              </tr>
              <tr>
                <td style="color: #718096; padding-left: 0;">Thành tiền:</td>
                <td style="text-align: right; font-weight: 600; color: #2d3748; padding-right: 0;">${formatCurrency(subtotal)}</td>
              </tr>
              ${order.voucherDiscount && Number(order.voucherDiscount) > 0 ? `
              <tr>
                <td style="color: #e53e3e; padding-left: 0;">Mã giảm giá:</td>
                <td style="text-align: right; font-weight: 600; color: #e53e3e; padding-right: 0;">-${formatCurrency(Number(order.voucherDiscount))}</td>
              </tr>
              ` : ''}
              <tr style="border-top: 2px solid #435ebe;">
                <td style="font-weight: bold; color: #435ebe; padding: 16px 0 0 0; font-size: 15px;">Tổng thanh toán:</td>
                <td style="text-align: right; font-weight: 800; color: #435ebe; padding: 16px 0 0 0; font-size: 20px;">${formatCurrency(order.totalAmount)}</td>
              </tr>
            </table>

            <div class="footer">
              <strong>Cảm ơn quý khách đã mua sắm tại GearHub!</strong><br/>
              <em>Mọi thắc mắc về hóa đơn & bảo hành vui lòng liên hệ hotline 1800 6789.</em>
            </div>
          </div>
          <script>window.onload = () => { window.print(); };</script>
        </body>
      </html>
    `);
    printWindow.document.close();
  };

  return (
    <div className="space-y-6 pb-10 animate-in fade-in slide-in-from-bottom-3 duration-500">
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6">
        {statCards.map((card) => {
          const Icon = card.icon;

          return (
            <div
              key={card.label}
              className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white transition-all duration-300 group py-6 px-6 flex items-center gap-4"
            >
              <div className={cn('w-12 h-12 rounded-[10px] flex items-center justify-center transition-transform duration-300 group-hover:scale-105 shadow-xs shrink-0 text-white', card.bgClass)}>
                <Icon set="bold" primaryColor="white" size={24} />
              </div>
              <div className="flex-1 min-w-0">
                <h6 className="text-[15px] font-semibold text-[#7c8db5] leading-tight mb-1 truncate">{card.label}</h6>
                <h6 className="text-[24px] font-extrabold text-[#25396f] leading-none mb-0 font-heading truncate">{card.value}</h6>
              </div>
            </div>
          );
        })}
      </div>

      <div className="bg-white rounded-[12px] shadow-[0_5px_15px_rgba(25,42,70,0.06)] border border-[#f2f7ff] overflow-hidden">
        <div className="px-5 py-5 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 border-b border-[#f2f7ff]">
          <div className="relative w-full lg:max-w-[260px]">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#a8b4c7]" />
            <input
              type="text"
              value={search}
              onChange={(event) => { setSearch(event.target.value); setPage(1); }}
              placeholder="Tìm kiếm đơn hàng"
              className="w-full h-10 pl-11 pr-4 rounded-[5px] border border-[#dce7f1] bg-white text-sm font-semibold text-[#25396f] outline-none transition-all focus:border-primary focus:ring-4 focus:ring-primary/10"
            />
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <button
              type="button"
              onClick={() => setIsFilterOpen(!isFilterOpen)}
              className={cn(
                'h-10 rounded-[5px] px-4 text-sm font-extrabold inline-flex items-center gap-2 transition-colors',
                isFilterOpen || hasActiveFilters
                  ? 'bg-primary text-white shadow-sm'
                  : 'bg-[#f2f7ff] text-[#607080] hover:bg-[#e9f1ff]',
              )}
            >
              <Filter className="w-4 h-4" />
              Bộ lọc
              {activeFilterChips.length > 0 && (
                <span className="min-w-5 h-5 rounded-full bg-white/20 px-1.5 text-[11px] leading-5">
                  {activeFilterChips.length}
                </span>
              )}
            </button>

            <select
              value={pageSize}
              onChange={(event) => { setPageSize(Number(event.target.value) as (typeof pageSizeOptions)[number]); setPage(1); }}
              className="h-10 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
              aria-label="Số đơn trên mỗi trang"
            >
              {pageSizeOptions.map((option) => (
                <option key={option} value={option}>{option}</option>
              ))}
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

        {isFilterOpen && (
          <div className="mx-5 my-5 rounded-[8px] border border-[#dce7f1] bg-[#fbfcff] p-4">
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
              <div>
                <label className="mb-2 block text-[11px] font-extrabold uppercase text-[#7c8db5]">Trạng thái đơn</label>
                <select
                  value={status}
                  onChange={(event) => { setStatus(event.target.value as OrderStatus | ''); setPage(1); }}
                  className="h-10 w-full rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
                >
                  <option value="">Tất cả trạng thái</option>
                  {Object.values(OrderStatus).map((option) => (
                    <option key={option} value={option}>{statusLabel[option as OrderStatus]}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="mb-2 block text-[11px] font-extrabold uppercase text-[#7c8db5]">Trạng thái thanh toán</label>
                <select
                  value={paymentStatus}
                  onChange={(event) => { setPaymentStatus(event.target.value as PaymentStatusFilter); setPage(1); }}
                  className="h-10 w-full rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
                >
                  <option value="">Tất cả thanh toán</option>
                  {Object.entries(paymentStatusLabel).map(([value, label]) => (
                    <option key={value} value={value}>{label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="mb-2 block text-[11px] font-extrabold uppercase text-[#7c8db5]">Phương thức thanh toán</label>
                <select
                  value={paymentMethod}
                  onChange={(event) => { setPaymentMethod(event.target.value as PaymentMethodFilter); setPage(1); }}
                  className="h-10 w-full rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
                >
                  <option value="">Tất cả phương thức</option>
                  {Object.entries(paymentMethodLabel).map(([value, label]) => (
                    <option key={value} value={value}>{label}</option>
                  ))}
                </select>
              </div>

              <div className="lg:col-span-2">
                <label className="mb-2 block text-[11px] font-extrabold uppercase text-[#7c8db5]">Thời gian tạo</label>
                <DateRangePicker
                  startDate={dateFrom}
                  endDate={dateTo}
                  onApply={(range) => {
                    setDateFrom(range.startDate);
                    setDateTo(range.endDate);
                    setDatePreset(range.startDate || range.endDate ? 'custom' : '');
                    setPage(1);
                  }}
                />
              </div>

              <div>
                <label className="mb-2 block text-[11px] font-extrabold uppercase text-[#7c8db5]">Giá trị từ</label>
                <input
                  type="number"
                  min="0"
                  value={minTotal}
                  onChange={(event) => { setMinTotal(event.target.value); setPage(1); }}
                  placeholder="0"
                  className="h-10 w-full rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
                />
              </div>

              <div>
                <label className="mb-2 block text-[11px] font-extrabold uppercase text-[#7c8db5]">Giá trị đến</label>
                <input
                  type="number"
                  min="0"
                  value={maxTotal}
                  onChange={(event) => { setMaxTotal(event.target.value); setPage(1); }}
                  placeholder="Không giới hạn"
                  className="h-10 w-full rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
                />
              </div>

              <label className="flex h-10 items-center gap-3 self-end rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f]">
                <input
                  type="checkbox"
                  checked={cancelRequestOnly}
                  onChange={(event) => { setCancelRequestOnly(event.target.checked); setPage(1); }}
                  className="h-4 w-4 rounded border-[#dce7f1] text-primary focus:ring-primary/20"
                />
                Chỉ đơn có yêu cầu hủy
              </label>
            </div>

            <div className="mt-4 flex justify-end">
              <button
                type="button"
                onClick={clearFilters}
                disabled={!hasActiveFilters}
                className="h-9 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-[12px] font-extrabold text-[#607080] inline-flex items-center gap-2 hover:text-primary hover:border-primary disabled:opacity-50 disabled:pointer-events-none"
              >
                <RotateCcw className="w-4 h-4" />
                Xóa bộ lọc
              </button>
            </div>
          </div>
        )}

        {activeFilterChips.length > 0 && (
          <div className="px-5 pb-5 flex flex-wrap items-center gap-2">
            {activeFilterChips.map((chip) => (
              <button
                key={chip.key}
                type="button"
                onClick={chip.onRemove}
                className="rounded-full bg-[#f2f7ff] px-3 py-1.5 text-[12px] font-extrabold text-[#435ebe] inline-flex items-center gap-2 hover:bg-[#e9f1ff]"
              >
                {chip.label}
                <XCircle className="w-3.5 h-3.5" />
              </button>
            ))}
            <button
              type="button"
              onClick={clearFilters}
              className="rounded-full px-3 py-1.5 text-[12px] font-extrabold text-[#607080] hover:text-primary"
            >
              Xóa tất cả
            </button>
          </div>
        )}

        {isError && (
          <div className="mx-5 mt-5 rounded-[8px] border border-red-100 bg-red-50 p-4 flex gap-3 text-red-600">
            <AlertCircle className="w-5 h-5 shrink-0 mt-0.5" />
            <div>
              <h6 className="font-extrabold text-red-700 mb-1">Không thể tải dữ liệu đơn hàng</h6>
              <p className="text-sm font-semibold text-red-500 mb-0">Máy chủ hiện không phản hồi. Vui lòng thử lại sau.</p>
            </div>
          </div>
        )}

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1040px]">
            <thead>
              <tr className="border-b border-[#dce7f1] bg-[#fbfcff] text-[#607080] text-[11px] font-extrabold uppercase">
                <th className="px-5 py-4 w-12">
                  <input
                    type="checkbox"
                    checked={allVisibleSelected}
                    onChange={toggleSelectVisibleOrders}
                    className="h-4 w-4 rounded border-[#dce7f1] text-primary focus:ring-primary/20"
                    aria-label="Chọn tất cả đơn hàng trên trang"
                  />
                </th>
                <th className="px-5 py-4">Đơn hàng</th>
                <th className="px-5 py-4">Ngày đặt</th>
                <th className="px-5 py-4">Khách hàng</th>
                <th className="px-5 py-4 text-right">Tổng đơn</th>
                <th className="px-5 py-4">Trạng thái</th>
                <th className="px-5 py-4 text-right">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#dce7f1] bg-[#f1f2ff] text-sm">
              {isLoading ? (
                Array.from({ length: pageSize > 10 ? 10 : pageSize }).map((_, index) => (
                  <tr key={index} className="animate-pulse">
                    <td colSpan={7} className="px-5 py-6">
                      <div className="h-5 rounded bg-white/70" />
                    </td>
                  </tr>
                ))
              ) : orders.length > 0 ? (
                orders.map((order) => (
                  <tr key={order.id} className="hover:bg-white/60 transition-colors group">
                    <td className="px-5 py-4">
                      <input
                        type="checkbox"
                        checked={selectedOrderIds.includes(order.id)}
                        onChange={() => toggleSelectOrder(order.id)}
                        className="h-4 w-4 rounded border-[#dce7f1] text-primary focus:ring-primary/20"
                        aria-label={`Chọn đơn ${order.orderNumber || order.id}`}
                      />
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex flex-col">
                        <span className="font-extrabold text-primary">
                          #{order.orderNumber || order.id.slice(-8).toUpperCase()}
                        </span>
                        <span className="mt-1 text-[10px] font-bold text-[#7c8db5]">
                          {getItemCount(order)} món
                        </span>
                        {hasCancelRequest(order) && (
                          <span className="mt-1 w-fit rounded-[5px] bg-[#fff7e6] px-1.5 py-0.5 text-[9px] font-extrabold text-[#946200]">
                            Yêu cầu hủy
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <span className="font-semibold text-[#607080]">{formatDate(order.createdAt)}</span>
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-[#dce7f1] text-[#607080] flex items-center justify-center text-xs font-extrabold uppercase">
                          {getCustomerName(order)[0] || 'G'}
                        </div>
                        <div className="min-w-0">
                          <p className="font-extrabold text-[#25396f] mb-0 truncate max-w-[220px]">{getCustomerName(order)}</p>
                          <p className="text-[11px] font-semibold text-[#607080] mb-0 truncate max-w-[220px]">{getCustomerContact(order)}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-4 text-right">
                      <span className="font-extrabold text-[#25396f]">{formatCurrency(order.totalAmount)}</span>
                    </td>
                    <td className="px-5 py-4">
                      {getStatusBadge(order.status)}
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center justify-end gap-2">
                        <select
                          className="h-9 max-w-[160px] rounded-[6px] border border-[#dce7f1] bg-white px-2 text-[11px] font-extrabold text-[#607080] outline-none focus:border-primary disabled:opacity-50"
                          value={order.status}
                          onChange={(event) => updateStatusMutation.mutate({ id: order.id, nextStatus: event.target.value as OrderStatus })}
                          disabled={updateStatusMutation.isPending}
                          aria-label="Cập nhật trạng thái đơn hàng"
                        >
                          {Object.values(OrderStatus).map((option) => (
                            <option key={option} value={option}>{statusLabel[option as OrderStatus]}</option>
                          ))}
                        </select>
                        {updateStatusMutation.isPending && <Loader2 className="w-4 h-4 animate-spin text-primary" />}
                        <button
                          type="button"
                          onClick={() => setSelectedOrderId(order.id)}
                          className="w-9 h-9 rounded-[6px] inline-flex items-center justify-center text-primary bg-primary/10 hover:bg-primary/20 transition-colors"
                          title="Xem chi tiết"
                        >
                          <ExternalLink className="w-4 h-4" />
                        </button>
                        <button
                          type="button"
                          className="w-9 h-9 rounded-[6px] inline-flex items-center justify-center text-[#607080] hover:bg-white transition-colors"
                          title="Thêm thao tác"
                        >
                          <EllipsisVertical className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="px-6 py-20 text-center">
                    <div className="mx-auto w-16 h-16 rounded-[14px] bg-white flex items-center justify-center mb-4">
                      <ShoppingBag className="w-8 h-8 text-primary/50" />
                    </div>
                    <h6 className="text-[18px] font-extrabold text-[#25396f] mb-1">Chưa có đơn hàng nào</h6>
                    <p className="text-sm font-semibold text-[#7c8db5] mb-5">Thử thay đổi từ khóa hoặc xóa bộ lọc hiện tại.</p>
                    <Button variant="outline" size="sm" className="rounded-[8px]" onClick={clearFilters}>Xóa bộ lọc</Button>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        <div className="px-5 py-4 border-t border-[#dce7f1] bg-white flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <p className="text-[13px] font-semibold text-[#a8b4c7] mb-0">
            Hiển thị {(page - 1) * pageSize + (orders.length > 0 ? 1 : 0)} tới {(page - 1) * pageSize + orders.length} của {meta.total} dòng
            {selectedOrderIds.length > 0 && <span> &nbsp; {selectedOrderIds.length} rows selected</span>}
          </p>
          {meta.lastPage > 1 && (
            <nav aria-label="Order pagination">
              <ul className="flex items-center gap-1.5">
                <li>
                  <button
                    type="button"
                    disabled={page === 1}
                    onClick={() => setPage(page - 1)}
                    className="w-9 h-9 rounded-[6px] border border-[#dce7f1] bg-white text-[#7c8db5] inline-flex items-center justify-center hover:text-primary hover:border-primary disabled:opacity-40 disabled:pointer-events-none"
                  >
                    <ChevronLeft className="w-4 h-4" />
                  </button>
                </li>
                {visiblePages.map((visiblePage) => (
                  <li key={visiblePage}>
                    <button
                      type="button"
                      onClick={() => setPage(visiblePage)}
                      className={cn(
                        'w-9 h-9 rounded-[6px] text-sm font-extrabold transition-all',
                        visiblePage === page
                          ? 'bg-primary text-white shadow-sm'
                          : 'bg-white border border-[#dce7f1] text-[#607080] hover:text-primary hover:border-primary',
                      )}
                    >
                      {visiblePage}
                    </button>
                  </li>
                ))}
                <li>
                  <button
                    type="button"
                    disabled={page === meta.lastPage}
                    onClick={() => setPage(page + 1)}
                    className="w-9 h-9 rounded-[6px] border border-[#dce7f1] bg-white text-[#7c8db5] inline-flex items-center justify-center hover:text-primary hover:border-primary disabled:opacity-40 disabled:pointer-events-none"
                  >
                    <ChevronRight className="w-4 h-4" />
                  </button>
                </li>
              </ul>
            </nav>
          )}
        </div>
      </div>

      {selectedOrderId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/45 backdrop-blur-[2px] animate-in fade-in duration-200">
          <div className="bg-white rounded-[14px] shadow-[0_18px_45px_rgba(15,23,42,0.18)] border border-[#dce7f1] w-full max-w-4xl overflow-hidden animate-in zoom-in-95 duration-200 flex flex-col max-h-[90vh]">
            <div className="px-6 py-5 border-b border-[#edf2f7] flex items-start justify-between bg-white">
              <div className="flex items-center gap-3">
                <div className="w-11 h-11 rounded-[10px] bg-[#f2f7ff] flex items-center justify-center text-primary border border-[#edf2f7]">
                  <ShoppingBag size={22} />
                </div>
                <div>
                  <p className="text-[11px] font-extrabold uppercase tracking-wider text-[#7c8db5]">Order Detail</p>
                  <h3 className="text-xl font-extrabold text-[#25396f]">Chi tiết đơn hàng</h3>
                  {orderDetail && <p className="text-xs font-bold text-[#607080] mt-1">#{orderDetail.orderNumber || orderDetail.id.toUpperCase()}</p>}
                </div>
              </div>
              <div className="flex items-center gap-2">
                {orderDetail && (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handlePrintInvoice(orderDetail)}
                    className="h-9 gap-2 rounded-[8px] border-[#dce7f1] text-[#607080] hover:text-primary hover:border-primary font-extrabold flex items-center"
                  >
                    <ReceiptText className="w-4 h-4 text-primary" />
                    In hóa đơn
                  </Button>
                )}
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setSelectedOrderId(null)}
                  className="h-9 w-9 rounded-[8px] p-0 hover:bg-[#f2f7ff]"
                >
                  <XCircle className="w-5 h-5 text-[#7c8db5]" />
                </Button>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-6 space-y-5 bg-[#fbfcff]">
              {isLoadingDetail ? (
                <div className="flex items-center justify-center py-20">
                  <Loader2 size={40} className="text-primary animate-spin" />
                </div>
              ) : orderDetail ? (
                <>
                  {hasCancelRequest(orderDetail) && (
                    <div className="p-4 bg-white border border-[#dce7f1] rounded-[12px] flex flex-col gap-3 text-[#25396f]">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-[8px] bg-[#f2f7ff] border border-[#edf2f7] inline-flex items-center justify-center">
                          <AlertTriangle className="w-5 h-5 text-primary" />
                        </div>
                        <span className="font-extrabold text-sm">Yêu cầu hủy đơn từ khách hàng</span>
                      </div>
                      <p className="text-sm font-medium leading-relaxed text-[#607080]">
                        Lý do: <strong className="text-[#25396f]">{orderDetail.tracking?.[0]?.description || 'Không có lý do cụ thể'}</strong>
                      </p>
                    </div>
                  )}

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="space-y-3 rounded-[12px] border border-[#edf2f7] bg-white p-5">
                      <h4 className="text-xs font-extrabold text-[#7c8db5] uppercase border-b border-[#edf2f7] pb-2">Người nhận</h4>
                      <div className="space-y-2">
                        <p className="font-extrabold text-[#25396f] text-lg">{orderDetail.receiverName || getCustomerName(orderDetail)}</p>
                        <p className="font-bold text-[#607080]">{orderDetail.receiverPhone || orderDetail.phone}</p>
                        <p className="text-sm font-medium text-[#607080] leading-relaxed">{orderDetail.shippingAddress}</p>
                      </div>
                    </div>
                    <div className="space-y-3 rounded-[12px] border border-[#edf2f7] bg-white p-5">
                      <h4 className="text-xs font-extrabold text-[#7c8db5] uppercase border-b border-[#edf2f7] pb-2">Thông tin đơn</h4>
                      <div className="grid grid-cols-1 gap-3">
                        <div className="flex justify-between gap-3">
                          <span className="text-sm font-bold text-[#7c8db5]">Trạng thái:</span>
                          {getStatusBadge(orderDetail.status)}
                        </div>
                        <div className="flex justify-between gap-3">
                          <span className="text-sm font-bold text-[#7c8db5]">Thanh toán:</span>
                          <span className="text-sm font-extrabold text-[#25396f] uppercase">{orderDetail.paymentStatus || 'N/A'}</span>
                        </div>
                        <div className="flex justify-between gap-3">
                          <span className="text-sm font-bold text-[#7c8db5]">Mã đơn:</span>
                          <span className="text-sm font-mono font-bold text-[#25396f]">#{orderDetail.id}</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-4 rounded-[12px] border border-[#edf2f7] bg-white p-5">
                    <h4 className="text-xs font-extrabold text-[#7c8db5] uppercase border-b border-[#edf2f7] pb-2">Danh sách sản phẩm</h4>
                    <div className="divide-y divide-[#edf2f7] rounded-[10px] border border-[#edf2f7] overflow-hidden">
                      {orderDetail.items?.map((item: any) => (
                        <div key={item.id} className="flex items-center justify-between gap-4 p-4 bg-white hover:bg-[#fbfcff] transition-colors">
                          <div className="flex items-center gap-4">
                            <div className="w-12 h-12 rounded-[10px] bg-white border border-[#dce7f1] flex items-center justify-center p-1 overflow-hidden">
                              {item.productVariant?.product?.thumbnailUrl ? (
                                <img src={item.productVariant.product.thumbnailUrl} alt={item.productName} className="w-full h-full object-cover rounded-[8px]" />
                              ) : (
                                <Package className="text-[#a8b4c7] w-6 h-6" />
                              )}
                            </div>
                            <div>
                              <p className="text-sm font-extrabold text-[#25396f]">{item.productName}</p>
                              <p className="text-[10px] font-bold text-[#7c8db5] uppercase">{item.variantName || item.sku}</p>
                            </div>
                          </div>
                          <div className="text-right">
                            <p className="text-sm font-extrabold text-[#25396f]">{formatCurrency(item.priceAtPurchase || item.price)}</p>
                            <p className="text-[10px] font-bold text-[#7c8db5] uppercase">x{item.quantity}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </>
              ) : null}
            </div>

            <div className="p-6 bg-white border-t border-[#edf2f7]">
              {orderDetail && (() => {
                const subtotal = orderDetail.items?.reduce((sum: number, item: any) => sum + Number(item.priceAtPurchase || item.price || 0) * item.quantity, 0) || 0;
                const priceTotal = Math.round(subtotal / 1.08);
                const vatAmount = subtotal - priceTotal;
                return (
                  <div className="mb-4 space-y-2.5 border-b border-dashed border-[#edf2f7] pb-4">
                    <div className="flex justify-between items-center text-xs">
                      <span className="font-bold text-[#7c8db5] uppercase">Tạm tính (Chưa VAT)</span>
                      <span className="font-bold text-[#25396f]">{formatCurrency(priceTotal)}</span>
                    </div>
                    <div className="flex justify-between items-center text-xs">
                      <span className="font-bold text-[#7c8db5] uppercase">Thuế VAT (8%)</span>
                      <span className="font-bold text-[#25396f]">{formatCurrency(vatAmount)}</span>
                    </div>
                    <div className="flex justify-between items-center text-xs">
                      <span className="font-bold text-[#7c8db5] uppercase">Cộng thành tiền (Có VAT)</span>
                      <span className="font-bold text-[#25396f]">{formatCurrency(subtotal)}</span>
                    </div>
                    {orderDetail.voucherDiscount && Number(orderDetail.voucherDiscount) > 0 ? (
                      <div className="flex justify-between items-center text-xs text-rose-500">
                        <span className="font-bold uppercase">Mã giảm giá</span>
                        <span className="font-bold">-{formatCurrency(Number(orderDetail.voucherDiscount))}</span>
                      </div>
                    ) : null}
                  </div>
                );
              })()}
              <div className="flex items-center justify-between mb-5 rounded-[12px] border border-[#edf2f7] bg-[#fbfcff] px-4 py-3">
                <p className="text-sm font-extrabold text-[#7c8db5] uppercase">Tổng thanh toán</p>
                <p className="text-2xl font-extrabold text-[#25396f]">
                  {orderDetail ? formatCurrency(orderDetail.totalAmount) : '...'}
                </p>
              </div>
              {orderDetail && hasCancelRequest(orderDetail) ? (
                <div className="flex flex-col gap-3 w-full">
                  {orderDetail.paymentStatus === 'PAID' && orderDetail.paymentMethod === 'PAYMENT_GATEWAY' ? (
                    <div className="flex gap-3 w-full">
                      <Button
                        variant="danger"
                        className="flex-1 h-11 rounded-[8px] font-extrabold bg-[#25396f] hover:bg-[#1f2f5d] text-white"
                        onClick={() => setShowRefundConfirmDialog(true)}
                        disabled={refundOrderMutation.isPending}
                      >
                        {refundOrderMutation.isPending ? 'Đang hoàn tiền...' : 'Duyệt hủy & hoàn tiền'}
                      </Button>
                      <Button
                        variant="outline"
                        className="flex-1 h-11 rounded-[8px] font-extrabold border-[#dce7f1] text-[#607080] hover:border-primary hover:text-primary"
                        onClick={() => { setReviewApprove(false); setReviewReason(''); setShowReviewCancelDialog(true); }}
                        disabled={reviewCancelMutation.isPending}
                      >
                        Từ chối hủy đơn
                      </Button>
                    </div>
                  ) : (
                    <div className="flex gap-3 w-full">
                      <Button
                        variant="danger"
                        className="flex-1 h-11 rounded-[8px] font-extrabold"
                        onClick={() => { setReviewApprove(true); setReviewReason(''); setShowReviewCancelDialog(true); }}
                        disabled={reviewCancelMutation.isPending}
                      >
                        Đồng ý hủy đơn
                      </Button>
                      <Button
                        variant="outline"
                        className="flex-1 h-11 rounded-[8px] font-extrabold border-[#dce7f1] text-[#607080] hover:border-primary hover:text-primary"
                        onClick={() => { setReviewApprove(false); setReviewReason(''); setShowReviewCancelDialog(true); }}
                        disabled={reviewCancelMutation.isPending}
                      >
                        Từ chối hủy đơn
                      </Button>
                    </div>
                  )}
                  <Button variant="ghost" className="h-10 rounded-[8px] text-[#607080] font-bold" onClick={() => setSelectedOrderId(null)}>Đóng chi tiết</Button>
                </div>
              ) : (
                <div className="flex flex-col gap-3 w-full">
                  {orderDetail && orderDetail.paymentStatus === 'PAID' && orderDetail.paymentMethod === 'PAYMENT_GATEWAY' && (
                    <Button
                      variant="danger"
                      className="w-full h-11 rounded-[8px] font-extrabold bg-[#25396f] hover:bg-[#1f2f5d] text-white"
                      onClick={() => setShowRefundConfirmDialog(true)}
                      disabled={refundOrderMutation.isPending}
                    >
                      {refundOrderMutation.isPending ? 'Đang gửi yêu cầu hoàn tiền...' : 'Hủy đơn và hoàn tiền'}
                    </Button>
                  )}
                  <Button className="w-full h-11 rounded-[8px] font-extrabold" onClick={() => setSelectedOrderId(null)}>Đóng chi tiết</Button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {showReviewCancelDialog && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-slate-900/55 backdrop-blur-[2px]">
          <div className="bg-white rounded-[14px] shadow-[0_18px_45px_rgba(15,23,42,0.18)] border border-[#dce7f1] w-full max-w-md overflow-hidden animate-in zoom-in-95 duration-200">
            <div className="px-6 py-5 border-b border-[#edf2f7] flex items-start justify-between gap-4 bg-white">
              <div>
                <p className="text-[11px] font-extrabold uppercase tracking-wider text-[#7c8db5]">Cancel Request</p>
                <h3 className="text-lg font-extrabold text-[#25396f] mt-1">
                  {reviewApprove ? 'Xác nhận hủy đơn hàng' : 'Từ chối hủy đơn hàng'}
                </h3>
              </div>
              <button type="button" onClick={() => setShowReviewCancelDialog(false)} className="h-9 w-9 rounded-[8px] inline-flex items-center justify-center hover:bg-[#f2f7ff]">
                <XCircle className="w-5 h-5 text-[#7c8db5]" />
              </button>
            </div>
            <div className="p-6 space-y-4 font-body">
              <div className="rounded-[10px] border border-[#edf2f7] bg-[#fbfcff] p-4">
                <p className="text-sm font-medium text-[#607080] leading-relaxed">
                  {reviewApprove
                    ? 'Khi chấp nhận hủy đơn, hệ thống sẽ tự động hoàn kho và hoàn voucher cho khách hàng. Hành động này không thể hoàn tác.'
                    : 'Đơn hàng sẽ tiếp tục trạng thái xử lý để vận chuyển. Khách hàng sẽ nhận được thông báo về việc từ chối hủy.'}
                </p>
              </div>
              <div className="space-y-2">
                <label className="text-xs font-extrabold text-[#7c8db5] uppercase">
                  Phản hồi từ cửa hàng
                </label>
                <textarea
                  className="w-full min-h-[80px] p-3 text-sm border border-[#dce7f1] rounded-[10px] focus:border-primary focus:outline-none focus:ring-4 focus:ring-primary/10 transition-all"
                  placeholder={reviewApprove ? 'Nhập lý do chấp nhận hủy...' : 'Nhập lý do từ chối hủy...'}
                  value={reviewReason}
                  onChange={(event) => setReviewReason(event.target.value)}
                  maxLength={150}
                />
              </div>
            </div>
            <div className="p-6 bg-white border-t border-[#edf2f7] flex justify-end gap-3 font-body">
              <Button variant="outline" className="h-10 rounded-[8px] font-bold border-[#dce7f1] text-[#607080]" onClick={() => setShowReviewCancelDialog(false)}>
                Quay lại
              </Button>
              <Button
                variant={reviewApprove ? 'danger' : 'primary'}
                className={cn("h-10 rounded-[8px] font-extrabold px-6", !reviewApprove && "bg-primary hover:bg-primary/90")}
                disabled={reviewCancelMutation.isPending}
                onClick={() => {
                  if (selectedOrderId) {
                    reviewCancelMutation.mutate({
                      id: selectedOrderId,
                      approve: reviewApprove,
                      reason: reviewReason,
                    }, {
                      onSuccess: () => setShowReviewCancelDialog(false),
                    });
                  }
                }}
              >
                {reviewCancelMutation.isPending ? 'Đang xử lý...' : 'Xác nhận'}
              </Button>
            </div>
          </div>
        </div>
      )}

      {showRefundConfirmDialog && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-slate-900/55 backdrop-blur-[2px]">
          <div className="bg-white rounded-[14px] shadow-[0_18px_45px_rgba(15,23,42,0.18)] border border-[#dce7f1] w-full max-w-md overflow-hidden animate-in zoom-in-95 duration-200">
            <div className="px-6 py-5 border-b border-[#edf2f7] flex items-start justify-between gap-4 bg-white">
              <div>
                <p className="text-[11px] font-extrabold uppercase tracking-wider text-[#7c8db5]">Refund Confirmation</p>
                <h3 className="text-lg font-extrabold text-[#25396f] mt-1">
                  Xác nhận hủy đơn và hoàn tiền
                </h3>
              </div>
              <button type="button" onClick={() => setShowRefundConfirmDialog(false)} className="h-9 w-9 rounded-[8px] inline-flex items-center justify-center hover:bg-[#f2f7ff]">
                <XCircle className="w-5 h-5 text-[#7c8db5]" />
              </button>
            </div>
            <div className="p-6 space-y-4 font-body">
              <div className="rounded-[10px] border border-[#edf2f7] bg-[#fbfcff] p-4">
                <p className="text-sm font-medium text-[#607080] leading-relaxed">
                  Hệ thống sẽ tiến hành hủy đơn và hoàn trả <strong className="text-[#25396f]">{orderDetail ? formatCurrency(orderDetail.totalAmount) : '...'}</strong> cho đơn hàng này.
                </p>
              </div>
              <div className="rounded-[10px] border border-slate-200 bg-white p-4 flex gap-3">
                <AlertCircle className="w-5 h-5 text-[#607080] shrink-0 mt-0.5" />
                <p className="text-xs text-[#607080] leading-relaxed font-bold">
                  Giao dịch hoàn tiền trên cổng thanh toán có thể không đảo ngược được. Vui lòng kiểm tra kỹ trước khi xác nhận.
                </p>
              </div>
            </div>
            <div className="p-6 bg-white border-t border-[#edf2f7] flex justify-end gap-3 font-body">
              <Button variant="outline" className="h-10 rounded-[8px] font-bold border-[#dce7f1] text-[#607080]" onClick={() => setShowRefundConfirmDialog(false)}>
                Quay lại
              </Button>
              <Button
                variant="danger"
                className="h-10 rounded-[8px] font-extrabold px-6"
                disabled={refundOrderMutation.isPending}
                onClick={() => {
                  if (selectedOrderId) {
                    refundOrderMutation.mutate(selectedOrderId, {
                      onSuccess: () => setShowRefundConfirmDialog(false),
                    });
                  }
                }}
              >
                {refundOrderMutation.isPending ? 'Đang hoàn tiền...' : 'Xác nhận hoàn tiền'}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
