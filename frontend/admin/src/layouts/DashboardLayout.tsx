import React, { useState } from 'react';
import { NavLink, Outlet, useLocation } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  LayoutDashboard,
  Package,
  ShoppingCart,
  Users,
  Tag,
  Briefcase,
  LogOut,
  Menu,
  ChevronRight,
  User as UserIcon,
  Globe,
  CreditCard
} from 'lucide-react';
import { cn } from '../utils/cn';
import { authService } from '../services/auth.service';

const navigation = [
  { name: 'Dashboard', icon: LayoutDashboard, path: '/' },
  { name: 'Sản phẩm', icon: Package, path: '/products' },
  { name: 'Đơn hàng', icon: ShoppingCart, path: '/orders' },
  { name: 'Người dùng', icon: Users, path: '/users' },
  { name: 'Danh mục', icon: Tag, path: '/categories' },
  { name: 'Thương hiệu', icon: Briefcase, path: '/brands' },
  { name: 'Giao dịch', icon: CreditCard, path: '/transactions' },
];

export const DashboardLayout: React.FC = () => {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [currentLang, setCurrentLang] = useState('VN');
  const [showLangDropdown, setShowLangDropdown] = useState(false);
  const location = useLocation();

  const { data: user } = useQuery({
    queryKey: ['me'],
    queryFn: () => authService.getMe(),
    initialData: authService.getCurrentUser() || undefined,
    staleTime: Infinity,
  });

  return (
    <div className="min-h-screen bg-slate-50 flex">
      {/* Mobile Sidebar Overlay */}
      {isSidebarOpen && (
        <div
          className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-40 lg:hidden"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 w-72 bg-white border-r border-slate-200 z-50 transform transition-transform duration-300 lg:relative lg:translate-x-0",
          !isSidebarOpen && "-translate-x-full"
        )}
      >
        <div className="h-full flex flex-col p-6">
          <div className="flex items-center gap-3 px-4 mb-10">
            <div className="bg-primary p-2 rounded-xl shadow-lg shadow-primary/20">
              <Package className="text-white w-6 h-6" />
            </div>
            <span className="text-xl font-bold font-heading text-slate-800 uppercase tracking-tight">GearHub <span className="text-cta">Admin</span></span>
          </div>

          <nav className="flex-1 space-y-2">
            {navigation.map((item) => {
              const isActive = location.pathname === item.path;
              return (
                <NavLink
                  key={item.name}
                  to={item.path}
                  className={({ isActive }) => cn(
                    "flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-semibold transition-all duration-200 group relative",
                    isActive
                      ? "bg-primary text-white shadow-lg shadow-primary/20"
                      : "text-slate-500 hover:bg-slate-100/80 hover:text-slate-800"
                  )}
                >
                  <item.icon className={cn("w-5 h-5", !isActive && "text-slate-400 group-hover:rotate-6")} />
                  {item.name}
                  {isActive && <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-6 bg-cta rounded-full" />}
                  <ChevronRight className={cn("ml-auto w-4 h-4 opacity-0 group-hover:opacity-100 transition-opacity", isActive && "opacity-100")} />
                </NavLink>
              );
            })}
          </nav>

          <div className="mt-auto pt-6 border-t border-slate-100">
            <button
              onClick={() => authService.logout()}
              className="w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-semibold text-red-500 hover:bg-red-50 transition-all duration-200 group"
            >
              <LogOut className="w-5 h-5 group-hover:-translate-x-1" />
              Đăng xuất
            </button>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <div className="flex-1 flex flex-col overflow-x-hidden">
        {/* Topbar */}
        <header className="sticky top-0 h-20 bg-white/80 backdrop-blur-md border-b border-slate-200 z-30 px-6 lg:px-10 flex items-center justify-between">
          <button
            className="p-2 -ml-2 rounded-lg hover:bg-slate-100 lg:hidden"
            onClick={() => setIsSidebarOpen(true)}
          >
            <Menu className="w-6 h-6 text-slate-600" />
          </button>

          <div className="lg:block hidden">
            <h2 className="text-xl font-bold text-slate-800 capitalize">
              {navigation.find(n => n.path === location.pathname)?.name || 'Dashboard'}
            </h2>
          </div>

          <div className="flex items-center gap-6">
            {/* Language Switcher */}
            <div className="relative">
              <button
                onClick={() => setShowLangDropdown(!showLangDropdown)}
                className="flex items-center gap-2 px-3 py-2 rounded-xl bg-slate-50 border border-slate-100 hover:border-primary transition-all text-sm font-black text-slate-700"
              >
                <Globe className="w-4 h-4 text-slate-400" />
                <span>{currentLang}</span>
              </button>

              {showLangDropdown && (
                <div className="absolute top-full right-0 mt-2 w-24 bg-white border border-slate-100 rounded-2xl shadow-xl p-2 z-[100] animate-in fade-in zoom-in-95 duration-200">
                  {['VN', 'EN', 'CN'].map((lang) => (
                    <button
                      key={lang}
                      onClick={() => {
                        setCurrentLang(lang);
                        setShowLangDropdown(false);
                      }}
                      className={cn(
                        "w-full text-left px-3 py-2 rounded-xl text-xs font-bold transition-all",
                        currentLang === lang ? "bg-primary text-white" : "text-slate-500 hover:bg-slate-50"
                      )}
                    >
                      {lang === 'VN' ? 'Vietnam' : lang === 'EN' ? 'English' : 'Chinese'}
                    </button>
                  ))}
                </div>
              )}
            </div>

            <div className="text-right hidden sm:block">
              <p className="text-sm font-bold text-slate-900">{user?.fullName || (user as any)?.profile?.fullName || 'Administrator'}</p>
              <p className="text-xs font-medium text-slate-500">{user?.email}</p>
            </div>
            <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center p-0.5 border-2 border-slate-200">
              {user?.avatarUrl || (user as any)?.profile?.avatarUrl ? (
                <img src={user?.avatarUrl || (user as any)?.profile?.avatarUrl} alt="avatar" className="w-full h-full rounded-full object-cover" />
              ) : (
                <UserIcon className="w-6 h-6 text-slate-400" />
              )}
            </div>
          </div>
        </header>

        {/* Dynamic Page Content */}
        <main className="flex-1 p-6 lg:p-10 max-w-[1600px] mx-auto w-full">
          <Outlet />
        </main>
      </div>
    </div>
  );
};
