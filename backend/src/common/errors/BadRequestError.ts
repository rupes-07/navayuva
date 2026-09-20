import { AppError } from './AppError.js';

export class BadRequestError extends AppError {
  public constructor(message = 'The request is invalid', details?: { field?: string; message: string }[]) {
    super(message, 400, 'BAD_REQUEST', details);
  }
}
