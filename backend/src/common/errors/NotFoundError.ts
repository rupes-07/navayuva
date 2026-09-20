import { AppError } from './AppError.js';

export class NotFoundError extends AppError {
  public constructor(message = 'The requested resource was not found') {
    super(message, 404, 'NOT_FOUND');
  }
}
