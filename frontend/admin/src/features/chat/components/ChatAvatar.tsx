import React from 'react';
import { cn } from '../../../utils/cn';
import type { ChatProfile } from '../types';
import { getInitials } from '../utils';

interface ChatAvatarProps {
  profile?: ChatProfile | null;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export const ChatAvatar: React.FC<ChatAvatarProps> = ({ profile, size = 'md', className }) => {
  const sizes = {
    sm: 'h-8 w-8 text-[10px]',
    md: 'h-10 w-10 text-xs',
    lg: 'h-16 w-16 text-lg',
  };

  if (profile?.avatarUrl) {
    return (
      <img
        src={profile.avatarUrl}
        alt={profile.fullName || profile.email}
        className={cn('shrink-0 rounded-full object-cover ring-1 ring-white/10', sizes[size], className)}
      />
    );
  }

  return (
    <div className={cn(
      'shrink-0 rounded-full bg-gradient-to-br from-cyan-300 to-emerald-300 text-slate-950 font-black flex items-center justify-center ring-1 ring-white/20',
      sizes[size],
      className
    )}>
      {getInitials(profile)}
    </div>
  );
};
