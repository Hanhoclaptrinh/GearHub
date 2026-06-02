import React, { useState, useEffect } from 'react';
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
  CreditCard,
  MessageSquareText,
  Ticket,
  Star,
  History
} from '../components/ui/IconlyIcons';
import { Warehouse } from '../components/ui/IconlyIcons';
import { cn } from '../utils/cn';
import { authService } from '../services/auth.service';

const navigation = [
  { name: 'Dashboard', icon: LayoutDashboard, path: '/', roles: ['ADMIN', 'STAFF'] },
  { name: 'Quản lý tin nhắn', icon: MessageSquareText, path: '/chat', roles: ['ADMIN', 'STAFF'] },
  { name: 'Quản lý sản phẩm', icon: Package, path: '/products', roles: ['ADMIN', 'STAFF'] },
  { name: 'Quản lý kho hàng', icon: Warehouse, path: '/inventory', roles: ['ADMIN', 'STAFF'] },
  { name: 'Quản lý đơn hàng', icon: ShoppingCart, path: '/orders', roles: ['ADMIN', 'STAFF'] },
  { name: 'Quản lý đánh giá', icon: Star, path: '/reviews', roles: ['ADMIN', 'STAFF'] },
  {
    name: 'Quản trị nhân sự',
    icon: Users,
    path: '/users-management',
    roles: ['ADMIN'],
    children: [
      { name: 'Khách hàng', path: '/users' },
      { name: 'Nhân viên', path: '/staff' },
    ]
  },
  { name: 'Quản lý danh mục', icon: Tag, path: '/categories', roles: ['ADMIN', 'STAFF'] },
  { name: 'Quản lý thương hiệu', icon: Briefcase, path: '/brands', roles: ['ADMIN', 'STAFF'] },
  { name: 'Quản lý ưu đãi', icon: Ticket, path: '/vouchers', roles: ['ADMIN', 'STAFF'] },
  { name: 'Quản lý giao dịch', icon: CreditCard, path: '/transactions', roles: ['ADMIN'] },
  { name: 'Lịch sử hoạt động', icon: History, path: '/activity-logs', roles: ['ADMIN'] },
];

const getPageTitle = (pathname: string) => {
  if (pathname === '/') return 'Dashboard';

  for (const item of navigation) {
    if (item.path !== '/' && (pathname === item.path || pathname.startsWith(`${item.path}/`))) {
      return item.name;
    }

    if (item.children?.some(child => pathname === child.path || pathname.startsWith(`${child.path}/`))) {
      return item.name;
    }
  }

  return 'Dashboard';
};

export const DashboardLayout: React.FC = () => {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const location = useLocation();

  const { data: user } = useQuery({
    queryKey: ['me'],
    queryFn: () => authService.getMe(),
    initialData: authService.getCurrentUser() || undefined,
    staleTime: Infinity,
  });

  const [openMenus, setOpenMenus] = useState<string[]>([]);

  useEffect(() => {
    navigation.forEach(item => {
      if (item.children?.some(c => location.pathname === c.path)) {
        if (!openMenus.includes(item.name)) {
          setOpenMenus(prev => [...prev, item.name]);
        }
      }
    });
  }, [location.pathname]);

  const toggleMenu = (name: string) => {
    setOpenMenus(prev =>
      prev.includes(name) ? prev.filter(m => m !== name) : [...prev, name]
    );
  };

  return (
    <div className="h-screen overflow-hidden bg-[#f2f7ff] flex font-sans">
      {/* Mobile Sidebar Overlay */}
      {isSidebarOpen && (
        <div
          className="fixed inset-0 bg-slate-900/30 backdrop-blur-xs z-40 xl:hidden"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 w-[300px] bg-white border-r border-[#f2f7ff] z-50 transform transition-transform duration-300 xl:relative xl:translate-x-0 shadow-sm flex flex-col",
          !isSidebarOpen && "-translate-x-full"
        )}
      >
        {/* Sidebar Header */}
        <div className="py-8 px-6 flex items-center justify-between">
          <div className="flex items-center gap-3">
            {/* <div className="bg-primary p-2.5 rounded-xl shadow-md">
              <Package className="text-white w-6 h-6" />
            </div> */}
            <span className="text-2xl font-extrabold text-[#25396f] tracking-tight">
              GearHub <span className="text-[#f97316]">Admin</span>
            </span>
          </div>
          <button
            className="xl:hidden p-1 text-[#25396f] hover:bg-[#f2f7ff] rounded-lg transition-colors"
            onClick={() => setIsSidebarOpen(false)}
          >
            <ChevronRight className="w-6 h-6 rotate-180" />
          </button>
        </div>

        {/* Sidebar Menu */}
        <nav className="flex-1 min-h-0 px-6 pb-6 overflow-y-auto overscroll-contain custom-scrollbar">
          <ul className="space-y-1 list-none p-0 m-0">
            {/* Main Menu Header */}
            <li className="text-base font-semibold text-[#25396f]/80 px-4 mt-6 mb-3 list-none">
              Menu chính
            </li>

            {navigation
              .filter(item => item.roles.includes(user?.role || ''))
              .map((item, index) => {
                const hasChildren = item.children && item.children.length > 0;
                const isOpen = openMenus.includes(item.name);
                const isActive = location.pathname === item.path || (hasChildren && item.children?.some(c => location.pathname === c.path));

                // Add System Header before Quản lý giao dịch
                const showSystemHeader = item.path === '/transactions' || item.path === '/activity-logs';
                const prevItem = index > 0 ? navigation.filter(i => i.roles.includes(user?.role || ''))[index - 1] : null;
                const renderSystemHeader = showSystemHeader && prevItem && prevItem.path !== '/transactions' && prevItem.path !== '/activity-logs';

                return (
                  <React.Fragment key={item.name}>
                    {renderSystemHeader && (
                      <li className="text-base font-semibold text-[#25396f]/80 px-4 mt-6 mb-3 list-none">
                        Hệ thống
                      </li>
                    )}

                    <li className="list-none">
                      {hasChildren ? (
                        <div className="space-y-1">
                          <button
                            onClick={() => toggleMenu(item.name)}
                            className={cn(
                              "w-full flex items-center gap-4 px-4 py-3 rounded-xl text-base font-semibold transition-all duration-300 group relative",
                              isActive
                                ? "bg-primary text-white shadow-md shadow-primary/10 font-bold"
                                : "text-[#25396f] hover:bg-[#f0f1f5]"
                            )}
                          >
                            <item.icon className={cn("w-5 h-5", isActive ? "text-white" : "text-[#7c8db5] group-hover:text-[#25396f]")} />
                            <span className="flex-1 text-left">{item.name}</span>
                            <ChevronRight className={cn("w-4 h-4 transition-transform duration-400", isOpen && "rotate-90", isActive ? "text-white" : "text-[#7c8db5]")} />
                          </button>

                          <ul className={cn(
                            "space-y-1 mt-1 list-none p-0 overflow-hidden transition-all duration-300 ease-in-out",
                            isOpen ? "max-h-[500px] opacity-100" : "max-h-0 opacity-0"
                          )}>
                            {item.children?.map(child => {
                              const isChildActive = location.pathname === child.path;
                              return (
                                <li key={child.path} className="list-none">
                                  <NavLink
                                    to={child.path}
                                    className={cn(
                                      "block pl-12 pr-4 py-2.5 rounded-xl text-[0.9rem] transition-all duration-300",
                                      isChildActive
                                        ? "text-primary font-bold"
                                        : "text-[#25396f] font-semibold hover:translate-x-1.5 hover:text-primary"
                                    )}
                                  >
                                    {child.name}
                                  </NavLink>
                                </li>
                              );
                            })}
                          </ul>
                        </div>
                      ) : (
                        <NavLink
                          to={item.path}
                          className={cn(
                            "flex items-center gap-4 px-4 py-3 rounded-xl text-base font-semibold transition-all duration-300 group relative",
                            isActive
                              ? "bg-primary text-white shadow-md shadow-primary/10 font-bold"
                              : "text-[#25396f] hover:bg-[#f0f1f5]"
                          )}
                        >
                          <item.icon className={cn("w-5 h-5", isActive ? "text-white" : "text-[#7c8db5] group-hover:text-[#25396f]")} />
                          <span>{item.name}</span>
                        </NavLink>
                      )}
                    </li>
                  </React.Fragment>
                );
              })}
          </ul>
        </nav>

        {/* Sidebar Footer (Logout) */}
        <div className="p-6 border-t border-[#f2f7ff]">
          <button
            onClick={() => authService.logout()}
            className="w-full flex items-center gap-4 px-4 py-3 rounded-xl text-base font-bold text-red-500 hover:bg-red-50 transition-all duration-300 group"
          >
            <LogOut className="w-5 h-5 group-hover:-translate-x-1" />
            Đăng xuất
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 min-w-0 h-screen flex flex-col overflow-hidden xl:absolute xl:inset-y-0 xl:right-0 xl:left-0 xl:pl-[300px]">
        {/* Top Header (Mobile Only) */}
        <header className="h-16 bg-white border-b border-[#f2f7ff] px-6 flex items-center xl:hidden sticky top-0 z-30">
          <button
            className="p-2 -ml-2 rounded-lg hover:bg-[#f2f7ff] text-[#25396f] transition-colors"
            onClick={() => setIsSidebarOpen(true)}
          >
            <Menu className="w-6 h-6" />
          </button>
        </header>

        {/* Dynamic Page Content Wrapper */}
        <main className="flex-1 min-h-0 overflow-y-auto overscroll-contain overflow-x-hidden custom-scrollbar">
          <div className="max-w-[1600px] w-full mx-auto p-6 lg:p-8">
            {/* Mazer page-heading */}
            <div className="mb-6">
              <h3 className="text-[28px] font-bold text-[#25396f] tracking-tight">
                {getPageTitle(location.pathname)}
              </h3>
            </div>
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
};
