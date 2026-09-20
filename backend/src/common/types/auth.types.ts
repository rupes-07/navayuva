import type { Role } from '../constants/roles.js';

export type AuthUser = {
  id: string;
  email?: string;
  phone?: string;
  role: Role;
  roles: Role[];
  permissions: string[];
  metadata?: Record<string, unknown>;
};

export type AuthContext = {
  user: AuthUser;
  token: string;
};
