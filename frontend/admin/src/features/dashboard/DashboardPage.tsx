import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  TrendingUp,
  Loader2,
  Package,
  Star,
  ArrowRight
} from '../../components/ui/IconlyIcons';
import { Buy, Wallet, Bookmark, TwoUsers } from 'react-iconly';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
  LabelList
} from 'recharts';
import { dashboardService } from '../../services/dashboard.service';
import { authService } from '../../services/auth.service';
import { orderService } from '../../services/order.service';
import { inventoryService } from '../../services/inventory.service';
import { reviewService } from '../../services/review.service';
import { chatService } from '../../services/chat.service';
import { Card, CardHeader, CardContent } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';
import { cn } from '../../utils/cn';

const COLORS = ['#435ebe', '#56b6f7', '#4fbe87', '#f3616d', '#eaca4a', '#607080'];

const STAT_COLORS: any = {
  PENDING: '#eaca4a',
  CONFIRMED: '#435ebe',
  PROCESSING: '#56b6f7',
  SHIPPING: '#06B6D4',
  DELIVERED: '#4fbe87',
  CANCELLED: '#f3616d',
  RETURNED: '#607080',
  FAILED: '#454546',
};

const StatCard = ({ title, value, icon: Icon, bgClass }: { title: string, value: string | number, icon: any, bgClass: string }) => (
  <Card className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white transition-all duration-300 group">
    <CardContent className="py-6 px-6 flex items-center gap-4">
      <div className={cn("w-12 h-12 rounded-[10px] flex items-center justify-center transition-transform duration-300 group-hover:scale-105 shadow-xs shrink-0 text-white", bgClass)}>
        <Icon set="bold" primaryColor="white" size={24} />
      </div>
      <div className="flex-1 min-w-0">
        <h6 className="text-[15px] font-semibold text-[#7c8db5] leading-tight mb-1 truncate">{title}</h6>
        <h6 className="text-[24px] font-extrabold text-[#25396f] leading-none mb-0 font-heading truncate">{value}</h6>
      </div>
    </CardContent>
  </Card>
);

export const DashboardPage: React.FC = () => {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: dashboardService.getStats,
  });

  const { data: currentUser } = useQuery({
    queryKey: ['me'],
    queryFn: () => authService.getMe(),
    initialData: authService.getCurrentUser() || undefined,
    staleTime: Infinity,
  });

  // Query hooks for new widgets
  const { data: pendingOrdersData, isLoading: isLoadingPending } = useQuery({
    queryKey: ['dashboard-pending-orders'],
    queryFn: () => orderService.getOrders({ status: 'PENDING', limit: 5 }),
  });
  const pendingOrders = pendingOrdersData?.data || [];

  const { data: lowStockData, isLoading: isLoadingLowStock } = useQuery({
    queryKey: ['dashboard-low-stock'],
    queryFn: () => inventoryService.getInventoryList({ stockFilter: 'low_stock', limit: 5 }),
  });
  const lowStockProducts = (lowStockData?.data || []) as Array<{
    productId: string;
    productName: string;
    thumbnailUrl?: string;
    variants?: Array<{ stockStatus?: string; [key: string]: unknown }>;
  }>;

  const { data: reviewsData, isLoading: isLoadingReviews } = useQuery({
    queryKey: ['dashboard-reviews'],
    queryFn: () => reviewService.getReviews({ limit: 5 }),
  });
  const latestReviews = reviewsData?.data || [];

  const { data: chatRoomsData, isLoading: isLoadingChats } = useQuery({
    queryKey: ['dashboard-recent-chats'],
    queryFn: () => chatService.getRooms({ limit: 5 }),
  });
  const recentChats = chatRoomsData?.items || [];

  const lowStockVariants = React.useMemo(() => {
    return lowStockProducts.flatMap(p =>
      (p.variants || [])
        .filter(v => v.stockStatus !== 'IN_STOCK')
        .map(v => ({
          productId: p.productId,
          productName: p.productName,
          thumbnailUrl: p.thumbnailUrl,
          ...v
        }))
    ).slice(0, 5);
  }, [lowStockProducts]);

  if (isLoading) {
    return (
      <div className="h-[60vh] flex flex-col items-center justify-center gap-4">
        <Loader2 className="w-12 h-12 text-primary animate-spin" />
        <p className="text-slate-500 font-bold animate-pulse font-heading">Đang tải dữ liệu từ máy chủ...</p>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="p-10 bg-red-50 text-red-600 rounded-3xl border border-red-100 flex items-center gap-4">
        <Package className="w-10 h-10" />
        <div>
          <h2 className="text-xl font-bold">Máy chủ hiện không phản hồi</h2>
          <p className="font-medium">Vui lòng kiểm tra lại trạng thái kết nối và thử lại.</p>
        </div>
      </div>
    );
  }

  const { stats, topProducts } = data!;
  const { revenueTrends = [], orderTrends = [] } = stats || {};

  const totalOrders = Object.values(stats?.ordersByStatus || {}).reduce((sum: number, count: unknown) => sum + Number(count), 0);

  const orderDistribution = Object.entries(stats?.ordersByStatus || {}).map(([name, value]) => ({
    name,
    value: Number(value)
  }));

  const formatCurrency = (val: number) =>
    new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);

  const renderStars = (rating: number) => {
    return (
      <div className="flex gap-0.5">
        {Array.from({ length: 5 }).map((_, i) => (
          <Star
            key={i}
            className={cn(
              "w-3 h-3",
              i < rating ? "fill-[#eaca4a] text-[#eaca4a]" : "text-slate-200"
            )}
          />
        ))}
      </div>
    );
  };

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-700">
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">

        {/* Left Column - Main Dashboard Panels (9 columns) */}
        <div className="lg:col-span-9 space-y-8">

          {/* 4 Stat Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6">
            <StatCard
              title="Tổng đơn hàng"
              value={totalOrders}
              icon={Buy}
              bgClass="bg-[#57caeb]"
            />
            <StatCard
              title="Doanh thu"
              value={new Intl.NumberFormat('vi-VN', { notation: 'compact', maximumFractionDigits: 2 } as any).format(stats?.totalRevenue ?? 0) + '₫'}
              icon={Wallet}
              bgClass="bg-[#5ddc97]"
            />
            <StatCard
              title="Sắp hết hàng"
              value={stats?.lowStockAlert ?? 0}
              icon={Bookmark}
              bgClass="bg-[#ff7976]"
            />
            <StatCard
              title="Khách hàng"
              value={stats?.totalUsers ?? 0}
              icon={TwoUsers}
              bgClass="bg-[#9694ff]"
            />
          </div>

          {/* Revenue & Orders Trend Charts (Mazer Profile Visit Style) */}
          <div className="grid grid-cols-1 gap-6">
            <Card className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white">
              <CardHeader className="flex flex-row items-center justify-between border-none px-6 pt-6 pb-0">
                <div>
                  <h4 className="text-[18px] font-bold text-[#25396f]">Xu hướng doanh thu & Đơn hàng</h4>
                  <p className="text-[13px] font-semibold text-slate-400 mt-1 uppercase tracking-tight">Thống kê 7 ngày gần nhất</p>
                </div>
                <div className="flex items-center gap-2">
                  <Badge className="bg-[#435ebe]/10 text-[#435ebe] border-none font-bold text-[11px] px-2 py-0.5">Doanh thu (VND)</Badge>
                  <Badge className="bg-[#56b6f7]/10 text-[#56b6f7] border-none font-bold text-[11px] px-2 py-0.5">Đơn hàng</Badge>
                </div>
              </CardHeader>
              <CardContent className="px-6 pb-6 pt-4 space-y-6">
                <div className="h-[280px] w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={revenueTrends}>
                      <defs>
                        <linearGradient id="colorRev" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#435ebe" stopOpacity={0.25} />
                          <stop offset="95%" stopColor="#435ebe" stopOpacity={0} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                      <XAxis
                        dataKey="date"
                        axisLine={false}
                        tickLine={false}
                        tick={{ fill: '#7c8db5', fontSize: 12, fontWeight: 600 }}
                        dy={10}
                      />
                      <YAxis
                        axisLine={false}
                        tickLine={false}
                        tick={{ fill: '#7c8db5', fontSize: 11, fontWeight: 600 }}
                        tickFormatter={(val) => `${val / 1000000}M`}
                      />
                      <Tooltip
                        contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.05)' }}
                        formatter={(val: any) => [formatCurrency(Number(val)), 'Doanh thu']}
                      />
                      <Area
                        type="monotone"
                        dataKey="value"
                        stroke="#435ebe"
                        strokeWidth={3}
                        fillOpacity={1}
                        fill="url(#colorRev)"
                        animationDuration={1500}
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
                <div className="h-[120px] w-full pt-4 border-t border-[#f2f7ff]">
                  <p className="text-[10px] font-bold text-slate-400 uppercase mb-2 tracking-widest pl-2">Số lượng đơn hàng</p>
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={orderTrends}>
                      <XAxis dataKey="date" hide />
                      <Tooltip
                        cursor={{ fill: '#f2f7ff' }}
                        contentStyle={{ borderRadius: '8px', border: 'none', fontSize: '12px', boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.05)' }}
                        formatter={(val: any) => [val, 'Đơn hàng']}
                      />
                      <Bar dataKey="count" fill="#56b6f7" radius={[4, 4, 0, 0]} barSize={24} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Row 3: Pending Orders & Latest Reviews */}
          <div className="grid grid-cols-1 xl:grid-cols-12 gap-6">

            {/* Left: Danh sách Đơn hàng mới chờ xử lý */}
            <div className="xl:col-span-7">
              <Card className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white h-full">
                <CardHeader className="flex flex-row items-center justify-between border-none px-6 pt-6 pb-2">
                  <div>
                    <h4 className="text-[18px] font-bold text-[#25396f]">Đơn hàng mới chờ xử lý</h4>
                    <p className="text-[13px] font-semibold text-slate-400 uppercase tracking-tight">Đơn hàng cần được xác nhận</p>
                  </div>
                  <Link to="/orders?status=PENDING" className="text-primary hover:text-primary-dark text-xs font-bold flex items-center gap-1">
                    Xem tất cả
                    <ArrowRight className="w-3.5 h-3.5" />
                  </Link>
                </CardHeader>
                <CardContent className="px-6 pb-6">
                  <div className="overflow-x-auto font-body">
                    <table className="w-full text-left border-collapse">
                      <thead>
                        <tr className="border-b border-[#f2f7ff] text-slate-400 text-xs font-bold uppercase tracking-wider">
                          <th className="pb-3 font-semibold">Mã đơn</th>
                          <th className="pb-3 font-semibold">Khách hàng</th>
                          <th className="pb-3 font-semibold text-right">Tổng tiền</th>
                          <th className="pb-3 text-center font-semibold">Thao tác</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-[#f2f7ff] text-sm">
                        {isLoadingPending ? (
                          <tr>
                            <td colSpan={4} className="py-10 text-center">
                              <Loader2 className="w-6 h-6 animate-spin text-primary mx-auto" />
                            </td>
                          </tr>
                        ) : pendingOrders.length > 0 ? (
                          pendingOrders.map((order: any) => (
                            <tr key={order.id} className="hover:bg-[#f2f7ff]/30 transition-colors group">
                              <td className="py-3 font-bold text-[#25396f]">
                                #{order.orderNumber || order.id.slice(-8).toUpperCase()}
                              </td>
                              <td className="py-3">
                                <div className="min-w-0">
                                  <p className="font-bold text-[#25396f] text-[13px] leading-tight mb-0.5 truncate">{order.receiverName || order.user?.fullName || 'Khách hàng'}</p>
                                  <p className="text-[11px] font-semibold text-slate-400 leading-none mb-0">{order.receiverPhone || order.phone || ''}</p>
                                </div>
                              </td>
                              <td className="py-3 text-right font-extrabold text-[#25396f]">
                                {formatCurrency(order.totalAmount)}
                              </td>
                              <td className="py-3 text-center">
                                <Link
                                  to={`/orders?orderId=${order.id}`}
                                  className="inline-flex items-center justify-center px-3 py-1 text-xs font-bold text-primary bg-primary/10 hover:bg-primary/20 rounded-lg transition-colors"
                                >
                                  Xử lý
                                </Link>
                              </td>
                            </tr>
                          ))
                        ) : (
                          <tr>
                            <td colSpan={4} className="py-10 text-center text-[#7c8db5] font-medium">Chưa có đơn hàng nào chờ xử lý.</td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* Right: Đánh giá mới nhất */}
            <div className="xl:col-span-5">
              <Card className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white h-full">
                <CardHeader className="flex flex-row items-center justify-between border-none px-6 pt-6 pb-2">
                  <div>
                    <h4 className="text-[18px] font-bold text-[#25396f]">Đánh giá mới nhất</h4>
                    <p className="text-[13px] font-semibold text-slate-400 uppercase tracking-tight">Phản hồi từ khách mua hàng</p>
                  </div>
                  <Link to="/reviews" className="text-primary hover:text-primary-dark text-xs font-bold flex items-center gap-1">
                    Xem tất cả
                    <ArrowRight className="w-3.5 h-3.5" />
                  </Link>
                </CardHeader>
                <CardContent className="px-6 pb-6">
                  <div className="space-y-4 max-h-[320px] overflow-y-auto custom-scrollbar font-body">
                    {isLoadingReviews ? (
                      <div className="py-10 flex justify-center">
                        <Loader2 className="w-6 h-6 animate-spin text-primary" />
                      </div>
                    ) : latestReviews.length > 0 ? (
                      latestReviews.map((review: any, idx: number) => {
                        const avatar = review.user?.avatarUrl || `/assets/images/faces/${(idx % 8) + 1}.jpg`;
                        const displayName = review.isAnonymous ? "Khách ẩn danh" : (review.user?.fullName || review.user?.email || "Khách hàng");
                        return (
                          <div key={review.id} className="flex gap-3 text-xs border-b border-[#f2f7ff] pb-3 last:border-none last:pb-0">
                            <div className="w-[36px] h-[36px] rounded-full overflow-hidden shrink-0">
                              <img
                                src={avatar}
                                alt="user"
                                className="w-full h-full object-cover"
                                onError={(e) => {
                                  (e.target as HTMLImageElement).src = `/assets/images/faces/${(idx % 8) + 1}.jpg`;
                                }}
                              />
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="flex justify-between items-baseline mb-1">
                                <h5 className="font-bold text-[#25396f] text-[13px] truncate">{displayName}</h5>
                                <span className="text-[10px] text-slate-400 font-semibold shrink-0">
                                  {review.createdAt ? new Date(review.createdAt).toLocaleDateString('vi-VN') : ''}
                                </span>
                              </div>
                              <div className="flex items-center gap-1.5 mb-1.5">
                                {renderStars(review.rating)}
                                <span className="text-[10px] font-bold text-slate-400 truncate max-w-[120px]">
                                  {review.product?.name || 'Sản phẩm'}
                                </span>
                              </div>
                              <p className="text-slate-500 font-medium leading-relaxed italic line-clamp-2">
                                "{review.comment || 'Không có bình luận...'}"
                              </p>
                            </div>
                          </div>
                        );
                      })
                    ) : (
                      <p className="text-center py-6 text-[#7c8db5] font-medium text-xs">Chưa có đánh giá nào.</p>
                    )}
                  </div>
                </CardContent>
              </Card>
            </div>

          </div>

          {/* Row 4: Top Products & Low Stock Alert */}
          <div className="grid grid-cols-1 xl:grid-cols-12 gap-6">

            {/* Left: Sản phẩm bán chạy */}
            <div className="xl:col-span-7">
              <Card className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white h-full">
                <CardHeader className="flex flex-row items-center justify-between border-none px-6 pt-6 pb-2">
                  <div>
                    <h4 className="text-[18px] font-bold text-[#25396f]">Sản phẩm bán chạy</h4>
                    <p className="text-[13px] font-semibold text-slate-400 uppercase tracking-tight">Xếp hạng sản phẩm bán chạy nhất</p>
                  </div>
                  <TrendingUp className="text-[#7c8db5]/40 w-5 h-5" />
                </CardHeader>
                <CardContent className="px-6 pb-6 pt-2">
                  <div className="h-[280px] w-full">
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart
                        layout="vertical"
                        data={topProducts || []}
                        margin={{ left: 10, right: 35, top: 15, bottom: 5 }}
                      >
                        <XAxis type="number" hide />
                        <YAxis
                          type="category"
                          dataKey="name"
                          axisLine={false}
                          tickLine={false}
                          tick={{ fill: '#25396f', fontSize: 11, fontWeight: 700 }}
                          width={140}
                          tickFormatter={(v) => v && v.length > 20 ? `${v.substring(0, 18)}...` : v}
                        />
                        <Tooltip
                          cursor={{ fill: '#f2f7ff' }}
                          contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.05)' }}
                          formatter={(val: any) => [`${val} đơn vị`, 'Đã bán']}
                        />
                        <Bar dataKey="totalSold" fill="#435ebe" radius={[0, 8, 8, 0]} barSize={16}>
                          <LabelList dataKey="totalSold" position="right" fill="#25396f" style={{ fontSize: 11, fontWeight: 800 }} offset={8} />
                        </Bar>
                      </BarChart>
                    </ResponsiveContainer>
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* Right: Danh sách sản phẩm sắp hết hàng */}
            <div className="xl:col-span-5">
              <Card className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white h-full">
                <CardHeader className="flex flex-row items-center justify-between border-none px-6 pt-6 pb-2">
                  <div>
                    <h4 className="text-[18px] font-bold text-[#25396f]">Cảnh báo hết hàng</h4>
                    <p className="text-[13px] font-semibold text-slate-400 uppercase tracking-tight">Sản phẩm sắp hết hoặc hết hàng</p>
                  </div>
                  <Link to="/inventory?stockFilter=low_stock" className="text-primary hover:text-primary-dark text-xs font-bold flex items-center gap-1">
                    Xem kho
                    <ArrowRight className="w-3.5 h-3.5" />
                  </Link>
                </CardHeader>
                <CardContent className="px-6 pb-6">
                  <div className="space-y-4 max-h-[320px] overflow-y-auto custom-scrollbar font-body">
                    {isLoadingLowStock ? (
                      <div className="py-10 flex justify-center">
                        <Loader2 className="w-6 h-6 animate-spin text-primary" />
                      </div>
                    ) : lowStockVariants.length > 0 ? (
                      lowStockVariants.map((variant: any) => {
                        const isOut = variant.currentStock === 0 || variant.stockStatus === 'OUT_OF_STOCK';
                        return (
                          <div key={variant.variantId} className="flex items-center gap-3 border-b border-[#f2f7ff] pb-3 last:border-none last:pb-0">
                            <div className="w-[40px] h-[40px] rounded-[8px] bg-[#ebf3ff] flex items-center justify-center border border-[#ebf3ff]/50 overflow-hidden shrink-0">
                              {variant.thumbnailUrl || variant.imageUrl ? (
                                <img src={variant.thumbnailUrl || variant.imageUrl} alt="" className="w-full h-full object-cover" />
                              ) : (
                                <Package className="w-5 h-5 text-primary" />
                              )}
                            </div>
                            <div className="flex-1 min-w-0">
                              <p className="font-bold text-[#25396f] text-[13px] line-clamp-1 mb-0.5">{variant.productName}</p>
                              <div className="flex items-center gap-1.5">
                                <span className="font-mono text-[9px] font-black text-slate-400 bg-slate-50 px-1 rounded border border-slate-100 uppercase tracking-tighter shrink-0">
                                  {variant.sku}
                                </span>
                                <span className="text-[10px] text-slate-400 font-semibold truncate">
                                  {variant.variantName?.split(' - ')[1] || variant.variantName}
                                </span>
                              </div>
                            </div>
                            <div className="text-right shrink-0">
                              <p className={cn("text-[14px] font-extrabold", isOut ? "text-red-500" : "text-amber-500")}>
                                Tồn: {variant.currentStock}
                              </p>
                              <span className={cn(
                                "inline-flex items-center justify-center px-1.5 py-0.5 rounded text-[9px] font-bold uppercase mt-0.5",
                                isOut ? "bg-red-50 text-red-600" : "bg-amber-50 text-amber-600"
                              )}>
                                {isOut ? 'Hết hàng' : 'Sắp hết'}
                              </span>
                            </div>
                          </div>
                        );
                      })
                    ) : (
                      <p className="text-center py-6 text-[#7c8db5] font-medium text-xs">Kho hàng ở mức an toàn.</p>
                    )}
                  </div>
                </CardContent>
              </Card>
            </div>

          </div>

        </div>

        {/* Right Column - Mazer Sidebar Widgets (3 columns) */}
        <div className="lg:col-span-3 space-y-6">

          {/* Administrator Profile Card (John Duck Panel) */}
          <Card className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white transition-all duration-300">
            <CardContent className="py-4.5 px-5">
              <div className="flex items-center gap-3">
                <div className="w-[50px] h-[50px] rounded-full overflow-hidden shrink-0">
                  <img
                    src={currentUser?.avatarUrl || (currentUser as any)?.profile?.avatarUrl || "/assets/images/faces/1.jpg"}
                    alt="avatar"
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.target as HTMLImageElement).src = "/assets/images/faces/1.jpg";
                    }}
                  />
                </div>
                <div className="min-w-0">
                  <h5 className="font-bold text-[#25396f] text-[15px] leading-tight mb-0.5 truncate">
                    {currentUser?.fullName || (currentUser as any)?.profile?.fullName || 'Administrator'}
                  </h5>
                  <h6 className="text-[13px] font-semibold text-slate-400 leading-tight mb-0 truncate">
                    @{currentUser?.email?.split('@')[0] || 'admin'}
                  </h6>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Khách hàng nhắn tin gần đây */}
          <Card className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white">
            <CardHeader className="border-none px-6 pt-6 pb-2 flex flex-row items-center justify-between">
              <div>
                <h4 className="text-[18px] font-bold text-[#25396f]">Tin nhắn hỗ trợ</h4>
                <p className="text-[13px] font-semibold text-slate-400 uppercase tracking-tight">Khách nhắn gần đây</p>
              </div>
              <Link to="/chat" className="text-primary hover:text-primary-dark text-xs font-bold flex items-center gap-1">
                Xem tất cả
                <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </CardHeader>
            <CardContent className="px-0 pb-4">
              <div className="divide-y divide-[#f2f7ff] max-h-[350px] overflow-y-auto custom-scrollbar font-body">
                {isLoadingChats ? (
                  <div className="py-10 flex justify-center">
                    <Loader2 className="w-6 h-6 animate-spin text-primary" />
                  </div>
                ) : recentChats.length > 0 ? (
                  recentChats.map((room: any, idx: number) => {
                    const faceImgSrc = `/assets/images/faces/${(idx % 8) + 1}.jpg`;
                    const hasUnread = room.staffUnreadCount > 0;
                    return (
                      <Link
                        key={room.id}
                        to={`/chat`}
                        className="flex items-center gap-4 py-3 px-6 hover:bg-slate-50/50 transition-colors cursor-pointer group animate-in fade-in"
                      >
                        <div className="w-[40px] h-[40px] rounded-full overflow-hidden shrink-0 relative">
                          <img
                            src={room.customer?.avatarUrl || faceImgSrc}
                            alt="avatar"
                            className="w-full h-full object-cover"
                            onError={(e) => {
                              (e.target as HTMLImageElement).src = faceImgSrc;
                            }}
                          />
                          {hasUnread && (
                            <div className="absolute top-0 right-0 w-2.5 h-2.5 rounded-full bg-primary ring-2 ring-white animate-pulse" />
                          )}
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex justify-between items-baseline gap-1">
                            <h5 className="font-bold text-[#25396f] text-[14px] truncate mb-0.5 group-hover:text-primary transition-colors">
                              {room.customer?.fullName || room.customer?.email || 'Khách hàng'}
                            </h5>
                            <span className="text-[10px] text-[#7c8db5] font-semibold shrink-0">
                              {room.lastMessageAt ? new Date(room.lastMessageAt).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) : ''}
                            </span>
                          </div>
                          <p className={cn("text-[12px] truncate mb-0 leading-tight", hasUnread ? "font-bold text-slate-800" : "font-medium text-slate-400")}>
                            {room.lastMessageContent || 'Chưa có tin nhắn...'}
                          </p>
                        </div>
                      </Link>
                    );
                  })
                ) : (
                  <p className="text-center py-6 text-[#7c8db5] font-medium text-xs">Chưa có tin nhắn hỗ trợ nào.</p>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Visitors Profile style Order Distribution Chart */}
          <Card className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white">
            <CardHeader className="border-none px-6 pt-6 pb-0">
              <h4 className="text-[18px] font-bold text-[#25396f]">Trạng thái đơn hàng</h4>
              <p className="text-[13px] font-semibold text-slate-400 uppercase tracking-tight">Tỷ lệ phân bổ đơn hàng</p>
            </CardHeader>
            <CardContent className="px-6 pb-6 pt-4">
              <div className="h-[220px] w-full flex items-center justify-center">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={orderDistribution}
                      innerRadius={65}
                      outerRadius={80}
                      paddingAngle={3}
                      dataKey="value"
                      animationDuration={1000}
                    >
                      {orderDistribution.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={STAT_COLORS[entry.name as keyof typeof STAT_COLORS] || COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip
                      contentStyle={{ borderRadius: '12px', border: 'none' }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              </div>
              <div className="mt-4 grid grid-cols-2 gap-2 text-[12px]">
                {orderDistribution.map((entry, index) => (
                  <div key={entry.name} className="flex items-center gap-1.5 min-w-0">
                    <div
                      className="w-2.5 h-2.5 rounded-full shrink-0"
                      style={{ backgroundColor: STAT_COLORS[entry.name as keyof typeof STAT_COLORS] || COLORS[index % COLORS.length] }}
                    />
                    <span className="font-bold text-[#7c8db5] uppercase tracking-tight truncate">
                      {entry.name}: <span className="text-[#25396f] font-extrabold">{entry.value}</span>
                    </span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

        </div>

      </div>
    </div>
  );
};
