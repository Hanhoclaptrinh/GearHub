import React, { useState } from 'react';
import { Smile, SendHorizontal } from '../../../components/ui/IconlyIcons';
import { cn } from '../../../utils/cn';

interface MessageComposerProps {
  disabled?: boolean;
  disabledReason?: string;
  onSend: (content: string) => void;
  onTyping: (isTyping: boolean) => void;
}

export const MessageComposer: React.FC<MessageComposerProps> = ({ disabled, disabledReason, onSend, onTyping }) => {
  const [value, setValue] = useState('');

  const send = () => {
    const content = value.trim();
    if (!content || disabled) return;
    onSend(content);
    setValue('');
    onTyping(false);
  };

  return (
    <div className="shrink-0 border-t border-[#dce7f1] bg-white">
      {/* Disabled reason banner */}
      {disabled && disabledReason && (
        <div className="mx-4 mt-3 rounded-[8px] bg-[#fff7e6] border border-[#ffe6a6] px-4 py-2.5 text-[12px] font-semibold text-[#946200]">
          {disabledReason}
        </div>
      )}

      {/* Input row */}
      <div className="flex items-center gap-3 px-4 py-3">
        <button
          type="button"
          className="shrink-0 text-[#a8b4c7] hover:text-[#435ebe] transition-colors"
          tabIndex={-1}
        >
          <Smile className="h-5 w-5" />
        </button>

        <input
          type="text"
          value={value}
          disabled={disabled}
          onChange={(e) => {
            setValue(e.target.value);
            onTyping(!!e.target.value.trim());
          }}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault();
              send();
            }
          }}
          placeholder="Trả lời khách hàng..."
          className={cn(
            "flex-1 h-11 rounded-[8px] border border-[#dce7f1] bg-[#f8fafc] px-4 text-[13px] font-semibold text-[#25396f] outline-none transition",
            "placeholder:text-[#a8b4c7]",
            "focus:border-[#435ebe] focus:bg-white focus:ring-2 focus:ring-[#435ebe]/10",
            "disabled:cursor-not-allowed disabled:opacity-60"
          )}
        />

        <button
          onClick={send}
          disabled={disabled || !value.trim()}
          title="Gửi tin nhắn"
          className={cn(
            "h-11 w-11 shrink-0 rounded-[8px] flex items-center justify-center transition-all",
            value.trim() && !disabled
              ? "bg-[#435ebe] text-white shadow-[0_2px_8px_rgba(67,94,190,0.3)] hover:bg-[#3950a2] active:scale-95"
              : "bg-[#f2f7ff] text-[#a8b4c7] cursor-not-allowed"
          )}
        >
          <SendHorizontal className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
};
