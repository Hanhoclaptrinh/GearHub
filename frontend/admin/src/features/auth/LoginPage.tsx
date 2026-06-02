import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useNavigate } from 'react-router-dom';
import { Lock, Mail } from '../../components/ui/IconlyIcons';
import { authService } from '../../services/auth.service';
import { toast } from 'sonner';
import authBg from '../../assets/auth-bg.jpg';

const loginSchema = z.object({
  identifier: z.string().min(1, 'Email hoặc số điện thoại là bắt buộc'),
  password: z.string().min(6, 'Mật khẩu phải có ít nhất 6 ký tự'),
});

type LoginFormValues = z.infer<typeof loginSchema>;

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
    <div className="min-h-screen bg-white flex w-full font-sans overflow-x-hidden">
      <div className="grid grid-cols-1 lg:grid-cols-12 w-full min-h-screen">
        {/* Left Form Column */}
        <div className="col-span-1 lg:col-span-5 flex flex-col justify-center py-12 px-8 sm:px-16 md:px-24 lg:px-16 xl:px-24">
          <div className="w-full max-w-md mx-auto lg:mx-0">
            {/* Logo */}
            <div className="flex items-center gap-3 mb-16">
              {/* <div className="bg-primary p-2.5 rounded-xl shadow-md">
                <Package className="text-white w-6 h-6" />
              </div> */}
              <span className="text-4xl font-extrabold text-[#25396f] tracking-tight">
                GearHub <span className="text-[#f97316]">CMS</span>
              </span>
            </div>

            {/* Titles */}
            <h1 className="text-6xl font-extrabold text-[#25396f] mb-3 leading-tight tracking-tight">
              Đăng nhập
            </h1>
            <p className="text-lg font-semibold text-[#a8aebb] mb-10 leading-relaxed">
              Đăng nhập bằng thông tin tài khoản đã được cung cấp để truy cập hệ thống quản trị.
            </p>

            {/* Form */}
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
              {/* Email / Username field */}
              <div className="space-y-1">
                <div className="relative">
                  <div className="absolute left-4 top-1/2 -translate-y-1/2 text-[#7c8db5] transition-colors">
                    <Mail className="w-5 h-5" />
                  </div>
                  <input
                    type="text"
                    placeholder="Email hoặc số điện thoại"
                    className={`w-full py-4 pl-12 pr-4 border ${errors.identifier ? 'border-red-400 focus:ring-red-100' : 'border-[#dce7f1] focus:border-primary'
                      } rounded-xl text-base font-semibold text-[#607080] placeholder-[#adb5bd] outline-none transition-all focus:ring-4 focus:ring-primary/20 bg-white`}
                    {...register('identifier')}
                  />
                </div>
                {errors.identifier && (
                  <p className="text-xs font-semibold text-red-500 pl-1 mt-1">
                    {errors.identifier.message}
                  </p>
                )}
              </div>

              {/* Password field */}
              <div className="space-y-1">
                <div className="relative">
                  <div className="absolute left-4 top-1/2 -translate-y-1/2 text-[#7c8db5] transition-colors">
                    <Lock className="w-5 h-5" />
                  </div>
                  <input
                    type="password"
                    placeholder="Mật khẩu"
                    className={`w-full py-4 pl-12 pr-4 border ${errors.password ? 'border-red-400 focus:ring-red-100' : 'border-[#dce7f1] focus:border-primary'
                      } rounded-xl text-base font-semibold text-[#607080] placeholder-[#adb5bd] outline-none transition-all focus:ring-4 focus:ring-primary/20 bg-white`}
                    {...register('password')}
                  />
                </div>
                {errors.password && (
                  <p className="text-xs font-semibold text-red-500 pl-1 mt-1">
                    {errors.password.message}
                  </p>
                )}
              </div>

              {/* Remember Me */}
              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="keepLoggedIn"
                  className="w-5 h-5 border-[#e1e3ea] text-primary focus:ring-primary/20 rounded-md cursor-pointer transition-all border-2"
                />
                <label
                  htmlFor="keepLoggedIn"
                  className="ml-2.5 text-base font-semibold text-[#607080] cursor-pointer select-none"
                >
                  Duy trì đăng nhập
                </label>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                disabled={isLoading}
                className="w-full py-4 bg-primary hover:bg-[#3f5491] text-white text-lg font-bold rounded-xl shadow-lg shadow-primary/25 hover:shadow-primary/35 transition-all duration-300 transform hover:-translate-y-0.5 cursor-pointer disabled:opacity-75 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {isLoading ? 'Đang đăng nhập...' : 'Đăng nhập'}
              </button>
            </form>

            <div className="mt-12 text-base font-semibold text-[#607080]">
              <p>
                Quên mật khẩu?{' '}
                <a href="#" className="text-primary font-bold hover:underline">
                  Khôi phục ngay
                </a>
              </p>
            </div>
          </div>
        </div>

        {/* Right Graphic Column */}
        <div className="hidden lg:block lg:col-span-7 relative h-screen">
          <div
            className="absolute inset-0 animate-fade-in duration-1000"
            style={{
              background: `url(${authBg}), linear-gradient(90deg, #2d499d, #3f5491)`,
              backgroundSize: 'cover',
              backgroundPosition: 'center',
            }}
          />
        </div>
      </div>
    </div>
  );
};
