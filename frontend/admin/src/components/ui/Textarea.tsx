import React, { forwardRef } from 'react';
import { cn } from '../../utils/cn';

interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string;
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ className, label, error, ...props }, ref) => {
    return (
      <div className="flex flex-col gap-1.5 w-full relative">
        {label && (
          <label className="text-sm font-semibold text-slate-700 ml-1">
            {label}
          </label>
        )}
        <textarea
          ref={ref}
          className={cn(
            'px-4 py-3 border border-slate-200 rounded-lg text-base transition-all duration-200 outline-none w-full bg-white min-h-[100px] resize-none',
            'focus:border-primary focus:ring-3 focus:ring-primary/20',
            error ? 'border-red-400 focus:border-red-500 focus:ring-red-100' : null,
            className
          )}
          {...props}
        />
        {error && (
          <span className="text-xs font-medium text-red-500 ml-1 mt-0.5">
            {error}
          </span>
        )}
      </div>
    );
  }
);

Textarea.displayName = 'Textarea';
