import { AppError } from './AppError.js';

export class InternalServerError extends AppError {
  public constructor(message = 'An unexpected error occurred') {
    super(message, 500, 'INTERNAL_SERVER_ERROR', undefined, false);
  }
}
