import type { AuthContext } from '../types/auth.types.js';

declare global {
  namespace Express {
    interface Request {
      auth?: AuthContext;
      auditMetadata?: Record<string, unknown>;
    }
  }
}

export {};
