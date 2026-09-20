export type JsonValue = string | number | boolean | null | JsonValue[] | { [key: string]: JsonValue };

export type ApiSuccess<T = undefined> = {
  success: true;
  message: string;
  data: T;
  meta?: Record<string, unknown>;
};

export type ApiError = {
  success: false;
  message: string;
  error: {
    code: string;
    details?: Array<{ field?: string; message: string }>;
  };
};

export type RequestContext = {
  requestId?: string;
  userId?: string;
};
