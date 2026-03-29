import React, { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Users,
  Search,
  CheckCircle2,
  XCircle,
  RefreshCcw,
  Shield,
  User as UserIcon,
  Mail,
  Calendar,
  MoreVertical,
  ShieldAlert,
  ChevronLeft,
  ChevronRight
} from 'lucide-react';
import { userService } from '../../services/user.service';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Card, CardContent } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';

export const UserList: React.FC = () => {
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const queryClient = useQueryClient();

  const { data, isLoading, isError } = useQuery({
    queryKey: ['users', search, page],
    queryFn: () => userService.getAllUsers({ search, page, limit: 10 }),
  });

  const users = data?.data || [];
  const meta = data?.meta || { total: 0, lastPage: 1 };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 font-heading leading-tight">Quản lý người dùng</h1>
          <p className="text-sm font-bold text-slate-500 uppercase tracking-widest">Tổng {meta.total} tài khoản trong hệ thống</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="border-none shadow-lg shadow-slate-100 p-6 bg-white rounded-3xl group">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-2xl bg-primary/5 text-primary flex items-center justify-center group-hover:scale-110 transition-transform">
              <Users className="w-6 h-6" />
            </div>
            <div className="flex flex-col">
              <span className="text-[10px] font-black text-slate-400 uppercase">Tổng User</span>
              <span className="text-2xl font-black text-slate-900">{meta.total}</span>
            </div>
          </div>
        </Card>
        <Card className="border-none shadow-lg shadow-slate-100 p-6 bg-white rounded-3xl group">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-2xl bg-green-50 text-green-500 flex items-center justify-center group-hover:scale-110 transition-transform">
              <CheckCircle2 className="w-6 h-6" />
            </div>
            <div className="flex flex-col">
              <span className="text-[10px] font-black text-slate-400 uppercase">Hoạt động (Trang này)</span>
              <span className="text-2xl font-black text-slate-900">{users.filter((u: any) => u.isActive).length}</span>
            </div>
          </div>
        </Card>
        <Card className="border-none shadow-lg shadow-slate-100 p-6 bg-white rounded-3xl group">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-2xl bg-blue-50 text-blue-500 flex items-center justify-center group-hover:scale-110 transition-transform">
              <Shield className="w-6 h-6" />
            </div>
            <div className="flex flex-col">
              <span className="text-[10px] font-black text-slate-400 uppercase">Admin (Trang này)</span>
              <span className="text-2xl font-black text-slate-900">{users.filter((u: any) => u.role === 'ADMIN').length}</span>
            </div>
          </div>
        </Card>
        <Card className="border-none shadow-lg shadow-slate-100 p-6 bg-white rounded-3xl group">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-2xl bg-red-50 text-red-500 flex items-center justify-center group-hover:scale-110 transition-transform">
              <ShieldAlert className="w-6 h-6" />
            </div>
            <div className="flex flex-col">
              <span className="text-[10px] font-black text-slate-400 uppercase">Đã khoá (Trang này)</span>
              <span className="text-2xl font-black text-slate-900">{users.filter((u: any) => !u.isActive).length}</span>
            </div>
          </div>
        </Card>
      </div>

      <Card className="border-none shadow-xl shadow-slate-200/50 rounded-3xl">
        <CardContent className="p-4">
          <div className="flex flex-col md:flex-row gap-4 items-center">
            <div className="relative flex-1 w-full group">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-primary transition-colors" />
              <Input
                placeholder="Tìm theo Tên, Email hoặc ID..."
                className="pl-12 py-3 h-12 rounded-2xl bg-slate-50 border-none ring-0 focus:ring-4 focus:ring-primary/5 transition-all text-sm font-bold"
                value={search}
                onChange={(e) => { setSearch(e.target.value); setPage(1); }}
              />
            </div>
            <Button
              variant="outline"
              className="px-6 h-12 rounded-2xl border-slate-100 hover:border-primary transition-all"
              onClick={() => queryClient.invalidateQueries({ queryKey: ['users'] })}
            >
              <RefreshCcw className="w-5 h-5 mr-2" /> Tải lại
            </Button>
          </div>
        </CardContent>
      </Card>

      <div className="bg-white rounded-[32px] shadow-2xl shadow-slate-200/50 border border-slate-100 overflow-hidden animate-in fade-in slide-in-from-bottom-5 duration-500">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1000px]">
            <thead className="bg-slate-50/50 border-b border-slate-100">
              <tr>
                <th className="px-8 py-5 text-xs font-black text-slate-500 uppercase tracking-widest pl-10">Người dùng</th>
                <th className="px-8 py-5 text-xs font-black text-slate-500 uppercase tracking-widest">Email</th>
                <th className="px-8 py-5 text-xs font-black text-slate-500 uppercase tracking-widest">Vai trò</th>
                <th className="px-8 py-5 text-xs font-black text-slate-500 uppercase tracking-widest">Trạng thái</th>
                <th className="px-8 py-5 text-xs font-black text-slate-500 uppercase tracking-widest">Đã tham gia</th>
                <th className="px-8 py-5 text-xs font-black text-slate-500 uppercase tracking-widest text-center">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 font-body">
              {isLoading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td colSpan={6} className="px-10 py-6 bg-slate-50/20" />
                  </tr>
                ))
              ) : users.length > 0 ? (
                users.map((user: any) => (
                  <tr key={user.id} className="hover:bg-slate-50/50 transition-colors group">
                    <td className="px-8 py-5 pl-10">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 rounded-2xl bg-white border border-slate-200 overflow-hidden flex-shrink-0 flex items-center justify-center p-0.5 group-hover:scale-105 transition-transform shadow-sm">
                          {user.profile?.avatarUrl ? (
                            <img src={user.profile.avatarUrl} alt={user.profile.fullName} className="w-full h-full object-cover rounded-xl" />
                          ) : (
                            <UserIcon className="w-6 h-6 text-slate-300" />
                          )}
                        </div>
                        <div className="flex flex-col">
                          <span className="font-black text-slate-800 group-hover:text-primary transition-colors">{user.profile?.fullName || 'Nguời dùng mới'}</span>
                          <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">ID: {user.id.slice(-8).toUpperCase()}</span>
                        </div>
                      </div>
                    </td>
                    <td className="px-8 py-5">
                      <div className="flex items-center gap-2 text-slate-600">
                        <Mail className="w-4 h-4 text-slate-300" />
                        <span className="text-sm font-black">{user.email}</span>
                      </div>
                    </td>
                    <td className="px-8 py-5">
                      {user.role === 'ADMIN' ? (
                        <Badge variant="info" className="gap-1.5 h-8 px-3 rounded-full">
                          <Shield className="w-3.5 h-3.5" /> Quản trị viên
                        </Badge>
                      ) : (
                        <Badge variant="default" className="bg-slate-100 text-slate-500 border-none h-8 px-3 rounded-full">
                          Người dùng
                        </Badge>
                      )}
                    </td>
                    <td className="px-8 py-5">
                      {user.isActive ? (
                        <Badge variant="success" className="gap-1.5 h-8 px-3 rounded-full animate-in fade-in scale-95 duration-200">
                          <CheckCircle2 className="w-3.5 h-3.5" /> Đang hoạt động
                        </Badge>
                      ) : (
                        <Badge variant="danger" className="gap-1.5 h-8 px-3 rounded-full animate-in fade-in scale-95 duration-200">
                          <XCircle className="w-3.5 h-3.5" /> Bị khoá
                        </Badge>
                      )}
                    </td>
                    <td className="px-8 py-5">
                      <div className="flex items-center gap-2">
                        <Calendar className="w-3.5 h-3.5 text-slate-300" />
                        <span className="text-xs font-bold text-slate-600">{new Date(user.createdAt).toLocaleDateString('vi-VN')}</span>
                      </div>
                    </td>
                    <td className="px-8 py-5">
                      <div className="flex items-center justify-center gap-2">
                        <Button variant="ghost" className="p-2 h-10 w-10 text-slate-400 hover:text-primary hover:bg-primary/5 rounded-full border-none transition-all">
                          <EditIcon className="w-5 h-5" />
                        </Button>
                        <Button variant="ghost" className="p-2 h-10 w-10 text-slate-400 hover:text-red-500 hover:bg-red-50 rounded-full border-none transition-all">
                          <MoreVertical className="w-5 h-5" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={6} className="px-8 py-20 text-center">
                    <div className="flex flex-col items-center gap-4">
                      <div className="w-20 h-20 bg-slate-50 rounded-[32px] flex items-center justify-center text-slate-200">
                        <Users size={40} />
                      </div>
                      <p className="text-slate-800 text-lg font-black tracking-tighter">Không tìm thấy người dùng nào phù hợp.</p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {meta.lastPage > 1 && (
          <div className="px-10 py-6 border-t border-slate-100 bg-slate-50/10 flex items-center justify-between">
            <p className="text-xs font-black text-slate-400 uppercase tracking-widest">Trang {page} / {meta.lastPage}</p>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={page === 1}
                onClick={() => setPage(page - 1)}
                className="rounded-xl border-slate-200 text-xs font-black uppercase"
              >
                <ChevronLeft className="w-4 h-4 mr-1" /> Trước
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={page === meta.lastPage}
                onClick={() => setPage(page + 1)}
                className="rounded-xl border-slate-200 text-xs font-black uppercase"
              >
                Sau <ChevronRight className="w-4 h-4 ml-1" />
              </Button>
            </div>
          </div>
        )}
      </div>

      {isError && (
        <div className="p-8 bg-red-50 border-2 border-red-100 rounded-[40px] flex items-center gap-6 text-red-600 shadow-2xl shadow-red-100/50 animate-in slide-in-from-bottom-5">
          <ShieldAlert className="w-10 h-10 flex-shrink-0" />
          <div>
            <p className="text-xl font-black text-red-700">Lỗi nạp dữ liệu khách hàng</p>
            <p className="text-base font-bold opacity-80">Máy chủ hiện không phản hồi. Vui lòng thử tải lại trang.</p>
          </div>
        </div>
      )}
    </div>
  );
};

const EditIcon = ({ className }: { className?: string }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
  </svg>
);
