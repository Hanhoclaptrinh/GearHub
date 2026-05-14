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
import { authService } from './services/auth.service';

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

import { Toaster } from 'sonner';

const App: React.FC = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <Toaster
        position="top-right"
        richColors
        closeButton
        theme="light"
        expand={true}
        toastOptions={{
          style: {
            borderRadius: '12px',
            padding: '16px 24px',
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
            <Route path="inventory" element={<InventoryPage />} />
            <Route path="orders" element={<OrderList />} />
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
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
};

export default App;
