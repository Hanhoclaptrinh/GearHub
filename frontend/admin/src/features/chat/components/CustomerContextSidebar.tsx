import React from 'react';
import { CalendarDays, Mail, Phone, ShoppingBag, UserRoundCheck } from '../../../components/ui/IconlyIcons';
import { useQuery } from '@tanstack/react-query';
import { orderService } from '../../../services/order.service';
import { cn } from '../../../utils/cn';
import type { ChatRoomSummary } from '../types';
import { formatShortTime, getDisplayName } from '../utils';
import { ChatAvatar } from './ChatAvatar';
import { RoomStatusBadge } from './RoomStatusBadge';

interface CustomerContextSidebarProps {
  room: ChatRoomSummary | null;
}

const InfoRow: React.FC<{ icon: React.ElementType; label: string; value?: string | null }> = ({ icon: Icon, label, value }) => (
  <div className="flex items-start gap-3 rounded-[8px] bg-[#fbfcff] border border-[#f2f7ff] p-3">
    <Icon className="mt-0.5 h-4 w-4 shrink-0 text-[#435ebe]" />
    <div className="min-w-0">
      <p className="text-[10px] font-extrabold uppercase tracking-widest text-[#a8b4c7]">{label}</p>
      <p className="mt-1 break-words text-[12px] font-semibold text-[#25396f]">{value || 'Không có sẵn'}</p>
    </div>
  </div>
);

const SectionTitle: React.FC<{ title: string; badge?: React.ReactNode }> = ({ title, badge }) => (
  <div className="mb-3 flex items-center justify-between">
    <h4 className="text-[10px] font-extrabold uppercase tracking-widest text-[#a8b4c7]">{title}</h4>
    {badge}
  </div>
);

const orderStatusMap: Record<string, { label: string; className: string }> = {
  PENDING: { label: 'Chờ xác nhận', className: 'bg-[#fff7e6] text-[#946200] border-[#ffe6a6]' },
  CONFIRMED: { label: 'Đã xác nhận', className: 'bg-[#f2f7ff] text-[#435ebe] border-[#dce7f1]' },
  PROCESSING: { label: 'Đang đóng gói', className: 'bg-[#f2f7ff] text-[#435ebe] border-[#dce7f1]' },
  SHIPPING: { label: 'Đang giao', className: 'bg-[#e6fdff] text-[#008c9e] border-[#a8edf5]' },
  DELIVERED: { label: 'Đã giao', className: 'bg-[#edf9f1] text-[#2f8f5b] border-[#b6e8cc]' },
  COMPLETED: { label: 'Hoàn tất', className: 'bg-[#edf9f1] text-[#2f8f5b] border-[#b6e8cc]' },
  CANCELLED: { label: 'Đã hủy', className: 'bg-red-50 text-red-600 border-red-200' },
  RETURNED: { label: 'Trả hàng', className: 'bg-red-50 text-red-600 border-red-200' },
  FAILED: { label: 'Thất bại', className: 'bg-red-50 text-red-600 border-red-200' },
};

const formatCurrency = (value: number) =>
  new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(value || 0);

export const CustomerContextSidebar: React.FC<CustomerContextSidebarProps> = ({ room }) => {
  const customer = room?.customer;
  const { data: orders, isLoading } = useQuery({
    queryKey: ['chat-customer-orders', customer?.id],
    queryFn: () => orderService.getOrders({ page: 1, limit: 3, userId: customer?.id }),
    enabled: !!customer?.id,
    staleTime: 60_000,
  });

  const recentOrders = orders?.data || [];
  const totalOrders = orders?.meta?.total ?? recentOrders.length;

  return (
    <aside className="hidden min-h-0 overflow-hidden border-l border-[#dce7f1] bg-white xl:flex xl:w-full xl:flex-col">
      {!room ? (
        /* ── Empty State ── */
        <div className="flex h-full flex-col items-center justify-center px-8 text-center gap-3">
          <div className="w-16 h-16 rounded-[14px] bg-[#f2f7ff] flex items-center justify-center">
            <Mail className="h-7 w-7 text-[#435ebe]/60" />
          </div>
          <p className="text-[13px] font-extrabold text-[#25396f]">Chi tiết khách hàng</p>
          <p className="text-[11px] font-semibold leading-relaxed text-[#7c8db5]">
            Mở một hội thoại để xem thông tin ngữ cảnh
          </p>
        </div>
      ) : (
        <>
          {/* ── Customer Hero ── */}
          <div className="shrink-0 border-b border-[#f2f7ff] bg-[#fbfcff] px-5 py-5">
            <div className="flex items-center gap-4">
              <div className="relative">
                <ChatAvatar profile={customer} size="lg" />
                {room.status === 'STAFF_ACTIVE' && (
                  <span className="absolute bottom-0 right-0 h-4 w-4 rounded-full bg-[#5ddc97] border-2 border-white" />
                )}
              </div>
              <div className="min-w-0 flex-1">
                <h3 className="truncate text-[14px] font-extrabold text-[#25396f] mb-0.5">
                  {getDisplayName(customer)}
                </h3>
                <p className="truncate text-[11px] font-semibold text-[#7c8db5] mb-2">
                  {customer?.email}
                </p>
                <RoomStatusBadge status={room.status} />
              </div>
            </div>
          </div>

          {/* ── Scrollable body ── */}
          <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain">
            <div className="p-5 space-y-6">

              {/* Profile section */}
              <section>
                <SectionTitle title="Thông tin" />
                <div className="space-y-2">
                  <InfoRow icon={Mail} label="Email" value={customer?.email} />
                  <InfoRow icon={Phone} label="Số điện thoại" value={customer?.phone} />
                  <InfoRow
                    icon={CalendarDays}
                    label="Ngày tham gia"
                    value={customer?.createdAt ? new Date(customer.createdAt).toLocaleDateString('vi-VN') : null}
                  />
                </div>
              </section>

              {/* Room section */}
              <section>
                <SectionTitle title="Hội thoại" />
                <div className="space-y-2">
                  <InfoRow
                    icon={UserRoundCheck}
                    label="Nhân viên phụ trách"
                    value={room.staff?.fullName || room.staff?.email || 'Chưa nhận'}
                  />
                  <InfoRow
                    icon={CalendarDays}
                    label="Hoạt động lần cuối"
                    value={formatShortTime(room.lastMessageAt)}
                  />
                </div>
              </section>

              {/* Orders section */}
              <section>
                <SectionTitle
                  title="Đơn hàng gần đây"
                  badge={
                    <span className="rounded-full bg-[#f2f7ff] border border-[#dce7f1] px-2.5 py-0.5 text-[10px] font-extrabold text-[#435ebe]">
                      {isLoading ? '...' : totalOrders}
                    </span>
                  }
                />

                {isLoading ? (
                  <div className="space-y-2">
                    {Array.from({ length: 3 }).map((_, i) => (
                      <div key={i} className="h-[68px] rounded-[8px] bg-[#f2f7ff] animate-pulse" />
                    ))}
                  </div>
                ) : recentOrders.length > 0 ? (
                  <div className="space-y-2">
                    {recentOrders.map((order: any) => {
                      const statusInfo = orderStatusMap[order.status] || { label: order.status, className: 'bg-slate-100 text-slate-600 border-slate-200' };
                      return (
                        <div key={order.id} className="rounded-[8px] bg-[#fbfcff] border border-[#f2f7ff] p-3 space-y-2">
                          <div className="flex items-start justify-between gap-2">
                            <p className="text-[11px] font-extrabold text-[#25396f] truncate">
                              #{order.orderNumber || order.id.slice(-8).toUpperCase()}
                            </p>
                            <span className={cn(
                              'shrink-0 rounded-[4px] border px-2 py-0.5 text-[9px] font-extrabold uppercase',
                              statusInfo.className
                            )}>
                              {statusInfo.label}
                            </span>
                          </div>
                          <div className="flex items-center justify-between">
                            <p className="text-[10px] font-semibold text-[#a8b4c7]">
                              {new Date(order.createdAt).toLocaleDateString('vi-VN')}
                            </p>
                            {order.totalAmount && (
                              <p className="text-[11px] font-extrabold text-[#25396f]">
                                {formatCurrency(order.totalAmount)}
                              </p>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <div className="rounded-[8px] bg-[#fbfcff] border border-[#f2f7ff] p-5 text-center">
                    <ShoppingBag className="mx-auto h-6 w-6 text-[#a8b4c7] mb-2" />
                    <p className="text-[11px] font-semibold text-[#7c8db5]">Chưa có đơn hàng nào</p>
                  </div>
                )}
              </section>

            </div>
          </div>
        </>
      )}
    </aside>
  );
};
