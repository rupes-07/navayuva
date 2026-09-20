import pino from 'pino';
import pinoHttp from 'pino-http';
import { env } from './env.js';

export const logger = pino({
  level: env.LOG_LEVEL,
  base: {
    service: 'nawa-yuba-club-backend',
    environment: env.NODE_ENV,
  },
  redact: {
    paths: [
      'req.headers.authorization',
      'req.headers.cookie',
      'res.headers.authorization',
      'body.password',
      'body.token',
      'body.refreshToken',
      'body.paymentSecret',
    ],
    censor: '[REDACTED]',
  },
});

export const requestLogger = pinoHttp({
  logger,
  genReqId: (request, response) => {
    const existing = request.headers['x-request-id'];
    const id = Array.isArray(existing) ? (existing[0] ?? crypto.randomUUID()) : (existing ?? crypto.randomUUID());
    response.setHeader('X-Request-ID', id);
    return id;
  },
  customSuccessObject: (request, response, responseLog) => ({
    ...responseLog,
    userId: (request as typeof request & { user?: { id?: string } }).user?.id,
    route: request.route?.path ?? request.path,
  }),
  customErrorObject: (request, error, responseLog) => ({
    ...responseLog,
    err: error,
    userId: (request as typeof request & { user?: { id?: string } }).user?.id,
    route: request.route?.path ?? request.path,
  }),
});
