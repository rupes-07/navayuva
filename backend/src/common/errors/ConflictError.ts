import { AppError } from './AppError.js';

export class ConflictError extends AppError {
  public constructor(message = 'The resource already exists or conflicts with an existing record', details?: { field?: string; message: string }[]) {
    super(message, 409, 'CONFLICT', details);
  }
}
