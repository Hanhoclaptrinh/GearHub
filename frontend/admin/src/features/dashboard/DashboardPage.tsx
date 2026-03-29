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

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
        <StatCard 
          title="Tổng đơn hàng" 
          value={stats.totalOrders ?? 0} 
          icon={ShoppingCart} 
          color="bg-blue-500" 
          trend="+12%" 
        />
        <StatCard 
          title="Doanh thu" 
          value={new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(stats.totalRevenue ?? 0)} 
          icon={DollarSign} 
          color="bg-green-500" 
          trend="+8.5%" 
        />
        <StatCard 
          title="Sản phẩm" 
          value={stats.totalProducts ?? 0} 
          icon={Package} 
          color="bg-orange-500" 
        />
        <StatCard 
          title="Người dùng" 
          value={stats.totalUsers ?? 0} 
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
              <p className="text-xs font-medium text-slate-500 mt-1">Sản phẩm có lượng tiêu thụ cao nhất trong tháng này</p>
            </div>
            <TrendingUp className="text-primary/50 w-6 h-6" />
          </CardHeader>
          <CardContent>
            <div className="space-y-6">
               {(topProducts || []).map((product: any, idx: number) => (
                 <div key={idx} className="flex items-center gap-4 group cursor-pointer hover:bg-slate-50 p-2 rounded-xl transition-colors">
                    <div className="w-12 h-12 rounded-xl bg-slate-100 flex items-center justify-center overflow-hidden border border-slate-200">
                        {product.assets?.[0]?.url ? (
                          <img src={product.assets[0].url} alt={product.name} className="w-full h-full object-cover group-hover:scale-110 transition-transform" />
                        ) : (
                          <Package className="w-6 h-6 text-slate-400" />
                        )}
                    </div>
                    <div className="flex-1">
                      <h4 className="font-extrabold text-slate-800 line-clamp-1">{product.name}</h4>
                      <p className="text-xs font-bold text-slate-500">{product.brand?.name} · {product._count?.items ?? 0} đơn</p>
                    </div>
                    <div className="text-right">
                       <p className="font-bold text-primary">{new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(product.minPrice ?? 0)}</p>
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
             <CardTitle>Dòng tiền doanh thu</CardTitle>
             <p className="text-xs font-medium text-slate-500 mt-1">Phân bổ nguồn thu gần đây</p>
          </CardHeader>
          <CardContent className="h-[300px] flex items-center justify-center border-t border-slate-50">
             <div className="text-center space-y-4">
                <div className="w-32 h-32 border-[12px] border-primary border-t-cta rounded-full mx-auto relative flex items-center justify-center shadow-lg shadow-primary/20">
                    <span className="text-lg font-black text-slate-800">85%</span>
                </div>
                <div>
                   <p className="text-sm font-bold text-slate-700">Hiệu suất mục tiêu</p>
                   <p className="text-xs font-medium text-slate-400">Tăng 15% so với tháng trước</p>
                </div>
             </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};
