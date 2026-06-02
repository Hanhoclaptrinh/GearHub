import React, { useMemo, useState } from 'react';
import { AlertCircle, CheckCircle2, Lock, Shield, UserRound, X } from './IconlyIcons';
import { Button } from './Button';
import type { Role, User } from '../../types';

type AccountStatus = 'ACTIVE' | 'INACTIVE' | 'BANNED';

interface EditableUser extends User {
  status?: AccountStatus;
  totalSpent?: number;
  _count?: {
    orders?: number;
  };
}

interface UserEditFormData {
  status: AccountStatus;
  role: Role;
}

interface UserEditModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: UserEditFormData) => void;
  user?: EditableUser | null;
  currentUser?: User | null;
  isLoading?: boolean;
}

const statusOptions: Array<{ value: AccountStatus; label: string; tone: string }> = [
  { value: 'ACTIVE', label: 'Hoạt động', tone: 'bg-[#edf9f1] text-[#2f8f5b]' },
  { value: 'INACTIVE', label: 'Không hoạt động', tone: 'bg-[#fff7e6] text-[#946200]' },
  { value: 'BANNED', label: 'Bị khoá', tone: 'bg-red-50 text-red-600' },
];

const roleOptions: Array<{ value: Role; label: string; description: string }> = [
  { value: 'USER', label: 'Người dùng', description: 'Tài khoản khách hàng, chỉ dùng frontend mua hàng.' },
  { value: 'STAFF', label: 'Nhân viên', description: 'Có quyền vận hành các nghiệp vụ trong admin.' },
  { value: 'ADMIN', label: 'Quản trị viên', description: 'Toàn quyền quản trị hệ thống.' },
];

const formatCurrency = (value?: number) =>
  new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(value || 0);

const getInitials = (name?: string, email?: string) => {
  const source = name?.trim() || email?.split('@')[0] || 'GH';
  return source
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0])
    .join('')
    .toUpperCase();
};

export const UserEditModal: React.FC<UserEditModalProps> = ({
  isOpen,
  onClose,
  onSave,
  user,
  currentUser,
  isLoading = false,
}) => {
  if (!isOpen) return null;
  if (!user) return null;

  return (
    <UserEditModalContent
      key={user.id}
      onClose={onClose}
      onSave={onSave}
      user={user}
      currentUser={currentUser}
      isLoading={isLoading}
    />
  );
};

const UserEditModalContent: React.FC<Omit<UserEditModalProps, 'isOpen' | 'user'> & { user: EditableUser }> = ({
  onClose,
  onSave,
  user,
  currentUser,
  isLoading = false,
}) => {
  const isEditingSelf = user?.id === currentUser?.id;
  const isCurrentUserAdmin = currentUser?.role === 'ADMIN';
  const [formData, setFormData] = useState<UserEditFormData>({
    status: user.status || 'ACTIVE',
    role: user.role || 'USER',
  });

  const isBannedDisabled = isEditingSelf && isCurrentUserAdmin;
  const isRoleDisabled = isEditingSelf && isCurrentUserAdmin;
  const displayName = user?.profile?.fullName || user?.fullName || 'Người dùng mới';
  const currentStatus = statusOptions.find((option) => option.value === formData.status) || statusOptions[0];
  const currentRole = roleOptions.find((option) => option.value === formData.role) || roleOptions[0];
  const changedFields = useMemo(() => {
    if (!user) return 0;
    return Number(formData.status !== (user.status || 'ACTIVE')) + Number(formData.role !== (user.role || 'USER'));
  }, [formData.role, formData.status, user]);

  const handleSave = () => {
    if (isBannedDisabled && formData.status === 'BANNED') {
      window.alert('Bạn không thể tự khóa tài khoản của chính mình');
      return;
    }

    if (isRoleDisabled && formData.role !== 'ADMIN') {
      window.alert('Bạn không thể tự hạ quyền Admin của chính mình');
      return;
    }

    onSave(formData);
  };

  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center bg-[#172033]/45 p-4 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="flex max-h-[92vh] w-full max-w-3xl flex-col overflow-hidden rounded-[14px] border border-[#dce7f1] bg-white shadow-[0_24px_70px_rgba(25,42,70,0.24)] animate-in zoom-in-95 duration-200">
        <div className="flex shrink-0 items-start justify-between gap-4 border-b border-[#edf2f7] bg-[#fbfcff] px-6 py-5">
          <div className="flex min-w-0 items-start gap-4">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[10px] bg-primary/10 text-primary">
              <Shield className="h-5 w-5" />
            </div>
            <div className="min-w-0">
              <div className="mb-1 flex flex-wrap items-center gap-2">
                <h2 className="text-[20px] font-extrabold leading-tight text-[#25396f]">Cập nhật người dùng</h2>
                <span className="rounded-[6px] bg-white px-2.5 py-1 text-[11px] font-extrabold text-[#7c8db5] ring-1 ring-[#dce7f1]">
                  {changedFields > 0 ? `${changedFields} thay đổi` : 'Không đổi'}
                </span>
              </div>
              <p className="text-sm font-semibold text-[#7c8db5]">
                Điều chỉnh trạng thái tài khoản và quyền truy cập admin.
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="flex h-9 w-9 shrink-0 items-center justify-center rounded-[8px] text-[#7c8db5] transition-colors hover:bg-white hover:text-[#25396f] disabled:opacity-50"
            disabled={isLoading}
            aria-label="Đóng modal"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto">
            <div className="grid grid-cols-1 gap-0 lg:grid-cols-[260px_1fr]">
              <aside className="border-b border-[#edf2f7] bg-[#fbfcff] p-6 lg:border-b-0 lg:border-r">
                <div className="space-y-4">
                  <div className="rounded-[12px] border border-[#edf2f7] bg-white p-4">
                    <div className="mb-4 flex h-16 w-16 items-center justify-center overflow-hidden rounded-full bg-primary/10 text-lg font-extrabold text-primary">
                      {user.profile?.avatarUrl || user.avatarUrl ? (
                        <img src={user.profile?.avatarUrl || user.avatarUrl} alt={displayName} className="h-full w-full object-cover" />
                      ) : (
                        getInitials(displayName, user.email)
                      )}
                    </div>
                    <p className="mb-1 line-clamp-2 text-base font-extrabold leading-tight text-[#25396f]">{displayName}</p>
                    <p className="mb-0 truncate text-xs font-bold text-[#7c8db5]">{user.email}</p>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div className="rounded-[10px] border border-[#edf2f7] bg-white p-3">
                      <p className="mb-1 text-[10px] font-extrabold uppercase text-[#7c8db5]">Đơn hàng</p>
                      <p className="text-lg font-extrabold leading-none text-[#25396f]">{user._count?.orders ?? 0}</p>
                    </div>
                    <div className="rounded-[10px] border border-[#edf2f7] bg-white p-3">
                      <p className="mb-1 text-[10px] font-extrabold uppercase text-[#7c8db5]">Chi tiêu</p>
                      <p className="truncate text-sm font-extrabold text-[#25396f]">{formatCurrency(user.totalSpent)}</p>
                    </div>
                  </div>

                  <div className="rounded-[10px] border border-[#edf2f7] bg-white p-4">
                    <p className="mb-2 text-[11px] font-extrabold uppercase tracking-wide text-[#7c8db5]">Sau khi lưu</p>
                    <div className="space-y-2">
                      <span className={`inline-flex rounded-[6px] px-2.5 py-1 text-[11px] font-extrabold ${currentStatus.tone}`}>
                        {currentStatus.label}
                      </span>
                      <p className="mb-0 text-sm font-extrabold text-[#25396f]">{currentRole.label}</p>
                    </div>
                  </div>
                </div>
              </aside>

              <div className="space-y-5 p-6">
                {isEditingSelf && isCurrentUserAdmin && (
                  <div className="rounded-[10px] border border-amber-200 bg-amber-50 p-4">
                    <div className="flex gap-3">
                      <AlertCircle className="mt-0.5 h-5 w-5 shrink-0 text-amber-600" />
                      <div>
                        <p className="mb-1 text-sm font-extrabold text-amber-800">Bảo vệ tài khoản hiện tại</p>
                        <p className="mb-0 text-xs font-semibold leading-5 text-amber-700">
                          Bạn không thể tự khóa hoặc hạ quyền tài khoản admin của chính mình.
                        </p>
                      </div>
                    </div>
                  </div>
                )}

                <section className="space-y-3">
                  <div className="flex items-center justify-between gap-3">
                    <label className="text-[11px] font-extrabold uppercase tracking-wide text-[#7c8db5]">Trạng thái tài khoản</label>
                    {isBannedDisabled && <Lock className="h-3.5 w-3.5 text-amber-500" />}
                  </div>
                  <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
                    {statusOptions.map((option) => {
                      const disabled = isLoading || (isBannedDisabled && option.value === 'BANNED');
                      const active = formData.status === option.value;
                      return (
                        <button
                          key={option.value}
                          type="button"
                          disabled={disabled}
                          onClick={() => setFormData((current) => ({ ...current, status: option.value }))}
                          className={`min-h-20 rounded-[10px] border p-4 text-left transition-all disabled:cursor-not-allowed disabled:opacity-50 ${
                            active ? 'border-primary bg-primary/5 shadow-[0_5px_12px_rgba(67,94,190,0.10)]' : 'border-[#dce7f1] bg-white hover:border-primary/50'
                          }`}
                        >
                          <span className={`mb-2 inline-flex rounded-[6px] px-2 py-1 text-[10px] font-extrabold ${option.tone}`}>
                            {option.label}
                          </span>
                          <p className="mb-0 text-xs font-semibold text-[#7c8db5]">
                            {option.value === 'ACTIVE' ? 'Cho phép đăng nhập.' : option.value === 'INACTIVE' ? 'Tạm ngưng mềm.' : 'Chặn truy cập.'}
                          </p>
                        </button>
                      );
                    })}
                  </div>
                </section>

                <section className="space-y-3">
                  <div className="flex items-center justify-between gap-3">
                    <label className="text-[11px] font-extrabold uppercase tracking-wide text-[#7c8db5]">Vai trò</label>
                    {isRoleDisabled && <Lock className="h-3.5 w-3.5 text-amber-500" />}
                  </div>
                  <div className="grid grid-cols-1 gap-3">
                    {roleOptions.map((option) => {
                      const disabled = isLoading || isRoleDisabled;
                      const active = formData.role === option.value;
                      return (
                        <button
                          key={option.value}
                          type="button"
                          disabled={disabled}
                          onClick={() => setFormData((current) => ({ ...current, role: option.value }))}
                          className={`flex items-start gap-3 rounded-[10px] border p-4 text-left transition-all disabled:cursor-not-allowed disabled:opacity-50 ${
                            active ? 'border-primary bg-primary/5 shadow-[0_5px_12px_rgba(67,94,190,0.10)]' : 'border-[#dce7f1] bg-white hover:border-primary/50'
                          }`}
                        >
                          <span className={`mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-[8px] ${active ? 'bg-primary text-white' : 'bg-[#f2f7ff] text-primary'}`}>
                            {active ? <CheckCircle2 className="h-4 w-4" /> : <UserRound className="h-4 w-4" />}
                          </span>
                          <span className="min-w-0">
                            <span className="block text-sm font-extrabold text-[#25396f]">{option.label}</span>
                            <span className="mt-1 block text-xs font-semibold leading-5 text-[#7c8db5]">{option.description}</span>
                          </span>
                        </button>
                      );
                    })}
                  </div>
                </section>
              </div>
            </div>

            <div className="flex shrink-0 flex-col-reverse gap-3 border-t border-[#edf2f7] bg-white px-6 py-4 sm:flex-row sm:justify-end">
              <Button
                type="button"
                variant="outline"
                className="h-10 rounded-[8px] border border-[#dce7f1] bg-white px-5 text-sm font-extrabold text-[#607080] shadow-none hover:border-primary hover:bg-primary/5 hover:text-primary"
                onClick={onClose}
                disabled={isLoading}
              >
                Hủy
              </Button>
              <Button
                type="button"
                className="h-10 rounded-[8px] bg-primary px-5 text-sm font-extrabold text-white shadow-[0_5px_12px_rgba(67,94,190,0.18)] hover:bg-primary/90"
                onClick={handleSave}
                isLoading={isLoading}
                disabled={changedFields === 0}
              >
                Lưu thay đổi
              </Button>
            </div>
        </div>
      </div>
    </div>
  );
};
