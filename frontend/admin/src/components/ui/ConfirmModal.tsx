import React from 'react';
import { X, AlertTriangle } from 'lucide-react';
import { Button } from './Button';
import { cn } from '../../utils/cn';

interface ConfirmModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  variant?: 'danger' | 'warning' | 'info';
  isLoading?: boolean;
}

export const ConfirmModal: React.FC<ConfirmModalProps> = ({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmText = 'Xác nhận',
  cancelText = 'Hủy bỏ',
  variant = 'danger',
  isLoading = false,
}) => {
  if (!isOpen) return null;

  const variants = {
    danger: {
      icon: <AlertTriangle className="w-6 h-6 text-red-500" />,
      bg: 'bg-red-50',
      button: 'bg-red-500 hover:bg-red-600 shadow-red-200',
    },
    warning: {
      icon: <AlertTriangle className="w-6 h-6 text-amber-500" />,
      bg: 'bg-amber-50',
      button: 'bg-amber-500 hover:bg-amber-600 shadow-amber-200',
    },
    info: {
      icon: <AlertTriangle className="w-6 h-6 text-blue-500" />,
      bg: 'bg-blue-50',
      button: 'bg-blue-500 hover:bg-blue-600 shadow-blue-200',
    },
  };

  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white w-full max-w-md rounded-[32px] shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200 border border-white">
        <div className="p-6 pb-0 flex justify-end">
          <button onClick={onClose} className="p-2 rounded-full hover:bg-slate-50 transition-all">
            <X className="w-5 h-5 text-slate-300" />
          </button>
        </div>
        
        <div className="p-8 pt-0 flex flex-col items-center text-center">
          <div className={cn("w-16 h-16 rounded-2xl flex items-center justify-center mb-6", variants[variant].bg)}>
            {variants[variant].icon}
          </div>
          
          <h3 className="text-xl font-black text-slate-900 mb-2 uppercase tracking-tight">{title}</h3>
          <p className="text-slate-500 font-bold text-sm leading-relaxed mb-8 px-4">{message}</p>
          
          <div className="flex gap-3 w-full">
            <Button 
              variant="outline" 
              className="flex-1 h-12 rounded-2xl font-black uppercase text-[10px] tracking-widest border-slate-100" 
              onClick={onClose}
              disabled={isLoading}
            >
              {cancelText}
            </Button>
            <Button 
              className={cn("flex-1 h-12 rounded-2xl font-black uppercase text-[10px] tracking-widest shadow-lg", variants[variant].button)} 
              onClick={onConfirm}
              isLoading={isLoading}
            >
              {confirmText}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};
