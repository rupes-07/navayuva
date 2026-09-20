export type ErrorDetail = {
  field?: string;
  message: string;
};

export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly details?: ErrorDetail[];
  public readonly isOperational: boolean;

  public constructor(
    message: string,
    statusCode: number,
    code: string,
    details?: ErrorDetail[],
    isOperational = true,
  ) {
    super(message);
    this.name = new.target.name;
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.isOperational = isOperational;
    Error.captureStackTrace?.(this, new.target);
  }
}
