import React from 'react';
import { CheckCircle2, Clock3, Lock, Radio } from 'lucide-react';
import { cn } from '../../../utils/cn';
import type { RoomStatus } from '../types';
import { getRoomStatusLabel } from '../utils';

interface RoomStatusBadgeProps {
  status: RoomStatus;
}

export const RoomStatusBadge: React.FC<RoomStatusBadgeProps> = ({ status }) => {
  const Icon = status === 'CLOSED' ? Lock : status === 'STAFF_ACTIVE' ? Radio : status === 'NEED_HUMAN' ? Clock3 : CheckCircle2;

  return (
    <span className={cn(
      'inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[10px] font-black uppercase tracking-wide ring-1',
      status === 'CLOSED' && 'bg-slate-800 text-slate-300 ring-slate-700',
      status === 'STAFF_ACTIVE' && 'bg-emerald-400/10 text-emerald-200 ring-emerald-300/20',
      status === 'NEED_HUMAN' && 'bg-amber-400/10 text-amber-200 ring-amber-300/20',
      status === 'BOT_ONLY' && 'bg-sky-400/10 text-sky-200 ring-sky-300/20'
    )}>
      <Icon className="h-3 w-3" />
      {getRoomStatusLabel(status)}
    </span>
  );
};
