import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const booleanFromEnv = z
  .enum(['true', 'false', '1', '0', 'yes', 'no'])
  .optional()
  .transform((value) => value === 'true' || value === '1' || value === 'yes');

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(5000),
  API_PREFIX: z.string().trim().min(1).default('/api/v1'),
  DATABASE_URL: z.string().trim().optional().default(''),
  SUPABASE_URL: z.string().url().optional().default(''),
  SUPABASE_ANON_KEY: z.string().trim().optional().default(''),
  SUPABASE_SERVICE_ROLE_KEY: z.string().trim().optional().default(''),
  JWT_SECRET: z.string().trim().optional().default(''),
  CORS_ORIGIN: z.string().trim().default('*'),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  REQUEST_RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(900000),
  REQUEST_RATE_LIMIT_MAX: z.coerce.number().int().positive().default(100),
  EMAIL_PROVIDER: z.string().trim().optional().default(''),
  EMAIL_API_KEY: z.string().trim().optional().default(''),
  EMAIL_FROM: z.string().trim().optional().default(''),
  SMS_PROVIDER: z.string().trim().optional().default(''),
  SMS_API_KEY: z.string().trim().optional().default(''),
  PAYMENT_PROVIDER: z.string().trim().optional().default(''),
  PAYMENT_SECRET: z.string().trim().optional().default(''),
  PAYMENT_WEBHOOK_SECRET: z.string().trim().optional().default(''),
  AI_PROVIDER: z.string().trim().optional().default(''),
  AI_API_KEY: z.string().trim().optional().default(''),
  ENABLE_TEST_DATABASE: booleanFromEnv,
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  const issues = parsed.error.issues
    .map((issue) => `${issue.path.join('.')}: ${issue.message}`)
    .join('; ');
  throw new Error(`Invalid environment configuration: ${issues}`);
}

export const env = parsed.data;
export const isProduction = env.NODE_ENV === 'production';
export const isTest = env.NODE_ENV === 'test';

export function requireServerSecret(value: string | undefined, name: string): string {
  if (!value || value.length < 16) {
    throw new Error(`${name} must be configured with a strong secret in ${env.NODE_ENV} mode`);
  }
  return value;
}
