import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
    ChevronLeft,
    Mail,
    Phone,
    Calendar,
    Shield,
    CheckCircle2,
    XCircle,
    AlertCircle,
    ShoppingBag,
    CreditCard,
    Clock,
    ExternalLink,
    MapPin,
    Activity
} from 'lucide-react';
import { userService } from '../../services/user.service';
import { Button } from '../../components/ui/Button';
import { Card, CardContent } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';
import { cn } from '../../utils/cn';

export const UserDetailPage: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();

    const { data: user, isLoading, isError } = useQuery({
        queryKey: ['users', 'detail', id],
        queryFn: () => userService.getUserDetail(id!),
        enabled: !!id,
    });

    if (isLoading) {
        return (
            <div className="flex items-center justify-center min-h-[400px]">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
            </div>
        );
    }

    if (isError || !user) {
        return (
            <div className="text-center py-20">
                <p className="text-slate-500 font-bold">Không tìm thấy thông tin người dùng.</p>
                <Button onClick={() => navigate(-1)} variant="ghost" className="mt-4">
                    Quay lại
                </Button>
            </div>
        );
    }

    const getStatusBadgeInfo = (status: string) => {
        const statusMap: any = {
            ACTIVE: { label: 'Đang hoạt động', variant: 'success', icon: CheckCircle2 },
            INACTIVE: { label: 'Không hoạt động', variant: 'warning', icon: AlertCircle },
            BANNED: { label: 'Bị khoá', variant: 'danger', icon: XCircle },
        };
        return statusMap[status] || statusMap.ACTIVE;
    };

    const statusInfo = getStatusBadgeInfo(user.status);
    const StatusIcon = statusInfo.icon;

    return (
        <div className="space-y-8 animate-in fade-in duration-500">
            <div className="flex items-center gap-4">
                <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => navigate(-1)}
                    className="rounded-xl hover:bg-white shadow-sm border border-transparent hover:border-slate-100"
                >
                    <ChevronLeft className="w-5 h-5 mr-1" /> Quay lại
                </Button>
                <div>
                    <h1 className="text-2xl font-black text-slate-900 tracking-tight">Chi tiết hồ sơ</h1>
                    <p className="text-xs font-bold text-slate-400 uppercase tracking-widest">ID: {user.id}</p>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Left Column: Profile Info */}
                <div className="space-y-6">
                    <Card className="border-none shadow-2xl shadow-slate-200/50 rounded-[40px] overflow-hidden">
                        <div className="h-32 bg-gradient-to-br from-primary to-cta opacity-10" />
                        <CardContent className="px-8 pb-8 -mt-16 text-center">
                            <div className="inline-block p-1.5 bg-white rounded-[32px] shadow-xl mb-4">
                                <div className="w-28 h-28 rounded-[28px] overflow-hidden bg-slate-50 border border-slate-100 flex items-center justify-center">
                                    {user.profile?.avatarUrl ? (
                                        <img src={user.profile.avatarUrl} alt={user.profile?.fullName} className="w-full h-full object-cover" />
                                    ) : (
                                        <Shield className="w-12 h-12 text-slate-200" />
                                    )}
                                </div>
                            </div>
                            <h2 className="text-2xl font-black text-slate-900 mb-1">{user.profile?.fullName || 'Người dùng mới'}</h2>
                            <Badge
                                variant={user.role === 'ADMIN' ? 'info' : 'default'}
                                className={cn(
                                    "rounded-full px-4 h-7 font-black text-[10px] uppercase tracking-widest",
                                    user.role === 'ADMIN' ? "bg-blue-50 text-blue-600" : "bg-slate-50 text-slate-500"
                                )}
                            >
                                {user.role === 'ADMIN' ? 'Quản trị viên' : user.role === 'STAFF' ? 'Nhân viên' : 'Khách hàng'}
                            </Badge>

                            <div className="mt-8 space-y-4 text-left">
                                <div className="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl">
                                    <div className="w-10 h-10 rounded-xl bg-white flex items-center justify-center text-slate-400 shadow-sm">
                                        <Mail className="w-5 h-5" />
                                    </div>
                                    <div>
                                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Email</p>
                                        <p className="text-sm font-bold text-slate-700">{user.email}</p>
                                    </div>
                                </div>
                                <div className="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl">
                                    <div className="w-10 h-10 rounded-xl bg-white flex items-center justify-center text-slate-400 shadow-sm">
                                        <Phone className="w-5 h-5" />
                                    </div>
                                    <div>
                                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Số điện thoại</p>
                                        <p className="text-sm font-bold text-slate-700">{user.profile?.phone || 'Chưa cập nhật'}</p>
                                    </div>
                                </div>
                                <div className="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl">
                                    <div className="w-10 h-10 rounded-xl bg-white flex items-center justify-center text-slate-400 shadow-sm">
                                        <Calendar className="w-5 h-5" />
                                    </div>
                                    <div>
                                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Ngày tham gia</p>
                                        <p className="text-sm font-bold text-slate-700">{new Date(user.createdAt).toLocaleDateString('vi-VN')}</p>
                                    </div>
                                </div>
                                <div className="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl">
                                    <div className="w-10 h-10 rounded-xl bg-white flex items-center justify-center text-slate-400 shadow-sm">
                                        <StatusIcon className={cn("w-5 h-5", statusInfo.variant === 'success' ? "text-green-500" : "text-red-500")} />
                                    </div>
                                    <div>
                                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Trạng thái</p>
                                        <p className={cn("text-sm font-bold", statusInfo.variant === 'success' ? "text-green-600" : "text-red-600")}>
                                            {statusInfo.label}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </div>

                {/* Right Column: Stats & Tables */}
                <div className="lg:col-span-2 space-y-8">
                    {/* Metrics */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <Card className="border-none shadow-xl shadow-slate-200/50 rounded-3xl p-6 bg-white overflow-hidden relative group">
                            <div className="absolute top-0 right-0 w-24 h-24 bg-green-50 rounded-full -mr-12 -mt-12 transition-transform group-hover:scale-110" />
                            <div className="relative">
                                <div className="w-12 h-12 rounded-2xl bg-green-50 text-green-600 flex items-center justify-center mb-4">
                                    <CreditCard className="w-6 h-6" />
                                </div>
                                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Tổng chi tiêu</p>
                                <h3 className="text-2xl font-black text-slate-900 mt-1">
                                    {user.stats.totalSpent.toLocaleString('vi-VN')}đ
                                </h3>
                            </div>
                        </Card>
                        <Card className="border-none shadow-xl shadow-slate-200/50 rounded-3xl p-6 bg-white overflow-hidden relative group">
                            <div className="absolute top-0 right-0 w-24 h-24 bg-blue-50 rounded-full -mr-12 -mt-12 transition-transform group-hover:scale-110" />
                            <div className="relative">
                                <div className="w-12 h-12 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center mb-4">
                                    <ShoppingBag className="w-6 h-6" />
                                </div>
                                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Tổng đơn hàng</p>
                                <h3 className="text-2xl font-black text-slate-900 mt-1">
                                    {user.stats.totalOrders} <span className="text-sm font-bold text-slate-400 ml-1 uppercase">Đơn</span>
                                </h3>
                            </div>
                        </Card>
                        <Card className="border-none shadow-xl shadow-slate-200/50 rounded-3xl p-6 bg-white overflow-hidden relative group">
                            <div className="absolute top-0 right-0 w-24 h-24 bg-amber-50 rounded-full -mr-12 -mt-12 transition-transform group-hover:scale-110" />
                            <div className="relative">
                                <div className="w-12 h-12 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center mb-4">
                                    <MapPin className="w-6 h-6" />
                                </div>
                                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Địa chỉ giao hàng</p>
                                <h3 className="text-sm font-bold text-slate-900 mt-1 line-clamp-1">
                                    {user.profile?.address || 'Chưa cập nhật'}
                                </h3>
                            </div>
                        </Card>
                    </div>

                    {/* Recent Orders */}
                    <Card className="border-none shadow-2xl shadow-slate-200/50 rounded-[40px] overflow-hidden">
                        <div className="px-8 py-6 border-b border-slate-50 flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="w-10 h-10 rounded-xl bg-slate-50 flex items-center justify-center text-slate-400">
                                    <Clock className="w-5 h-5" />
                                </div>
                                <h3 className="font-black text-slate-800 uppercase tracking-tight">Đơn hàng gần đây</h3>
                            </div>
                            <Button
                                variant="ghost"
                                size="sm"
                                className="text-[10px] font-black uppercase text-primary hover:bg-primary/5 rounded-xl px-4"
                                onClick={() => navigate(`/orders?userId=${user.id}`)}
                            >
                                Xem tất cả <ExternalLink className="w-3.5 h-3.5 ml-1" />
                            </Button>
                        </div>
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead className="bg-slate-50/50">
                                    <tr>
                                        <th className="px-8 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest">Mã đơn</th>
                                        <th className="px-8 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest">Ngày đặt</th>
                                        <th className="px-8 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest">Giá trị</th>
                                        <th className="px-8 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest">Trạng thái</th>
                                        <th className="px-8 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">Thao tác</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-50">
                                    {user.orders.length > 0 ? user.orders.map((order: any) => (
                                        <tr key={order.id} className="hover:bg-slate-50/30 transition-colors">
                                            <td className="px-8 py-4">
                                                <span className="font-black text-slate-900 text-sm">#{order.orderNumber}</span>
                                            </td>
                                            <td className="px-8 py-4 text-xs font-bold text-slate-500">
                                                {new Date(order.createdAt).toLocaleDateString('vi-VN')}
                                            </td>
                                            <td className="px-8 py-4 font-black text-slate-900 text-sm">
                                                {order.totalAmount.toLocaleString('vi-VN')}đ
                                            </td>
                                            <td className="px-8 py-4">
                                                <Badge className={cn(
                                                    "rounded-full px-3 h-6 text-[10px] font-black border-none",
                                                    order.status === 'DELIVERED' ? "bg-green-50 text-green-600" :
                                                        order.status === 'CANCELLED' ? "bg-slate-100 text-slate-400" :
                                                            order.status === 'PENDING' ? "bg-amber-50 text-amber-600" :
                                                                "bg-blue-50 text-blue-600"
                                                )}>
                                                    {order.status === 'CANCELLED' ? 'Đã hủy' :
                                                        order.status === 'DELIVERED' ? 'Hoàn tất' :
                                                            order.status === 'PENDING' ? 'Chờ duyệt' : order.status}
                                                </Badge>
                                            </td>
                                            <td className="px-8 py-4 text-center">
                                                <Button variant="ghost" size="sm" className="h-8 w-8 p-0 rounded-lg hover:bg-primary/5 text-slate-400 hover:text-primary">
                                                    <ExternalLink className="w-4 h-4" />
                                                </Button>
                                            </td>
                                        </tr>
                                    )) : (
                                        <tr>
                                            <td colSpan={5} className="px-8 py-12 text-center text-slate-400 font-bold italic">
                                                Người dùng này chưa có đơn hàng nào.
                                            </td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </Card>

                    {/* Activity Logs */}
                    <Card className="border-none shadow-2xl shadow-slate-200/50 rounded-[40px] overflow-hidden">
                        <div className="px-8 py-6 border-b border-slate-50 flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="w-10 h-10 rounded-xl bg-slate-50 flex items-center justify-center text-slate-400">
                                    <Activity className="w-5 h-5" />
                                </div>
                                <h3 className="font-black text-slate-800 uppercase tracking-tight">Nhật ký hoạt động</h3>
                            </div>
                            <Button
                                variant="ghost"
                                size="sm"
                                className="text-[10px] font-black uppercase text-primary hover:bg-primary/5 rounded-xl px-4"
                                onClick={() => navigate(`/activity-log?userId=${user.id}`)}
                            >
                                Xem tất cả <ExternalLink className="w-3.5 h-3.5 ml-1" />
                            </Button>
                        </div>
                        <div className="p-8">
                            <div className="space-y-6">
                                {user.activityLogs.length > 0 ? user.activityLogs.map((log: any, idx: number) => (
                                    <div key={log.id} className="flex gap-4 relative">
                                        {idx !== user.activityLogs.length - 1 && (
                                            <div className="absolute left-[19px] top-10 bottom-0 w-[2px] bg-slate-100" />
                                        )}
                                        <div className="w-10 h-10 rounded-full bg-slate-50 border border-slate-100 flex items-center justify-center z-10 flex-shrink-0">
                                            <div className="w-2 h-2 rounded-full bg-primary shadow-[0_0_8px_rgba(var(--primary-rgb),0.5)]" />
                                        </div>
                                        <div className="flex-1 pb-4">
                                            <div className="flex items-center justify-between mb-1">
                                                <p className="text-sm font-black text-slate-800">{log.action}</p>
                                                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest flex items-center gap-1">
                                                    <Clock className="w-3 h-3" /> {new Date(log.createdAt).toLocaleString('vi-VN')}
                                                </span>
                                            </div>
                                            <div className="p-3 bg-slate-50 rounded-xl border border-slate-100">
                                                <p className="text-xs text-slate-500 font-medium">
                                                    {JSON.stringify(log.metadata) !== '{}' ? JSON.stringify(log.metadata) : 'Không có thông tin bổ sung'}
                                                </p>
                                            </div>
                                        </div>
                                    </div>
                                )) : (
                                    <p className="text-center text-slate-400 font-bold italic">Chưa có nhật ký hoạt động nào.</p>
                                )}
                            </div>
                        </div>
                    </Card>
                </div>
            </div>
        </div>
    );
};
