import React, { useMemo, useState } from 'react';
import { ChevronDown, KeyRound, Mail, Phone, Shield, UserRound, X } from './IconlyIcons';
import { Button } from './Button';
import type { Role } from '../../types';

interface UserCreateFormData {
  email: string;
  password: string;
  fullName: string;
  phone: string;
  role: Role;
}

interface UserCreateModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: UserCreateFormData) => void;
  isLoading?: boolean;
  defaultRole?: string;
}

const fieldLabelClass = 'text-[11px] font-extrabold text-[#7c8db5] uppercase tracking-wide';
const fieldClass =
  'w-full rounded-[8px] border border-[#dce7f1] bg-white text-sm font-bold text-[#25396f] outline-none transition-all placeholder:text-[#a8b4c7] focus:border-primary focus:ring-4 focus:ring-primary/10';

const getSafeDefaultRole = (value?: string): Role => (value === 'STAFF' || value === 'ADMIN' || value === 'USER' ? value : 'USER');

const getInitials = (name: string, email: string) => {
  const source = name.trim() || email.split('@')[0] || 'GH';
  return source
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0])
    .join('')
    .toUpperCase();
};

export const UserCreateModal: React.FC<UserCreateModalProps> = ({
  isOpen,
  onClose,
  onSave,
  isLoading = false,
  defaultRole = 'USER',
}) => {
  if (!isOpen) return null;

  return (
    <UserCreateModalContent
      key={defaultRole}
      onClose={onClose}
      onSave={onSave}
      isLoading={isLoading}
      defaultRole={defaultRole}
    />
  );
};

const UserCreateModalContent: React.FC<Omit<UserCreateModalProps, 'isOpen'>> = ({
  onClose,
  onSave,
  isLoading = false,
  defaultRole = 'USER',
}) => {
  const defaultFormData = useMemo<UserCreateFormData>(() => ({
    email: '',
    password: '',
    fullName: '',
    phone: '',
    role: getSafeDefaultRole(defaultRole),
  }), [defaultRole]);

  const [formData, setFormData] = useState<UserCreateFormData>(defaultFormData);
  const isStaffFlow = defaultRole === 'STAFF';
  const roleLabel = formData.role === 'ADMIN' ? 'Quản trị viên' : formData.role === 'STAFF' ? 'Nhân viên' : 'Người dùng';
  const passwordReady = formData.password.length >= 6;

  const handleChange = (event: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = event.target;
    setFormData((current) => ({ ...current, [name]: value }));
  };

  const handleSubmit = (event: React.FormEvent) => {
    event.preventDefault();
    onSave({
      ...formData,
      email: formData.email.trim(),
      fullName: formData.fullName.trim(),
      phone: formData.phone.trim(),
    });
  };

  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center bg-[#172033]/45 p-4 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="flex max-h-[92vh] w-full max-w-3xl flex-col overflow-hidden rounded-[14px] border border-[#dce7f1] bg-white shadow-[0_24px_70px_rgba(25,42,70,0.24)] animate-in zoom-in-95 duration-200">
        <div className="flex shrink-0 items-start justify-between gap-4 border-b border-[#edf2f7] bg-[#fbfcff] px-6 py-5">
          <div className="flex min-w-0 items-start gap-4">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[10px] bg-primary/10 text-primary">
              <UserRound className="h-5 w-5" />
            </div>
            <div className="min-w-0">
              <div className="mb-1 flex flex-wrap items-center gap-2">
                <h2 className="text-[20px] font-extrabold leading-tight text-[#25396f]">
                  {isStaffFlow ? 'Thêm nhân sự mới' : 'Thêm người dùng mới'}
                </h2>
                <span className="rounded-[6px] bg-white px-2.5 py-1 text-[11px] font-extrabold text-[#7c8db5] ring-1 ring-[#dce7f1]">
                  {roleLabel}
                </span>
              </div>
              <p className="text-sm font-semibold text-[#7c8db5]">
                Tạo tài khoản mới với thông tin đăng nhập ban đầu.
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

        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto">
          <div className="grid grid-cols-1 gap-0 lg:grid-cols-[260px_1fr]">
            <aside className="border-b border-[#edf2f7] bg-[#fbfcff] p-6 lg:border-b-0 lg:border-r">
              <div className="space-y-4">
                <div className="rounded-[12px] border border-[#edf2f7] bg-white p-4">
                  <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-primary/10 text-lg font-extrabold text-primary">
                    {getInitials(formData.fullName, formData.email)}
                  </div>
                  <p className="mb-1 line-clamp-2 text-base font-extrabold leading-tight text-[#25396f]">
                    {formData.fullName || 'Tên nhân sự'}
                  </p>
                  <p className="mb-0 truncate text-xs font-bold text-[#7c8db5]">{formData.email || 'email@gearhub.com'}</p>
                </div>

                <div className="rounded-[10px] border border-[#edf2f7] bg-white p-4">
                  <p className="mb-2 text-[11px] font-extrabold uppercase tracking-wide text-[#7c8db5]">Vai trò</p>
                  <div className="flex items-center gap-3">
                    <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[9px] bg-[#f2f7ff] text-primary">
                      <Shield className="h-5 w-5" />
                    </span>
                    <div className="min-w-0">
                      <p className="mb-1 truncate text-sm font-extrabold text-[#25396f]">{roleLabel}</p>
                      <p className="mb-0 text-xs font-semibold text-[#7c8db5]">
                        {formData.role === 'ADMIN' ? 'Toàn quyền quản trị' : formData.role === 'STAFF' ? 'Vận hành admin' : 'Khách hàng'}
                      </p>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="rounded-[10px] border border-[#edf2f7] bg-white p-3">
                    <p className="mb-1 text-[10px] font-extrabold uppercase text-[#7c8db5]">Mật khẩu</p>
                    <p className={`text-sm font-extrabold ${passwordReady ? 'text-[#2f8f5b]' : 'text-[#946200]'}`}>
                      {passwordReady ? 'Đủ 6 ký tự' : 'Cần thêm'}
                    </p>
                  </div>
                  <div className="rounded-[10px] border border-[#edf2f7] bg-white p-3">
                    <p className="mb-1 text-[10px] font-extrabold uppercase text-[#7c8db5]">Liên hệ</p>
                    <p className="truncate text-sm font-extrabold text-[#25396f]">{formData.phone || 'Chưa nhập'}</p>
                  </div>
                </div>
              </div>
            </aside>

            <div className="space-y-5 p-6">
              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div className="md:col-span-2">
                  <label className={fieldLabelClass}>Họ và tên</label>
                  <div className="relative mt-2">
                    <UserRound className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-[#a8b4c7]" />
                    <input
                      name="fullName"
                      value={formData.fullName}
                      onChange={handleChange}
                      required
                      placeholder="Nguyễn Văn A"
                      className={`${fieldClass} h-11 pl-11 pr-4`}
                    />
                  </div>
                </div>

                <div>
                  <label className={fieldLabelClass}>Email</label>
                  <div className="relative mt-2">
                    <Mail className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-[#a8b4c7]" />
                    <input
                      type="email"
                      name="email"
                      value={formData.email}
                      onChange={handleChange}
                      required
                      placeholder="example@gearhub.com"
                      className={`${fieldClass} h-11 pl-11 pr-4`}
                    />
                  </div>
                </div>

                <div>
                  <label className={fieldLabelClass}>Số điện thoại</label>
                  <div className="relative mt-2">
                    <Phone className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-[#a8b4c7]" />
                    <input
                      name="phone"
                      value={formData.phone}
                      onChange={handleChange}
                      required
                      placeholder="0901234567"
                      className={`${fieldClass} h-11 pl-11 pr-4`}
                    />
                  </div>
                </div>

                <div>
                  <label className={fieldLabelClass}>Mật khẩu ban đầu</label>
                  <div className="relative mt-2">
                    <KeyRound className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-[#a8b4c7]" />
                    <input
                      type="password"
                      name="password"
                      value={formData.password}
                      onChange={handleChange}
                      required
                      minLength={6}
                      placeholder="Tối thiểu 6 ký tự"
                      className={`${fieldClass} h-11 pl-11 pr-4`}
                    />
                  </div>
                </div>

                {isStaffFlow && (
                  <div>
                    <label className={fieldLabelClass}>Vai trò</label>
                    <div className="relative mt-2">
                      <Shield className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-[#a8b4c7]" />
                      <select
                        name="role"
                        value={formData.role}
                        onChange={handleChange}
                        className={`${fieldClass} h-11 cursor-pointer appearance-none pl-11 pr-10`}
                      >
                        <option value="STAFF">Nhân viên</option>
                        <option value="ADMIN">Quản trị viên</option>
                      </select>
                      <ChevronDown className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[#7c8db5]" />
                    </div>
                  </div>
                )}
              </div>

              <div className="rounded-[10px] border border-[#edf2f7] bg-[#fbfcff] p-4">
                <div className="flex gap-3">
                  <div className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-[8px] bg-primary/10 text-primary">
                    <Shield className="h-4 w-4" />
                  </div>
                  <div className="min-w-0">
                    <p className="mb-1 text-sm font-extrabold text-[#25396f]">Quyền truy cập sau khi tạo</p>
                    <p className="mb-0 text-xs font-semibold leading-5 text-[#7c8db5]">
                      {formData.role === 'ADMIN'
                        ? 'Admin có toàn quyền trong hệ thống, chỉ cấp khi thật sự cần.'
                        : formData.role === 'STAFF'
                          ? 'Nhân viên có thể truy cập admin để xử lý nghiệp vụ vận hành.'
                          : 'Người dùng thông thường dùng cho tài khoản khách hàng.'}
                    </p>
                  </div>
                </div>
              </div>
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
              type="submit"
              className="h-10 rounded-[8px] bg-primary px-5 text-sm font-extrabold text-white shadow-[0_5px_12px_rgba(67,94,190,0.18)] hover:bg-primary/90"
              isLoading={isLoading}
              disabled={!formData.fullName.trim() || !formData.email.trim() || !passwordReady || !formData.phone.trim()}
            >
              Tạo tài khoản
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
};
