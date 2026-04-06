import React from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Users,
  Package,
  ShoppingCart,
  DollarSign,
  TrendingUp,
  ArrowUpRight,
  Loader2,
  Clock,
  Shield,
  CreditCard,
  Edit,
  Trash2,
  Plus
} from 'lucide-react';
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
  Bar
} from 'recharts';
import { dashboardService } from '../../services/dashboard.service';
import { Card, CardHeader, CardTitle, CardContent } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';

const COLORS = ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#64748B'];

const STAT_COLORS: any = {
  PENDING: '#F59E0B',
  CONFIRMED: '#3B82F6',
  PROCESSING: '#8B5CF6',
  SHIPPING: '#06B6D4',
  DELIVERED: '#10B981',
  CANCELLED: '#EF4444',
  RETURNED: '#64748B',
  FAILED: '#475569',
};

const StatCard = ({ title, value, icon: Icon, color, trend }: { title: string, value: string | number, icon: any, color: string, trend?: string }) => (
  <Card className="hover:border-primary/20 transition-all duration-300 group">
    <CardContent className="pt-6 pb-6 pr-8 flex items-start justify-between">
      <div className="space-y-3">
        <p className="text-sm font-bold text-slate-500 uppercase tracking-wider">{title}</p>
        <div className="flex items-baseline gap-2">
          <h3 className="text-3xl font-extrabold text-slate-900 font-heading">{value}</h3>
          {trend && <span className="text-green-500 text-xs font-bold bg-green-50 px-2 py-0.5 rounded-full flex items-center gap-0.5">
            <ArrowUpRight className="w-3 h-3" /> {trend}
          </span>}
        </div>
      </div>
      <div className={`p-4 rounded-2xl ${color} shadow-lg shadow-current/10 group-hover:scale-110 transition-transform`}>
        <Icon className="w-6 h-6 text-white" />
      </div>
    </CardContent>
  </Card>
);

const ActivityIcon = ({ action }: { action: string }) => {
  if (action.includes('CREATED')) return <Plus className="w-4 h-4 text-green-500" />;
  if (action.includes('UPDATED')) return <Edit className="w-4 h-4 text-blue-500" />;
  if (action.includes('DELETED')) return <Trash2 className="w-4 h-4 text-red-500" />;
  if (action.includes('LOGIN')) return <Shield className="w-4 h-4 text-purple-500" />;
  if (action.includes('ORDER')) return <ShoppingCart className="w-4 h-4 text-orange-500" />;
  if (action.includes('PAYMENT')) return <CreditCard className="w-4 h-4 text-green-600" />;
  return <Clock className="w-4 h-4 text-slate-400" />;
};

export const DashboardPage: React.FC = () => {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: dashboardService.getStats,
  });

  if (isLoading) {
    return (
      <div className="h-[60vh] flex flex-col items-center justify-center gap-4">
        <Loader2 className="w-12 h-12 text-primary animate-spin" />
        <p className="text-slate-500 font-bold animate-pulse font-heading">Đang đồng bộ hóa dữ liệu real-time...</p>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="p-10 bg-red-50 text-red-600 rounded-3xl border border-red-100 flex items-center gap-4">
        <Package className="w-10 h-10" />
        <div>
          <h2 className="text-xl font-bold">Gián đoạn kết nối máy chủ</h2>
          <p className="font-medium">Vui lòng kiểm tra lại trạng thái API backend và thử lại.</p>
        </div>
      </div>
    );
  }

  const { stats, topProducts } = data!;
  const { revenueTrends = [], orderTrends = [], latestLogs = [] } = stats || {};

  const totalOrders = Object.values(stats?.ordersByStatus || {}).reduce((sum: number, count: any) => sum + Number(count), 0);

  const orderDistribution = Object.entries(stats?.ordersByStatus || {}).map(([name, value]) => ({
    name,
    value: Number(value)
  }));

  const formatCurrency = (val: number) =>
    new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
      {/* Header Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
        <StatCard
          title="Tổng đơn hàng"
          value={totalOrders}
          icon={ShoppingCart}
          color="bg-blue-500"
          trend="+12%"
        />
        <StatCard
          title="Doanh thu"
          value={formatCurrency(stats?.totalRevenue ?? 0)}
          icon={DollarSign}
          color="bg-emerald-500"
          trend="+8.5%"
        />
        <StatCard
          title="Sắp hết hàng"
          value={stats?.lowStockAlert ?? 0}
          icon={Package}
          color="bg-orange-500"
        />
        <StatCard
          title="Khách hàng"
          value={stats?.totalUsers ?? 0}
          icon={Users}
          color="bg-indigo-500"
          trend="+24"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Biểu đồ doanh thu & đơn hàng */}
        <Card className="lg:col-span-2 shadow-sm">
          <CardHeader className="flex flex-row items-center justify-between">
            <div>
              <CardTitle>Xu hướng doanh thu & Đơn hàng</CardTitle>
              <p className="text-xs font-semibold text-slate-400 mt-1 uppercase tracking-tight">Thống kê 7 ngày gần nhất</p>
            </div>
            <div className="flex items-center gap-2">
              <Badge variant="info">Doanh thu (VND)</Badge>
              <Badge>Đơn hàng</Badge>
            </div>
          </CardHeader>
          <CardContent>
            <div className="h-[350px] w-full pt-4">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={revenueTrends}>
                  <defs>
                    <linearGradient id="colorRev" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#10B981" stopOpacity={0.15} />
                      <stop offset="95%" stopColor="#10B981" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                  <XAxis
                    dataKey="date"
                    axisLine={false}
                    tickLine={false}
                    tick={{ fill: '#94a3b8', fontSize: 12, fontWeight: 600 }}
                    dy={10}
                  />
                  <YAxis
                    axisLine={false}
                    tickLine={false}
                    tick={{ fill: '#94a3b8', fontSize: 11, fontWeight: 600 }}
                    tickFormatter={(val) => `${val / 1000000}M`}
                  />
                  <Tooltip
                    contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }}
                    formatter={(val: any) => [formatCurrency(Number(val)), 'Doanh thu']}
                  />
                  <Area
                    type="monotone"
                    dataKey="value"
                    stroke="#10B981"
                    strokeWidth={3}
                    fillOpacity={1}
                    fill="url(#colorRev)"
                    animationDuration={1500}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>

            {/* Biểu đồ đơn hàng nhỏ bên dưới */}
            <div className="h-[120px] w-full mt-6 pt-4 border-t border-slate-50">
              <p className="text-[10px] font-bold text-slate-400 uppercase mb-2 tracking-widest pl-2">Số lượng đơn hàng</p>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={orderTrends}>
                  <XAxis dataKey="date" hide />
                  <Tooltip
                    cursor={{ fill: '#f8fafc' }}
                    contentStyle={{ borderRadius: '8px', border: 'none', fontSize: '12px' }}
                    formatter={(val: any) => [val, 'Đơn hàng']}
                  />
                  <Bar dataKey="count" fill="#3B82F6" radius={[4, 4, 0, 0]} barSize={20} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        {/* Order Distribution Chart */}
        <Card className="shadow-sm">
          <CardHeader>
            <CardTitle>Phân bổ đơn hàng</CardTitle>
            <p className="text-xs font-semibold text-slate-400 mt-1 uppercase tracking-tight">Theo trạng thái đơn hàng</p>
          </CardHeader>
          <CardContent>
            <div className="h-[250px] w-full">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={orderDistribution}
                    innerRadius={60}
                    outerRadius={80}
                    paddingAngle={5}
                    dataKey="value"
                    animationDuration={1000}
                  >
                    {orderDistribution.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={STAT_COLORS[entry.name as keyof typeof STAT_COLORS] || COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip
                    contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="mt-4 grid grid-cols-2 gap-2 text-xs">
              {orderDistribution.map((entry, index) => (
                <div key={entry.name} className="flex items-center gap-2">
                  <div
                    className="w-2 h-2 rounded-full"
                    style={{ backgroundColor: STAT_COLORS[entry.name as keyof typeof STAT_COLORS] || COLORS[index % COLORS.length] }}
                  />
                  <span className="font-bold text-slate-500 uppercase tracking-tight truncate">
                    {entry.name}: {entry.value}
                  </span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Top Products */}
        <Card className="shadow-sm border-none bg-slate-50/50">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <div>
              <CardTitle className="text-lg">Sản phẩm nổi bật</CardTitle>
              <p className="text-xs font-bold text-slate-400 mt-1 lowercase first-letter:uppercase">Những sản phẩm được ưa chuộng nhất</p>
            </div>
            <TrendingUp className="text-primary/40 w-6 h-6" />
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {(topProducts || []).map((product: any, idx: number) => (
                <div key={idx} className="flex items-center gap-4 bg-white p-3 rounded-2xl border border-slate-100 hover:border-primary/20 hover:shadow-md transition-all cursor-pointer group">
                  <div className="w-12 h-12 rounded-xl bg-slate-50 flex items-center justify-center border border-slate-100 group-hover:scale-105 transition-transform">
                    <Package className="w-6 h-6 text-slate-300" />
                  </div>
                  <div className="flex-1">
                    <h4 className="font-bold text-slate-800 text-sm line-clamp-1">{product.product?.name || product.name}</h4>
                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">{product.name}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-extrabold text-primary text-sm">{product.totalSold || 0} bán</p>
                    <Badge className="text-[9px] h-4 bg-primary/10 text-primary border-none">TOP {idx + 1}</Badge>
                  </div>
                </div>
              ))}
              {!topProducts?.length && <p className="text-center py-10 text-slate-400 font-medium">Chưa ghi nhận dữ liệu bán hàng.</p>}
            </div>
          </CardContent>
        </Card>

        {/* Activity Feed */}
        <Card className="shadow-sm border-none bg-indigo-50/20">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <div>
              <CardTitle className="text-lg">Hoạt động gần đây</CardTitle>
              <p className="text-xs font-bold text-slate-400 mt-1 lowercase first-letter:uppercase">Dòng thời gian các sự kiện quan trọng</p>
            </div>
            <Clock className="text-indigo-400 w-6 h-6" />
          </CardHeader>
          <CardContent>
            <div className="space-y-6 relative before:absolute before:left-[17px] before:top-2 before:bottom-2 before:w-[2px] before:bg-indigo-100">
              {(latestLogs || []).map((log: any, idx: number) => (
                <div key={idx} className="flex gap-4 relative z-10 group">
                  <div className="w-9 h-9 rounded-full bg-white border-2 border-indigo-50 flex items-center justify-center shadow-sm group-hover:scale-110 transition-transform">
                    <ActivityIcon action={log.action} />
                  </div>
                  <div className="flex-1 -mt-0.5">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="text-[11px] font-extrabold text-slate-900 line-clamp-1">
                        {log.user?.profile?.fullName || log.user?.email || 'Hệ thống'}
                      </span>
                      <span className="text-[10px] text-slate-400 font-bold bg-slate-100 px-1.5 py-0.5 rounded uppercase">
                        {new Date(log.createdAt).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                    <p className="text-xs font-medium text-slate-600 line-clamp-1 uppercase tracking-tight">
                      {log.action.replace(/_/g, ' ')}
                    </p>
                    {log.metadata?.url && (
                      <p className="text-[10px] text-slate-400 mt-1 truncate max-w-[200px] font-mono italic">
                        {log.metadata.url}
                      </p>
                    )}
                  </div>
                </div>
              ))}
              {!latestLogs?.length && <p className="text-center py-10 text-slate-400 font-medium">Hệ thống đang chờ đợi hoạt động đầu tiên...</p>}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};
