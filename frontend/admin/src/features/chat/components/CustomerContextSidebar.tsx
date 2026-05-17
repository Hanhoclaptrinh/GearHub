import React from 'react';
import { CalendarDays, Mail, PackageCheck, Phone, ShoppingBag, UserRound, UserRoundCheck } from 'lucide-react';
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
  <div className="flex items-start gap-3 rounded-lg bg-white/[0.04] p-3 ring-1 ring-white/5">
    <Icon className="mt-0.5 h-4 w-4 shrink-0 text-slate-500" />
    <div className="min-w-0">
      <p className="text-[10px] font-black uppercase tracking-wide text-slate-500">{label}</p>
      <p className="mt-1 break-words text-xs font-bold text-slate-200">{value || 'Không có sẵn'}</p>
    </div>
  </div>
);

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
    <aside className="hidden min-h-0 border-l border-white/10 bg-slate-950/80 xl:flex xl:w-[320px] xl:flex-col">
      {!room ? (
        <div className="flex h-full flex-col items-center justify-center px-8 text-center">
          <UserRound className="h-10 w-10 text-slate-600" />
          <p className="mt-4 text-sm font-black text-white">Chi tiết ngữ cảnh</p>
          <p className="mt-1 text-xs font-semibold leading-relaxed text-slate-500">Mở một đoạn chat để xem chi tiết ngữ cảnh khách hàng</p>
        </div>
      ) : (
        <>
          <div className="border-b border-white/10 p-5">
            <div className="flex items-center gap-4">
              <ChatAvatar profile={customer} size="lg" />
              <div className="min-w-0">
                <h3 className="truncate text-base font-black uppercase text-white">{getDisplayName(customer)}</h3>
                <p className="truncate text-xs font-semibold text-slate-500">{customer?.email}</p>
              </div>
            </div>
          </div>

          <div className="min-h-0 flex-1 space-y-5 overflow-y-auto p-5">
            <section>
              <div className="mb-3 flex items-center justify-between">
                <h4 className="text-xs font-black uppercase tracking-widest text-slate-500">Hồ sơ</h4>
              </div>
              <div className="space-y-2">
                <InfoRow icon={Mail} label="Email" value={customer?.email} />
                <InfoRow icon={Phone} label="Số điện thoại" value={customer?.phone} />
                <InfoRow icon={CalendarDays} label="Đã tham gia vào" value={customer?.createdAt ? new Date(customer.createdAt).toLocaleDateString('vi-VN') : null} />
              </div>
            </section>

            <section>
              <h4 className="mb-3 text-xs font-black uppercase tracking-widest text-slate-500">Phòng</h4>
              <div className="space-y-2">
                <div className="rounded-lg bg-white/[0.04] p-3 ring-1 ring-white/5">
                  <p className="text-[10px] font-black uppercase tracking-wide text-slate-500">Trạng thái</p>
                  <div className="mt-2"><RoomStatusBadge status={room.status} /></div>
                </div>
                <InfoRow icon={UserRoundCheck} label="Nhân viên trực tuyến" value={room.staff?.fullName || room.staff?.email || 'Unclaimed'} />
                <InfoRow icon={PackageCheck} label="Hoạt động lần cuối" value={formatShortTime(room.lastMessageAt)} />
              </div>
            </section>

            <section>
              <div className="mb-3 flex items-center justify-between">
                <h4 className="text-xs font-black uppercase tracking-widest text-slate-500">Đơn hàng đã mua</h4>
                <span className="rounded-full bg-white/[0.06] px-2 py-1 text-[10px] font-black text-slate-300 ring-1 ring-white/10">
                  {isLoading ? '...' : totalOrders}
                </span>
              </div>
              <div className="space-y-2">
                {isLoading ? (
                  Array.from({ length: 3 }).map((_, index) => (
                    <div key={index} className="h-16 rounded-lg bg-white/[0.04] ring-1 ring-white/5 animate-pulse" />
                  ))
                ) : recentOrders.length > 0 ? (
                  recentOrders.map((order: any) => (
                    <div key={order.id} className="rounded-lg bg-white/[0.04] p-3 ring-1 ring-white/5">
                      <div className="flex items-center justify-between gap-2">
                        <p className="truncate text-xs font-black text-white">{order.id}</p>
                        <span className={cn(
                          'rounded-full px-2 py-0.5 text-[9px] font-black uppercase',
                          order.status === 'DELIVERED' ? 'bg-emerald-400/10 text-emerald-200' : 'bg-white/[0.06] text-slate-300'
                        )}>
                          {order.status}
                        </span>
                      </div>
                      <p className="mt-2 text-[10px] font-bold text-slate-500">
                        {new Date(order.createdAt).toLocaleDateString('vi-VN')}
                      </p>
                    </div>
                  ))
                ) : (
                  <div className="rounded-lg bg-white/[0.04] p-5 text-center ring-1 ring-white/5">
                    <ShoppingBag className="mx-auto h-6 w-6 text-slate-600" />
                    <p className="mt-2 text-xs font-bold text-slate-500">Không có đơn hàng nào</p>
                  </div>
                )}
              </div>
            </section>

            <section>
              <h4 className="mb-3 text-xs font-black uppercase tracking-widest text-slate-500">Sản phẩm đã xem</h4>
              <div className="rounded-lg bg-white/[0.04] p-5 text-center ring-1 ring-white/5">
                <p className="text-xs font-bold text-slate-500">Không có sản phẩm nào đã xem gần đây</p>
              </div>
            </section>
          </div>
        </>
      )}
    </aside>
  );
};
