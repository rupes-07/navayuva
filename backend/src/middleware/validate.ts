import type { NextFunction, Request, Response } from 'express';
import type { ZodSchema, ZodError } from 'zod';
import { ValidationError } from '../common/errors/ValidationError.js';

type ValidationTarget = 'body' | 'query' | 'params';

export function validate(
  target: ValidationTarget,
  schema: ZodSchema,
) {
  return (request: Request, _response: Response, next: NextFunction): void => {
    try {
      const result = schema.safeParse(request[target]);
      if (!result.success) {
        const details = result.error.issues.map((issue) => ({
          field: issue.path.join('.'),
          message: issue.message,
        }));
        throw new ValidationError('Validation failed', details);
      }
      request[target] = result.data;
      next();
    } catch (error) {
      next(error);
    }
  };
}

export function formatZodError(error: ZodError): Array<{ field: string; message: string }> {
  return error.issues.map((issue) => ({
    field: issue.path.join('.'),
    message: issue.message,
  }));
}
