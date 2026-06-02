import React, { useState, useMemo, useEffect } from 'react';
import { useQuery, useQueryClient, useMutation } from '@tanstack/react-query';
import {
  Users,
  Search,
  XCircle,
  User as UserIcon,
  ChevronLeft,
  ChevronRight,
  AlertCircle,
  Plus,
  Filter,
  Eye,
  Download,
  ChevronDown,
  FileSpreadsheet,
  FileText,
  RotateCcw,
  UserCheck,
  UserX,
} from '../../components/ui/IconlyIcons';
import {
  AddUser as IconlyAddUser,
  Danger as IconlyDanger,
  ShieldDone as IconlyShieldDone,
  ShieldFail as IconlyShieldFail,
  TimeCircle as IconlyTimeCircle,
  TwoUsers as IconlyTwoUsers,
} from 'react-iconly';
import { useNavigate } from 'react-router-dom';
import { userService } from '../../services/user.service';
import { authService } from '../../services/auth.service';
import { Button } from '../../components/ui/Button';
import { UserEditModal } from '../../components/ui/UserEditModal';
import { UserCreateModal } from '../../components/ui/UserCreateModal';
import { cn } from '../../utils/cn';
import { toast } from 'sonner';

interface UserListProps {
  initialRole?: string;
}

const pageSizeOptions = [10, 50, 100] as const;

export const UserList: React.FC<UserListProps> = ({ initialRole = 'all' }) => {
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<string>('all');
  const [role, setRole] = useState<string>(initialRole);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState<(typeof pageSizeOptions)[number]>(10);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [isExportOpen, setIsExportOpen] = useState(false);
  const [selectedUserIds, setSelectedUserIds] = useState<string[]>([]);
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
    queryKey: ['users', search, page, pageSize, status, role],
    queryFn: () => userService.getAllUsers({
      search,
      page,
      limit: pageSize,
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

  // ---- Bulk selection helpers ----
  const allVisibleSelected = users.length > 0 && users.every((u: any) => selectedUserIds.includes(u.id));
  const someSelected = selectedUserIds.length > 0;

  const toggleSelectUser = (userId: string) => {
    setSelectedUserIds((prev) =>
      prev.includes(userId) ? prev.filter((id) => id !== userId) : [...prev, userId]
    );
  };

  const toggleSelectAll = () => {
    setSelectedUserIds(allVisibleSelected ? [] : users.map((u: any) => u.id));
  };

  const clearSelection = () => setSelectedUserIds([]);

  // Bulk ban
  const bulkBan = async () => {
    try {
      await Promise.all(
        selectedUserIds.map((userId) =>
          updateStatusMutation.mutateAsync({ userId, status: 'BANNED' })
        )
      );
      toast.success(`Đã khoá ${selectedUserIds.length} tài khoản`);
      clearSelection();
    } catch {
      toast.error('Có lỗi xảy ra khi khoá tài khoản');
    }
  };

  // Bulk activate
  const bulkActivate = async () => {
    try {
      await Promise.all(
        selectedUserIds.map((userId) =>
          updateStatusMutation.mutateAsync({ userId, status: 'ACTIVE' })
        )
      );
      toast.success(`Đã kích hoạt ${selectedUserIds.length} tài khoản`);
      clearSelection();
    } catch {
      toast.error('Có lỗi xảy ra khi kích hoạt tài khoản');
    }
  };

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
      },
      INACTIVE: {
        label: 'Không hoạt động',
        variant: 'warning',
      },
      BANNED: {
        label: 'Bị khoá',
        variant: 'danger',
      },
    };
    return statusMap[status] || statusMap.ACTIVE;
  };

  // ---- Stats cards cho tab khách hàng (initialRole === 'USER') ----
  const isCustomerView = initialRole === 'USER';

  const customerStatCards = [
    {
      label: 'Tổng khách hàng',
      value: userStats?.customers ?? userStats?.total ?? 0,
      icon: IconlyTwoUsers,
      bgClass: 'bg-[#9694ff]',
      filterFn: () => { setStatus('all'); setPage(1); },
      active: status === 'all',
    },
    {
      label: 'Khách mới tháng này',
      value: userStats?.newCustomersThisMonth ?? 0,
      icon: IconlyAddUser,
      bgClass: 'bg-[#57caeb]',
    },
    {
      label: 'Đang hoạt động',
      value: userStats?.activeCustomers ?? userStats?.active ?? 0,
      icon: IconlyShieldDone,
      bgClass: 'bg-[#5ddc97]',
      filterFn: () => { setStatus('ACTIVE'); setPage(1); },
      active: status === 'ACTIVE',
    },
    {
      label: 'Không hoạt động',
      value: userStats?.inactiveCustomers ?? userStats?.inactive ?? 0,
      icon: IconlyTimeCircle,
      bgClass: 'bg-[#eaca4a]',
      filterFn: () => { setStatus('INACTIVE'); setPage(1); },
      active: status === 'INACTIVE',
    },
    {
      label: 'Tài khoản bị khoá',
      value: userStats?.bannedCustomers ?? userStats?.banned ?? 0,
      icon: IconlyShieldFail,
      bgClass: 'bg-[#ff7976]',
      filterFn: () => { setStatus('BANNED'); setPage(1); },
      active: status === 'BANNED',
    },
  ];

  // ---- Stats cards chung (initialRole === 'all') ----
  const allStatCards = [
    {
      label: 'Tổng tài khoản',
      value: userStats?.total ?? 0,
      icon: IconlyTwoUsers,
      bgClass: 'bg-[#9694ff]',
      filterFn: () => { setStatus('all'); setRole('all'); setPage(1); },
      active: status === 'all' && role === 'all',
    },
    {
      label: 'Đang hoạt động',
      value: userStats?.active ?? 0,
      icon: IconlyShieldDone,
      bgClass: 'bg-[#5ddc97]',
      filterFn: () => { setStatus('ACTIVE'); setRole('all'); setPage(1); },
      active: status === 'ACTIVE',
    },
    {
      label: 'Quản trị viên',
      value: userStats?.admins ?? 0,
      icon: IconlyDanger,
      bgClass: 'bg-[#57caeb]',
      filterFn: () => { setRole('ADMIN'); setStatus('all'); setPage(1); },
      active: role === 'ADMIN',
    },
    {
      label: 'Bị khoá',
      value: userStats?.banned ?? 0,
      icon: IconlyShieldFail,
      bgClass: 'bg-[#ff7976]',
      filterFn: () => { setStatus('BANNED'); setRole('all'); setPage(1); },
      active: status === 'BANNED',
    },
  ];

  const statCards = isCustomerView ? customerStatCards : allStatCards;

  // ---- Pagination ----
  const visiblePages = Array.from({ length: Math.min(meta.lastPage, 5) }, (_, index) => {
    if (meta.lastPage <= 5) return index + 1;
    if (page <= 3) return index + 1;
    if (page >= meta.lastPage - 2) return meta.lastPage - 4 + index;
    return page - 2 + index;
  });

  // ---- Avatar: dùng ảnh giả từ /assets/images/faces/ (1.jpg - 8.jpg) ----
  // deterministic theo user id: lấy tổng charCode % 8 + 1
  const FACE_COUNT = 8;
  const getFaceAvatar = (userId: string): string => {
    const sum = userId.split('').reduce((acc, c) => acc + c.charCodeAt(0), 0);
    const idx = (sum % FACE_COUNT) + 1;
    return `/assets/images/faces/${idx}.jpg`;
  };

  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(value || 0);

  // ---- Active filter chips ----
  const hasActiveFilters = Boolean(search || (status !== 'all') || (role !== initialRole));

  const activeFilterChips = [
    search && {
      key: 'search',
      label: `Tìm kiếm: ${search}`,
      onRemove: () => { setSearch(''); setPage(1); },
    },
    status !== 'all' && {
      key: 'status',
      label: `Trạng thái: ${{ ACTIVE: 'Đang hoạt động', INACTIVE: 'Không hoạt động', BANNED: 'Bị khoá' }[status] || status}`,
      onRemove: () => { setStatus('all'); setPage(1); },
    },
    role !== initialRole && role !== 'all' && {
      key: 'role',
      label: `Vai trò: ${{ ADMIN: 'Quản trị viên', STAFF: 'Nhân viên', USER: 'Người dùng' }[role] || role}`,
      onRemove: () => { setRole(initialRole); setPage(1); },
    },
  ].filter(Boolean) as Array<{ key: string; label: string; onRemove: () => void }>;

  const clearFilters = () => {
    setSearch('');
    setStatus('all');
    setRole(initialRole);
    setPage(1);
  };

  // ---- Export helpers ----
  const formatDate = (value?: string) => {
    if (!value) return 'N/A';
    return new Intl.DateTimeFormat('vi-VN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    }).format(new Date(value));
  };

  const escapeHtml = (value: unknown) =>
    String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');

  const fetchExportUsers = async () => {
    const exportLimit = Math.max(meta.total || pageSize, pageSize);
    const response = await userService.getAllUsers({
      search,
      page: 1,
      limit: exportLimit,
      status: status !== 'all' ? status : undefined,
      role: role !== 'all' ? role : undefined,
    });
    return response?.data || users;
  };

  const exportExcel = async () => {
    const exportRows = await fetchExportUsers();
    const header = ['ID', 'Họ tên', 'Email', 'Vai trò', 'Trạng thái', 'Ngày tham gia', 'Tổng đơn hàng đã đặt', 'Tổng chi tiêu'];
    const rows = exportRows.map((user: any) => [
      user.id,
      user.profile?.fullName || 'Người dùng mới',
      user.email,
      { ADMIN: 'Quản trị viên', STAFF: 'Nhân viên', USER: 'Người dùng' }[user.role as string] || user.role,
      { ACTIVE: 'Đang hoạt động', INACTIVE: 'Không hoạt động', BANNED: 'Bị khoá' }[user.status as string] || user.status,
      formatDate(user.createdAt),
      user._count?.orders ?? 0,
      formatCurrency(user.totalSpent ?? 0),
    ]);

    const csv = [header, ...rows]
      .map((row: any[]) => row.map((cell: any) => `"${String(cell).replace(/"/g, '""')}"`).join(','))
      .join('\n');

    const blob = new Blob([`\uFEFF${csv}`], { type: 'application/vnd.ms-excel;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `customers-${new Date().toISOString().slice(0, 10)}.csv`;
    link.click();
    URL.revokeObjectURL(url);
    setIsExportOpen(false);
  };

  const exportPdf = async () => {
    const exportRows = await fetchExportUsers();
    const printWindow = window.open('', '_blank');
    if (!printWindow) {
      toast.error('Trình duyệt đang chặn cửa sổ xuất PDF');
      return;
    }

    printWindow.document.write(`
      <html>
        <head>
          <title>Danh sách khách hàng</title>
          <style>
            body { font-family: Arial, sans-serif; color: #25396f; padding: 24px; }
            h1 { font-size: 20px; margin-bottom: 16px; }
            table { width: 100%; border-collapse: collapse; font-size: 12px; }
            th, td { border: 1px solid #dce7f1; padding: 8px; text-align: left; }
            th { background: #f2f7ff; text-transform: uppercase; font-size: 10px; }
          </style>
        </head>
        <body>
          <h1>${isCustomerView ? 'Danh sách khách hàng' : 'Danh sách tài khoản'}</h1>
          <table>
            <thead>
              <tr>
                <th>Họ tên</th>
                <th>Email</th>
                <th>Vai trò</th>
                <th>Trạng thái</th>
                <th>Ngày tham gia</th>
                <th>Tổng đơn hàng đã đặt</th>
                <th>Tổng chi tiêu</th>
              </tr>
            </thead>
            <tbody>
              ${exportRows.map((user: any) => `
                <tr>
                  <td>${escapeHtml(user.profile?.fullName || 'Người dùng mới')}</td>
                  <td>${escapeHtml(user.email)}</td>
                  <td>${escapeHtml({ ADMIN: 'Quản trị viên', STAFF: 'Nhân viên', USER: 'Người dùng' }[user.role as string] || user.role)}</td>
                  <td>${escapeHtml({ ACTIVE: 'Đang hoạt động', INACTIVE: 'Không hoạt động', BANNED: 'Bị khoá' }[user.status as string] || user.status)}</td>
                  <td>${escapeHtml(formatDate(user.createdAt))}</td>
                  <td>${escapeHtml(user._count?.orders ?? 0)}</td>
                  <td>${escapeHtml(formatCurrency(user.totalSpent ?? 0))}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>
          <script>window.onload = () => { window.print(); };</script>
        </body>
      </html>
    `);
    printWindow.document.close();
    setIsExportOpen(false);
  };

  // ---- Page title ----
  const pageTitle = initialRole === 'USER'
    ? 'Quản lý khách hàng'
    : initialRole === 'STAFF'
      ? 'Quản lý nhân viên'
      : 'Quản lý tài khoản';

  return (
    <div className="space-y-6 pb-10 animate-in fade-in slide-in-from-bottom-3 duration-500">

      {/* ===== Header ===== */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 font-heading leading-tight">{pageTitle}</h1>
          <p className="text-sm font-bold text-slate-500 uppercase tracking-widest">
            {isCustomerView
              ? `Tổng ${meta.total} khách hàng`
              : initialRole === 'STAFF'
                ? `Tổng ${meta.total} nhân sự`
                : `Tổng ${meta.total} tài khoản`}
          </p>
        </div>

        {initialRole === 'STAFF' && (
          <Button
            onClick={() => setIsCreateModalOpen(true)}
            className="h-10 rounded-[6px] bg-primary px-4 text-sm font-extrabold text-white shadow-[0_5px_12px_rgba(67,94,190,0.18)] hover:bg-primary/90"
          >
            <Plus className="w-4 h-4 mr-2" /> Thêm nhân sự
          </Button>
        )}
      </div>

      {/* ===== Stat Cards ===== */}
      <div className={cn('grid grid-cols-1 sm:grid-cols-2 gap-6', isCustomerView ? 'xl:grid-cols-5' : 'xl:grid-cols-4')}>
        {statCards.map((card) => {
          const Icon = card.icon;
          const content = (
            <>
              <div className={cn('w-12 h-12 rounded-[10px] flex items-center justify-center transition-transform duration-300 group-hover:scale-105 shadow-xs shrink-0 text-white', card.bgClass)}>
                <Icon set="bold" primaryColor="white" size={24} />
              </div>
              <div className="flex-1 min-w-0">
                <h6 className="text-[15px] font-semibold text-[#7c8db5] leading-tight mb-1 truncate">{card.label}</h6>
                <h6 className="text-[24px] font-extrabold text-[#25396f] leading-none mb-0 font-heading truncate">{card.value}</h6>
              </div>
            </>
          );

          return card.filterFn ? (
            <button
              key={card.label}
              type="button"
              onClick={card.filterFn}
              className={cn(
                'border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white transition-all duration-300 group py-6 px-6 flex items-center gap-4 text-left',

              )}
            >
              {content}
            </button>
          ) : (
            <div
              key={card.label}
              className="border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white transition-all duration-300 group py-6 px-6 flex items-center gap-4"
            >
              {content}
            </div>
          );
        })}
      </div>

      {/* ===== Table Card ===== */}
      <div className="bg-white rounded-[12px] shadow-[0_5px_15px_rgba(25,42,70,0.06)] border border-[#f2f7ff] overflow-hidden">

        {/* -- Toolbar -- */}
        <div className="px-5 py-5 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 border-b border-[#f2f7ff]">
          {/* Search */}
          <div className="relative w-full lg:max-w-[300px]">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#a8b4c7]" />
            <input
              type="text"
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
              placeholder="Tìm theo Tên, Email hoặc ID..."
              className="w-full h-10 pl-11 pr-4 rounded-[5px] border border-[#dce7f1] bg-white text-sm font-semibold text-[#25396f] outline-none transition-all focus:border-primary focus:ring-4 focus:ring-primary/10"
            />
          </div>

          {/* Right actions */}
          <div className="flex flex-wrap items-center gap-3">
            {/* Filter toggle */}
            <button
              type="button"
              onClick={() => setIsFilterOpen(!isFilterOpen)}
              className={cn(
                'h-10 rounded-[5px] px-4 text-sm font-extrabold inline-flex items-center gap-2 transition-colors',
                isFilterOpen || hasActiveFilters
                  ? 'bg-primary text-white shadow-sm'
                  : 'bg-[#f2f7ff] text-[#607080] hover:bg-[#e9f1ff]',
              )}
            >
              <Filter className="w-4 h-4" />
              Bộ lọc
              {activeFilterChips.length > 0 && (
                <span className="min-w-5 h-5 rounded-full bg-white/20 px-1.5 text-[11px] leading-5">
                  {activeFilterChips.length}
                </span>
              )}
            </button>

            {/* Page size */}
            <select
              value={pageSize}
              onChange={(e) => { setPageSize(Number(e.target.value) as (typeof pageSizeOptions)[number]); setPage(1); }}
              className="h-10 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
              aria-label="Số tài khoản trên mỗi trang"
            >
              {pageSizeOptions.map((option) => (
                <option key={option} value={option}>{option}</option>
              ))}
            </select>

            {/* Export */}
            <div className="relative">
              <button
                type="button"
                onClick={() => setIsExportOpen(!isExportOpen)}
                className="h-10 rounded-[5px] bg-[#f2f7ff] px-4 text-sm font-extrabold text-[#607080] inline-flex items-center gap-2 hover:bg-[#e9f1ff] transition-colors"
              >
                <Download className="w-4 h-4" />
                Xuất file
                <ChevronDown className="w-4 h-4" />
              </button>

              {isExportOpen && (
                <div className="absolute right-0 top-12 z-30 w-44 rounded-[8px] border border-[#dce7f1] bg-white shadow-[0_12px_24px_rgba(25,42,70,0.12)] p-1">
                  <button
                    type="button"
                    onClick={exportExcel}
                    className="w-full h-9 rounded-[6px] px-3 text-left text-[12px] font-extrabold text-[#25396f] hover:bg-[#f2f7ff] inline-flex items-center gap-2"
                  >
                    <FileSpreadsheet className="w-4 h-4 text-[#4fbe87]" />
                    Xuất Excel
                  </button>
                  <button
                    type="button"
                    onClick={exportPdf}
                    className="w-full h-9 rounded-[6px] px-3 text-left text-[12px] font-extrabold text-[#25396f] hover:bg-[#f2f7ff] inline-flex items-center gap-2"
                  >
                    <FileText className="w-4 h-4 text-[#f3616d]" />
                    Xuất PDF
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* -- Filter panel -- */}
        {isFilterOpen && (
          <div className="mx-5 my-5 rounded-[8px] border border-[#dce7f1] bg-[#fbfcff] p-4">
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
              {/* Trạng thái */}
              <div>
                <label className="mb-2 block text-[11px] font-extrabold uppercase text-[#7c8db5]">Trạng thái</label>
                <select
                  value={status}
                  onChange={(e) => { setStatus(e.target.value); setPage(1); }}
                  className="h-10 w-full rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
                >
                  <option value="all">Tất cả trạng thái</option>
                  <option value="ACTIVE">Đang hoạt động</option>
                  <option value="INACTIVE">Không hoạt động</option>
                  <option value="BANNED">Bị khoá</option>
                </select>
              </div>

              {/* Vai trò – only show for 'all' tab */}
              {initialRole === 'all' && (
                <div>
                  <label className="mb-2 block text-[11px] font-extrabold uppercase text-[#7c8db5]">Vai trò</label>
                  <select
                    value={role}
                    onChange={(e) => { setRole(e.target.value); setPage(1); }}
                    className="h-10 w-full rounded-[5px] border border-[#dce7f1] bg-white px-3 text-sm font-bold text-[#25396f] outline-none focus:border-primary"
                  >
                    <option value="all">Tất cả vai trò</option>
                    <option value="ADMIN">Quản trị viên</option>
                    <option value="STAFF">Nhân viên</option>
                    <option value="USER">Người dùng</option>
                  </select>
                </div>
              )}
            </div>

            <div className="mt-4 flex justify-end">
              <button
                type="button"
                onClick={clearFilters}
                disabled={!hasActiveFilters}
                className="h-9 rounded-[5px] border border-[#dce7f1] bg-white px-3 text-[12px] font-extrabold text-[#607080] inline-flex items-center gap-2 hover:text-primary hover:border-primary disabled:opacity-50 disabled:pointer-events-none"
              >
                <RotateCcw className="w-4 h-4" />
                Xóa bộ lọc
              </button>
            </div>
          </div>
        )}

        {/* -- Filter chips -- */}
        {activeFilterChips.length > 0 && (
          <div className="px-5 pb-4 flex flex-wrap items-center gap-2">
            {activeFilterChips.map((chip) => (
              <button
                key={chip.key}
                type="button"
                onClick={chip.onRemove}
                className="rounded-full bg-[#f2f7ff] px-3 py-1.5 text-[12px] font-extrabold text-[#435ebe] inline-flex items-center gap-2 hover:bg-[#e9f1ff]"
              >
                {chip.label}
                <XCircle className="w-3.5 h-3.5" />
              </button>
            ))}
            <button
              type="button"
              onClick={clearFilters}
              className="rounded-full px-3 py-1.5 text-[12px] font-extrabold text-[#607080] hover:text-primary"
            >
              Xóa tất cả
            </button>
          </div>
        )}

        {/* -- Error banner -- */}
        {isError && (
          <div className="mx-5 mt-5 rounded-[8px] border border-red-100 bg-red-50 p-4 flex gap-3 text-red-600">
            <AlertCircle className="w-5 h-5 shrink-0 mt-0.5" />
            <div>
              <h6 className="font-extrabold text-red-700 mb-1">Không thể tải dữ liệu khách hàng</h6>
              <p className="text-sm font-semibold text-red-500 mb-0">Máy chủ hiện không phản hồi. Vui lòng thử lại sau.</p>
            </div>
          </div>
        )}

        {/* -- Bulk action bar -- */}
        {someSelected && (
          <div className="mx-5 mb-0 mt-4 rounded-[8px] bg-primary/5 border border-primary/20 px-4 py-3 flex items-center justify-between gap-4">
            <p className="text-[13px] font-extrabold text-[#25396f] mb-0">
              Đã chọn <span className="text-primary">{selectedUserIds.length}</span> tài khoản
            </p>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={bulkActivate}
                disabled={updateStatusMutation.isPending}
                className="h-8 rounded-[6px] bg-[#edf9f1] text-[#2f8f5b] px-3 text-[12px] font-extrabold inline-flex items-center gap-1.5 hover:bg-[#d4f0e1] disabled:opacity-50"
              >
                <UserCheck className="w-3.5 h-3.5" />
                Kích hoạt
              </button>
              <button
                type="button"
                onClick={bulkBan}
                disabled={updateStatusMutation.isPending}
                className="h-8 rounded-[6px] bg-red-50 text-red-600 px-3 text-[12px] font-extrabold inline-flex items-center gap-1.5 hover:bg-red-100 disabled:opacity-50"
              >
                <UserX className="w-3.5 h-3.5" />
                Khoá tài khoản
              </button>
              <button
                type="button"
                onClick={clearSelection}
                className="h-8 rounded-[6px] border border-[#dce7f1] bg-white px-3 text-[12px] font-extrabold text-[#607080] inline-flex items-center gap-1.5 hover:text-primary hover:border-primary"
              >
                <XCircle className="w-3.5 h-3.5" />
                Bỏ chọn
              </button>
            </div>
          </div>
        )}

        {/* -- Table -- */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[960px]">
            <thead>
              <tr className="border-b border-[#dce7f1] bg-[#fbfcff] text-[#607080] text-[11px] font-extrabold uppercase">
                {/* Checkbox */}
                <th className="px-5 py-4 w-10">
                  <input
                    type="checkbox"
                    checked={allVisibleSelected}
                    onChange={toggleSelectAll}
                    className="h-4 w-4 rounded border-[#dce7f1] text-primary focus:ring-primary/20 cursor-pointer"
                    aria-label="Chọn tất cả"
                  />
                </th>
                <th className="px-5 py-4">Khách hàng</th>
                <th className="px-5 py-4">Trạng thái</th>
                <th className="px-5 py-4 text-right">Tổng đơn</th>
                <th className="px-5 py-4 text-right">Tổng chi tiêu</th>
                <th className="px-5 py-4 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#dce7f1] bg-[#f1f2ff] text-sm">
              {isLoading ? (
                Array.from({ length: pageSize > 10 ? 10 : pageSize }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td colSpan={6} className="px-5 py-6">
                      <div className="h-5 rounded bg-white/70" />
                    </td>
                  </tr>
                ))
              ) : users.length > 0 ? (
                users.map((user: any) => {
                  const statusInfo = getStatusBadgeInfo(user.status);
                  const displayName = user.profile?.fullName || 'Người dùng mới';
                  const faceAvatar = getFaceAvatar(user.id);
                  const totalOrders = user._count?.orders ?? 0;
                  const totalSpent = user.totalSpent ?? 0;
                  const isSelected = selectedUserIds.includes(user.id);

                  return (
                    <tr
                      key={user.id}
                      className={cn(
                        'transition-colors group',
                        isSelected ? 'bg-primary/5' : 'hover:bg-white/60'
                      )}
                    >
                      {/* Checkbox */}
                      <td className="px-5 py-4">
                        <input
                          type="checkbox"
                          checked={isSelected}
                          onChange={() => toggleSelectUser(user.id)}
                          className="h-4 w-4 rounded border-[#dce7f1] text-primary focus:ring-primary/20 cursor-pointer"
                          aria-label={`Chọn ${displayName}`}
                        />
                      </td>

                      {/* Customer: avatar (face image) + name + email */}
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-3">
                          <img
                            src={faceAvatar}
                            alt={displayName}
                            className="w-9 h-9 rounded-full object-cover flex-shrink-0 border border-[#dce7f1]"
                          />
                          <div className="min-w-0">
                            <p className="font-extrabold text-[#25396f] mb-0 truncate max-w-[220px]">
                              {displayName}
                            </p>
                            <p className="text-[11px] font-semibold text-[#7c8db5] mb-0 truncate max-w-[220px]">
                              {user.email}
                            </p>
                          </div>
                        </div>
                      </td>

                      {/* Status */}
                      <td className="px-5 py-4">
                        <span className={cn(
                          'inline-flex items-center gap-1.5 rounded-[6px] px-2.5 py-1 text-[10px] font-extrabold uppercase',
                          statusInfo.variant === 'success'
                            ? 'bg-[#edf9f1] text-[#2f8f5b]'
                            : statusInfo.variant === 'danger'
                              ? 'bg-red-50 text-red-600'
                              : 'bg-[#fff7e6] text-[#946200]'
                        )}>
                          {statusInfo.label}
                        </span>
                      </td>

                      {/* Total orders */}
                      <td className="px-5 py-4 text-right">
                        <span className="font-extrabold text-[#25396f]">{totalOrders}</span>
                        <span className="ml-1 text-[11px] font-semibold text-[#7c8db5]">đơn</span>
                      </td>

                      {/* Total spent — from backend groupBy aggregate */}
                      <td className="px-5 py-4 text-right">
                        <span className="font-extrabold text-[#25396f] text-[13px]">{formatCurrency(totalSpent)}</span>
                      </td>

                      {/* Actions */}
                      <td className="px-5 py-4">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            type="button"
                            onClick={() => navigate(`/${initialRole === 'STAFF' ? 'staff' : 'users'}/${user.id}`)}
                            className="w-9 h-9 rounded-[6px] inline-flex items-center justify-center text-primary bg-primary/10 hover:bg-primary/20 transition-colors"
                            title="Xem chi tiết"
                          >
                            <Eye className="w-4 h-4" />
                          </button>
                          <button
                            type="button"
                            onClick={() => handleEditClick(user)}
                            className="w-9 h-9 rounded-[6px] inline-flex items-center justify-center text-[#607080] hover:bg-white transition-colors"
                            title="Chỉnh sửa"
                          >
                            <UserIcon className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={6} className="px-6 py-20 text-center">
                    <div className="mx-auto w-16 h-16 rounded-[14px] bg-white flex items-center justify-center mb-4">
                      <Users className="w-8 h-8 text-primary/50" />
                    </div>
                    <h6 className="text-[18px] font-extrabold text-[#25396f] mb-1">Không tìm thấy tài khoản nào</h6>
                    <p className="text-sm font-semibold text-[#7c8db5] mb-5">Thử thay đổi từ khóa hoặc xóa bộ lọc hiện tại.</p>
                    <button
                      type="button"
                      onClick={clearFilters}
                      className="h-9 rounded-[8px] border border-[#dce7f1] bg-white px-4 text-sm font-extrabold text-[#607080] hover:text-primary hover:border-primary"
                    >
                      Xóa bộ lọc
                    </button>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* -- Pagination -- */}
        <div className="px-5 py-4 border-t border-[#dce7f1] bg-white flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <p className="text-[13px] font-semibold text-[#a8b4c7] mb-0">
            Hiển thị {(page - 1) * pageSize + (users.length > 0 ? 1 : 0)} tới {(page - 1) * pageSize + users.length} của {meta.total} tài khoản
          </p>
          {meta.lastPage > 1 && (
            <nav aria-label="User pagination">
              <ul className="flex items-center gap-1.5">
                <li>
                  <button
                    type="button"
                    disabled={page === 1}
                    onClick={() => setPage(page - 1)}
                    className="w-9 h-9 rounded-[6px] border border-[#dce7f1] bg-white text-[#7c8db5] inline-flex items-center justify-center hover:text-primary hover:border-primary disabled:opacity-40 disabled:pointer-events-none"
                  >
                    <ChevronLeft className="w-4 h-4" />
                  </button>
                </li>
                {visiblePages.map((visiblePage) => (
                  <li key={visiblePage}>
                    <button
                      type="button"
                      onClick={() => setPage(visiblePage)}
                      className={cn(
                        'w-9 h-9 rounded-[6px] text-sm font-extrabold transition-all',
                        visiblePage === page
                          ? 'bg-primary text-white shadow-sm'
                          : 'bg-white border border-[#dce7f1] text-[#607080] hover:text-primary hover:border-primary',
                      )}
                    >
                      {visiblePage}
                    </button>
                  </li>
                ))}
                <li>
                  <button
                    type="button"
                    disabled={page === meta.lastPage}
                    onClick={() => setPage(page + 1)}
                    className="w-9 h-9 rounded-[6px] border border-[#dce7f1] bg-white text-[#7c8db5] inline-flex items-center justify-center hover:text-primary hover:border-primary disabled:opacity-40 disabled:pointer-events-none"
                  >
                    <ChevronRight className="w-4 h-4" />
                  </button>
                </li>
              </ul>
            </nav>
          )}
        </div>
      </div>

      {/* ===== Modals ===== */}
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
