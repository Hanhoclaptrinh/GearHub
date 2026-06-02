import React from 'react';
import { CheckCircle2, Clock3, Lock, Radio } from '../../../components/ui/IconlyIcons';
import { cn } from '../../../utils/cn';
import type { RoomStatus } from '../types';
import { getRoomStatusLabel } from '../utils';

interface RoomStatusBadgeProps {
  status: RoomStatus;
}

export const RoomStatusBadge: React.FC<RoomStatusBadgeProps> = ({ status }) => {
  const Icon =
    status === 'CLOSED' ? Lock
    : status === 'STAFF_ACTIVE' ? Radio
    : status === 'NEED_HUMAN' ? Clock3
    : CheckCircle2;

  return (
    <span className={cn(
      'inline-flex items-center gap-1.5 rounded-[6px] px-2.5 py-1 text-[10px] font-extrabold uppercase tracking-wide border',
      status === 'CLOSED' && 'bg-slate-50 text-[#607080] border-[#dce7f1]',
      status === 'STAFF_ACTIVE' && 'bg-[#edf9f1] text-[#2f8f5b] border-[#b6e8cc]',
      status === 'NEED_HUMAN' && 'bg-[#fff7e6] text-[#946200] border-[#ffe6a6]',
      status === 'BOT_ONLY' && 'bg-[#f2f7ff] text-[#435ebe] border-[#dce7f1]',
    )}>
      <Icon className="h-3 w-3" />
      {getRoomStatusLabel(status)}
    </span>
  );
};
