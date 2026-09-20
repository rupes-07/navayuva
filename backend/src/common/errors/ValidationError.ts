import { AppError } from './AppError.js';

export class ValidationError extends AppError {
  public constructor(message = 'Validation failed', details: { field?: string; message: string }[] = []) {
    super(message, 422, 'VALIDATION_ERROR', details);
  }
}
