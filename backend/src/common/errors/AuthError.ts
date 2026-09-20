import { AppError } from './AppError.js';

export class UnauthorizedError extends AppError {
  public constructor(message = 'Authentication is required') {
    super(message, 401, 'UNAUTHORIZED');
  }
}
