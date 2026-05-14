import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useNavigate } from 'react-router-dom';
import { Package, Lock, Mail, ArrowRight } from 'lucide-react';
import { Input } from '../../components/ui/Input';
import { Button } from '../../components/ui/Button';
import { authService } from '../../services/auth.service';

const loginSchema = z.object({
  identifier: z.string().min(1, 'Email hoặc số điện thoại là bắt buộc'),
  password: z.string().min(6, 'Mật khẩu phải có ít nhất 6 ký tự'),
});

type LoginFormValues = z.infer<typeof loginSchema>;

import { toast } from 'sonner';

export const LoginPage: React.FC = () => {
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = async (values: LoginFormValues) => {
    setIsLoading(true);
    try {
      await authService.login(values.identifier, values.password);
      toast.success('Chào mừng quay trở lại!');
      navigate('/');
    } catch (err: any) {
      toast.error(err.response?.data?.message || err.message || 'Đăng nhập thất bại. Vui lòng thử lại.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center p-6 bg-[radial-gradient(circle_at_top_right,_var(--tw-gradient-from),_var(--tw-gradient-to))] from-primary/5 via-transparent to-transparent">
      <div className="w-full max-w-md">
        <div className="text-center mb-10">
          <div className="inline-flex items-center justify-center p-4 bg-primary rounded-2xl shadow-xl shadow-primary/20 mb-6 group transition-transform hover:scale-105 duration-300">
            <Package className="text-white w-10 h-10 group-hover:rotate-6 transition-transform" />
          </div>
          <h1 className="text-3xl font-bold text-slate-900 mb-2 font-heading tracking-tight">GearHub <span className="text-cta">CMS</span></h1>
          <p className="text-slate-500 font-medium">Hệ thống quản lý dành cho quản trị và nhân viên</p>
        </div>

        <div className="bg-white p-8 rounded-3xl shadow-xl border border-slate-100 relative overflow-hidden group">
          <div className="absolute top-0 right-0 w-32 h-32 bg-primary/5 rounded-full -mr-16 -mt-16 blur-2xl group-hover:bg-primary/10 transition-colors" />

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6 relative z-10">
            <div className="relative group/field">
              <div className="absolute left-4 top-[42px] z-10 text-slate-400 group-focus-within/field:text-primary transition-colors">
                <Mail className="w-5 h-5" />
              </div>
              <Input
                label="Email / Số điện thoại"
                placeholder="admin@gearhub.com"
                className="pl-12"
                {...register('identifier')}
                error={errors.identifier?.message}
              />
            </div>

            <div className="relative group/field">
              <div className="absolute left-4 top-[42px] z-10 text-slate-400 group-focus-within/field:text-primary transition-colors">
                <Lock className="w-5 h-5" />
              </div>
              <Input
                label="Mật khẩu"
                type="password"
                placeholder="••••••••"
                className="pl-12"
                {...register('password')}
                error={errors.password?.message}
              />
            </div>

            <div className="pt-2">
              <Button
                type="submit"
                className="w-full py-4 text-base rounded-xl group/btn overflow-hidden relative"
                isLoading={isLoading}
              >
                Đăng nhập
                <ArrowRight className="ml-2 w-5 h-5 group-hover:translate-x-2 transition-transform h-min" />
              </Button>
            </div>
          </form>
        </div>

        <p className="mt-8 text-center text-slate-400 text-sm font-medium">
          &copy; 2026 GearHub Management System. All rights reserved.
        </p>
      </div>
    </div>
  );
};
