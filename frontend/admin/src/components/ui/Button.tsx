import React from 'react';
import { cn } from '../../utils/cn';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
}

export const Button: React.FC<ButtonProps> = ({
  className,
  variant = 'primary',
  size = 'md',
  isLoading,
  children,
  ...props
}) => {
  const baseStyles = 'inline-flex items-center justify-center font-medium transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-primary/50 disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer active:scale-[0.98]';
  const variants = {
    primary: 'bg-cta text-white px-5 py-2.5 rounded-lg shadow-md hover:bg-cta/90',
    secondary: 'bg-primary text-white px-5 py-2.5 rounded-lg shadow-md hover:bg-primary/90',
    outline: 'border-2 border-primary text-primary px-5 py-2.5 rounded-lg hover:bg-primary/5',
    danger: 'bg-red-500 text-white px-5 py-2.5 rounded-lg shadow-md hover:bg-red-600',
    ghost: 'text-slate-600 hover:bg-slate-100 hover:text-slate-900 px-3 py-2 rounded-md',
  };

  const sizes = {
    sm: 'px-3 py-1.5 text-xs inline-flex',
    md: 'px-5 py-2.5 text-sm',
    lg: 'px-8 py-4 text-base',
  };

  return (
    <button
      className={cn(baseStyles, variants[variant], sizes[size], className)}
      disabled={isLoading || props.disabled}
      {...props}
    >
      {isLoading ? (
        <span className="mr-2 h-4 w-4 animate-spin border-2 border-white border-t-transparent rounded-full" />
      ) : null}
      {children}
    </button>
  );
};
