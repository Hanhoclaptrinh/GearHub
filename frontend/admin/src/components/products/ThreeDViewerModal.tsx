import React, { useEffect } from 'react';
import { X, Box, Download, ZoomIn, Info } from '../ui/IconlyIcons';
import { Button } from '../ui/Button';

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'model-viewer': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & {
        src?: string;
        'ios-src'?: string;
        alt?: string;
        ar?: boolean;
        'ar-modes'?: string;
        'camera-controls'?: boolean;
        'auto-rotate'?: boolean;
        'shadow-intensity'?: string;
      }, HTMLElement>;
    }
  }
}

interface ThreeDViewerModalProps {
  isOpen: boolean;
  onClose: () => void;
  glbUrl: string;
  usdzUrl?: string;
  productName: string;
}

export const ThreeDViewerModal: React.FC<ThreeDViewerModalProps> = ({
  isOpen,
  onClose,
  glbUrl,
  usdzUrl,
  productName
}) => {
  // Load model-viewer script if not present
  useEffect(() => {
    if (isOpen) {
      const scriptId = 'model-viewer-script';
      if (!document.getElementById(scriptId)) {
        const script = document.createElement('script');
        script.id = scriptId;
        script.type = 'module';
        script.src = 'https://ajax.googleapis.com/ajax/libs/model-viewer/3.4.0/model-viewer.min.js';
        document.head.appendChild(script);
      }
    }
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 sm:p-6 md:p-10 animate-in fade-in duration-300">
      <div className="absolute inset-0 bg-slate-900/80 backdrop-blur-xl" onClick={onClose} />
      
      <div className="relative w-full max-w-6xl aspect-video bg-white rounded-[40px] shadow-2xl overflow-hidden flex flex-col md:flex-row animate-in zoom-in-95 duration-500">
        {/* Viewer Area */}
        <div className="flex-1 bg-slate-50 relative group">
          <model-viewer
            src={glbUrl}
            ios-src={usdzUrl}
            alt={`Mô hình 3D của ${productName}`}
            ar
            ar-modes="webxr scene-viewer quick-look"
            camera-controls
            auto-rotate
            shadow-intensity="1"
            className="w-full h-full outline-none"
            style={{ '--poster-color': 'transparent' } as any}
          >
            <div className="absolute bottom-6 left-6 flex gap-3 pointer-events-none opacity-0 group-hover:opacity-100 transition-opacity">
               <div className="bg-white/80 backdrop-blur px-4 py-2 rounded-2xl flex items-center gap-2 shadow-sm border border-white">
                  <ZoomIn className="w-4 h-4 text-slate-400" />
                  <span className="text-[10px] font-black text-slate-600 uppercase tracking-widest">Cuộn để phóng to</span>
               </div>
            </div>
          </model-viewer>
        </div>

        {/* Info Sidebar */}
        <div className="w-full md:w-80 bg-white border-l border-slate-100 p-8 flex flex-col justify-between">
           <div className="space-y-6">
              <div className="flex items-center justify-between">
                 <div className="p-3 bg-indigo-50 text-indigo-500 rounded-2xl">
                    <Box className="w-6 h-6" />
                 </div>
                 <button onClick={onClose} className="p-2 hover:bg-slate-100 rounded-full transition-colors">
                    <X className="w-6 h-6 text-slate-400" />
                 </button>
              </div>

              <div className="space-y-2">
                 <h2 className="text-2xl font-black text-slate-900 leading-tight">{productName}</h2>
                 <p className="text-xs font-bold text-slate-400 uppercase tracking-widest">Trình xem mô hình 3D AR</p>
              </div>

              <div className="space-y-4 pt-4">
                 <div className="flex items-start gap-4">
                    <div className="w-10 h-10 rounded-xl bg-slate-50 flex items-center justify-center flex-shrink-0 text-slate-400">
                       <Info className="w-5 h-5" />
                    </div>
                    <p className="text-sm font-bold text-slate-500 leading-relaxed">
                       Sử dụng chuột hoặc cảm ứng để xoay và xem chi tiết sản phẩm từ mọi góc độ.
                    </p>
                 </div>
              </div>
           </div>

           <div className="space-y-3">
              <Button className="w-full h-14 rounded-2xl gap-2 shadow-primary/20 bg-indigo-600 hover:bg-indigo-700">
                 <Download className="w-5 h-5" /> Tải về mô hình
              </Button>
              <p className="text-[10px] text-center font-black text-slate-300 uppercase tracking-tighter italic">Định dạng file: GLB / USDZ</p>
           </div>
        </div>
      </div>
    </div>
  );
};
