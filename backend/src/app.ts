import compression from 'compression';
import express from 'express';
import swaggerUi from 'swagger-ui-express';
import { env } from './config/env.js';
import { corsMiddleware } from './config/cors.js';
import { helmetMiddleware } from './config/security.js';
import { logger, requestLogger } from './config/logger.js';
import { auditMiddleware } from './middleware/auditMiddleware.js';
import { errorHandler } from './middleware/errorHandler.js';
import { notFound } from './middleware/notFound.js';
import { apiRateLimiter } from './middleware/rateLimiter.js';
import { routes } from './routes/index.js';

export const app = express();

app.disable('x-powered-by');
app.set('trust proxy', env.NODE_ENV === 'production' ? 1 : false);
app.use(helmetMiddleware);
app.use(corsMiddleware);
app.use(compression());
app.use(requestLogger);
app.use(auditMiddleware);
app.use(express.json({ limit: '1mb', strict: true }));
app.use(express.urlencoded({ extended: false, limit: '1mb' }));
app.use(env.API_PREFIX, apiRateLimiter);
app.use(env.API_PREFIX, routes);
app.use(notFound);
app.use(errorHandler);

if (env.NODE_ENV !== 'production') {
  const swaggerDocument = {
    openapi: '3.0.0',
    info: {
      title: 'Nawa Yuba Club API',
      version: '1.0.0',
      description: 'Civic and youth community platform API',
    },
    servers: [{ url: env.API_PREFIX }],
    paths: {},
  };
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
}

export function startServer(): ReturnType<typeof app.listen> {
  return app.listen(env.PORT, () => {
    logger.info({ port: env.PORT, apiPrefix: env.API_PREFIX }, 'HTTP server listening');
  });
}
