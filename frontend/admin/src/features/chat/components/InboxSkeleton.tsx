import React from 'react';

export const InboxSkeleton: React.FC = () => (
  <div className="space-y-3 p-3">
    {Array.from({ length: 8 }).map((_, index) => (
      <div key={index} className="rounded-lg bg-white/[0.04] p-4 ring-1 ring-white/5">
        <div className="flex gap-3">
          <div className="h-10 w-10 rounded-full bg-white/10 animate-pulse" />
          <div className="flex-1 space-y-3">
            <div className="h-3 w-2/3 rounded bg-white/10 animate-pulse" />
            <div className="h-3 w-full rounded bg-white/5 animate-pulse" />
            <div className="h-2 w-1/3 rounded bg-white/5 animate-pulse" />
          </div>
        </div>
      </div>
    ))}
  </div>
);
