import path from 'node:path';

export type FileValidationResult = {
  safeName: string;
  extension: string;
};

const allowedMimeByExtension: Record<string, string[]> = {
  '.jpg': ['image/jpeg'],
  '.jpeg': ['image/jpeg'],
  '.png': ['image/png'],
  '.webp': ['image/webp'],
  '.pdf': ['application/pdf'],
  '.doc': ['application/msword'],
  '.docx': ['application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
  '.mp4': ['video/mp4'],
  '.mov': ['video/quicktime'],
};

export function validateFileMetadata(
  originalName: string,
  mimeType: string,
  size: number,
  maxSize: number,
): FileValidationResult {
  const safeName = path.basename(originalName).replace(/[\x00-\x1F<>:"/\\|?*]/g, '_');
  const extension = path.extname(safeName).toLowerCase();
  const allowedMimes = allowedMimeByExtension[extension];

  if (!extension || !allowedMimes?.includes(mimeType.toLowerCase())) {
    throw new Error('File type is not allowed');
  }
  if (size <= 0 || size > maxSize) {
    throw new Error('File size is not allowed');
  }

  return { safeName, extension };
}
