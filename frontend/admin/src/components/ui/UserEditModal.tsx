import React, { useState, useEffect } from 'react';
import { X, AlertCircle, Lock } from 'lucide-react';
import { Button } from './Button';

interface UserEditModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSave: (data: any) => void;
    user?: any;
    currentUser?: any;
    isLoading?: boolean;
}

export const UserEditModal: React.FC<UserEditModalProps> = ({
    isOpen,
    onClose,
    onSave,
    user,
    currentUser,
    isLoading = false,
}) => {
    const isEditingSelf = user?.id === currentUser?.id;
    const isCurrentUserAdmin = currentUser?.role === 'ADMIN';
    const [formData, setFormData] = useState({
        status: 'ACTIVE',
        role: 'USER',
    });

    useEffect(() => {
        if (user) {
            setFormData({
                status: user.status || 'ACTIVE',
                role: user.role || 'USER',
            });
        }
    }, [user, isOpen]);

    const handleStatusChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
        setFormData({ ...formData, status: e.target.value });
    };

    const handleRoleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
        setFormData({ ...formData, role: e.target.value });
    };

    const handleSave = () => {
        if (isEditingSelf && isCurrentUserAdmin && formData.status === 'BANNED') {
            alert('Bạn không thể tự khóa tài khoản của chính mình');
            return;
        }

        if (isEditingSelf && isCurrentUserAdmin && formData.role !== 'ADMIN') {
            alert('Bạn không thể tự hạ quyền Admin của chính mình');
            return;
        }

        onSave(formData);
    };

    const isBannedDisabled = isEditingSelf && isCurrentUserAdmin;
    const isRoleDisabled = isEditingSelf && isCurrentUserAdmin;

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[200] flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm animate-in fade-in duration-200">
            <div className="bg-white w-full max-w-md rounded-[32px] shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200 border border-white">
                <div className="p-6 pb-0 flex justify-between items-center">
                    <h3 className="text-xl font-black text-slate-900 uppercase tracking-tight">Cập nhật người dùng</h3>
                    <button onClick={onClose} className="p-2 rounded-full hover:bg-slate-50 transition-all" disabled={isLoading}>
                        <X className="w-5 h-5 text-slate-300" />
                    </button>
                </div>

                {user && (
                    <div className="p-8 pt-6">
                        <div className="mb-6 p-4 bg-slate-50 rounded-2xl">
                            <p className="text-xs font-black text-slate-400 uppercase tracking-widest mb-1">Tên người dùng</p>
                            <p className="text-sm font-bold text-slate-900">{user.profile?.fullName || 'Người dùng mới'}</p>
                            <p className="text-xs font-bold text-slate-500 mt-2">{user.email}</p>
                        </div>

                        {isEditingSelf && isCurrentUserAdmin && (
                            <div className="mb-6 p-4 bg-amber-50 border border-amber-200 rounded-2xl flex gap-3">
                                <AlertCircle className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
                                <div>
                                    <p className="text-xs font-black text-amber-700 uppercase">Bảo vệ tài khoản</p>
                                    <p className="text-xs font-bold text-amber-600 mt-1">Bạn không thể tự khóa hoặc hạ quyền tài khoản admin của chính mình.</p>
                                </div>
                            </div>
                        )}

                        <div className="space-y-4 mb-6">
                            <div>
                                <div className="flex items-center justify-between mb-2">
                                    <label className="text-xs font-black text-slate-400 uppercase tracking-widest">Trạng thái tài khoản</label>
                                    {isBannedDisabled && <Lock className="w-3.5 h-3.5 text-amber-500" />}
                                </div>
                                <select
                                    value={formData.status}
                                    onChange={handleStatusChange}
                                    className={`w-full px-4 py-3 rounded-2xl border border-slate-200 bg-white text-slate-900 font-bold focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all ${isBannedDisabled ? 'opacity-50 cursor-not-allowed' : ''
                                        }`}
                                    disabled={isLoading || isBannedDisabled}
                                >
                                    <option value="ACTIVE">Hoạt động</option>
                                    <option value="INACTIVE">Không hoạt động</option>
                                    {!isBannedDisabled && <option value="BANNED">Bị khoá</option>}
                                    {isBannedDisabled && <option value="BANNED" disabled>Bị khoá (Không thể chọn)</option>}
                                </select>
                            </div>

                            <div>
                                <div className="flex items-center justify-between mb-2">
                                    <label className="text-xs font-black text-slate-400 uppercase tracking-widest">Vai trò</label>
                                    {isRoleDisabled && <Lock className="w-3.5 h-3.5 text-amber-500" />}
                                </div>
                                <select
                                    value={formData.role}
                                    onChange={handleRoleChange}
                                    className={`w-full px-4 py-3 rounded-2xl border border-slate-200 bg-white text-slate-900 font-bold focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all ${isRoleDisabled ? 'opacity-50 cursor-not-allowed' : ''
                                        }`}
                                    disabled={isLoading || isRoleDisabled}
                                >
                                    {!isRoleDisabled && (
                                        <>
                                            <option value="USER">Người dùng</option>
                                            <option value="STAFF">Nhân viên</option>
                                            <option value="ADMIN">Quản trị viên</option>
                                        </>
                                    )}
                                    {isRoleDisabled && <option value="ADMIN">Quản trị viên (Bị khóa)</option>}
                                </select>
                            </div>
                        </div>

                        <div className="flex gap-3">
                            <Button
                                variant="outline"
                                className="flex-1 h-12 rounded-2xl font-black uppercase text-[10px] tracking-widest border-slate-100"
                                onClick={onClose}
                                disabled={isLoading}
                            >
                                Hủy bỏ
                            </Button>
                            <Button
                                className="flex-1 h-12 rounded-2xl font-black uppercase text-[10px] tracking-widest shadow-lg bg-primary hover:bg-primary/90"
                                onClick={handleSave}
                                isLoading={isLoading}
                            >
                                Lưu thay đổi
                            </Button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};
