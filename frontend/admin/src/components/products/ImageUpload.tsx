import React, { useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import { X, Star, UploadCloud, Box } from '../ui/IconlyIcons';
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
    accept: {
      'image/*': ['.png', '.jpg', '.jpeg', '.webp'],
    },
  });

  const is3DModel = (_url: string) => {
    return false;
  };

  return (
    <div className="space-y-5">
      <div
        {...getRootProps()}
        className={cn(
          "border border-dashed rounded-[12px] p-6 flex flex-col items-center justify-center transition-all cursor-pointer group hover:bg-slate-50",
          isDragActive ? "border-primary bg-primary/5 scale-[0.98]" : "border-[#dce7f1] bg-white"
        )}
      >
        <input {...getInputProps()} />
        <div className="w-12 h-12 bg-[#f2f7ff] rounded-[10px] flex items-center justify-center mb-4 group-hover:scale-105 transition-transform">
          <UploadCloud className="w-6 h-6 text-primary" />
        </div>
        <p className="text-[#25396f] font-extrabold text-base text-center">Tải ảnh sản phẩm</p>
        <p className="text-[#7c8db5] font-bold text-[10px] uppercase tracking-widest mt-1">PNG, JPG, JPEG, WEBP</p>
      </div>

      {previews.length > 0 && (
        <div className="grid grid-cols-2 xl:grid-cols-3 gap-3">
          {previews.map((preview, idx) => {
            const is3D = is3DModel(preview);
            return (
              <div
                key={idx}
                className={cn(
                  "group relative aspect-square rounded-[10px] overflow-hidden border transition-all bg-white",
                  primaryIndex === idx ? "border-primary shadow-lg shadow-primary/10" : "border-[#edf2f7]"
                )}
              >
                {is3D ? (
                  <div className="w-full h-full flex flex-col items-center justify-center bg-[#f2f7ff] text-primary">
                    <Box className="w-8 h-8 mb-1" />
                    <span className="text-[10px] font-black uppercase tracking-tighter">{preview.split('.').pop()?.substring(0, 4) || '3D'}</span>
                  </div>
                ) : (
                  <img
                    src={preview}
                    alt="preview"
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.target as any).src = 'https://placehold.co/400x400/f1f5f9/64748b?text=3D+Model';
                    }}
                  />
                )}

                <div className="absolute inset-0 bg-[#25396f]/65 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center gap-2 backdrop-blur-[2px]">
                  {!is3D && (
                    <button
                      type="button"
                      onClick={() => setPrimaryIndex(idx)}
                      className={cn(
                        "p-2 rounded-full transition-all active:scale-90",
                        primaryIndex === idx ? "bg-primary text-white" : "bg-white text-slate-700 hover:bg-primary hover:text-white"
                      )}
                      title="Đặt làm ảnh chính"
                    >
                      <Star className="w-4 h-4 fill-current" />
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={() => onRemove(idx)}
                    className="p-2 bg-white text-red-500 rounded-full hover:bg-red-500 hover:text-white transition-all active:scale-90"
                    title="Xoá file"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>

                {primaryIndex === idx && !is3D && (
                  <div className="absolute top-2 left-2 bg-primary text-white text-[8px] font-black px-2 py-0.5 rounded-full shadow-md">
                    CHÍNH
                  </div>
                )}

                {is3D && (
                  <div className="absolute top-2 left-2 bg-primary text-white text-[8px] font-black px-2 py-0.5 rounded-full shadow-md">
                    3D
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
