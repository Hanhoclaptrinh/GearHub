import React, { useEffect, useRef, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Star,
  MessageSquareText,
  Search,
  AlertCircle,
  Eye,
  EyeOff,
  CheckCircle2,
  Clock,
  Sparkles,
  Send,
  ChevronLeft,
  ChevronRight,
  User as UserIcon,
  ShoppingBag,
  Filter,
  RotateCcw,
  XCircle,
} from '../../components/ui/IconlyIcons';
import ApexCharts from 'apexcharts';
import { toast } from 'sonner';
import { reviewService } from '../../services/review.service';
import { Textarea } from '../../components/ui/Textarea';
import { cn } from '../../utils/cn';
import type { Review } from '../../types';

// ── helpers ─────────────────────────────────────────────────────────────────

const formatDate = (d: string) =>
  new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(new Date(d));

const StarRow = ({ count, small }: { count: number; small?: boolean }) => (
  <div className="flex gap-0.5">
    {Array.from({ length: 5 }).map((_, i) => (
      <Star
        key={i}
        size={small ? 13 : 15}
        className={cn('transition-all', i < count ? 'fill-[#eaca4a] text-[#eaca4a]' : 'text-[#dce7f1]')}
      />
    ))}
  </div>
);

// ── ApexCharts wrappers ──────────────────────────────────────────────────────

const RatingDistributionChart: React.FC<{
  average: number;
  total: number;
  distribution: Record<string, number>;
  weeklyNew?: number;
}> = ({ average, total, distribution, weeklyNew }) => {
  const maxCount = Math.max(1, ...([5, 4, 3, 2, 1].map((s) => distribution[String(s)] ?? 0)));

  return (
    <div className="bg-white rounded-[12px] shadow-[0_5px_15px_rgba(25,42,70,0.06)] p-6 flex flex-col sm:flex-row gap-6 h-full">
      {/* Left: big number + meta */}
      <div className="flex flex-col justify-center gap-3 sm:min-w-[160px] sm:border-r sm:border-[#f2f7ff] sm:pr-6">
        <div className="flex items-center gap-2">
          <span className="text-[42px] font-extrabold text-[#435ebe] leading-none font-heading">{average.toFixed(2)}</span>
          <Star size={28} className="fill-[#eaca4a] text-[#eaca4a] mb-0.5 shrink-0" />
        </div>
        <div>
          <p className="text-[15px] font-extrabold text-[#25396f] leading-snug">Tổng {total} đánh giá</p>
          <p className="text-[12px] font-semibold text-[#7c8db5] mt-0.5 leading-snug">
            Tất cả đánh giá từ khách hàng thực
          </p>
        </div>
        {weeklyNew !== undefined && weeklyNew > 0 && (
          <span className="self-start inline-flex items-center gap-1 px-3 py-1.5 rounded-full bg-[#f2f7ff] text-[#435ebe] text-[12px] font-extrabold">
            +{weeklyNew} tuần này
          </span>
        )}
      </div>

      {/* Right: progress bars */}
      <div className="flex-1 flex flex-col justify-center gap-3">
        {[5, 4, 3, 2, 1].map((star) => {
          const count = distribution[String(star)] ?? 0;
          const pct = maxCount > 0 ? (count / maxCount) * 100 : 0;
          return (
            <div key={star} className="flex items-center gap-3">
              <span className="text-[12px] font-extrabold text-[#7c8db5] w-[42px] shrink-0 text-right">
                {star} Sao
              </span>
              <div className="flex-1 h-[10px] rounded-full bg-[#eef1ff] overflow-hidden">
                <div
                  className="h-full rounded-full bg-[#435ebe] transition-all duration-700 ease-out"
                  style={{ width: `${pct}%` }}
                />
              </div>
              <span className="text-[12px] font-extrabold text-[#7c8db5] w-[28px] shrink-0 text-right">
                {count}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
};


const ResponseStatusChart: React.FC<{
  unreplied: number;
  replied: number;
  hidden: number;
}> = ({ unreplied, replied, hidden }) => {
  const chartRef = useRef<HTMLDivElement>(null);
  const instanceRef = useRef<ApexCharts | null>(null);

  useEffect(() => {
    if (!chartRef.current) return;

    const options: ApexCharts.ApexOptions = {
      chart: {
        type: 'donut',
        height: 220,
        toolbar: { show: false },
        animations: { enabled: true, speed: 600 },
      },
      series: [replied, unreplied, hidden],
      labels: ['Đã phản hồi', 'Chưa phản hồi', 'Đang bị ẩn'],
      colors: ['#4fbe87', '#ffb236', '#f3616d'],
      dataLabels: {
        enabled: true,
        style: { fontSize: '11px', fontFamily: 'inherit', fontWeight: 700 },
        dropShadow: { enabled: false },
      },
      plotOptions: {
        pie: {
          donut: {
            size: '65%',
            labels: {
              show: true,
              total: {
                show: true,
                label: 'Tổng',
                fontSize: '12px',
                fontFamily: 'inherit',
                fontWeight: 700,
                color: '#7c8db5',
                formatter: () => String(replied + unreplied + hidden),
              },
              value: {
                fontSize: '22px',
                fontFamily: 'inherit',
                fontWeight: 800,
                color: '#25396f',
                offsetY: 4,
              },
            },
          },
        },
      },
      legend: {
        position: 'bottom',
        fontSize: '12px',
        fontFamily: 'inherit',
        fontWeight: 700,
        labels: { colors: '#607080' },
        markers: { size: 7, offsetX: -3 } as any,
        itemMargin: { horizontal: 12 },
      },
      stroke: { width: 2, colors: ['#fff'] },
      tooltip: {
        theme: 'light',
        y: { formatter: (val) => `${val} đánh giá` },
      },
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
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [unreplied, replied, hidden]);

  return (
    <div className="bg-white rounded-[12px] shadow-[0_5px_15px_rgba(25,42,70,0.06)] p-6 flex flex-col gap-2 h-full">
      <h6 className="text-[13px] font-semibold text-[#7c8db5]">Thống kê phản hồi</h6>
      <div className="grid grid-cols-3 gap-3 mb-2">
        {[
          { label: 'Đã phản hồi', value: replied, color: 'text-[#4fbe87]', bg: 'bg-[#edf9f1]' },
          { label: 'Chưa phản hồi', value: unreplied, color: 'text-[#946200]', bg: 'bg-[#fff7e6]' },
          { label: 'Đang bị ẩn', value: hidden, color: 'text-[#f3616d]', bg: 'bg-[#fff0f1]' },
        ].map((s) => (
          <div key={s.label} className={cn('rounded-[8px] px-3 py-2 text-center', s.bg)}>
            <p className={cn('text-[20px] font-extrabold leading-none font-heading', s.color)}>{s.value}</p>
            <p className="text-[10px] font-semibold text-[#7c8db5] mt-0.5">{s.label}</p>
          </div>
        ))}
      </div>
      <div ref={chartRef} className="flex-1 min-h-[180px]" />
    </div>
  );
};

// ── Inline reply panel ───────────────────────────────────────────────────────

const ReplyPanel: React.FC<{
  review: Review;
  onCancel: () => void;
  onSubmit: (id: string, text: string) => void;
  isPending: boolean;
}> = ({ review, onCancel, onSubmit, isPending }) => {
  const [text, setText] = useState(review.reply || '');
  const [aiLoading, setAiLoading] = useState(false);

  const handleAI = async () => {
    setAiLoading(true);
    try {
      const data = await reviewService.generateAiReply(review.id);
      setText(data.replyDraft);
      toast.success('AI đã soạn thảo câu trả lời nháp!');
    } catch (e: any) {
      toast.error(e.response?.data?.message || 'Không thể tạo bản nháp bằng AI');
    } finally {
      setAiLoading(false);
    }
  };

  return (
    <div className="mt-3 rounded-[10px] border border-primary/10 bg-primary/5 p-4 animate-in slide-in-from-top-2 duration-200 space-y-3">
      <div className="flex items-center justify-between gap-3">
        <span className="text-[12px] font-extrabold text-[#25396f] uppercase tracking-wide flex items-center gap-1.5">
          <MessageSquareText className="w-4 h-4 text-primary" />
          Phản hồi từ cửa hàng
        </span>
        <button
          type="button"
          onClick={handleAI}
          disabled={aiLoading || isPending}
          className="h-8 rounded-[8px] px-3 text-[11px] font-extrabold uppercase inline-flex items-center gap-1.5 bg-gradient-to-r from-violet-600 to-primary text-white hover:opacity-90 disabled:opacity-60 transition-all"
        >
          <Sparkles className={cn('w-3.5 h-3.5', aiLoading && 'animate-spin')} />
          {aiLoading ? 'AI đang soạn...' : 'Gợi ý phản hồi ✦'}
        </button>
      </div>
      <Textarea
        placeholder="Viết phản hồi của bạn hoặc để AI tạo mẫu phản hồi..."
        className="rounded-[8px] border-[#dce7f1] focus:border-primary text-sm font-semibold text-[#25396f] min-h-[90px] bg-white"
        value={text}
        onChange={(e) => setText(e.target.value)}
        disabled={isPending || aiLoading}
      />
      <div className="flex justify-end gap-2">
        <button
          type="button"
          onClick={onCancel}
          disabled={isPending || aiLoading}
          className="h-9 rounded-[8px] px-4 text-[12px] font-extrabold text-[#607080] bg-white border border-[#dce7f1] hover:bg-[#f2f7ff] transition-colors"
        >
          Hủy
        </button>
        <button
          type="button"
          onClick={() => {
            if (!text.trim()) { toast.error('Nội dung phản hồi không được để trống'); return; }
            onSubmit(review.id, text.trim());
          }}
          disabled={isPending || aiLoading}
          className="h-9 rounded-[8px] px-4 text-[12px] font-extrabold text-white bg-primary hover:bg-primary/90 disabled:opacity-60 transition-all inline-flex items-center gap-1.5"
        >
          <Send className="w-3.5 h-3.5" />
          {isPending ? 'Đang gửi...' : 'Gửi phản hồi'}
        </button>
      </div>
    </div>
  );
};

// ── Main component ───────────────────────────────────────────────────────────

type LimitOption = 10 | 50 | 100;

export const ReviewList: React.FC = () => {
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState<LimitOption>(10);
  const [search, setSearch] = useState('');
  const [rating, setRating] = useState<'ALL' | '1' | '2' | '3' | '4' | '5'>('ALL');
  const [repliedStatus, setRepliedStatus] = useState<'ALL' | 'replied' | 'unreplied'>('ALL');
  const [isHidden, setIsHidden] = useState<'ALL' | 'true' | 'false'>('ALL');
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [activeReplyId, setActiveReplyId] = useState<string | null>(null);
  const [isFilterOpen, setIsFilterOpen] = useState(false);

  const queryClient = useQueryClient();

  const { data: stats } = useQuery({
    queryKey: ['review-stats'],
    queryFn: reviewService.getReviewStats,
  });

  const { data: reviewsData, isLoading, isError } = useQuery({
    queryKey: ['admin-reviews', page, limit, rating, repliedStatus, isHidden, search],
    queryFn: () => reviewService.getReviews({
      page,
      limit,
      rating: rating !== 'ALL' ? parseInt(rating) : undefined,
      repliedStatus: repliedStatus !== 'ALL' ? repliedStatus as any : undefined,
      isHidden: isHidden === 'true' ? true : isHidden === 'false' ? false : undefined,
      search: search.trim() || undefined,
    }),
  });

  const replyMutation = useMutation({
    mutationFn: ({ id, reply }: { id: string; reply: string }) => reviewService.replyReview(id, reply),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-reviews'] });
      queryClient.invalidateQueries({ queryKey: ['review-stats'] });
      toast.success('Gửi phản hồi thành công!');
      setActiveReplyId(null);
    },
    onError: (e: any) => toast.error(e.response?.data?.message || 'Lỗi khi gửi phản hồi'),
  });

  const toggleMutation = useMutation({
    mutationFn: (id: string) => reviewService.toggleVisibility(id),
    onSuccess: (d) => {
      queryClient.invalidateQueries({ queryKey: ['admin-reviews'] });
      queryClient.invalidateQueries({ queryKey: ['review-stats'] });
      toast.success(d.message);
    },
    onError: (e: any) => toast.error(e.response?.data?.message || 'Lỗi cập nhật'),
  });

  // bulk hide
  const bulkHideMutation = useMutation({
    mutationFn: async (ids: string[]) => {
      await Promise.all(ids.map((id) => reviewService.toggleVisibility(id)));
      return ids.length;
    },
    onSuccess: (count) => {
      queryClient.invalidateQueries({ queryKey: ['admin-reviews'] });
      queryClient.invalidateQueries({ queryKey: ['review-stats'] });
      toast.success(`Đã ẩn ${count} đánh giá`);
      setSelectedIds([]);
    },
    onError: (e: any) => toast.error(e.response?.data?.message || 'Lỗi ẩn hàng loạt'),
  });

  const reviews: Review[] = reviewsData?.data || [];
  const meta = reviewsData?.meta;

  const allVisibleSelected = reviews.length > 0 && reviews.every((r) => selectedIds.includes(r.id));

  const toggleSelect = (id: string) =>
    setSelectedIds((prev) => prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]);

  const toggleSelectAll = () =>
    setSelectedIds(allVisibleSelected ? [] : reviews.map((r) => r.id));

  const resetFilters = () => {
    setSearch(''); setRating('ALL'); setRepliedStatus('ALL'); setIsHidden('ALL'); setPage(1); setSelectedIds([]);
  };

  const hasActiveFilters = search || rating !== 'ALL' || repliedStatus !== 'ALL' || isHidden !== 'ALL';

  const visiblePages = Array.from({ length: Math.min(meta?.lastPage ?? 0, 5) }, (_, i) => {
    const last = meta?.lastPage ?? 0;
    if (last <= 5) return i + 1;
    if (page <= 3) return i + 1;
    if (page >= last - 2) return last - 4 + i;
    return page - 2 + i;
  });

  return (
    <div className="space-y-6 pb-10 animate-in fade-in slide-in-from-bottom-3 duration-500">

      {/* ── Top charts row ────────────────────────────────────────────────── */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        <RatingDistributionChart
          average={stats?.average ?? 0}
          total={stats?.total ?? 0}
          distribution={stats?.ratingDistribution ?? {}}
        />
        <ResponseStatusChart
          replied={stats?.replied ?? 0}
          unreplied={stats?.unreplied ?? 0}
          hidden={stats?.hidden ?? 0}
        />
      </div>

      {/* ── Main table card ───────────────────────────────────────────────── */}
      <div className="bg-white rounded-[12px] shadow-[0_5px_15px_rgba(25,42,70,0.06)] overflow-hidden">

        {/* Card header */}
        <div className="px-6 py-5 border-b border-[#f2f7ff] flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
          <h6 className="text-[18px] font-extrabold text-[#25396f] mb-0">Danh sách đánh giá</h6>
          <div className="flex flex-col sm:flex-row items-start sm:items-center gap-3 w-full lg:w-auto">
            {/* Search */}
            <div className="relative flex-1 sm:min-w-[280px]">
              <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-[#7c8db5]" />
              <input
                type="text"
                placeholder="Tìm kiếm đánh giá..."
                className="w-full h-10 pl-10 pr-4 rounded-[5px] border border-[#dce7f1] bg-white text-sm font-semibold text-[#25396f] outline-none focus:border-primary transition-all"
                value={search}
                onChange={(e) => { setSearch(e.target.value); setPage(1); }}
              />
            </div>
            {/* Limit */}
            <select
              value={limit}
              onChange={(e) => { setLimit(Number(e.target.value) as LimitOption); setPage(1); }}
              className="h-10 px-3 rounded-[5px] border border-[#dce7f1] bg-white text-sm font-semibold text-[#25396f] outline-none focus:border-primary"
            >
              {([10, 50, 100] as LimitOption[]).map((n) => <option key={n} value={n}>{n}</option>)}
            </select>
            {/* Filter toggle */}
            <button
              type="button"
              onClick={() => setIsFilterOpen(!isFilterOpen)}
              className={cn(
                'h-10 rounded-[5px] px-4 text-sm font-extrabold inline-flex items-center gap-2 transition-colors',
                isFilterOpen || hasActiveFilters ? 'bg-primary text-white' : 'bg-[#f2f7ff] text-[#607080] hover:bg-[#e9f1ff]',
              )}
            >
              <Filter className="w-4 h-4" />
              Bộ lọc
              {hasActiveFilters && (
                <span className="min-w-5 h-5 rounded-full bg-white/20 px-1.5 text-[11px] leading-5">!</span>
              )}
            </button>
          </div>
        </div>

        {/* Filter panel */}
        {isFilterOpen && (
          <div className="mx-5 my-4 rounded-[8px] border border-[#dce7f1] bg-[#fbfcff] p-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {/* Rating */}
              <div>
                <label className="mb-2 block text-[11px] font-extrabold uppercase text-[#7c8db5]">Số sao</label>
                <select
                  value={rating}
                  onChange={(e) => { setRating(e.target.value as any); setPage(1); }}
                  className="h-10 w-full rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
                >
                  <option value="ALL">Tất cả số sao</option>
                  <option value="5">5 sao</option>
                  <option value="4">4 sao</option>
                  <option value="3">3 sao</option>
                  <option value="2">2 sao</option>
                  <option value="1">1 sao</option>
                </select>
              </div>
              {/* Reply status */}
              <div>
                <label className="mb-2 block text-[11px] font-extrabold uppercase text-[#7c8db5]">Phản hồi</label>
                <select
                  value={repliedStatus}
                  onChange={(e) => { setRepliedStatus(e.target.value as any); setPage(1); }}
                  className="h-10 w-full rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
                >
                  <option value="ALL">Tất cả</option>
                  <option value="unreplied">Chưa phản hồi</option>
                  <option value="replied">Đã phản hồi</option>
                </select>
              </div>
              {/* Visibility */}
              <div>
                <label className="mb-2 block text-[11px] font-extrabold uppercase text-[#7c8db5]">Hiển thị</label>
                <select
                  value={isHidden}
                  onChange={(e) => { setIsHidden(e.target.value as any); setPage(1); }}
                  className="h-10 w-full rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
                >
                  <option value="ALL">Tất cả</option>
                  <option value="false">Đang hiển thị</option>
                  <option value="true">Đang bị ẩn</option>
                </select>
              </div>
              {/* Reset */}
              <div className="flex items-end">
                <button
                  type="button"
                  onClick={resetFilters}
                  disabled={!hasActiveFilters}
                  className="h-10 w-full rounded-[5px] border border-[#dce7f1] bg-white text-[12px] font-extrabold text-[#607080] inline-flex items-center justify-center gap-2 hover:text-primary hover:border-primary disabled:opacity-50 disabled:pointer-events-none transition-colors"
                >
                  <RotateCcw className="w-4 h-4" />
                  Xóa bộ lọc
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Bulk action bar */}
        {selectedIds.length > 0 && (
          <div className="mx-5 mb-4 rounded-[8px] border border-primary/10 bg-primary/5 px-4 py-3 flex items-center justify-between gap-3">
            <p className="text-sm font-extrabold text-[#25396f]">Đã chọn {selectedIds.length} đánh giá</p>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => bulkHideMutation.mutate(selectedIds)}
                disabled={bulkHideMutation.isPending}
                className="h-8 rounded-[8px] px-3 text-[11px] font-extrabold text-[#946200] bg-[#fff7e6] border border-[#ffe6a6] hover:bg-[#ffeecc] transition-colors inline-flex items-center gap-1.5 disabled:opacity-60"
              >
                <EyeOff className="w-3.5 h-3.5" />
                Ẩn hàng loạt
              </button>
              <button
                type="button"
                onClick={() => setSelectedIds([])}
                className="h-8 rounded-[8px] px-3 text-[11px] font-extrabold text-[#607080] bg-white border border-[#dce7f1] hover:bg-[#f2f7ff] transition-colors"
              >
                Bỏ chọn
              </button>
            </div>
          </div>
        )}

        {/* Error */}
        {isError && (
          <div className="mx-5 my-4 rounded-[8px] border border-red-100 bg-red-50 p-4 flex gap-3 text-red-600">
            <AlertCircle className="w-5 h-5 shrink-0 mt-0.5" />
            <p className="text-sm font-semibold">Không thể tải danh sách đánh giá. Vui lòng thử lại.</p>
          </div>
        )}

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1100px]">
            <thead>
              <tr className="border-y border-[#f2f7ff] bg-[#fbfcff] text-[#7c8db5] text-[11px] font-extrabold uppercase">
                <th className="px-5 py-4 w-10">
                  <input
                    type="checkbox"
                    checked={allVisibleSelected}
                    onChange={toggleSelectAll}
                    className="h-4 w-4 rounded border-[#dce7f1] text-primary focus:ring-primary/20"
                    aria-label="Chọn tất cả"
                  />
                </th>
                <th className="px-5 py-4 w-[18%]">Sản phẩm</th>
                <th className="px-5 py-4 w-[14%]">Người đánh giá</th>
                <th className="px-5 py-4">Nội dung đánh giá</th>
                <th className="px-5 py-4 w-[90px]">Ngày</th>
                <th className="px-5 py-4 w-[90px] text-center">Ẩn</th>
                <th className="px-5 py-4 w-[110px] text-center">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#f2f7ff] text-sm">
              {isLoading ? (
                Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    {Array.from({ length: 7 }).map((_, j) => (
                      <td key={j} className="px-5 py-4">
                        <div className="h-4 rounded bg-[#f2f7ff]" />
                      </td>
                    ))}
                  </tr>
                ))
              ) : reviews.length > 0 ? (
                reviews.map((review) => {
                  const isEditingReply = activeReplyId === review.id;
                  const productImg = review.product?.thumbnailUrl
                    || review.product?.assets?.find((a) => a.isPrimary)?.url
                    || review.product?.assets?.[0]?.url;

                  return (
                    <React.Fragment key={review.id}>
                      <tr className={cn('hover:bg-[#f8faff] transition-colors', review.isHidden && 'bg-[#fff8f8] opacity-80')}>
                        {/* Checkbox */}
                        <td className="px-5 py-4">
                          <input
                            type="checkbox"
                            checked={selectedIds.includes(review.id)}
                            onChange={() => toggleSelect(review.id)}
                            className="h-4 w-4 rounded border-[#dce7f1] text-primary focus:ring-primary/20"
                          />
                        </td>

                        {/* Product */}
                        <td className="px-5 py-4">
                          <div className="flex items-center gap-2.5">
                            <div className="w-10 h-10 rounded-[8px] bg-[#f2f7ff] border border-[#dce7f1] overflow-hidden flex items-center justify-center shrink-0">
                              {productImg ? (
                                <img src={productImg} alt={review.product?.name} className="w-full h-full object-cover" />
                              ) : (
                                <ShoppingBag className="w-5 h-5 text-[#7c8db5]" />
                              )}
                            </div>
                            <div className="min-w-0">
                              <p className="text-[13px] font-extrabold text-[#25396f] truncate max-w-[140px]">
                                {review.product?.name || 'N/A'}
                              </p>
                              {review.variantName && (
                                <p className="text-[10px] font-semibold text-[#7c8db5] truncate max-w-[140px]">
                                  {review.variantName}
                                </p>
                              )}
                            </div>
                          </div>
                        </td>

                        {/* Reviewer */}
                        <td className="px-5 py-4">
                          <div className="flex items-center gap-2">
                            <div className="w-8 h-8 rounded-full bg-[#f2f7ff] border border-[#dce7f1] overflow-hidden flex items-center justify-center shrink-0">
                              {review.user?.profile?.avatarUrl ? (
                                <img src={review.user.profile.avatarUrl} alt="" className="w-full h-full object-cover" />
                              ) : (
                                <UserIcon className="w-4 h-4 text-[#7c8db5]" />
                              )}
                            </div>
                            <div className="min-w-0">
                              <p className="text-[12px] font-extrabold text-[#25396f] truncate max-w-[110px]">
                                {review.user?.profile?.fullName || 'Ẩn danh'}
                              </p>
                              <p className="text-[10px] text-[#7c8db5] truncate max-w-[110px]">
                                {review.user?.email || ''}
                              </p>
                            </div>
                          </div>
                        </td>

                        {/* Review content */}
                        <td className="px-5 py-4">
                          <div className="space-y-1.5">
                            <StarRow count={review.rating} small />
                            <p className="text-[13px] text-[#25396f] line-clamp-2 leading-snug">
                              {review.comment || (
                                <span className="italic text-[#7c8db5]">Chỉ chấm điểm, không có bình luận.</span>
                              )}
                            </p>
                            {/* Reply preview */}
                            {review.reply && !isEditingReply && (
                              <div className="flex items-start gap-1.5 bg-primary/5 rounded-[6px] px-2.5 py-1.5 mt-1">
                                <CheckCircle2 className="w-3 h-3 text-primary shrink-0 mt-0.5" />
                                <p className="text-[11px] font-semibold text-[#435ebe] line-clamp-1">{review.reply}</p>
                              </div>
                            )}
                            {/* Inline reply editor */}
                            {isEditingReply && (
                              <ReplyPanel
                                review={review}
                                onCancel={() => setActiveReplyId(null)}
                                onSubmit={(id, text) => replyMutation.mutate({ id, reply: text })}
                                isPending={replyMutation.isPending}
                              />
                            )}
                            {/* badges */}
                            <div className="flex flex-wrap gap-1 mt-1">

                              {review.isAnonymous && (
                                <span className="text-[9px] font-extrabold uppercase px-1.5 py-0.5 rounded-full bg-[#fff7e6] text-[#946200]">Ẩn danh</span>
                              )}
                              {review.isHidden && (
                                <span className="text-[9px] font-extrabold uppercase px-1.5 py-0.5 rounded-full bg-red-50 text-red-500">Bị ẩn</span>
                              )}
                            </div>
                          </div>
                        </td>

                        {/* Date */}
                        <td className="px-5 py-4">
                          <span className="text-[11px] font-semibold text-[#7c8db5] whitespace-nowrap">
                            {formatDate(review.createdAt)}
                          </span>
                        </td>

                        {/* Hide toggle */}
                        <td className="px-5 py-4 text-center">
                          <button
                            type="button"
                            onClick={() => toggleMutation.mutate(review.id)}
                            disabled={toggleMutation.isPending && toggleMutation.variables === review.id}
                            title={review.isHidden ? 'Hiện đánh giá' : 'Ẩn đánh giá'}
                            className={cn(
                              'w-8 h-8 rounded-[8px] inline-flex items-center justify-center transition-colors disabled:opacity-60',
                              review.isHidden
                                ? 'bg-[#edf9f1] text-[#2f8f5b] hover:bg-[#d6f3df]'
                                : 'bg-[#fff7e6] text-[#946200] hover:bg-[#ffeecc]',
                            )}
                          >
                            {review.isHidden ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
                          </button>
                        </td>

                        {/* Actions: reply / edit */}
                        <td className="px-5 py-4 text-center">
                          {review.reply ? (
                            <button
                              type="button"
                              onClick={() => setActiveReplyId(isEditingReply ? null : review.id)}
                              className="h-8 rounded-[8px] px-3 text-[11px] font-extrabold text-primary bg-primary/10 hover:bg-primary/20 transition-colors inline-flex items-center gap-1.5"
                            >
                              <MessageSquareText className="w-3.5 h-3.5" />
                              Sửa
                            </button>
                          ) : (
                            <button
                              type="button"
                              onClick={() => setActiveReplyId(isEditingReply ? null : review.id)}
                              className="h-8 rounded-[8px] px-3 text-[11px] font-extrabold text-[#2f8f5b] bg-[#edf9f1] hover:bg-[#d6f3df] transition-colors inline-flex items-center gap-1.5"
                            >
                              <Clock className="w-3.5 h-3.5" />
                              Phản hồi
                            </button>
                          )}
                        </td>
                      </tr>
                    </React.Fragment>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={7} className="px-6 py-20 text-center">
                    <div className="mx-auto w-14 h-14 rounded-[12px] bg-[#f2f7ff] flex items-center justify-center mb-4">
                      <MessageSquareText className="w-7 h-7 text-primary/40" />
                    </div>
                    <h6 className="text-[16px] font-extrabold text-[#25396f] mb-1">Chưa có đánh giá nào</h6>
                    <p className="text-sm font-semibold text-[#7c8db5]">Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm</p>
                    {hasActiveFilters && (
                      <button type="button" onClick={resetFilters}
                        className="mt-4 h-9 rounded-[8px] px-4 text-[12px] font-extrabold text-primary bg-primary/10 hover:bg-primary/20 inline-flex items-center gap-1.5">
                        <XCircle className="w-4 h-4" /> Xóa bộ lọc
                      </button>
                    )}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {meta && meta.lastPage > 1 && (
          <div className="px-5 py-4 border-t border-[#f2f7ff] flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <p className="text-[13px] font-semibold text-[#a8b4c7]">
              Hiển thị {(page - 1) * limit + (reviews.length > 0 ? 1 : 0)} tới {(page - 1) * limit + reviews.length} của {meta.total} đánh giá
            </p>
            {meta.lastPage > 1 && (
              <div className="flex items-center gap-1.5">
                <button
                  disabled={page === 1}
                  onClick={() => setPage(page - 1)}
                  className="w-9 h-9 rounded-[5px] border border-[#dce7f1] bg-white flex items-center justify-center text-[#607080] hover:bg-[#f2f7ff] disabled:opacity-40 disabled:cursor-not-allowed transition-all"
                >
                  <ChevronLeft className="w-4 h-4" />
                </button>
                {visiblePages.map((p) => (
                  <button
                    key={p}
                    onClick={() => setPage(p)}
                    className={cn(
                      'w-9 h-9 rounded-[5px] text-sm font-extrabold transition-all',
                      p === page ? 'bg-primary text-white shadow-sm' : 'border border-[#dce7f1] bg-white text-[#607080] hover:bg-[#f2f7ff]',
                    )}
                  >
                    {p}
                  </button>
                ))}
                <button
                  disabled={page === meta.lastPage}
                  onClick={() => setPage(page + 1)}
                  className="w-9 h-9 rounded-[5px] border border-[#dce7f1] bg-white flex items-center justify-center text-[#607080] hover:bg-[#f2f7ff] disabled:opacity-40 disabled:cursor-not-allowed transition-all"
                >
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
