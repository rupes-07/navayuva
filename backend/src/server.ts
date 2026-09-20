import { app, startServer } from './app.js';
import { closeDatabase } from './config/database.js';
import { logger } from './config/logger.js';

const server = startServer();

function shutdown(signal: string): void {
  logger.info({ signal }, 'Shutdown signal received');
  server.close(() => {
    void closeDatabase()
      .then(() => {
        logger.info({ signal }, 'HTTP server and database pool closed');
        process.exit(0);
      })
      .catch((error: unknown) => {
        logger.error({ err: error }, 'Shutdown failed');
        process.exit(1);
      });
  });
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

void app;
