import type { NextFunction, Request, Response } from 'express';
import { randomUUID } from 'node:crypto';

export function auditMiddleware(request: Request, _response: Response, next: NextFunction): void {
  request.auditMetadata = {
    requestId: request.header('x-request-id') ?? randomUUID(),
    ip: request.ip,
    userAgent: request.get('user-agent'),
  };
  next();
}
