import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { env } from './env.js';

type SupabaseClients = {
  anon: SupabaseClient | null;
  serviceRole: SupabaseClient | null;
};

function createSupabaseClient(url: string, key: string, serviceRole = false): SupabaseClient | null {
  if (!url || !key) {
    return null;
  }

  return createClient(url, key, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
    global: {
      headers: serviceRole ? { apikey: key, Authorization: `Bearer ${key}` } : undefined,
    },
  });
}

export const supabaseClients: SupabaseClients = {
  anon: createSupabaseClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY),
  serviceRole: createSupabaseClient(
    env.SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    true,
  ),
};

export function getSupabaseAdmin(): SupabaseClient {
  if (!supabaseClients.serviceRole) {
    throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required');
  }
  return supabaseClients.serviceRole;
}

export function getSupabaseAnon(): SupabaseClient {
  if (!supabaseClients.anon) {
    throw new Error('SUPABASE_URL and SUPABASE_ANON_KEY are required');
  }
  return supabaseClients.anon;
}
