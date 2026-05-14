import React, { useState } from 'react';
import { X, User, Mail, Phone, Lock, Shield } from 'lucide-react';
import { Button } from './Button';
import { Input } from './Input';

interface UserCreateModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSave: (data: any) => void;
    isLoading?: boolean;
    defaultRole?: string;
}

export const UserCreateModal: React.FC<UserCreateModalProps> = ({
    isOpen,
    onClose,
    onSave,
    isLoading = false,
    defaultRole = 'USER'
}) => {
    const [formData, setFormData] = useState({
        email: '',
        password: '',
        fullName: '',
        phone: '',
        role: defaultRole,
    });

    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onSave(formData);
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[200] flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm animate-in fade-in duration-200">
            <div className="bg-white w-full max-w-md rounded-[32px] shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200 border border-white">
                <div className="p-6 pb-0 flex justify-between items-center">
                    <h3 className="text-xl font-black text-slate-900 uppercase tracking-tight">
                        {defaultRole === 'STAFF' ? 'Thêm nhân sự mới' : 'Thêm người dùng mới'}
                    </h3>
                    <button onClick={onClose} className="p-2 rounded-full hover:bg-slate-50 transition-all" disabled={isLoading}>
                        <X className="w-5 h-5 text-slate-300" />
                    </button>
                </div>

                <form onSubmit={handleSubmit} className="p-8 pt-6">
                    <div className="space-y-4 mb-6">
                        <div className="relative">
                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1 block">Họ và tên</label>
                            <div className="relative">
                                <User className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                                <Input
                                    name="fullName"
                                    placeholder="Nguyễn Văn A"
                                    className="pl-12"
                                    value={formData.fullName}
                                    onChange={handleChange}
                                    required
                                />
                            </div>
                        </div>

                        <div className="relative">
                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1 block">Email</label>
                            <div className="relative">
                                <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                                <Input
                                    type="email"
                                    name="email"
                                    placeholder="example@gearhub.com"
                                    className="pl-12"
                                    value={formData.email}
                                    onChange={handleChange}
                                    required
                                />
                            </div>
                        </div>

                        <div className="relative">
                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1 block">Số điện thoại</label>
                            <div className="relative">
                                <Phone className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                                <Input
                                    name="phone"
                                    placeholder="0901234567"
                                    className="pl-12"
                                    value={formData.phone}
                                    onChange={handleChange}
                                    required
                                />
                            </div>
                        </div>

                        <div className="relative">
                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1 block">Mật khẩu ban đầu</label>
                            <div className="relative">
                                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                                <Input
                                    type="password"
                                    name="password"
                                    placeholder="••••••••"
                                    className="pl-12"
                                    value={formData.password}
                                    onChange={handleChange}
                                    required
                                    minLength={6}
                                />
                            </div>
                        </div>

                        {defaultRole === 'STAFF' && (
                            <div className="relative">
                                <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1 block">Vai trò</label>
                                <div className="relative">
                                    <Shield className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                                    <select
                                        name="role"
                                        value={formData.role}
                                        onChange={handleChange}
                                        className="w-full pl-12 pr-4 py-3 rounded-2xl border border-slate-200 bg-white text-slate-900 font-bold focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all"
                                    >
                                        <option value="STAFF">Nhân viên (Staff)</option>
                                        <option value="ADMIN">Quản trị viên (Admin)</option>
                                    </select>
                                </div>
                            </div>
                        )}
                    </div>

                    <div className="flex gap-3">
                        <Button
                            type="button"
                            variant="outline"
                            className="flex-1 h-12 rounded-2xl font-black uppercase text-[10px] tracking-widest border-slate-100"
                            onClick={onClose}
                            disabled={isLoading}
                        >
                            Hủy bỏ
                        </Button>
                        <Button
                            type="submit"
                            className="flex-1 h-12 rounded-2xl font-black uppercase text-[10px] tracking-widest shadow-lg bg-primary hover:bg-primary/90"
                            isLoading={isLoading}
                        >
                            Tạo tài khoản
                        </Button>
                    </div>
                </form>
            </div>
        </div>
    );
};
