import type { NextFunction, Request, Response } from 'express';
import { getSupabaseAnon } from '../../config/supabase.js';
import { UnauthorizedError } from '../../common/errors/AuthError.js';
import type { AuthUser } from '../../common/types/auth.types.js';
import { ROLES, type Role } from '../../common/constants/roles.js';

function normalizeRole(value: unknown): Role {
  return Object.values(ROLES).includes(value as Role) ? (value as Role) : ROLES.GENERAL_MEMBER;
}

export async function authenticate(
  request: Request,
  _response: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const authorization = request.header('authorization');
    if (!authorization?.startsWith('Bearer ')) {
      throw new UnauthorizedError();
    }

    const token = authorization.slice(7).trim();
    if (!token) {
      throw new UnauthorizedError();
    }

    const { data, error } = await getSupabaseAnon().auth.getUser(token);
    if (error || !data.user) {
      throw new UnauthorizedError();
    }

    const metadataRole = data.user.user_metadata?.role;
    const role = normalizeRole(metadataRole);
    const user: AuthUser = {
      id: data.user.id,
      email: data.user.email ?? undefined,
      phone: data.user.phone ?? undefined,
      role,
      roles: [role],
      permissions: [],
      metadata: data.user.user_metadata as Record<string, unknown> | undefined,
    };

    request.auth = { user, token };
    next();
  } catch (error) {
    next(error);
  }
}
