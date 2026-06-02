import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  AlertCircle,
  Briefcase,
  Calendar,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  CreditCard,
  Download,
  ExternalLink,
  FileSpreadsheet,
  FileText,
  MapPin,
  NotebookText,
  Phone,
  Search,
  ShoppingBag,
  User,
} from '../../components/ui/IconlyIcons';
import {
  Buy as IconlyBuy,
  CloseSquare as IconlyCloseSquare,
  PaperDownload as IconlyPaperDownload,
  TimeCircle as IconlyTimeCircle,
  Wallet as IconlyWallet,
} from 'react-iconly';
import { toast } from 'sonner';
import { transactionService } from '../../services/transaction.service';
import { Button } from '../../components/ui/Button';
import { Drawer } from '../../components/ui/Drawer';
import { cn } from '../../utils/cn';

const pageSizeOptions = [10, 50, 100] as const;

type TransactionStatusFilter = '' | 'SUCCESS' | 'PENDING' | 'FAILED' | 'REFUNDED';
type PaymentMethodFilter = '' | 'COD' | 'PAYMENT_GATEWAY' | 'BANK_TRANSFER' | 'E_WALLET';

const statusLabel: Record<Exclude<TransactionStatusFilter, ''>, string> = {
  SUCCESS: 'Thành công',
  PENDING: 'Chờ xử lý',
  FAILED: 'Thất bại',
  REFUNDED: 'Đã hoàn tiền',
};

const paymentMethodLabel: Record<Exclude<PaymentMethodFilter, ''>, string> = {
  COD: 'Thanh toán COD',
  PAYMENT_GATEWAY: 'Cổng thanh toán',
  BANK_TRANSFER: 'Chuyển khoản',
  E_WALLET: 'Ví điện tử',
};

const formatCurrency = (value: number) =>
  new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(value || 0);

const formatDate = (value?: string) => {
  if (!value) return 'N/A';
  return new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(new Date(value));
};

const formatTime = (value?: string) => {
  if (!value) return 'N/A';
  return new Intl.DateTimeFormat('vi-VN', { hour: '2-digit', minute: '2-digit' }).format(new Date(value));
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

const formatRangeLabel = (startDate: string, endDate: string) => {
  if (!startDate && !endDate) return 'Tất cả thời gian';
  if (startDate && endDate) return `${formatDate(startDate)} - ${formatDate(endDate)}`;
  if (startDate) return `Từ ${formatDate(startDate)}`;
  return `Đến ${formatDate(endDate)}`;
};

const escapeHtml = (value: unknown) =>
  String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');

const getPaymentMethodLabel = (method: string, provider?: string) => {
  const label = paymentMethodLabel[method as Exclude<PaymentMethodFilter, ''>] || method || 'N/A';
  return provider ? `${label} (${provider})` : label;
};

const getStatusBadge = (status: string) => {
  const baseClass = 'inline-flex items-center gap-1.5 rounded-[6px] border-none px-2.5 py-1 text-[10px] font-extrabold uppercase';

  if (status === 'SUCCESS') {
    return <span className={cn(baseClass, 'bg-[#edf9f1] text-[#2f8f5b]')}>Thành công</span>;
  }
  if (status === 'FAILED') {
    return <span className={cn(baseClass, 'bg-red-50 text-red-600')}>Thất bại</span>;
  }
  if (status === 'REFUNDED') {
    return <span className={cn(baseClass, 'bg-[#fff7e6] text-[#946200]')}>Hoàn tiền</span>;
  }
  return <span className={cn(baseClass, 'bg-primary/10 text-primary')}>Chờ xử lý</span>;
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
          'h-10 rounded-[5px] border px-3 text-sm font-bold inline-flex items-center gap-2 outline-none transition-colors',
          startDate || endDate
            ? 'border-primary bg-primary/10 text-primary'
            : 'border-[#dce7f1] bg-white text-[#607080] hover:border-primary',
        )}
      >
        <Calendar className="w-4 h-4" />
        <span className="max-w-[220px] truncate">{formatRangeLabel(startDate, endDate)}</span>
        <ChevronDown className={cn('w-4 h-4 transition-transform', isOpen && 'rotate-180')} />
      </button>

      {isOpen && (
        <div className="absolute right-0 z-30 mt-2 w-[860px] max-w-[calc(100vw-2rem)] rounded-[12px] border border-[#dce7f1] bg-white shadow-2xl overflow-hidden">
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
                <p className="text-sm font-semibold text-[#7c8db5] mb-0">Khoảng thời gian: <span className="font-extrabold text-[#25396f]">{formatRangeLabel(draftStart, draftEnd)}</span></p>
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

export const TransactionList: React.FC = () => {
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState<(typeof pageSizeOptions)[number]>(10);
  const [selectedTx, setSelectedTx] = useState<any>(null);
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethodFilter>('');
  const [status, setStatus] = useState<TransactionStatusFilter>('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [isExportOpen, setIsExportOpen] = useState(false);

  const { data, isLoading, isError } = useQuery({
    queryKey: ['transactions', search, page, pageSize, paymentMethod, status, startDate, endDate],
    queryFn: () => transactionService.getAllTransactions({
      search: search || undefined,
      page,
      limit: pageSize,
      paymentMethod: paymentMethod || undefined,
      status: status || undefined,
      startDate: startDate || undefined,
      endDate: endDate || undefined,
    }),
  });

  const { data: statsData } = useQuery({
    queryKey: ['transactions', 'stats', startDate, endDate],
    queryFn: () => transactionService.getTransactionStats({
      startDate: startDate || undefined,
      endDate: endDate || undefined,
    }),
  });

  const transactions = data?.data || [];
  const meta = data?.meta || { total: 0, page: 1, limit: pageSize, lastPage: 1 };
  const totalPages = Math.max(1, meta.lastPage || 1);
  const stats = {
    totalTransactions: statsData?.totalTransactions ?? 0,
    successTransactions: statsData?.successTransactions ?? 0,
    pendingTransactions: statsData?.pendingTransactions ?? 0,
    failedTransactions: statsData?.failedTransactions ?? 0,
    refundedTransactions: statsData?.refundedTransactions ?? 0,
    successfulAmount: statsData?.successfulAmount ?? statsData?.successAmount ?? 0,
    refundedAmount: statsData?.refundedAmount ?? statsData?.refundAmount ?? 0,
    successRate: statsData?.successRate ?? 0,
  };

  const visiblePages = Array.from({ length: Math.min(totalPages, 5) }, (_, index) => {
    if (totalPages <= 5) return index + 1;
    if (page <= 3) return index + 1;
    if (page >= totalPages - 2) return totalPages - 4 + index;
    return page - 2 + index;
  });

  const statCards = [
    { label: 'Tổng giao dịch', value: stats.totalTransactions, icon: IconlyBuy, bgClass: 'bg-[#9694ff]' },
    { label: 'Thành công', value: stats.successTransactions, icon: IconlyWallet, bgClass: 'bg-[#5ddc97]' },
    { label: 'Chờ xử lý', value: stats.pendingTransactions, icon: IconlyTimeCircle, bgClass: 'bg-[#57caeb]' },
    { label: 'Thất bại', value: stats.failedTransactions, icon: IconlyCloseSquare, bgClass: 'bg-[#ff7976]' },
    { label: 'Đã hoàn tiền', value: stats.refundedTransactions, icon: IconlyPaperDownload, bgClass: 'bg-[#eaca4a]' },
  ];

  const hasActiveFilters = Boolean(search || paymentMethod || status || startDate || endDate);
  const activeFilterChips = [
    search && { key: 'search', label: `Từ khóa: ${search}`, onRemove: () => { setSearch(''); setPage(1); } },
    paymentMethod && { key: 'paymentMethod', label: `Phương thức: ${paymentMethodLabel[paymentMethod]}`, onRemove: () => { setPaymentMethod(''); setPage(1); } },
    status && { key: 'status', label: `Trạng thái: ${statusLabel[status]}`, onRemove: () => { setStatus(''); setPage(1); } },
    (startDate || endDate) && {
      key: 'dateRange',
      label: `Thời gian: ${formatRangeLabel(startDate, endDate)}`,
      onRemove: () => {
        setStartDate('');
        setEndDate('');
        setPage(1);
      },
    },
  ].filter(Boolean) as Array<{ key: string; label: string; onRemove: () => void }>;

  const resetFilters = () => {
    setSearch('');
    setPaymentMethod('');
    setStatus('');
    setStartDate('');
    setEndDate('');
    setPage(1);
  };

  const fetchExportTransactions = async () => {
    const firstPage = await transactionService.getAllTransactions({
      search: search || undefined,
      page: 1,
      limit: 100,
      paymentMethod: paymentMethod || undefined,
      status: status || undefined,
      startDate: startDate || undefined,
      endDate: endDate || undefined,
    });

    const firstRows = firstPage?.data || [];
    const lastPage = firstPage?.meta?.lastPage || 1;
    if (lastPage <= 1) return firstRows;

    const remainingPages = await Promise.all(
      Array.from({ length: lastPage - 1 }, (_, index) =>
        transactionService.getAllTransactions({
          search: search || undefined,
          page: index + 2,
          limit: 100,
          paymentMethod: paymentMethod || undefined,
          status: status || undefined,
          startDate: startDate || undefined,
          endDate: endDate || undefined,
        }),
      ),
    );

    return [
      ...firstRows,
      ...remainingPages.flatMap((response: any) => response?.data || []),
    ];
  };

  const buildExportRows = (rows: any[]) => rows.map((tx) => ({
    transactionCode: tx.transactionCode || tx.id,
    providerTransactionId: tx.providerTransactionId || '',
    orderNumber: tx.order?.orderNumber || tx.orderId || '',
    customer: tx.order?.receiverName || tx.order?.user?.email || 'N/A',
    paymentMethod: getPaymentMethodLabel(tx.paymentMethod, tx.provider),
    amount: Number(tx.amount || 0),
    status: statusLabel[tx.status as Exclude<TransactionStatusFilter, ''>] || tx.status,
    createdAt: `${formatDate(tx.createdAt)} ${formatTime(tx.createdAt)}`,
  }));

  const exportExcel = async () => {
    const rows = buildExportRows(await fetchExportTransactions());
    const header = ['Mã GD', 'Mã đối soát', 'Mã đơn', 'Khách hàng', 'Phương thức', 'Số tiền', 'Trạng thái', 'Thời gian'];
    const csv = [header, ...rows.map((row) => [
      row.transactionCode,
      row.providerTransactionId,
      row.orderNumber,
      row.customer,
      row.paymentMethod,
      row.amount,
      row.status,
      row.createdAt,
    ])]
      .map((row) => row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(','))
      .join('\n');
    const blob = new Blob([`\uFEFF${csv}`], { type: 'application/vnd.ms-excel;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `transactions-${new Date().toISOString().slice(0, 10)}.csv`;
    link.click();
    URL.revokeObjectURL(url);
    setIsExportOpen(false);
  };

  const exportPdf = async () => {
    const rows = buildExportRows(await fetchExportTransactions());
    const printWindow = window.open('', '_blank');
    if (!printWindow) {
      toast.error('Trình duyệt đang chặn cửa sổ xuất PDF');
      return;
    }

    printWindow.document.write(`
      <html>
        <head>
          <title>Danh sách giao dịch</title>
          <style>
            body { font-family: Arial, sans-serif; color: #25396f; padding: 24px; }
            h1 { font-size: 20px; margin-bottom: 16px; }
            table { width: 100%; border-collapse: collapse; font-size: 12px; }
            th, td { border: 1px solid #dce7f1; padding: 8px; text-align: left; }
            th { background: #f2f7ff; text-transform: uppercase; font-size: 10px; }
          </style>
        </head>
        <body>
          <h1>Danh sách giao dịch</h1>
          <table>
            <thead><tr><th>Mã GD</th><th>Mã đơn</th><th>Khách hàng</th><th>Phương thức</th><th>Số tiền</th><th>Trạng thái</th><th>Thời gian</th></tr></thead>
            <tbody>
              ${rows.map((row) => `
                <tr>
                  <td>${escapeHtml(row.transactionCode)}</td>
                  <td>${escapeHtml(row.orderNumber)}</td>
                  <td>${escapeHtml(row.customer)}</td>
                  <td>${escapeHtml(row.paymentMethod)}</td>
                  <td>${escapeHtml(formatCurrency(row.amount))}</td>
                  <td>${escapeHtml(row.status)}</td>
                  <td>${escapeHtml(row.createdAt)}</td>
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

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="bg-white rounded-[12px] shadow-[0_5px_15px_rgba(25,42,70,0.06)] border border-[#f2f7ff] p-5">
          <p className="text-[12px] font-extrabold text-[#7c8db5] uppercase mb-2">Tổng tiền thành công</p>
          <p className="text-[28px] font-extrabold text-primary mb-1">{formatCurrency(stats.successfulAmount)}</p>
          <p className="text-[12px] font-semibold text-[#7c8db5] mb-0">Tỷ lệ thành công {Number(stats.successRate || 0).toFixed(1)}%</p>
        </div>
        <div className="bg-white rounded-[12px] shadow-[0_5px_15px_rgba(25,42,70,0.06)] border border-[#f2f7ff] p-5">
          <p className="text-[12px] font-extrabold text-[#7c8db5] uppercase mb-2">Tổng tiền hoàn</p>
          <p className="text-[28px] font-extrabold text-[#946200] mb-1">{formatCurrency(stats.refundedAmount)}</p>
          <p className="text-[12px] font-semibold text-[#7c8db5] mb-0">Theo khoảng ngày đang chọn</p>
        </div>
        <div className="bg-white rounded-[12px] shadow-[0_5px_15px_rgba(25,42,70,0.06)] border border-[#f2f7ff] p-5">
          <p className="text-[12px] font-extrabold text-[#7c8db5] uppercase mb-2">Giá trị TB thành công</p>
          <p className="text-[28px] font-extrabold text-[#25396f] mb-1">{formatCurrency(stats.successTransactions ? stats.successfulAmount / stats.successTransactions : 0)}</p>
          <p className="text-[12px] font-semibold text-[#7c8db5] mb-0">{stats.successTransactions} giao dịch thành công</p>
        </div>
      </div>

      <div className="bg-white rounded-[12px] shadow-[0_5px_15px_rgba(25,42,70,0.06)] border border-[#f2f7ff] overflow-hidden text-sm">
        <div className="px-5 py-5 flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4 border-b border-[#f2f7ff]">
          <div className="relative w-full xl:max-w-[340px]">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#a8b4c7]" />
            <input
              placeholder="Tìm theo mã GD, mã đơn, mã đối soát..."
              className="w-full h-10 pl-11 pr-4 rounded-[5px] border border-[#dce7f1] bg-white text-sm font-semibold text-[#25396f] outline-none transition-all focus:border-primary focus:ring-4 focus:ring-primary/10"
              value={search}
              onChange={(event) => {
                setSearch(event.target.value);
                setPage(1);
              }}
            />
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <select
              className="h-10 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#607080] outline-none"
              value={paymentMethod}
              onChange={(event) => {
                setPaymentMethod(event.target.value as PaymentMethodFilter);
                setPage(1);
              }}
            >
              <option value="">Tất cả phương thức</option>
              <option value="COD">Thanh toán COD</option>
              <option value="PAYMENT_GATEWAY">Cổng thanh toán</option>
              <option value="BANK_TRANSFER">Chuyển khoản</option>
              <option value="E_WALLET">Ví điện tử</option>
            </select>

            <select
              className="h-10 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#607080] outline-none"
              value={status}
              onChange={(event) => {
                setStatus(event.target.value as TransactionStatusFilter);
                setPage(1);
              }}
            >
              <option value="">Tất cả trạng thái</option>
              <option value="SUCCESS">Thành công</option>
              <option value="PENDING">Chờ xử lý</option>
              <option value="FAILED">Thất bại</option>
              <option value="REFUNDED">Đã hoàn tiền</option>
            </select>

            <DateRangePicker
              startDate={startDate}
              endDate={endDate}
              onApply={(range) => {
                setStartDate(range.startDate);
                setEndDate(range.endDate);
                setPage(1);
              }}
            />

            <select
              value={pageSize}
              onChange={(event) => {
                setPageSize(Number(event.target.value) as (typeof pageSizeOptions)[number]);
                setPage(1);
              }}
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

        {activeFilterChips.length > 0 && (
          <div className="px-5 py-3 border-b border-[#f2f7ff] bg-[#fbfcff] flex flex-wrap gap-2">
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
        )}

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1120px]">
            <thead className="bg-[#f8faff] border-b border-[#f2f7ff]">
              <tr>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase">Mã GD / đối soát</th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase">Mã đơn / khách hàng</th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase">Phương thức</th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase text-right">Số tiền</th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase text-center">Trạng thái</th>
                <th className="px-5 py-4 text-[11px] font-extrabold text-[#7c8db5] uppercase">Thời gian</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#f2f7ff]">
              {isLoading ? (
                Array.from({ length: pageSize }).map((_, index) => (
                  <tr key={index} className="animate-pulse">
                    <td colSpan={6} className="px-5 py-7 bg-slate-50/30" />
                  </tr>
                ))
              ) : transactions.length > 0 ? (
                transactions.map((tx: any) => (
                  <tr key={tx.id} className="hover:bg-[#fbfcff] transition-colors group">
                    <td className="px-5 py-4">
                      <button
                        type="button"
                        onClick={() => setSelectedTx(tx)}
                        className="font-mono text-sm font-extrabold text-primary hover:underline underline-offset-4 decoration-primary/30 text-left block truncate max-w-[230px]"
                        title={tx.transactionCode || tx.id}
                      >
                        {tx.transactionCode || tx.id}
                      </button>
                      <p className="text-[11px] font-semibold text-[#7c8db5] mb-0 truncate max-w-[230px]">
                        {tx.providerTransactionId || 'Chưa có mã đối soát'}
                      </p>
                    </td>
                    <td className="px-5 py-4">
                      <p className="font-extrabold text-[#25396f] mb-1">
                        #{tx.order?.orderNumber || (tx.orderId && tx.orderId.substring(0, 8).toUpperCase()) || 'N/A'}
                      </p>
                      <p className="text-[12px] font-semibold text-[#7c8db5] mb-0 truncate max-w-[220px]">
                        {tx.order?.receiverName || tx.order?.user?.email || 'Khách hàng'}
                      </p>
                    </td>
                    <td className="px-5 py-4">
                      <p className="font-bold text-[#25396f] mb-1">{getPaymentMethodLabel(tx.paymentMethod, tx.provider)}</p>
                      <p className="text-[11px] font-semibold text-[#7c8db5] mb-0">{tx.provider || 'Nội bộ'}</p>
                    </td>
                    <td className="px-5 py-4 text-right">
                      <span className="font-extrabold text-[#25396f]">{formatCurrency(Number(tx.amount || 0))}</span>
                    </td>
                    <td className="px-5 py-4 text-center">{getStatusBadge(tx.status)}</td>
                    <td className="px-5 py-4">
                      <p className="text-sm font-extrabold text-[#25396f] mb-1">{formatDate(tx.createdAt)}</p>
                      <p className="text-[12px] font-semibold text-[#7c8db5] mb-0">{formatTime(tx.createdAt)}</p>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={6} className="px-6 py-20 text-center">
                    <div className="mx-auto w-16 h-16 rounded-[14px] bg-[#f2f7ff] flex items-center justify-center mb-4">
                      <CreditCard className="w-8 h-8 text-primary" />
                    </div>
                    <h6 className="text-[18px] font-extrabold text-[#25396f] mb-1">Không tìm thấy giao dịch nào</h6>
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
            Hiển thị {(page - 1) * pageSize + (transactions.length > 0 ? 1 : 0)} tới {(page - 1) * pageSize + transactions.length} của {meta.total} dòng
          </p>
          {totalPages > 1 && (
            <nav aria-label="Transaction pagination">
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
          <AlertCircle className="w-6 h-6 flex-shrink-0" />
          <div>
            <p className="text-base font-extrabold text-red-700 mb-0">Không thể tải dữ liệu giao dịch</p>
            <p className="text-sm font-semibold opacity-80 mb-0">Máy chủ hiện không phản hồi. Vui lòng thử lại.</p>
          </div>
        </div>
      )}

      <Drawer
        isOpen={!!selectedTx}
        onClose={() => setSelectedTx(null)}
        title="Thông tin chi tiết"
      >
        {selectedTx && (
          <div className="space-y-6 animate-in slide-in-from-right duration-500">
            <div className="p-5 rounded-[12px] bg-primary/5 border border-primary/10 space-y-4">
              <div className="flex items-center justify-between gap-3">
                <div className="flex items-center gap-2 px-3 py-1 bg-white border border-primary/20 rounded-[6px]">
                  <CreditCard size={14} className="text-primary" />
                  <span className="text-[10px] font-extrabold uppercase text-primary leading-none">Tổng thanh toán</span>
                </div>
                {getStatusBadge(selectedTx.status)}
              </div>
              <div className="text-3xl font-extrabold text-[#25396f] tracking-tight">
                {formatCurrency(Number(selectedTx.amount || 0))}
              </div>
            </div>

            <div className="space-y-4">
              <h4 className="flex items-center gap-2 text-[11px] font-extrabold text-[#7c8db5] uppercase mb-0">
                <FileText size={14} /> Chi tiết giao dịch
              </h4>
              <div className="space-y-4 bg-[#fbfcff] p-5 rounded-[12px] border border-[#f2f7ff]">
                <div>
                  <span className="text-[10px] font-extrabold text-[#7c8db5] uppercase">Nội dung</span>
                  <p className="font-semibold text-[#25396f] leading-relaxed mb-0">{selectedTx.description || 'Không có nội dung'}</p>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <span className="text-[10px] font-extrabold text-[#7c8db5] uppercase">Mã giao dịch</span>
                    <p className="font-mono text-xs font-bold text-[#25396f] bg-white px-2 py-1 border border-[#dce7f1] rounded-[6px] break-all mb-0">{selectedTx.transactionCode || selectedTx.id}</p>
                  </div>
                  <div>
                    <span className="text-[10px] font-extrabold text-[#7c8db5] uppercase">Mã đối soát</span>
                    <p className="font-mono text-xs font-bold text-[#25396f] bg-white px-2 py-1 border border-[#dce7f1] rounded-[6px] break-all mb-0">{selectedTx.providerTransactionId || 'N/A'}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 bg-white border border-[#dce7f1] rounded-[8px] flex items-center justify-center text-[#7c8db5]">
                    <Briefcase size={16} />
                  </div>
                  <div>
                    <span className="text-[10px] font-extrabold text-[#7c8db5] uppercase">Phương thức</span>
                    <p className="font-bold text-[#25396f] mb-0">{getPaymentMethodLabel(selectedTx.paymentMethod, selectedTx.provider)}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 bg-white border border-[#dce7f1] rounded-[8px] flex items-center justify-center text-[#7c8db5]">
                    <Calendar size={16} />
                  </div>
                  <div>
                    <span className="text-[10px] font-extrabold text-[#7c8db5] uppercase">Thời gian</span>
                    <p className="font-bold text-[#25396f] mb-0">{new Date(selectedTx.createdAt).toLocaleString('vi-VN')}</p>
                  </div>
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <h4 className="flex items-center gap-2 text-[11px] font-extrabold text-[#7c8db5] uppercase mb-0">
                <User size={14} /> Thông tin khách hàng
              </h4>
              <div className="space-y-4 bg-white p-5 rounded-[12px] border border-[#f2f7ff] shadow-sm">
                {[
                  { icon: User, label: 'Người nhận', value: selectedTx.order?.receiverName || 'N/A' },
                  { icon: Phone, label: 'Số điện thoại', value: selectedTx.order?.receiverPhone || 'N/A' },
                  { icon: ExternalLink, label: 'Tài khoản đặt hàng', value: selectedTx.order?.user?.email || 'Guest' },
                  { icon: MapPin, label: 'Địa chỉ giao hàng', value: selectedTx.order?.shippingAddress || 'N/A' },
                ].map((item) => {
                  const Icon = item.icon;
                  return (
                    <div key={item.label} className="flex items-start gap-3">
                      <div className="w-9 h-9 rounded-[8px] bg-[#f2f7ff] border border-[#dce7f1] flex items-center justify-center text-[#7c8db5] shrink-0">
                        <Icon size={16} />
                      </div>
                      <div className="min-w-0">
                        <span className="text-[10px] font-extrabold text-[#7c8db5] uppercase">{item.label}</span>
                        <p className="font-bold text-[#25396f] text-sm leading-relaxed mb-0 break-words">{item.value}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            <div className="space-y-4">
              <h4 className="flex items-center gap-2 text-[11px] font-extrabold text-[#7c8db5] uppercase mb-0">
                <ShoppingBag size={14} /> Sản phẩm ({selectedTx.order?.items?.length || 0})
              </h4>
              <div className="overflow-hidden border border-[#f2f7ff] rounded-[12px]">
                <table className="w-full text-left text-sm border-collapse">
                  <thead className="bg-[#f8faff]">
                    <tr>
                      <th className="px-4 py-3 text-[10px] font-extrabold text-[#7c8db5] uppercase border-b border-[#f2f7ff]">Sản phẩm</th>
                      <th className="px-4 py-3 text-[10px] font-extrabold text-[#7c8db5] uppercase border-b border-[#f2f7ff] text-right">Thành tiền</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#f2f7ff]">
                    {selectedTx.order?.items?.map((item: any, index: number) => (
                      <tr key={`${item.productName}-${index}`} className="bg-white">
                        <td className="px-4 py-3">
                          <span className="font-extrabold text-[#25396f] leading-tight block">{item.productName}</span>
                          <span className="text-[11px] font-semibold text-[#7c8db5]">{item.variantName} · x{item.quantity}</span>
                        </td>
                        <td className="px-4 py-3 text-right">
                          <span className="font-extrabold text-[#25396f]">{formatCurrency(Number(item.priceAtPurchase || 0) * item.quantity)}</span>
                        </td>
                      </tr>
                    ))}
                    {!selectedTx.order?.items?.length && (
                      <tr>
                        <td colSpan={2} className="px-4 py-10 text-center text-[#7c8db5] font-semibold">Không có dữ liệu sản phẩm</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="space-y-4">
              <h4 className="flex items-center gap-2 text-[11px] font-extrabold text-[#7c8db5] uppercase mb-0">
                <NotebookText size={14} /> Ghi chú đơn hàng
              </h4>
              <div className="p-4 rounded-[12px] bg-[#fff7e6] border border-[#ffe6a6] text-[#946200] text-sm font-semibold leading-relaxed">
                {selectedTx.order?.note || 'Không có ghi chú của khách hàng.'}
              </div>
            </div>

            <div className="pt-2 pb-2">
              <Button
                variant="outline"
                className="w-full h-11 rounded-[8px] font-extrabold text-xs border-[#dce7f1] hover:bg-[#f2f7ff] hover:text-[#25396f] transition-all"
                onClick={() => setSelectedTx(null)}
              >
                Đóng thông tin
              </Button>
            </div>
          </div>
        )}
      </Drawer>
    </div>
  );
};

export default TransactionList;
