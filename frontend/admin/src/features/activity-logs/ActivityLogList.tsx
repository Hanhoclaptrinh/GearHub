import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  History,
  Search,
  Calendar,
  Clock,
  RefreshCcw,
  User,
  FileText,
  AlertCircle,
  Laptop,
  Globe,
  Settings,
  ShieldAlert
} from 'lucide-react';
import { activityLogService } from '../../services/activity-log.service';
import { Button } from '../../components/ui/Button';
import { Drawer } from '../../components/ui/Drawer';
import { Input } from '../../components/ui/Input';
import { Card, CardContent } from '../../components/ui/Card';

export const ActivityLogList: React.FC = () => {
  const [searchEmail, setSearchEmail] = useState('');
  const [page, setPage] = useState(1);
  const [selectedLog, setSelectedLog] = useState<any>(null);
  const [actionFilter, setActionFilter] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ['activity-logs', searchEmail, page, actionFilter, startDate, endDate],
    queryFn: () => activityLogService.getAllLogs({
      page,
      limit: 10,
      action: actionFilter || undefined,
      from: startDate ? new Date(startDate).toISOString() : undefined,
      to: endDate ? new Date(endDate).toISOString() : undefined,
      // Pass user search to filter logs
      userId: undefined, // Standard search by service will scan on DB. We can filter on email/name on client or adjust params.
    }),
  });

  const logs = data?.data || [];
  const meta = data?.meta || { total: 0, lastPage: 1 };

  // Filter logs locally by email/name if searching
  const filteredLogs = logs.filter((log: any) => {
    if (!searchEmail.trim()) return true;
    const userEmail = log.user?.email || '';
    const userFullName = log.user?.profile?.fullName || '';
    return userEmail.toLowerCase().includes(searchEmail.toLowerCase()) || 
           userFullName.toLowerCase().includes(searchEmail.toLowerCase());
  });

  const actionLabels: Record<string, string> = {
    USER_REGISTER: 'Đăng ký tài khoản',
    USER_LOGIN: 'Đăng nhập',
    USER_LOGOUT: 'Đăng xuất',
    USER_CHANGE_PASSWORD: 'Đổi mật khẩu',
    USER_FORGOT_PASSWORD: 'Yêu cầu khôi phục mật khẩu',
    USER_RESET_PASSWORD: 'Đặt lại mật khẩu',
    PROFILE_UPDATED: 'Cập nhật hồ sơ',
    USER_STATUS_UPDATED: 'Trạng thái tài khoản',
    USER_ROLE_UPDATED: 'Quyền hạn tài khoản',
    PRODUCT_VIEWED: 'Xem sản phẩm',
    PRODUCT_CREATED: 'Tạo sản phẩm',
    PRODUCT_UPDATED: 'Cập nhật sản phẩm',
    PRODUCT_DELETED: 'Xóa sản phẩm',
    PRODUCT_RESTORED: 'Khôi phục sản phẩm',
    PRODUCT_TOGGLED: 'Bật/Tắt hiển thị sản phẩm',
    VARIANT_CREATED: 'Tạo biến thể sản phẩm',
    VARIANT_UPDATED: 'Cập nhật biến thể',
    VARIANT_TOGGLED: 'Bật/Tắt biến thể',
    ASSET_UPLOADED: 'Tải lên hình ảnh/mô hình 3D',
    ASSET_DELETED: 'Xóa hình ảnh/mô hình 3D',
    ASSET_SET_PRIMARY: 'Đặt ảnh chính sản phẩm',
    BRAND_CREATED: 'Tạo thương hiệu',
    BRAND_UPDATED: 'Cập nhật thương hiệu',
    BRAND_TOGGLED: 'Bật/Tắt thương hiệu',
    BRAND_DELETED: 'Xóa thương hiệu',
    CATEGORY_CREATED: 'Tạo danh mục mới',
    CATEGORY_UPDATED: 'Cập nhật danh mục',
    CATEGORY_DELETED: 'Xóa danh mục',
    CART_ITEM_ADDED: 'Thêm sản phẩm vào giỏ',
    CART_ITEM_UPDATED: 'Cập nhật giỏ hàng',
    CART_ITEM_REMOVED: 'Xóa khỏi giỏ hàng',
    CART_CLEARED: 'Xóa sạch giỏ hàng',
    CART_SYNCED: 'Đồng bộ giỏ hàng',
    WISHLIST_ADDED: 'Thêm yêu thích',
    WISHLIST_REMOVED: 'Xóa yêu thích',
    ORDER_PLACED: 'Đặt hàng mới',
    ORDER_CANCELLED: 'Hủy đơn hàng',
    ORDER_STATUS_UPDATED: 'Cập nhật trạng thái đơn',
    ORDER_REORDERED: 'Đặt lại đơn hàng',
    PAYMENT_INITIATED: 'Khởi tạo thanh toán',
    PAYMENT_SUCCESS: 'Thanh toán thành công',
    PAYMENT_FAILED: 'Thanh toán thất bại',
  };

  const getActionBadge = (action: string) => {
    let colorClass = 'bg-slate-50 text-slate-600 border-slate-100';
    
    if (action.startsWith('USER_') || action.startsWith('PROFILE_')) {
      colorClass = 'bg-blue-50 text-blue-600 border-blue-100';
    } else if (action.startsWith('PRODUCT_') || action.startsWith('VARIANT_') || action.startsWith('ASSET_')) {
      colorClass = 'bg-indigo-50 text-indigo-600 border-indigo-100';
    } else if (action.startsWith('ORDER_') || action.startsWith('CART_')) {
      colorClass = 'bg-green-50 text-green-600 border-green-100';
    } else if (action.startsWith('PAYMENT_')) {
      colorClass = 'bg-emerald-50 text-emerald-600 border-emerald-100';
    } else if (action.startsWith('BRAND_') || action.startsWith('CATEGORY_') || action.startsWith('VOUCHER_')) {
      colorClass = 'bg-amber-50 text-amber-600 border-amber-100';
    }

    const label = actionLabels[action] || action.replace(/_/g, ' ');

    return (
      <span className={`inline-flex items-center px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest border ${colorClass}`}>
        {label}
      </span>
    );
  };

  const getRoleBadge = (role: string) => {
    switch (role) {
      case 'ADMIN':
        return <span className="text-[9px] font-black tracking-wider uppercase px-2 py-0.5 rounded bg-red-50 text-red-500 border border-red-100">Admin</span>;
      case 'STAFF':
        return <span className="text-[9px] font-black tracking-wider uppercase px-2 py-0.5 rounded bg-blue-50 text-blue-500 border border-blue-100">Staff</span>;
      default:
        return <span className="text-[9px] font-black tracking-wider uppercase px-2 py-0.5 rounded bg-slate-50 text-slate-400 border border-slate-100">User</span>;
    }
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <div className="w-10 h-10 rounded-2xl bg-primary/10 flex items-center justify-center text-primary">
              <History size={20} />
            </div>
            <h1 className="text-3xl font-black text-slate-900 tracking-tight uppercase">Nhật ký hoạt động</h1>
          </div>
          <p className="text-slate-500 font-bold flex items-center gap-2">
            Lịch sử kiểm toán và giám sát hành động của quản trị viên và nhân viên
          </p>
        </div>
      </div>

      <Card className="border-none shadow-2xl shadow-slate-200/50 bg-white/80 backdrop-blur-sm rounded-[32px] overflow-hidden">
        <CardContent className="p-6">
          <div className="space-y-4">
            <div className="flex flex-col md:flex-row gap-4 items-center">
              <div className="relative flex-1 w-full group">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-primary transition-colors" />
                <Input
                  placeholder="Tìm kiếm theo email nhân viên..."
                  className="pl-11 py-2.5 h-11 border-slate-200 focus:border-primary transition-all rounded-2xl"
                  value={searchEmail}
                  onChange={(e) => {
                    setSearchEmail(e.target.value);
                    setPage(1);
                  }}
                />
              </div>
              <Button
                variant="outline"
                className="px-6 h-11 rounded-2xl hover:bg-slate-50 border-slate-200"
                onClick={() => refetch()}
              >
                <RefreshCcw className="w-5 h-5" />
              </Button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 w-full">
              <select
                className="h-11 px-4 rounded-2xl border border-slate-200 focus:border-primary focus:outline-none transition-all text-sm bg-white font-bold text-slate-700"
                value={actionFilter}
                onChange={(e) => {
                  setActionFilter(e.target.value);
                  setPage(1);
                }}
              >
                <option value="">Tất cả hoạt động</option>
                <optgroup label="Tài khoản & Xác thực">
                  <option value="USER_LOGIN">Đăng nhập</option>
                  <option value="USER_LOGOUT">Đăng xuất</option>
                  <option value="USER_CHANGE_PASSWORD">Thay đổi mật khẩu</option>
                  <option value="USER_ROLE_UPDATED">Cập nhật quyền hạn</option>
                  <option value="USER_STATUS_UPDATED">Cập nhật trạng thái tài khoản</option>
                </optgroup>
                <optgroup label="Sản phẩm & Thương hiệu">
                  <option value="PRODUCT_CREATED">Tạo sản phẩm</option>
                  <option value="PRODUCT_UPDATED">Cập nhật sản phẩm</option>
                  <option value="PRODUCT_DELETED">Xóa sản phẩm</option>
                  <option value="PRODUCT_TOGGLED">Bật/tắt sản phẩm</option>
                  <option value="BRAND_CREATED">Tạo thương hiệu</option>
                  <option value="BRAND_UPDATED">Cập nhật thương hiệu</option>
                  <option value="CATEGORY_CREATED">Tạo danh mục</option>
                  <option value="CATEGORY_UPDATED">Cập nhật danh mục</option>
                </optgroup>
                <optgroup label="Đơn hàng & Giao dịch">
                  <option value="ORDER_STATUS_UPDATED">Cập nhật trạng thái đơn hàng</option>
                  <option value="ORDER_CANCELLED">Hủy đơn hàng</option>
                  <option value="PAYMENT_SUCCESS">Thanh toán thành công</option>
                  <option value="PAYMENT_FAILED">Thanh toán thất bại</option>
                </optgroup>
              </select>

              <div className="flex items-center gap-2">
                <span className="text-[10px] font-black uppercase text-slate-400 pl-2 shrink-0">Từ ngày</span>
                <Input
                  type="date"
                  className="h-11 px-4 rounded-2xl border border-slate-200 focus:border-primary transition-all text-sm bg-white font-bold text-slate-700"
                  value={startDate}
                  onChange={(e) => {
                    setStartDate(e.target.value);
                    setPage(1);
                  }}
                />
              </div>

              <div className="flex items-center gap-2">
                <span className="text-[10px] font-black uppercase text-slate-400 pl-2 shrink-0">Đến ngày</span>
                <Input
                  type="date"
                  className="h-11 px-4 rounded-2xl border border-slate-200 focus:border-primary transition-all text-sm bg-white font-bold text-slate-700"
                  value={endDate}
                  onChange={(e) => {
                    setEndDate(e.target.value);
                    setPage(1);
                  }}
                />
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="bg-white rounded-[32px] shadow-2xl shadow-slate-200/50 border border-slate-100 overflow-hidden text-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1000px]">
            <thead className="bg-slate-50/50 border-b border-slate-100">
              <tr>
                <th className="px-8 py-5 text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">Người thực hiện</th>
                <th className="px-8 py-5 text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">Vai trò</th>
                <th className="px-8 py-5 text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">Hành động</th>
                <th className="px-8 py-5 text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">Thiết bị / IP</th>
                <th className="px-8 py-5 text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">Thời gian</th>
                <th className="px-8 py-5 text-[10px] font-black text-slate-500 uppercase tracking-[0.2em]">Chi tiết</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td colSpan={6} className="px-8 py-8 bg-slate-50/20" />
                  </tr>
                ))
              ) : filteredLogs.length > 0 ? (
                filteredLogs.map((log: any) => (
                  <tr key={log.id} className="hover:bg-slate-50/50 transition-colors group">
                    <td className="px-8 py-6">
                      <div className="flex flex-col">
                        <span className="font-black text-slate-900">
                          {log.user?.profile?.fullName || 'Hệ thống'}
                        </span>
                        {log.user?.email && (
                          <span className="text-xs text-slate-400 font-medium mt-0.5">{log.user.email}</span>
                        )}
                      </div>
                    </td>
                    <td className="px-8 py-6">
                      {log.user?.role ? getRoleBadge(log.user.role) : <span className="text-[9px] font-black tracking-wider uppercase px-2 py-0.5 rounded bg-slate-50 text-slate-400 border border-slate-100">SYSTEM</span>}
                    </td>
                    <td className="px-8 py-6">
                      {getActionBadge(log.action)}
                    </td>
                    <td className="px-8 py-6">
                      <div className="flex flex-col gap-1">
                        <span className="font-bold text-slate-600 flex items-center gap-1">
                          <Globe size={12} className="text-slate-400" />
                          {log.metadata?.ip || 'N/A'}
                        </span>
                        {log.metadata?.userAgent && (
                          <span className="text-[10px] font-bold text-slate-400 line-clamp-1 max-w-[180px]" title={log.metadata.userAgent}>
                            {log.metadata.userAgent}
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="px-8 py-6">
                      <div className="flex flex-col">
                        <span className="text-xs font-bold text-slate-800 flex items-center gap-1.5">
                          <Calendar size={12} className="text-slate-400" />
                          {new Date(log.createdAt).toLocaleDateString('vi-VN')}
                        </span>
                        <span className="text-[10px] font-bold text-slate-400 flex items-center gap-1.5 mt-1">
                          <Clock size={12} />
                          {new Date(log.createdAt).toLocaleTimeString('vi-VN')}
                        </span>
                      </div>
                    </td>
                    <td className="px-8 py-6">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setSelectedLog(log)}
                        className="rounded-xl px-4 font-bold border-slate-200 hover:bg-slate-50"
                      >
                        Xem
                      </Button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={6} className="px-8 py-20 text-center">
                    <div className="flex flex-col items-center gap-4">
                      <div className="w-20 h-20 bg-slate-50 rounded-[32px] flex items-center justify-center text-slate-200">
                        <History size={40} />
                      </div>
                      <div>
                        <p className="text-slate-800 text-lg font-black tracking-tight">Chưa có nhật ký hoạt động nào.</p>
                        <p className="text-slate-400 font-bold text-sm">Hãy thử thay đổi tiêu chí tìm kiếm.</p>
                      </div>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {meta.lastPage > 1 && (
          <div className="px-10 py-6 border-t border-slate-100 bg-slate-50/10 flex items-center justify-between">
            <p className="text-xs font-black text-slate-400 uppercase tracking-[0.2em]">Trang {page} / {meta.lastPage}</p>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={page === 1}
                onClick={() => setPage(page - 1)}
                className="rounded-xl px-6 font-bold"
              >
                Trước
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={page === meta.lastPage}
                onClick={() => setPage(page + 1)}
                className="rounded-xl px-6 font-bold"
              >
                Sau
              </Button>
            </div>
          </div>
        )}
      </div>

      {isError && (
        <div className="p-6 bg-red-50 border border-red-100 rounded-[32px] flex items-center gap-4 text-red-600 shadow-xl shadow-red-100/50">
          <AlertCircle className="w-6 h-6 flex-shrink-0" />
          <p className="text-sm font-black uppercase tracking-tight">Lỗi nạp nhật ký kiểm toán. Vui lòng kiểm tra lại server.</p>
        </div>
      )}

      {/* Log Detail Drawer */}
      <Drawer
        isOpen={!!selectedLog}
        onClose={() => setSelectedLog(null)}
        title="Chi tiết hoạt động"
      >
        {selectedLog && (
          <div className="space-y-8 animate-in slide-in-from-right duration-500">
            {/* Header info */}
            <div className="p-6 rounded-[24px] bg-primary/5 border border-primary/10 space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-[10px] font-black uppercase text-primary tracking-widest">Loại hoạt động</span>
                {selectedLog.user?.role ? getRoleBadge(selectedLog.user.role) : getRoleBadge('SYSTEM')}
              </div>
              <div className="text-2xl font-black text-slate-900 tracking-tight leading-snug">
                {selectedLog.action.replace(/_/g, ' ')}
              </div>
            </div>

            <div className="grid grid-cols-1 gap-6">
              {/* User Details */}
              <div className="space-y-4">
                <h4 className="flex items-center gap-2 text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] mb-2">
                  <User size={14} className="text-slate-300" /> Tài khoản thực hiện
                </h4>
                <div className="bg-slate-50/50 p-5 rounded-3xl border border-slate-100 space-y-3">
                  <div className="flex justify-between">
                    <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Họ & Tên</span>
                    <span className="font-bold text-slate-900">{selectedLog.user?.profile?.fullName || 'Hệ thống'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Email</span>
                    <span className="font-bold text-slate-800 underline underline-offset-4 decoration-primary/20">{selectedLog.user?.email || 'N/A'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Thời điểm</span>
                    <span className="font-bold text-slate-900">{new Date(selectedLog.createdAt).toLocaleString('vi-VN')}</span>
                  </div>
                </div>
              </div>

              {/* Environment Details */}
              <div className="space-y-4">
                <h4 className="flex items-center gap-2 text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] mb-2">
                  <Laptop size={14} className="text-slate-300" /> Môi trường thực hiện
                </h4>
                <div className="bg-slate-50/50 p-5 rounded-3xl border border-slate-100 space-y-3">
                  <div className="flex justify-between">
                    <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Địa chỉ IP</span>
                    <span className="font-mono text-xs font-bold text-slate-950 bg-white px-2 py-0.5 border border-slate-100 rounded">{selectedLog.metadata?.ip || 'N/A'}</span>
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Trình duyệt / User Agent</span>
                    <p className="text-xs font-bold text-slate-700 bg-white p-3 border border-slate-100 rounded-xl leading-relaxed break-words">{selectedLog.metadata?.userAgent || 'N/A'}</p>
                  </div>
                </div>
              </div>

              {/* Action Metadata Payload JSON */}
              <div className="space-y-4">
                <h4 className="flex items-center gap-2 text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] mb-2">
                  <Settings size={14} className="text-slate-300" /> Tham số & Dữ liệu chỉnh sửa (Metadata)
                </h4>
                <div className="bg-slate-950 text-emerald-400 p-5 rounded-3xl border border-slate-900 font-mono text-xs overflow-auto max-h-[300px] leading-relaxed shadow-lg">
                  <pre>{JSON.stringify(selectedLog.metadata || {}, null, 2)}</pre>
                </div>
              </div>
            </div>

            <div className="pt-6 pb-2">
              <Button
                variant="outline"
                className="w-full h-12 rounded-2xl font-black uppercase tracking-[0.2em] text-xs border-slate-200 hover:bg-slate-50 hover:text-slate-900 transition-all shadow-sm"
                onClick={() => setSelectedLog(null)}
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

export default ActivityLogList;
