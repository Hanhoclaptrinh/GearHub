import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { LoginPage } from './features/auth/LoginPage';
import { DashboardLayout } from './layouts/DashboardLayout';
import { DashboardPage } from './features/dashboard/DashboardPage';
import { ProductList } from './features/products/ProductList';
import { ProductPage } from './features/products/ProductPage';
import { OrderList } from './features/orders/OrderList';
import { UserList } from './features/users/UserList';
import { UserDetailPage } from './features/users/UserDetailPage';
import { CategoryList } from './features/categories/CategoryList';
import { BrandList } from './features/brands/BrandList';
import { TransactionList } from './features/transactions/TransactionList';
import { InventoryPage } from './features/inventory/InventoryPage';
import { ChatCenterPage } from './features/chat/ChatCenterPage';
import { authService } from './services/auth.service';
import { VoucherList } from './features/vouchers/VoucherList';
import { ReviewList } from './features/reviews/ReviewList';
import { ActivityLogList } from './features/activity-logs/ActivityLogList';
import { FlashSaleList } from './features/products/FlashSaleList';
import { Toaster } from 'sonner';


const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

const ProtectedRoute: React.FC<{
  children: React.ReactNode;
  allowedRoles?: string[];
}> = ({ children, allowedRoles }) => {
  if (!authService.isAuthenticated()) {
    return <Navigate to="/login" replace />;
  }

  const user = authService.getCurrentUser();
  if (allowedRoles && user && !allowedRoles.includes(user.role)) {
    return <Navigate to="/" replace />;
  }

  return <>{children}</>;
};

const mazerToastClassNames = {
  toast: '!rounded-[5px] !border-0 !px-4 !py-3 !font-body !text-white !shadow-[0_10px_25px_rgba(25,42,70,0.14)]',
  success: '!bg-[#4fbe87] !text-white',
  error: '!bg-[#f3616d] !text-white',
  warning: '!bg-[#eaca4a] !text-white',
  info: '!bg-[#56b6f7] !text-white',
  loading: '!bg-[#435ebe] !text-white',
  default: '!bg-[#435ebe] !text-white',
  title: '!font-semibold !text-white',
  description: '!text-white/85',
  icon: '!text-white',
  actionButton: '!bg-white/20 !text-white hover:!bg-white/30',
  cancelButton: '!bg-white/10 !text-white hover:!bg-white/20',
};

const App: React.FC = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <Toaster
        position="bottom-right"
        richColors
        closeButton
        theme="light"
        expand={true}
        duration={3000}
        mobileOffset={{ bottom: 16, right: 16, left: 16 }}
        offset={{ bottom: 24, right: 24 }}
        toastOptions={{
          classNames: mazerToastClassNames,
          style: {
            border: 'none',
            boxShadow: '0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)'
          },
        }}
      />
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />

          <Route
            path="/"
            element={
              <ProtectedRoute allowedRoles={['ADMIN', 'STAFF']}>
                <DashboardLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<DashboardPage />} />
            <Route path="products" element={<ProductList />} />
            <Route path="products/create" element={<ProductPage />} />
            <Route path="products/edit/:slug" element={<ProductPage />} />
            <Route path="flash-sales" element={<FlashSaleList />} />
            <Route path="inventory" element={<InventoryPage />} />
            <Route path="orders" element={<OrderList />} />
            <Route path="chat" element={<ChatCenterPage />} />
            <Route
              path="users"
              element={
                <ProtectedRoute allowedRoles={['ADMIN']}>
                  <UserList initialRole="USER" />
                </ProtectedRoute>
              }
            />
            <Route
              path="users/:id"
              element={
                <ProtectedRoute allowedRoles={['ADMIN']}>
                  <UserDetailPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="staff"
              element={
                <ProtectedRoute allowedRoles={['ADMIN']}>
                  <UserList initialRole="STAFF" />
                </ProtectedRoute>
              }
            />
            <Route
              path="staff/:id"
              element={
                <ProtectedRoute allowedRoles={['ADMIN']}>
                  <UserDetailPage />
                </ProtectedRoute>
              }
            />
            <Route path="categories" element={<CategoryList />} />
            <Route path="brands" element={<BrandList />} />
            <Route
              path="transactions"
              element={
                <ProtectedRoute allowedRoles={['ADMIN']}>
                  <TransactionList />
                </ProtectedRoute>
              }
            />
            <Route
              path="activity-logs"
              element={
                <ProtectedRoute allowedRoles={['ADMIN']}>
                  <ActivityLogList />
                </ProtectedRoute>
              }
            />
            <Route path="vouchers" element={<VoucherList />} />
            <Route
              path="reviews"
              element={
                <ProtectedRoute allowedRoles={['ADMIN', 'STAFF']}>
                  <ReviewList />
                </ProtectedRoute>
              }
            />
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
};

export default App;
