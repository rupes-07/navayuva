import cors, { type CorsOptions } from 'cors';
import { env } from './env.js';

const allowedOrigins = env.CORS_ORIGIN === '*'
  ? undefined
  : env.CORS_ORIGIN.split(',').map((origin) => origin.trim()).filter(Boolean);

export const corsOptions: CorsOptions = {
  origin: allowedOrigins ?? true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Authorization', 'Content-Type', 'Idempotency-Key', 'X-Request-ID'],
  exposedHeaders: ['X-Request-ID', 'X-RateLimit-Limit', 'X-RateLimit-Remaining'],
  credentials: true,
  maxAge: 600,
};

export const corsMiddleware = cors(corsOptions);
