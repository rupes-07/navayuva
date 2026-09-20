import type { Permission } from '../constants/permissions.js';
import type { Role } from '../constants/roles.js';
import type { AuthUser } from '../types/auth.types.js';

export function hasRole(user: AuthUser, roles: readonly Role[]): boolean {
  return roles.some((role) => user.roles.includes(role));
}

export function hasPermission(user: AuthUser, permission: Permission): boolean {
  return user.permissions.includes(permission);
}

export function hasAnyPermission(user: AuthUser, permissions: readonly Permission[]): boolean {
  return permissions.some((permission) => user.permissions.includes(permission));
}
