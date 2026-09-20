import type { Request, Response, NextFunction } from 'express';
import { NotFoundError } from '../common/errors/NotFoundError.js';
import type { ApiError } from '../common/types/common.types.js';

export function notFound(request: Request, _response: Response<ApiError>, next: NextFunction): void {
  if (request.path.startsWith('/api/')) {
    next(new NotFoundError(`Route ${request.method} ${request.originalUrl} was not found`));
    return;
  }
  next();
}
