import type { ErrorRequestHandler, Request, Response } from 'express';
import { ZodError } from 'zod';
import { logger } from '../config/logger.js';
import { AppError } from '../common/errors/AppError.js';
import { InternalServerError } from '../common/errors/InternalServerError.js';
import type { ApiError } from '../common/types/common.types.js';

export const errorHandler: ErrorRequestHandler = (
  error: unknown,
  _request: Request,
  response: Response<ApiError>,
  _next: NextFunction,
): void => {
  let appError: AppError;

  if (error instanceof AppError) {
    appError = error;
  } else if (error instanceof ZodError) {
    appError = new AppError(
      'Validation failed',
      422,
      'VALIDATION_ERROR',
      error.issues.map((issue) => ({ field: issue.path.join('.'), message: issue.message })),
    );
  } else {
    appError = new InternalServerError();
    logger.error({ err: error }, 'Unhandled request error');
  }

  response.status(appError.statusCode).json({
    success: false,
    message: appError.message,
    error: {
      code: appError.code,
      ...(appError.details ? { details: appError.details } : {}),
    },
  });
};
