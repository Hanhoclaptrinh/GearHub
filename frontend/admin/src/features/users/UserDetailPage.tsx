import React from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  Activity,
  AlertCircle,
  Calendar,
  CheckCircle2,
  ChevronLeft,
  Clock,
  CreditCard,
  ExternalLink,
  Mail,
  MapPin,
  Phone,
  Shield,
  ShoppingBag,
  UserRound,
  XCircle,
} from '../../components/ui/IconlyIcons';
import type { LucideIcon } from '../../components/ui/IconlyIcons';
import { userService } from '../../services/user.service';
import { Button } from '../../components/ui/Button';
import { cn } from '../../utils/cn';

type UserRole = 'ADMIN' | 'STAFF' | 'USER' | string;
type UserStatus = 'ACTIVE' | 'INACTIVE' | 'BANNED' | string;

type UserOrder = {
  id: string;
  orderNumber: string;
  createdAt: string;
  totalAmount: number;
  status: string;
};

type UserActivityLog = {
  id: string;
  action: string;
  createdAt: string;
  metadata?: Record<string, unknown>;
};

type UserDetail = {
  id: string;
  email: string;
  role: UserRole;
  status: UserStatus;
  createdAt: string;
  profile?: {
    fullName?: string;
    avatarUrl?: string;
    phone?: string;
    address?: string;
  };
  stats?: {
    totalSpent?: number;
    totalOrders?: number;
  };
  orders?: UserOrder[];
  activityLogs?: UserActivityLog[];
};

type StatusMeta = {
  label: string;
  Icon: LucideIcon;
  badgeClass: string;
  iconClass: string;
};

const statusMap: Record<string, StatusMeta> = {
  ACTIVE: {
    label: 'Đang hoạt động',
    Icon: CheckCircle2,
    badgeClass: 'bg-emerald-50 text-emerald-700 border-emerald-100',
    iconClass: 'text-emerald-600 bg-emerald-50',
  },
  INACTIVE: {
    label: 'Không hoạt động',
    Icon: AlertCircle,
    badgeClass: 'bg-amber-50 text-amber-700 border-amber-100',
    iconClass: 'text-amber-600 bg-amber-50',
  },
  BANNED: {
    label: 'Bị khóa',
    Icon: XCircle,
    badgeClass: 'bg-rose-50 text-rose-700 border-rose-100',
    iconClass: 'text-rose-600 bg-rose-50',
  },
};

const roleLabels: Record<string, string> = {
  ADMIN: 'Quản trị viên',
  STAFF: 'Nhân viên',
  USER: 'Khách hàng',
};

const orderStatusLabels: Record<string, string> = {
  PENDING: 'Chờ duyệt',
  CONFIRMED: 'Đã xác nhận',
  PROCESSING: 'Đang xử lý',
  SHIPPING: 'Đang giao',
  DELIVERED: 'Đã giao',
  COMPLETED: 'Hoàn tất',
  CANCELLED: 'Đã hủy',
  RETURNED: 'Hoàn trả',
  FAILED: 'Thất bại',
};

const actionLabels: Record<string, string> = {
  USER_REGISTER: 'Đăng ký tài khoản',
  USER_LOGIN: 'Đăng nhập',
  USER_LOGOUT: 'Đăng xuất',
  USER_CHANGE_PASSWORD: 'Đổi mật khẩu',
  USER_STATUS_UPDATED: 'Cập nhật trạng thái',
  USER_ROLE_UPDATED: 'Cập nhật quyền',
  PROFILE_UPDATED: 'Cập nhật hồ sơ',
  ORDER_PLACED: 'Đặt hàng',
  ORDER_CANCELLED: 'Hủy đơn hàng',
  ORDER_STATUS_UPDATED: 'Cập nhật đơn hàng',
  PAYMENT_SUCCESS: 'Thanh toán thành công',
  PAYMENT_FAILED: 'Thanh toán thất bại',
};

const formatCurrency = (value?: number) =>
  `${Number(value || 0).toLocaleString('vi-VN')}đ`;

const formatDate = (value?: string) => {
  if (!value) return 'N/A';
  return new Intl.DateTimeFormat('vi-VN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  }).format(new Date(value));
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

const getOrderStatusClass = (status: string) => {
  if (status === 'DELIVERED' || status === 'COMPLETED') return 'bg-emerald-50 text-emerald-700';
  if (status === 'CANCELLED' || status === 'FAILED' || status === 'RETURNED') return 'bg-slate-100 text-slate-600';
  if (status === 'PENDING') return 'bg-amber-50 text-amber-700';
  return 'bg-blue-50 text-blue-700';
};

const getMetadataPreview = (metadata?: Record<string, unknown>) => {
  if (!metadata || Object.keys(metadata).length === 0) return 'Không có thông tin bổ sung';
  const entries = Object.entries(metadata)
    .filter(([, value]) => value !== null && value !== undefined && value !== '')
    .slice(0, 3);

  if (entries.length === 0) return 'Không có thông tin bổ sung';
  return entries
    .map(([key, value]) => `${key}: ${typeof value === 'object' ? JSON.stringify(value) : String(value)}`)
    .join(' · ');
};

export const UserDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const { data: user, isLoading, isError } = useQuery<UserDetail>({
    queryKey: ['users', 'detail', id],
    queryFn: () => userService.getUserDetail(id!),
    enabled: !!id,
  });

  if (isLoading) {
    return (
      <div className="space-y-6 animate-pulse">
        <div className="h-16 rounded-[12px] bg-[#f2f7ff]" />
        <div className="h-40 rounded-[12px] bg-[#f2f7ff]" />
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
          <div className="h-80 rounded-[12px] bg-[#f2f7ff]" />
          <div className="lg:col-span-2 h-80 rounded-[12px] bg-[#f2f7ff]" />
        </div>
      </div>
    );
  }

  if (isError || !user) {
    return (
      <div className="rounded-[12px] border border-rose-100 bg-rose-50 p-8 text-center">
        <AlertCircle className="mx-auto mb-3 h-8 w-8 text-rose-500" />
        <h2 className="mb-1 text-lg font-extrabold text-rose-700">Không tìm thấy thông tin người dùng</h2>
        <p className="mb-5 text-sm font-semibold text-rose-500">Dữ liệu hồ sơ không khả dụng hoặc đã bị xóa.</p>
        <Button onClick={() => navigate(-1)} variant="outline" className="h-10 rounded-[8px] font-extrabold">
          <ChevronLeft className="mr-1 h-4 w-4" />
          Quay lại
        </Button>
      </div>
    );
  }

  const displayName = user.profile?.fullName || 'Người dùng mới';
  const statusMeta = statusMap[user.status] || statusMap.ACTIVE;
  const StatusIcon = statusMeta.Icon;
  const orders = user.orders || [];
  const activityLogs = user.activityLogs || [];

  const profileItems = [
    { label: 'Email', value: user.email, Icon: Mail },
    { label: 'Số điện thoại', value: user.profile?.phone || 'Chưa cập nhật', Icon: Phone },
    { label: 'Ngày tham gia', value: formatDate(user.createdAt), Icon: Calendar },
    { label: 'Địa chỉ', value: user.profile?.address || 'Chưa cập nhật', Icon: MapPin },
  ];

  const metrics = [
    {
      label: 'Tổng chi tiêu',
      value: formatCurrency(user.stats?.totalSpent),
      Icon: CreditCard,
      iconClass: 'bg-emerald-50 text-emerald-600',
    },
    {
      label: 'Tổng đơn hàng',
      value: `${user.stats?.totalOrders || 0} đơn`,
      Icon: ShoppingBag,
      iconClass: 'bg-blue-50 text-blue-600',
    },
    {
      label: 'Trạng thái',
      value: statusMeta.label,
      Icon: StatusIcon,
      iconClass: statusMeta.iconClass,
    },
  ];

  return (
    <div className="space-y-6 animate-in fade-in duration-300">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-3">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => navigate(-1)}
            className="h-10 rounded-[8px] border border-[#dce7f1] bg-white px-3 font-extrabold text-[#607080] hover:text-primary"
          >
            <ChevronLeft className="mr-1 h-4 w-4" />
            Quay lại
          </Button>
          <div>
            <h1 className="mb-0 text-2xl font-extrabold tracking-tight text-[#25396f]">Chi tiết hồ sơ</h1>
            <p className="mb-0 text-[12px] font-bold text-[#7c8db5]">ID: {user.id}</p>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => navigate(`/orders?userId=${user.id}`)}
            className="h-10 rounded-[8px] font-extrabold"
          >
            <ShoppingBag className="mr-2 h-4 w-4" />
            Đơn hàng
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => navigate(`/activity-log?userId=${user.id}`)}
            className="h-10 rounded-[8px] font-extrabold"
          >
            <Activity className="mr-2 h-4 w-4" />
            Nhật ký
          </Button>
        </div>
      </div>

      <section className="rounded-[12px] border border-[#dce7f1] bg-white p-5 shadow-[0_5px_15px_rgba(25,42,70,0.04)]">
        <div className="flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
          <div className="flex min-w-0 items-center gap-4">
            <div className="h-20 w-20 shrink-0 overflow-hidden rounded-[12px] border border-[#dce7f1] bg-[#f2f7ff]">
              {user.profile?.avatarUrl ? (
                <img src={user.profile.avatarUrl} alt={displayName} className="h-full w-full object-cover" />
              ) : (
                <div className="flex h-full w-full items-center justify-center text-primary">
                  <UserRound className="h-9 w-9" />
                </div>
              )}
            </div>

            <div className="min-w-0">
              <div className="mb-2 flex flex-wrap items-center gap-2">
                <h2 className="mb-0 truncate text-2xl font-extrabold text-[#25396f]">{displayName}</h2>
                <span
                  className={cn(
                    'inline-flex h-7 items-center rounded-full border px-3 text-[11px] font-extrabold uppercase',
                    statusMeta.badgeClass,
                  )}
                >
                  <StatusIcon className="mr-1.5 h-3.5 w-3.5" />
                  {statusMeta.label}
                </span>
              </div>
              <div className="flex flex-wrap items-center gap-2 text-sm font-semibold text-[#607080]">
                <span className="inline-flex items-center gap-1.5">
                  <Mail className="h-4 w-4 text-[#a8b4c7]" />
                  {user.email}
                </span>
                <span className="rounded-full bg-[#f2f7ff] px-2.5 py-1 text-[11px] font-extrabold text-primary">
                  {roleLabels[user.role] || user.role}
                </span>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-3 sm:grid-cols-3 lg:min-w-[440px]">
            {metrics.map((metric) => {
              const Icon = metric.Icon;
              return (
                <div key={metric.label} className="rounded-[10px] border border-[#f2f7ff] bg-[#fbfcff] p-4">
                  <div className={cn('mb-3 flex h-9 w-9 items-center justify-center rounded-[8px]', metric.iconClass)}>
                    <Icon className="h-4 w-4" />
                  </div>
                  <p className="mb-1 text-[11px] font-extrabold uppercase text-[#7c8db5]">{metric.label}</p>
                  <p className="mb-0 truncate text-[17px] font-extrabold text-[#25396f]">{metric.value}</p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      <div className="grid grid-cols-1 gap-5 xl:grid-cols-[360px_minmax(0,1fr)]">
        <section className="rounded-[12px] border border-[#dce7f1] bg-white shadow-[0_5px_15px_rgba(25,42,70,0.04)]">
          <div className="border-b border-[#f2f7ff] px-5 py-4">
            <h3 className="mb-0 flex items-center gap-2 text-[15px] font-extrabold text-[#25396f]">
              <Shield className="h-4 w-4 text-primary" />
              Thông tin cá nhân
            </h3>
          </div>

          <div className="divide-y divide-[#f2f7ff]">
            {profileItems.map((item) => {
              const Icon = item.Icon;
              return (
                <div key={item.label} className="flex gap-3 px-5 py-4">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[8px] bg-[#f2f7ff] text-primary">
                    <Icon className="h-4 w-4" />
                  </div>
                  <div className="min-w-0">
                    <p className="mb-1 text-[11px] font-extrabold uppercase text-[#7c8db5]">{item.label}</p>
                    <p className="mb-0 break-words text-sm font-bold text-[#25396f]">{item.value}</p>
                  </div>
                </div>
              );
            })}
          </div>
        </section>

        <div className="space-y-5">
          <section className="overflow-hidden rounded-[12px] border border-[#dce7f1] bg-white shadow-[0_5px_15px_rgba(25,42,70,0.04)]">
            <div className="flex flex-col gap-3 border-b border-[#f2f7ff] px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
              <h3 className="mb-0 flex items-center gap-2 text-[15px] font-extrabold text-[#25396f]">
                <Clock className="h-4 w-4 text-primary" />
                Đơn hàng gần đây
              </h3>
              <Button
                variant="ghost"
                size="sm"
                className="h-9 rounded-[8px] px-3 text-[12px] font-extrabold text-primary hover:bg-primary/5"
                onClick={() => navigate(`/orders?userId=${user.id}`)}
              >
                Xem tất cả
                <ExternalLink className="ml-1.5 h-3.5 w-3.5" />
              </Button>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full min-w-[680px] border-collapse text-left">
                <thead className="bg-[#fbfcff]">
                  <tr>
                    <th className="px-5 py-3 text-[11px] font-extrabold uppercase text-[#7c8db5]">Mã đơn</th>
                    <th className="px-5 py-3 text-[11px] font-extrabold uppercase text-[#7c8db5]">Ngày đặt</th>
                    <th className="px-5 py-3 text-[11px] font-extrabold uppercase text-[#7c8db5]">Giá trị</th>
                    <th className="px-5 py-3 text-[11px] font-extrabold uppercase text-[#7c8db5]">Trạng thái</th>
                    <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase text-[#7c8db5]">Thao tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#f2f7ff]">
                  {orders.length > 0 ? (
                    orders.map((order) => (
                      <tr key={order.id} className="transition-colors hover:bg-[#fbfcff]">
                        <td className="px-5 py-4">
                          <span className="text-sm font-extrabold text-[#25396f]">#{order.orderNumber}</span>
                        </td>
                        <td className="px-5 py-4 text-sm font-semibold text-[#607080]">{formatDate(order.createdAt)}</td>
                        <td className="px-5 py-4 text-sm font-extrabold text-[#25396f]">{formatCurrency(order.totalAmount)}</td>
                        <td className="px-5 py-4">
                          <span className={cn('inline-flex h-7 items-center rounded-full px-3 text-[11px] font-extrabold', getOrderStatusClass(order.status))}>
                            {orderStatusLabels[order.status] || order.status}
                          </span>
                        </td>
                        <td className="px-5 py-4 text-right">
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-8 w-8 rounded-[7px] p-0 text-[#7c8db5] hover:bg-primary/5 hover:text-primary"
                            onClick={() => navigate(`/orders?orderId=${order.id}`)}
                            title="Xem đơn hàng"
                          >
                            <ExternalLink className="h-4 w-4" />
                          </Button>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={5} className="px-5 py-12 text-center">
                        <ShoppingBag className="mx-auto mb-3 h-8 w-8 text-[#a8b4c7]" />
                        <p className="mb-0 text-sm font-bold text-[#7c8db5]">Người dùng này chưa có đơn hàng.</p>
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </section>

          <section className="rounded-[12px] border border-[#dce7f1] bg-white shadow-[0_5px_15px_rgba(25,42,70,0.04)]">
            <div className="flex flex-col gap-3 border-b border-[#f2f7ff] px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
              <h3 className="mb-0 flex items-center gap-2 text-[15px] font-extrabold text-[#25396f]">
                <Activity className="h-4 w-4 text-primary" />
                Nhật ký hoạt động
              </h3>
              <Button
                variant="ghost"
                size="sm"
                className="h-9 rounded-[8px] px-3 text-[12px] font-extrabold text-primary hover:bg-primary/5"
                onClick={() => navigate(`/activity-log?userId=${user.id}`)}
              >
                Xem tất cả
                <ExternalLink className="ml-1.5 h-3.5 w-3.5" />
              </Button>
            </div>

            <div className="p-5">
              {activityLogs.length > 0 ? (
                <div className="space-y-3">
                  {activityLogs.map((log) => (
                    <div key={log.id} className="rounded-[10px] border border-[#f2f7ff] bg-[#fbfcff] p-4">
                      <div className="mb-2 flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
                        <p className="mb-0 text-sm font-extrabold text-[#25396f]">
                          {actionLabels[log.action] || log.action.replace(/_/g, ' ')}
                        </p>
                        <span className="inline-flex items-center gap-1.5 text-[12px] font-bold text-[#7c8db5]">
                          <Clock className="h-3.5 w-3.5" />
                          {formatDateTime(log.createdAt)}
                        </span>
                      </div>
                      <p className="mb-0 line-clamp-2 text-[12px] font-semibold text-[#607080]">
                        {getMetadataPreview(log.metadata)}
                      </p>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="py-10 text-center">
                  <Activity className="mx-auto mb-3 h-8 w-8 text-[#a8b4c7]" />
                  <p className="mb-0 text-sm font-bold text-[#7c8db5]">Chưa có nhật ký hoạt động.</p>
                </div>
              )}
            </div>
          </section>
        </div>
      </div>
    </div>
  );
};
