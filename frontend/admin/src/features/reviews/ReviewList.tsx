import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Star, MessageSquareText, Search, RefreshCcw, AlertCircle, Eye, 
  EyeOff, CheckCircle2, Clock, Sparkles, Send, 
  ArrowLeft, ArrowRight, User as UserIcon, ShoppingBag
} from 'lucide-react';
import { toast } from 'sonner';
import { reviewService } from '../../services/review.service';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Card, CardContent } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';
import { Textarea } from '../../components/ui/Textarea';
import { cn } from '../../utils/cn';
import type { Review } from '../../types';

export const ReviewList: React.FC = () => {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [rating, setRating] = useState<'ALL' | '1' | '2' | '3' | '4' | '5'>('ALL');
  const [repliedStatus, setRepliedStatus] = useState<'ALL' | 'replied' | 'unreplied'>('ALL');
  const [isHidden, setIsHidden] = useState<'ALL' | 'true' | 'false'>('ALL');

  // Quản lý soạn thảo phản hồi
  const [activeReplyId, setActiveReplyId] = useState<string | null>(null);
  const [replyText, setReplyText] = useState('');
  const [aiGeneratingId, setAiGeneratingId] = useState<string | null>(null);

  const queryClient = useQueryClient();

  // Fetch thống kê
  const { data: stats, isLoading: isStatsLoading } = useQuery({
    queryKey: ['review-stats'],
    queryFn: reviewService.getReviewStats,
  });

  // Fetch danh sách đánh giá
  const { data: reviewsData, isLoading: isReviewsLoading, isError, refetch } = useQuery({
    queryKey: ['admin-reviews', page, rating, repliedStatus, isHidden, search],
    queryFn: () => reviewService.getReviews({
      page,
      limit: 10,
      rating: rating !== 'ALL' ? parseInt(rating) : undefined,
      repliedStatus: repliedStatus !== 'ALL' ? repliedStatus as any : undefined,
      isHidden: isHidden === 'true' ? true : isHidden === 'false' ? false : undefined,
      search: search.trim() || undefined,
    }),
  });

  // Mutation trả lời đánh giá
  const replyMutation = useMutation({
    mutationFn: ({ id, reply }: { id: string; reply: string }) => reviewService.replyReview(id, reply),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-reviews'] });
      queryClient.invalidateQueries({ queryKey: ['review-stats'] });
      toast.success('Gửi phản hồi thành công!');
      setActiveReplyId(null);
      setReplyText('');
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Có lỗi xảy ra khi gửi phản hồi');
    }
  });

  // Mutation ẩn/hiện đánh giá
  const toggleVisibilityMutation = useMutation({
    mutationFn: (id: string) => reviewService.toggleVisibility(id),
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['admin-reviews'] });
      queryClient.invalidateQueries({ queryKey: ['review-stats'] });
      toast.success(data.message);
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Lỗi cập nhật hiển thị đánh giá');
    }
  });

  // Gọi Gemini AI sinh câu trả lời nháp
  const handleGenerateAiReply = async (id: string) => {
    setAiGeneratingId(id);
    try {
      const data = await reviewService.generateAiReply(id);
      setReplyText(data.replyDraft);
      toast.success('AI đã soạn thảo câu trả lời nháp thành công!');
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Không thể tạo bản nháp bằng AI');
    } finally {
      setAiGeneratingId(null);
    }
  };

  const handleStartReply = (review: Review) => {
    setActiveReplyId(review.id);
    setReplyText(review.reply || '');
  };

  const handleCancelReply = () => {
    setActiveReplyId(null);
    setReplyText('');
  };

  const handleSubmitReply = (id: string) => {
    if (!replyText.trim()) {
      toast.error('Nội dung phản hồi không được để trống');
      return;
    }
    replyMutation.mutate({ id, reply: replyText.trim() });
  };

  const renderStars = (count: number) => {
    return (
      <div className="flex gap-0.5">
        {Array.from({ length: 5 }).map((_, i) => (
          <Star
            key={i}
            size={16}
            className={cn(
              "transition-all duration-300",
              i < count ? "fill-amber-400 text-amber-400 scale-105" : "text-slate-200"
            )}
          />
        ))}
      </div>
    );
  };

  const formatDateTime = (dateStr: string) => {
    return new Date(dateStr).toLocaleString('vi-VN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const reviews = reviewsData?.data || [];
  const meta = reviewsData?.meta;

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      {/* 4 Thống kê ở trên */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {[
          { label: 'Tổng số đánh giá', value: stats?.total ?? 0, icon: MessageSquareText, color: 'slate', desc: 'Hệ thống' },
          { label: 'Rating trung bình', value: stats ? `${stats.average}/5` : '0/5', icon: Star, color: 'yellow', desc: 'Sao hài lòng' },
          { label: 'Chưa phản hồi', value: stats?.unreplied ?? 0, icon: Clock, color: 'orange', desc: 'Cần phản hồi' },
          { label: 'Đánh giá bị ẩn', value: stats?.hidden ?? 0, icon: EyeOff, color: 'red', desc: 'Nội dung ẩn' }
        ].map((stat, i) => (
          <Card key={i} className="border-none shadow-xl shadow-slate-200/40 rounded-[28px] overflow-hidden group transition-all bg-white hover:shadow-2xl hover:shadow-slate-200/60">
            <CardContent className="p-6">
              <div className="flex justify-between items-start mb-6">
                <div className={cn(
                  "w-12 h-12 rounded-2xl flex items-center justify-center transition-transform group-hover:rotate-12 duration-300 shadow-sm",
                  stat.color === 'slate' ? "bg-slate-50 text-slate-400" :
                  stat.color === 'yellow' ? "bg-amber-50 text-amber-500" :
                  stat.color === 'red' ? "bg-red-50 text-red-500" :
                  "bg-orange-50 text-orange-500"
                )}>
                  <stat.icon size={22} className={cn(stat.color === 'yellow' && "fill-amber-500/20")} />
                </div>
                <span className={cn(
                  "text-[9px] font-black px-2.5 py-1 rounded-full uppercase tracking-tighter shadow-sm",
                  stat.color === 'slate' ? "bg-slate-50 text-slate-400" :
                  stat.color === 'yellow' ? "bg-amber-50 text-amber-600" :
                  stat.color === 'red' ? "bg-red-50 text-red-500" :
                  "bg-orange-50 text-orange-600"
                )}>
                  {stat.desc}
                </span>
              </div>
              <div className="space-y-1">
                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{stat.label}</p>
                <div className="flex items-baseline gap-2">
                  <h3 className="text-2xl font-black text-slate-900 tracking-tight">{isStatsLoading ? '...' : stat.value}</h3>
                  <span className="text-[10px] font-bold text-slate-300 uppercase">Lượt</span>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Header và làm mới */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-black text-slate-900 font-heading leading-tight tracking-tight">Quản lý Đánh giá</h1>
          <p className="text-sm font-bold text-slate-400 uppercase tracking-widest">
            Hiển thị {meta?.total ?? 0} đánh giá của khách hàng
          </p>
        </div>
        <Button variant="outline" className="px-6 h-12 rounded-2xl border-slate-100 hover:border-primary transition-all bg-white" onClick={() => refetch()}>
          <RefreshCcw className={cn("w-5 h-5 mr-2", isReviewsLoading && "animate-spin")} />
          Tải lại dữ liệu
        </Button>
      </div>

      {/* Bộ lọc nâng cao */}
      <Card className="border-none shadow-xl shadow-slate-200/50 rounded-3xl overflow-hidden bg-white">
        <CardContent className="p-4">
          <div className="flex flex-col lg:flex-row gap-4 items-center">
            {/* Thanh tìm kiếm */}
            <div className="relative flex-1 w-full group">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-primary transition-colors" />
              <Input
                placeholder="Tìm theo sản phẩm, tên khách hàng, nội dung đánh giá..."
                className="pl-12 py-3 h-12 rounded-2xl bg-slate-50 border-none ring-0 focus:ring-4 focus:ring-primary/5 transition-all text-sm font-bold shadow-inner"
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setPage(1);
                }}
              />
            </div>
            
            {/* Các combobox bộ lọc */}
            <div className="flex flex-wrap gap-4 w-full lg:w-auto">
              <select
                value={rating}
                onChange={(e) => {
                  setRating(e.target.value as any);
                  setPage(1);
                }}
                className="h-12 px-4 rounded-2xl bg-slate-50 border-none focus:ring-4 focus:ring-primary/10 transition-all font-bold text-sm shadow-inner outline-none text-slate-700 min-w-[140px]"
              >
                <option value="ALL">Tất cả số sao</option>
                <option value="5">⭐⭐⭐⭐⭐ 5 Sao</option>
                <option value="4">⭐⭐⭐⭐ 4 Sao</option>
                <option value="3">⭐⭐⭐ 3 Sao</option>
                <option value="2">⭐⭐ 2 Sao</option>
                <option value="1">⭐ 1 Sao</option>
              </select>

              <select
                value={repliedStatus}
                onChange={(e) => {
                  setRepliedStatus(e.target.value as any);
                  setPage(1);
                }}
                className="h-12 px-4 rounded-2xl bg-slate-50 border-none focus:ring-4 focus:ring-primary/10 transition-all font-bold text-sm shadow-inner outline-none text-slate-700 min-w-[160px]"
              >
                <option value="ALL">Tất cả Phản hồi</option>
                <option value="unreplied">Chưa phản hồi</option>
                <option value="replied">Đã phản hồi</option>
              </select>

              <select
                value={isHidden}
                onChange={(e) => {
                  setIsHidden(e.target.value as any);
                  setPage(1);
                }}
                className="h-12 px-4 rounded-2xl bg-slate-50 border-none focus:ring-4 focus:ring-primary/10 transition-all font-bold text-sm shadow-inner outline-none text-slate-700 min-w-[150px]"
              >
                <option value="ALL">Tất cả hiển thị</option>
                <option value="false">Đang hiển thị</option>
                <option value="true">Đang bị ẩn</option>
              </select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Danh sách các Review */}
      <div className="space-y-6">
        {isReviewsLoading ? (
          Array.from({ length: 3 }).map((_, i) => (
            <Card key={i} className="border-none shadow-xl shadow-slate-200/20 rounded-[32px] overflow-hidden bg-white animate-pulse">
              <div className="p-8 h-64 bg-slate-50/30" />
            </Card>
          ))
        ) : reviews.length > 0 ? (
          reviews.map((review: Review) => {
            const isEditing = activeReplyId === review.id;
            const isGeneratingThisAi = aiGeneratingId === review.id;
            
            return (
              <Card 
                key={review.id} 
                className={cn(
                  "border-none shadow-xl rounded-[32px] overflow-hidden bg-white hover:shadow-2xl transition-all duration-300 border border-slate-100",
                  review.isHidden && "bg-slate-50/50 opacity-90"
                )}
              >
                <CardContent className="p-8">
                  {/* Dòng 1: Header - Avatar & Tên Khách + Nút Ẩn/Hiện */}
                  <div className="flex flex-col md:flex-row md:items-start justify-between gap-6 mb-6">
                    <div className="flex items-center gap-4">
                      {/* Avatar */}
                      <div className="w-12 h-12 rounded-2xl bg-primary/5 flex items-center justify-center border border-primary/10 overflow-hidden shrink-0 shadow-sm">
                        {review.user?.profile?.avatarUrl ? (
                          <img 
                            src={review.user.profile.avatarUrl} 
                            alt={review.user.profile.fullName || 'User'} 
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <UserIcon className="w-5 h-5 text-primary" />
                        )}
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-black text-slate-800 text-lg tracking-tight">
                            {review.user?.profile?.fullName || 'Khách hàng GearHub'}
                          </span>
                          {review.isVerifiedPurchase && (
                            <Badge variant="success" className="text-[8px] font-black uppercase px-2 py-0.5 rounded-full tracking-wider shadow-sm shrink-0">
                              Đã mua hàng
                            </Badge>
                          )}
                          {review.isHidden && (
                            <Badge variant="danger" className="text-[8px] font-black uppercase px-2 py-0.5 rounded-full tracking-wider shadow-sm shrink-0">
                              Đang bị ẩn
                            </Badge>
                          )}
                        </div>
                        <span className="text-xs font-bold text-slate-400 block tracking-wide">{review.user?.email}</span>
                      </div>
                    </div>

                    {/* Điều khiển hiển thị (Ẩn/Hiện) */}
                    <div className="flex items-center gap-3 self-end md:self-auto">
                      <span className="text-xs font-bold text-slate-400 uppercase tracking-widest">{formatDateTime(review.createdAt)}</span>
                      <Button
                        variant="ghost"
                        size="sm"
                        className={cn(
                          "rounded-xl border border-slate-100 font-bold text-xs uppercase px-3 py-1.5 shadow-sm transition-all",
                          review.isHidden 
                            ? "text-green-600 bg-green-50 hover:bg-green-100 hover:border-green-200" 
                            : "text-red-500 hover:text-red-600 hover:bg-red-50 hover:border-red-100"
                        )}
                        onClick={() => toggleVisibilityMutation.mutate(review.id)}
                        isLoading={toggleVisibilityMutation.isPending && toggleVisibilityMutation.variables === review.id}
                      >
                        {review.isHidden ? (
                          <>
                            <Eye className="w-3.5 h-3.5 mr-1" /> Hiện đánh giá
                          </>
                        ) : (
                          <>
                            <EyeOff className="w-3.5 h-3.5 mr-1" /> Ẩn đánh giá
                          </>
                        )}
                      </Button>
                    </div>
                  </div>

                  <hr className="border-slate-100 mb-6" />

                  {/* Dòng 2: Nội dung Đánh giá & Sản phẩm */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 mb-6">
                    {/* Cột trái (8/12): Chi tiết đánh giá */}
                    <div className="lg:col-span-8 space-y-4">
                      {/* Số sao */}
                      <div className="flex items-center gap-3">
                        {renderStars(review.rating)}
                        <span className="text-sm font-black text-slate-600">{review.rating} trên 5 sao</span>
                      </div>

                      {/* Bình luận */}
                      <p className="text-slate-700 font-medium leading-relaxed bg-slate-50/50 rounded-2xl p-4 border border-slate-100/50">
                        {review.comment || <span className="italic text-slate-400">Khách hàng chỉ chấm điểm và không để lại bình luận.</span>}
                      </p>

                      {/* Các hình ảnh đính kèm */}
                      {review.assets && review.assets.length > 0 && (
                        <div className="flex flex-wrap gap-3 pt-2">
                          {review.assets.map((asset) => (
                            <a 
                              key={asset.id} 
                              href={asset.url} 
                              target="_blank" 
                              rel="noreferrer"
                              className="relative w-20 h-20 rounded-2xl border border-slate-100 shadow-sm overflow-hidden hover:scale-105 transition-all duration-300"
                            >
                              <img 
                                src={asset.url} 
                                alt="Review attachment" 
                                className="w-full h-full object-cover"
                              />
                            </a>
                          ))}
                        </div>
                      )}
                    </div>

                    {/* Cột phải (4/12): Sản phẩm được đánh giá */}
                    <div className="lg:col-span-4 bg-slate-50/70 border border-slate-100 rounded-3xl p-5 flex items-center gap-4 hover:bg-slate-100/40 transition-colors">
                      <div className="w-16 h-16 bg-white rounded-2xl border border-slate-100 overflow-hidden shrink-0 shadow-sm flex items-center justify-center p-2">
                        {review.product?.assets && (review.product.assets.find(a => a.isPrimary)?.url || review.product.assets[0]?.url) ? (
                          <img 
                            src={review.product.assets.find(a => a.isPrimary)?.url || review.product.assets[0]?.url} 
                            alt={review.product.name} 
                            className="w-full h-full object-contain"
                          />
                        ) : (
                          <ShoppingBag className="w-8 h-8 text-slate-300" />
                        )}
                      </div>
                      <div className="min-w-0">
                        <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-0.5">Sản phẩm đánh giá</span>
                        <a 
                          href={`/products/edit/${review.product?.slug}`}
                          className="font-black text-slate-800 hover:text-primary transition-colors text-sm truncate block tracking-tight leading-snug"
                          title={review.product?.name}
                        >
                          {review.product?.name}
                        </a>
                        {review.variantName && (
                          <span className="text-xs font-bold text-slate-400 block truncate mt-1">
                            Phân loại: {review.variantName}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Dòng 3: Khối trả lời (Nếu có hoặc đang edit) */}
                  <div className="mt-6 space-y-4">
                    {isEditing ? (
                      /* KHU VỰC SOẠN THẢO PHẢN HỒI (INLINE EDITOR) */
                      <div className="space-y-4 bg-slate-50/50 border border-slate-100 rounded-[28px] p-6 animate-in slide-in-from-top-4 duration-300">
                        <div className="flex items-center justify-between gap-4">
                          <span className="text-sm font-black text-slate-800 uppercase tracking-wider flex items-center gap-1.5">
                            <MessageSquareText size={18} className="text-primary" /> Phản hồi từ cửa hàng
                          </span>
                          
                          {/* Nút bấm AI gợi ý */}
                          <Button
                            type="button"
                            variant="outline"
                            size="sm"
                            className={cn(
                              "h-10 rounded-xl px-4 text-xs font-black uppercase tracking-wider flex items-center gap-1.5 border-none shadow-sm transition-all duration-300 relative overflow-hidden",
                              "bg-gradient-to-r from-violet-600 via-indigo-600 to-primary text-white hover:opacity-95 shadow-indigo-100"
                            )}
                            onClick={() => handleGenerateAiReply(review.id)}
                            isLoading={isGeneratingThisAi}
                          >
                            <Sparkles className="w-4 h-4 animate-pulse" />
                            {isGeneratingThisAi ? 'AI đang soạn nháp...' : 'Gợi ý bằng AI ✦'}
                          </Button>
                        </div>

                        <Textarea
                          placeholder="Viết câu trả lời của bạn ở đây... AI có thể giúp bạn soạn câu trả lời chuyên nghiệp trong giây lát bằng cách nhấn nút phía trên."
                          className="rounded-2xl border-slate-200 focus:border-primary shadow-sm bg-white min-h-[120px] text-sm font-semibold text-slate-700"
                          value={replyText}
                          onChange={(e) => setReplyText(e.target.value)}
                          disabled={replyMutation.isPending || isGeneratingThisAi}
                        />

                        <div className="flex justify-end gap-3">
                          <Button 
                            variant="ghost" 
                            className="rounded-xl border border-slate-200 hover:bg-slate-100 font-bold text-xs uppercase px-4 h-10 shadow-sm"
                            onClick={handleCancelReply}
                            disabled={replyMutation.isPending || isGeneratingThisAi}
                          >
                            Hủy
                          </Button>
                          <Button 
                            variant="secondary" 
                            className="rounded-xl font-bold text-xs uppercase px-5 h-10 shadow-md shadow-primary/10"
                            onClick={() => handleSubmitReply(review.id)}
                            isLoading={replyMutation.isPending}
                            disabled={isGeneratingThisAi}
                          >
                            <Send className="w-3.5 h-3.5 mr-2" /> Gửi phản hồi
                          </Button>
                        </div>
                      </div>
                    ) : review.reply ? (
                      /* KHỐI HIỂN THỊ CÂU TRẢ LỜI ĐÃ CÓ */
                      <div className="bg-primary/5 border border-primary/10 rounded-[28px] p-6 relative group/reply hover:bg-primary/10/5 transition-colors">
                        <div className="flex justify-between items-start gap-4 mb-3">
                          <div className="flex items-center gap-2">
                            <div className="bg-primary text-white p-1 rounded-lg">
                              <CheckCircle2 size={14} />
                            </div>
                            <span className="text-xs font-black text-primary uppercase tracking-widest">Đã phản hồi từ GearHub</span>
                          </div>
                          <Button 
                            variant="ghost" 
                            size="sm"
                            className="rounded-xl border border-primary/20 hover:bg-primary/10 text-primary font-bold text-xs uppercase px-3 py-1 bg-white shadow-sm opacity-90 hover:opacity-100"
                            onClick={() => handleStartReply(review)}
                          >
                            Chỉnh sửa
                          </Button>
                        </div>
                        <p className="text-slate-700 text-sm font-semibold leading-relaxed pl-1">
                          {review.reply}
                        </p>
                      </div>
                    ) : (
                      /* NÚT THÊM PHẢN HỒI KHI CHƯA CÓ */
                      <div className="flex justify-start">
                        <Button
                          variant="secondary"
                          size="sm"
                          className="rounded-xl font-bold text-xs uppercase px-5 h-11 shadow-md shadow-primary/10 group/btn"
                          onClick={() => handleStartReply(review)}
                        >
                          <MessageSquareText className="w-4 h-4 mr-2 group-hover/btn:scale-110 transition-transform" />
                          Viết phản hồi của cửa hàng
                        </Button>
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            );
          })
        ) : (
          /* TRẠNG THÁI KHÔNG TÌM THẤY ĐÁNH GIÁ */
          <Card className="border-none shadow-xl rounded-[40px] bg-white border border-slate-100 overflow-hidden">
            <CardContent className="p-32 text-center text-slate-300 font-black uppercase tracking-widest text-xl opacity-40">
              Không tìm thấy đánh giá nào khớp bộ lọc
            </CardContent>
          </Card>
        )}
      </div>

      {/* Lỗi fetch dữ liệu */}
      {isError && (
        <div className="p-8 bg-red-50 border-2 border-red-100 rounded-[40px] flex items-center gap-6 text-red-600 shadow-2xl shadow-red-100/50">
          <AlertCircle className="w-10 h-10 shrink-0" />
          <p className="text-xl font-black uppercase">Lỗi tải danh sách đánh giá từ máy chủ</p>
        </div>
      )}

      {/* Điều khiển phân trang (Pagination) */}
      {meta && meta.lastPage > 1 && (
        <div className="flex items-center justify-between bg-white rounded-3xl shadow-xl shadow-slate-100/50 p-4 border border-slate-100/80">
          <div className="text-xs font-bold text-slate-400 uppercase tracking-wider pl-4">
            Trang {meta.page} / {meta.lastPage} ({meta.total} kết quả)
          </div>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              className="h-10 w-10 p-0 rounded-xl border-slate-200"
              onClick={() => setPage((prev) => Math.max(1, prev - 1))}
              disabled={page === 1}
            >
              <ArrowLeft className="w-4 h-4" />
            </Button>
            {Array.from({ length: meta.lastPage }).map((_, idx) => {
              const pNum = idx + 1;
              const isCurrent = page === pNum;
              return (
                <Button
                  key={idx}
                  variant={isCurrent ? 'secondary' : 'ghost'}
                  size="sm"
                  className={cn(
                    "h-10 w-10 rounded-xl font-bold",
                    !isCurrent && "hover:bg-slate-100"
                  )}
                  onClick={() => setPage(pNum)}
                >
                  {pNum}
                </Button>
              );
            })}
            <Button
              variant="outline"
              size="sm"
              className="h-10 w-10 p-0 rounded-xl border-slate-200"
              onClick={() => setPage((prev) => Math.min(meta.lastPage, prev + 1))}
              disabled={page === meta.lastPage}
            >
              <ArrowRight className="w-4 h-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
};
