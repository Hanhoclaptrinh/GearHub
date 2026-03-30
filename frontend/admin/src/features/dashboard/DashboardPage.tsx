import React from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Users,
  Package,
  ShoppingCart,
  DollarSign,
  TrendingUp,
  ArrowUpRight,
  Loader2
} from 'lucide-react';
import { dashboardService } from '../../services/dashboard.service';
import { Card, CardHeader, CardTitle, CardContent } from '../../components/ui/Card';

const StatCard = ({ title, value, icon: Icon, color, trend }: { title: string, value: string | number, icon: any, color: string, trend?: string }) => (
  <Card className="hover:border-primary/20 transition-all duration-300">
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

export const DashboardPage: React.FC = () => {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: dashboardService.getStats,
  });

  if (isLoading) {
    return (
      <div className="h-[60vh] flex flex-col items-center justify-center gap-4">
        <Loader2 className="w-12 h-12 text-primary animate-spin" />
        <p className="text-slate-500 font-bold animate-pulse">Đang tải dữ liệu tổng quan...</p>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="p-10 bg-red-50 text-red-600 rounded-3xl border border-red-100 flex items-center gap-4">
        <Package className="w-10 h-10" />
        <div>
          <h2 className="text-xl font-bold">Lỗi tải dữ liệu</h2>
          <p className="font-medium">Vui lòng kiểm tra lại kết nối với máy chủ backend.</p>
        </div>
      </div>
    );
  }

  const { stats, topProducts } = data!;

  // tong don hang
  const totalOrders = Object.values(stats.ordersByStatus || {}).reduce((sum: number, count: any) => sum + Number(count), 0);

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
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
          value={new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(stats?.totalRevenue ?? 0)}
          icon={DollarSign}
          color="bg-green-500"
          trend="+8.5%"
        />
        <StatCard
          title="Hàng sắp hết"
          value={stats?.lowStockAlert ?? 0}
          icon={Package}
          color="bg-orange-500"
        />
        <StatCard
          title="Người dùng"
          value={stats?.totalUsers ?? 0}
          icon={Users}
          color="bg-purple-500"
          trend="+24"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <Card className="lg:col-span-2">
          <CardHeader className="flex flex-row items-center justify-between">
            <div>
              <CardTitle>Top sản phẩm bán chạy</CardTitle>
              <p className="text-xs font-medium text-slate-500 mt-1">Sản phẩm có lượng tiêu thụ cao nhất</p>
            </div>
            <TrendingUp className="text-primary/50 w-6 h-6" />
          </CardHeader>
          <CardContent>
            <div className="space-y-6">
              {(topProducts || []).map((product: any, idx: number) => (
                <div key={idx} className="flex items-center gap-4 group cursor-pointer hover:bg-slate-50 p-2 rounded-xl transition-colors">
                  <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-primary/10 to-primary/5 flex items-center justify-center overflow-hidden border border-primary/10">
                    <Package className="w-6 h-6 text-primary/40" />
                  </div>
                  <div className="flex-1">
                    <h4 className="font-extrabold text-slate-800 line-clamp-1">{product.product?.name || product.name}</h4>
                    <p className="text-xs font-bold text-slate-500">{product.name}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-bold text-primary">{totalOrders ?? 0} đơn</p>
                    <p className="text-[10px] font-bold text-green-500 bg-green-50 px-2 rounded-full inline-block">Best Seller</p>
                  </div>
                </div>
              ))}
              {!topProducts?.length && <p className="text-center py-10 text-slate-400 font-medium">Chưa có dữ liệu sản phẩm bán chạy.</p>}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Phân bổ đơn hàng</CardTitle>
            <p className="text-xs font-medium text-slate-500 mt-1">Theo từng trạng thái</p>
          </CardHeader>
          <CardContent className="h-[300px] flex flex-col justify-between border-t border-slate-50">
            <div className="space-y-4 flex-1 flex flex-col justify-center">
              {Object.entries(stats?.ordersByStatus || {}).map(([status, count]: [string, any]) => (
                <div key={status} className="space-y-2">
                  <div className="flex justify-between items-center">
                    <span className="text-sm font-bold text-slate-600 capitalize">{status}</span>
                    <span className="font-bold text-slate-800">{count}</span>
                  </div>
                  <div className="w-full bg-slate-100 rounded-full h-2">
                    <div
                      className="bg-primary rounded-full h-2 transition-all"
                      style={{ width: `${totalOrders > 0 ? (count / totalOrders) * 100 : 0}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};
