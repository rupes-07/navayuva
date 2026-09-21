import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { pool } from '../config/database.js';
import { logger } from '../config/logger.js';

const currentDirectory = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(currentDirectory, '../..');
const migrationsDirectory = path.join(projectRoot, 'supabase', 'migrations');

type MigrationRecord = {
  name: string;
  checksum: string;
  applied_at: Date;
};

async function ensureMigrationTable(): Promise<void> {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      name text PRIMARY KEY,
      checksum text NOT NULL,
      applied_at timestamptz NOT NULL DEFAULT now()
    );
  `);
}

async function getAppliedMigrations(): Promise<Map<string, MigrationRecord>> {
  const result = await pool.query<MigrationRecord>('SELECT name, checksum, applied_at FROM schema_migrations ORDER BY name');
  return new Map(result.rows.map((row) => [row.name, row]));
}

async function getMigrationFiles(): Promise<string[]> {
  try {
    const entries = await readdir(migrationsDirectory, { withFileTypes: true });
    return entries
      .filter((entry) => entry.isFile() && entry.name.toLowerCase().endsWith('.sql'))
      .map((entry) => entry.name)
      .sort();
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
      return [];
    }
    throw error;
  }
}

export async function runMigrations(): Promise<void> {
  await ensureMigrationTable();
  const applied = await getAppliedMigrations();
  const files = await getMigrationFiles();

  for (const fileName of files) {
    const existing = applied.get(fileName);
    const sql = await readFile(path.join(migrationsDirectory, fileName), 'utf8');
    const checksum = await import('node:crypto').then(({ createHash }) =>
      createHash('sha256').update(sql).digest('hex'),
    );

    if (existing && existing.checksum !== checksum) {
      throw new Error(`Migration checksum mismatch for ${fileName}`);
    }
    if (existing) {
      continue;
    }

    const client = await pool.connect();
    try {
      logger.info({ migration: fileName }, 'Applying database migration');
      await client.query('BEGIN');
      await client.query(sql);
      await client.query(
        'INSERT INTO schema_migrations (name, checksum) VALUES ($1, $2)',
        [fileName, checksum],
      );
      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

const isDirectExecution = process.argv[1]
  ? path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
  : false;

if (isDirectExecution) {
  runMigrations()
    .then(() => {
      logger.info('Database migrations completed');
    })
    .catch((error: unknown) => {
      logger.error({ err: error }, 'Database migration failed');
      process.exitCode = 1;
    })
    .finally(async () => {
      await pool.end();
    });
}
