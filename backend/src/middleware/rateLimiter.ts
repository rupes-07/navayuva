import rateLimit from 'express-rate-limit';
import { env } from '../config/env.js';

export const apiRateLimiter = rateLimit({
  windowMs: env.REQUEST_RATE_LIMIT_WINDOW_MS,
  limit: env.REQUEST_RATE_LIMIT_MAX,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  handler: (_request, response) => {
    response.status(429).json({
      success: false,
      message: 'Too many requests, please try again later',
      error: { code: 'RATE_LIMITED' },
    });
  },
});

export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 30,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  handler: (_request, response) => {
    response.status(429).json({
      success: false,
      message: 'Too many authentication attempts',
      error: { code: 'AUTH_RATE_LIMITED' },
    });
  },
});
