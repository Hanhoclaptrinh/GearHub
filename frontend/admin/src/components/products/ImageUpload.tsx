import React, { useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import { X, Star, UploadCloud } from 'lucide-react';
import { cn } from '../../utils/cn';

interface ImageUploadProps {
  previews: string[];
  onUpload: (newFiles: File[]) => void;
  onRemove: (index: number) => void;
  primaryIndex: number;
  setPrimaryIndex: (index: number) => void;
}

export const ImageUpload: React.FC<ImageUploadProps> = ({
  previews,
  onUpload,
  onRemove,
  primaryIndex,
  setPrimaryIndex,
}) => {
  const onDrop = useCallback((acceptedFiles: File[]) => {
    onUpload(acceptedFiles);
  }, [onUpload]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: { 'image/*': [] },
  });

  return (
    <div className="space-y-4">
      <div 
        {...getRootProps()} 
        className={cn(
          "border-2 border-dashed rounded-2xl p-10 flex flex-col items-center justify-center transition-all cursor-pointer",
          isDragActive ? "border-primary bg-primary/5 scale-[0.99]" : "border-slate-200 hover:border-primary/50 hover:bg-slate-50"
        )}
      >
        <input {...getInputProps()} />
        <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mb-4">
           <UploadCloud className="w-8 h-8 text-primary" />
        </div>
        <p className="text-slate-700 font-bold text-lg">Kéo thả hoặc click để tải lên</p>
        <p className="text-slate-400 font-medium text-sm mt-1">Hỗ trợ PNG, JPG, WebP (Tối đa 2MB/ảnh)</p>
      </div>

      {previews.length > 0 && (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          {previews.map((preview, idx) => (
            <div 
              key={idx} 
              className={cn(
                "group relative aspect-square rounded-2xl overflow-hidden border-2 transition-all",
                primaryIndex === idx ? "border-cta shadow-lg shadow-cta/20" : "border-slate-100"
              )}
            >
              <img src={preview} alt="preview" className="w-full h-full object-cover" />
              
              <div className="absolute inset-0 bg-slate-900/60 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center gap-2">
                 <button
                   type="button"
                   onClick={() => setPrimaryIndex(idx)}
                   className={cn(
                     "p-2 rounded-full transition-transform active:scale-90",
                     primaryIndex === idx ? "bg-cta text-white" : "bg-white text-slate-700 hover:bg-cta hover:text-white"
                   )}
                   title="Đặt làm ảnh chính"
                 >
                    <Star className="w-4 h-4" />
                 </button>
                 <button
                   type="button"
                   onClick={() => onRemove(idx)}
                   className="p-2 bg-white text-red-500 rounded-full hover:bg-red-500 hover:text-white transition-all active:scale-90"
                   title="Xoá ảnh"
                 >
                    <X className="w-4 h-4" />
                 </button>
              </div>

              {primaryIndex === idx && (
                <div className="absolute top-2 left-2 bg-cta text-white text-[10px] font-black px-2 py-0.5 rounded-full shadow-md animate-in slide-in-from-top-1">
                  ẢNH CHÍNH
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
