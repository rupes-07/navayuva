import { Pool, type PoolClient } from 'pg';
import { env, isProduction } from './env.js';

const ssl = isProduction && env.DATABASE_URL ? { rejectUnauthorized: false } : undefined;

export const pool = new Pool({
  connectionString: env.DATABASE_URL || undefined,
  max: Number.parseInt(process.env.DB_POOL_MAX ?? '20', 10),
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 10_000,
  ssl,
});

pool.on('error', (error) => {
  console.error('Unexpected PostgreSQL pool error', error);
});

export async function withTransaction<T>(work: (client: PoolClient) => Promise<T>): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await work(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function closeDatabase(): Promise<void> {
  await pool.end();
}
