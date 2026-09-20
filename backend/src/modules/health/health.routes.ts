import { Router } from 'express';
import { pool } from '../../config/database.js';

export const healthRoutes = Router();

healthRoutes.get('/', async (_request, response) => {
  try {
    await pool.query('SELECT 1');
    response.json({
      status: 'ok',
      database: 'connected',
      timestamp: new Date().toISOString(),
    });
  } catch {
    response.status(503).json({
      status: 'degraded',
      database: 'disconnected',
      timestamp: new Date().toISOString(),
    });
  }
});

healthRoutes.get('/ready', async (_request, response) => {
  try {
    const result = await pool.query('SELECT 1');
    const connected = result.rowCount === 1;
    response.status(connected ? 200 : 503).json({
      status: connected ? 'ready' : 'not_ready',
      database: connected ? 'connected' : 'disconnected',
      timestamp: new Date().toISOString(),
    });
  } catch {
    response.status(503).json({
      status: 'not_ready',
      database: 'disconnected',
      timestamp: new Date().toISOString(),
    });
  }
});
