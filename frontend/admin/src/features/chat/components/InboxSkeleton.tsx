import React from 'react';

export const InboxSkeleton: React.FC = () => (
  <div className="space-y-1.5 p-0">
    {Array.from({ length: 7 }).map((_, index) => (
      <div key={index} className="rounded-[10px] bg-white border border-[#f2f7ff] p-4">
        <div className="flex gap-3">
          <div className="h-10 w-10 rounded-full bg-[#dce7f1] animate-pulse shrink-0" />
          <div className="flex-1 space-y-2.5 pt-0.5">
            <div className="flex justify-between gap-4">
              <div className="h-3 w-1/2 rounded-[4px] bg-[#dce7f1] animate-pulse" />
              <div className="h-2.5 w-12 rounded-[4px] bg-[#f2f7ff] animate-pulse" />
            </div>
            <div className="h-2.5 w-2/3 rounded-[4px] bg-[#f2f7ff] animate-pulse" />
            <div className="h-2.5 w-full rounded-[4px] bg-[#f2f7ff] animate-pulse" />
          </div>
        </div>
      </div>
    ))}
  </div>
);
