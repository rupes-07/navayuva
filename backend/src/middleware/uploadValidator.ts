import type { NextFunction, Request, Response } from 'express';
import { BadRequestError } from '../common/errors/BadRequestError.js';

export type UploadFile = {
  fieldname: string;
  originalname: string;
  encoding: string;
  mimetype: string;
  size: number;
  destination?: string;
  filename?: string;
  path?: string;
  buffer?: Buffer;
};

export function uploadValidator(maxSize: number) {
  return (request: Request, _response: Response, next: NextFunction): void => {
    try {
      const files = request.files;
      const uploads = Array.isArray(files) ? files : Object.values(files ?? {}).flat();
      for (const upload of uploads) {
        const file = upload as UploadFile;
        if (!file.mimetype || file.size <= 0 || file.size > maxSize) {
          throw new BadRequestError('Uploaded file metadata is invalid');
        }
      }
      next();
    } catch (error) {
      next(error);
    }
  };
}
