import React, { forwardRef } from 'react';
import { cn } from '../../utils/cn';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  icon?: any;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className, label, error, icon: Icon, ...props }, ref) => {
    return (
      <div className="flex flex-col gap-1.5 w-full relative">
        {label && (
          <label className="text-sm font-semibold text-slate-700 ml-1">
            {label}
          </label>
        )}
        <div className="relative group/input">
           {Icon && (
             <div className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within/input:text-primary transition-colors">
                <Icon size={18} />
             </div>
           )}
           <input
             ref={ref}
             className={cn(
               'px-4 py-3 border border-slate-200 rounded-lg text-base transition-all duration-200 outline-none w-full bg-white',
               'focus:border-primary focus:ring-3 focus:ring-primary/20',
               Icon ? 'pl-11' : null,
               error ? 'border-red-400 focus:border-red-500 focus:ring-red-100' : null,
               className
             )}
             {...props}
           />
        </div>
        {error && (
          <span className="text-xs font-medium text-red-500 ml-1 mt-0.5">
            {error}
          </span>
        )}
      </div>
    );
  }
);

Input.displayName = 'Input';
