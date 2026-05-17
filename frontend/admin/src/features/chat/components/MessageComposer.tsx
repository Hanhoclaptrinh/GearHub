import React, { useState } from 'react';
import { SendHorizontal } from 'lucide-react';
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
    <div className="sticky bottom-0 border-t border-white/10 bg-slate-950/95 p-4 backdrop-blur">
      {disabled && (
        <div className="mb-3 rounded-lg bg-amber-400/10 px-4 py-3 text-xs font-bold text-amber-100 ring-1 ring-amber-300/20">
          {disabledReason}
        </div>
      )}
      <div className={cn(
        'flex items-end gap-3 rounded-lg bg-white/[0.06] p-2 ring-1 ring-white/10 transition',
        !disabled && 'focus-within:ring-cyan-300/40'
      )}>
        <textarea
          value={value}
          disabled={disabled}
          onChange={(event) => {
            setValue(event.target.value);
            onTyping(!!event.target.value.trim());
          }}
          onKeyDown={(event) => {
            if (event.key === 'Enter' && !event.shiftKey) {
              event.preventDefault();
              send();
            }
          }}
          placeholder="Trả lời khách hàng..."
          className="max-h-40 min-h-12 flex-1 resize-none bg-transparent px-3 py-3 text-sm font-semibold leading-relaxed text-white outline-none placeholder:text-slate-500 disabled:cursor-not-allowed"
        />
        <button
          onClick={send}
          disabled={disabled || !value.trim()}
          className="grid h-11 w-11 shrink-0 place-items-center rounded-md bg-cyan-300 text-slate-950 transition hover:bg-cyan-200 disabled:cursor-not-allowed disabled:bg-white/10 disabled:text-slate-600"
          title="Send"
        >
          <SendHorizontal className="h-5 w-5" />
        </button>
      </div>
    </div>
  );
};
