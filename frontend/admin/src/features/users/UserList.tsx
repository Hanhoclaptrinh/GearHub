import React, { useState, useMemo, useEffect } from 'react';
import { useQuery, useQueryClient, useMutation } from '@tanstack/react-query';
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
  ChevronLeft,
  ChevronRight,
  AlertCircle,
  AlertTriangle,
  Plus,
  Filter,
  Eye
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { userService } from '../../services/user.service';
import { authService } from '../../services/auth.service';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Card, CardContent } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';
import { UserEditModal } from '../../components/ui/UserEditModal';
import { UserCreateModal } from '../../components/ui/UserCreateModal';
import { cn } from '../../utils/cn';
import { toast } from 'sonner';

interface UserListProps {
  initialRole?: string;
}

export const UserList: React.FC<UserListProps> = ({ initialRole = 'all' }) => {
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<string>('all');
  const [role, setRole] = useState<string>(initialRole);
  const [page, setPage] = useState(1);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const queryClient = useQueryClient();
  const navigate = useNavigate();

  const currentUser = useMemo(() => authService.getCurrentUser(), []);

  // Dong bo state role khi initialRole thay doi (chuyen tab)
  useEffect(() => {
    setRole(initialRole);
    setPage(1);
  }, [initialRole]);

  const { data: userStats } = useQuery({
    queryKey: ['users', 'stats'],
    queryFn: userService.getUserStats,
  });

  const { data, isLoading, isError } = useQuery({
    queryKey: ['users', search, page, status, role],
    queryFn: () => userService.getAllUsers({
      search,
      page,
      limit: 10,
      status: status !== 'all' ? status : undefined,
      role: role !== 'all' ? role : undefined
    }),
  });

  const updateStatusMutation = useMutation({
    mutationFn: ({ userId, status }: any) => userService.updateUserStatus(userId, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      setIsEditModalOpen(false);
      setSelectedUser(null);
    },
  });

  const updateRoleMutation = useMutation({
    mutationFn: ({ userId, role }: any) => userService.updateUserRole(userId, role),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      toast.success('Cập nhật quyền thành công');
      setIsEditModalOpen(false);
      setSelectedUser(null);
    },
  });

  const createUserMutation = useMutation({
    mutationFn: (userData: any) => userService.createUser(userData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      queryClient.invalidateQueries({ queryKey: ['users', 'stats'] });
      toast.success('Tạo tài khoản thành công');
      setIsCreateModalOpen(false);
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Không thể tạo tài khoản');
    }
  });

  const users = data?.data || [];
  const meta = data?.meta || { total: 0, lastPage: 1 };

  const handleEditClick = (user: any) => {
    setSelectedUser(user);
    setIsEditModalOpen(true);
  };

  const handleSaveUserChanges = async (formData: any) => {
    try {
      // cap nhat trang thai tai khoan
      if (formData.status !== selectedUser.status) {
        await updateStatusMutation.mutateAsync({
          userId: selectedUser.id,
          status: formData.status,
        });
      }

      // cap nhat quyen
      if (formData.role !== selectedUser.role) {
        await updateRoleMutation.mutateAsync({
          userId: selectedUser.id,
          role: formData.role,
        });
      }
    } catch (error) {
      console.error('Error updating user:', error);
    }
  };

  const getStatusBadgeInfo = (status: string) => {
    const statusMap: any = {
      ACTIVE: {
        label: 'Đang hoạt động',
        variant: 'success',
        icon: CheckCircle2,
      },
      INACTIVE: {
        label: 'Không hoạt động',
        variant: 'warning',
        icon: AlertCircle,
      },
      BANNED: {
        label: 'Bị khoá',
        variant: 'danger',
        icon: XCircle,
      },
    };
    return statusMap[status] || statusMap.ACTIVE;
  };

  const getRoleBadgeInfo = (role: string) => {
    const roleMap: any = {
      ADMIN: { label: 'Quản trị viên', variant: 'info', icon: Shield },
      STAFF: { label: 'Nhân viên', variant: 'default', icon: UserIcon },
      USER: { label: 'Người dùng', variant: 'default', icon: UserIcon },
    };
    return roleMap[role] || roleMap.USER;
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 font-heading leading-tight">
            {initialRole === 'USER' ? 'Quản lý khách hàng' : initialRole === 'STAFF' ? 'Quản lý nhân viên' : 'Quản lý tài khoản'}
          </h1>
          <p className="text-sm font-bold text-slate-500 uppercase tracking-widest">
            {initialRole === 'USER' ? `Tổng ${meta.total} khách hàng` : initialRole === 'STAFF' ? `Tổng ${meta.total} nhân sự` : `Tổng ${meta.total} tài khoản`}
          </p>
        </div>

        {initialRole === 'STAFF' && (
          <Button 
            onClick={() => setIsCreateModalOpen(true)}
            className="rounded-2xl h-12 px-6 bg-primary shadow-lg shadow-primary/20 font-black uppercase text-xs tracking-widest"
          >
            <Plus className="w-5 h-5 mr-2" /> Thêm nhân sự
          </Button>
        )}
      </div>

      {initialRole === 'all' && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card
            className={cn(
              "border-none shadow-lg shadow-slate-100 p-6 bg-white rounded-3xl group cursor-pointer transition-all hover:scale-105",
              status === 'all' && role === 'all' ? "ring-2 ring-primary bg-primary/5" : ""
            )}
            onClick={() => { setStatus('all'); setRole('all'); setPage(1); }}
          >
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-2xl bg-primary/10 text-primary flex items-center justify-center group-hover:scale-110 transition-transform">
                <Users className="w-6 h-6" />
              </div>
              <div className="flex flex-col">
                <span className="text-[10px] font-black text-slate-400 uppercase">Tổng User</span>
                <span className="text-2xl font-black text-slate-900">{userStats?.total || 0}</span>
              </div>
            </div>
          </Card>
          <Card
            className={cn(
              "border-none shadow-lg shadow-slate-100 p-6 bg-white rounded-3xl group cursor-pointer transition-all hover:scale-105",
              status === 'ACTIVE' ? "ring-2 ring-green-500 bg-green-50/50" : ""
            )}
            onClick={() => { setStatus('ACTIVE'); setRole('all'); setPage(1); }}
          >
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-2xl bg-green-50 text-green-500 flex items-center justify-center group-hover:scale-110 transition-transform">
                <CheckCircle2 className="w-6 h-6" />
              </div>
              <div className="flex flex-col">
                <span className="text-[10px] font-black text-slate-400 uppercase">Hoạt động</span>
                <span className="text-2xl font-black text-slate-900">{userStats?.active || 0}</span>
              </div>
            </div>
          </Card>
          <Card
            className={cn(
              "border-none shadow-lg shadow-slate-100 p-6 bg-white rounded-3xl group cursor-pointer transition-all hover:scale-105",
              role === 'ADMIN' ? "ring-2 ring-blue-500 bg-blue-50/50" : ""
            )}
            onClick={() => { setRole('ADMIN'); setStatus('all'); setPage(1); }}
          >
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-2xl bg-blue-50 text-blue-500 flex items-center justify-center group-hover:scale-110 transition-transform">
                <Shield className="w-6 h-6" />
              </div>
              <div className="flex flex-col">
                <span className="text-[10px] font-black text-slate-400 uppercase">Admin</span>
                <span className="text-2xl font-black text-slate-900">{userStats?.admins || 0}</span>
              </div>
            </div>
          </Card>
          <Card
            className={cn(
              "border-none shadow-lg shadow-slate-100 p-6 bg-white rounded-3xl group cursor-pointer transition-all hover:scale-105",
              status === 'BANNED' ? "ring-2 ring-red-500 bg-red-50/50" : ""
            )}
            onClick={() => { setStatus('BANNED'); setRole('all'); setPage(1); }}
          >
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-2xl bg-red-50 text-red-500 flex items-center justify-center group-hover:scale-110 transition-transform">
                <AlertTriangle className="w-6 h-6" />
              </div>
              <div className="flex flex-col">
                <span className="text-[10px] font-black text-slate-400 uppercase">Bị khoá</span>
                <span className="text-2xl font-black text-slate-900">{userStats?.banned || 0}</span>
              </div>
            </div>
          </Card>
        </div>
      )}

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
            
            <div className="flex items-center gap-2 w-full md:w-auto">
              <div className="relative flex-1 md:flex-none md:min-w-[160px]">
                <Filter className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <select
                  value={status}
                  onChange={(e) => { setStatus(e.target.value); setPage(1); }}
                  className="w-full pl-10 pr-4 py-3 h-12 rounded-2xl bg-slate-50 border-none text-xs font-black uppercase text-slate-600 focus:ring-4 focus:ring-primary/5 transition-all appearance-none cursor-pointer"
                >
                  <option value="all">Tất cả trạng thái</option>
                  <option value="ACTIVE">Đang hoạt động</option>
                  <option value="INACTIVE">Không hoạt động</option>
                  <option value="BANNED">Bị khóa</option>
                </select>
              </div>

              <Button
                variant="outline"
                className="px-6 h-12 rounded-2xl border-slate-100 hover:border-primary transition-all flex-shrink-0"
                onClick={() => queryClient.invalidateQueries({ queryKey: ['users'] })}
              >
                <RefreshCcw className="w-5 h-5 mr-2" /> Tải lại
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="bg-white rounded-[32px] shadow-2xl shadow-slate-200/50 border border-slate-100 overflow-hidden animate-in fade-in slide-in-from-bottom-5 duration-500">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1200px]">
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
                users.map((user: any) => {
                  const statusInfo = getStatusBadgeInfo(user.status);
                  const roleInfo = getRoleBadgeInfo(user.role);
                  const StatusIcon = statusInfo.icon;
                  const RoleIcon = roleInfo.icon;

                  return (
                    <tr key={user.id} className="hover:bg-slate-50/50 transition-colors group">
                      <td className="px-8 py-5 pl-10">
                        <div className="flex items-center gap-4">
                          <div className="w-12 h-12 rounded-2xl bg-white border border-slate-200 overflow-hidden flex-shrink-0 flex items-center justify-center p-0.5 group-hover:scale-105 transition-transform shadow-sm">
                            {user.profile?.avatarUrl ? (
                              <img src={user.profile.avatarUrl} alt={user.profile?.fullName} className="w-full h-full object-cover rounded-xl" />
                            ) : (
                              <UserIcon className="w-6 h-6 text-slate-300" />
                            )}
                          </div>
                          <div className="flex flex-col">
                            <span className="font-black text-slate-800 group-hover:text-primary transition-colors">{user.profile?.fullName || 'Người dùng mới'}</span>
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
                        <Badge
                          variant={roleInfo.variant as any}
                          className={`gap-1.5 h-8 px-3 rounded-full ${roleInfo.variant === 'info' ? 'bg-blue-100 text-blue-700' : 'bg-slate-100 text-slate-600'}`}
                        >
                          <RoleIcon className="w-3.5 h-3.5" /> {roleInfo.label}
                        </Badge>
                      </td>
                      <td className="px-8 py-5">
                        <Badge
                          variant={statusInfo.variant as any}
                          className={`gap-1.5 h-8 px-3 rounded-full ${statusInfo.variant === 'success'
                            ? 'bg-green-100 text-green-700'
                            : statusInfo.variant === 'danger'
                              ? 'bg-red-100 text-red-700'
                              : 'bg-amber-100 text-amber-700'
                            }`}
                        >
                          <StatusIcon className="w-3.5 h-3.5" /> {statusInfo.label}
                        </Badge>
                      </td>
                      <td className="px-8 py-5">
                        <div className="flex items-center gap-2">
                          <Calendar className="w-3.5 h-3.5 text-slate-300" />
                          <span className="text-xs font-bold text-slate-600">{new Date(user.createdAt).toLocaleDateString('vi-VN')}</span>
                        </div>
                      </td>
                      <td className="px-8 py-5">
                        <div className="flex items-center justify-center gap-2">
                          <Button
                            variant="ghost"
                            className="p-2 h-10 w-10 text-slate-400 hover:text-primary hover:bg-primary/5 rounded-full border-none transition-all"
                            onClick={() => navigate(`/${initialRole === 'STAFF' ? 'staff' : 'users'}/${user.id}`)}
                            title="Xem chi tiết"
                          >
                            <Eye className="w-5 h-5" />
                          </Button>
                          <Button
                            variant="ghost"
                            className="p-2 h-10 w-10 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-full border-none transition-all"
                            onClick={() => handleEditClick(user)}
                            title="Chỉnh sửa"
                          >
                            <UserIcon className="w-5 h-5" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  );
                })
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
          <AlertTriangle className="w-10 h-10 flex-shrink-0" />
          <div>
            <p className="text-xl font-black text-red-700">Lỗi nạp dữ liệu khách hàng</p>
            <p className="text-base font-bold opacity-80">Máy chủ hiện không phản hồi. Vui lòng thử tải lại trang.</p>
          </div>
        </div>
      )}

      <UserEditModal
        isOpen={isEditModalOpen}
        onClose={() => {
          setIsEditModalOpen(false);
          setSelectedUser(null);
        }}
        onSave={handleSaveUserChanges}
        user={selectedUser}
        currentUser={currentUser}
        isLoading={updateStatusMutation.isPending || updateRoleMutation.isPending}
      />

      <UserCreateModal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
        onSave={(data) => createUserMutation.mutate(data)}
        isLoading={createUserMutation.isPending}
        defaultRole={initialRole === 'STAFF' ? 'STAFF' : 'USER'}
      />
    </div>
  );
};

const EditIcon = ({ className }: { className?: string }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
  </svg>
);
