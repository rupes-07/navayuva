import type { NextFunction, Request, Response } from 'express';
import { ForbiddenError } from '../common/errors/ForbiddenError.js';
import type { Permission } from '../common/constants/permissions.js';
import type { Role } from '../common/constants/roles.js';
import { hasPermission, hasRole } from '../common/utils/permissions.js';

export type AuthorizeOptions = {
  roles?: readonly Role[];
  permissions?: readonly Permission[];
  requireAllPermissions?: boolean;
};

export function authorize(options: AuthorizeOptions = {}) {
  return (request: Request, _response: Response, next: NextFunction): void => {
    try {
      if (!request.auth) {
        throw new ForbiddenError();
      }

      const { user } = request.auth;
      if (options.roles?.length && !hasRole(user, options.roles)) {
        throw new ForbiddenError();
      }

      if (options.permissions?.length) {
        const allowed = options.requireAllPermissions
          ? options.permissions.every((permission) => hasPermission(user, permission))
          : options.permissions.some((permission) => hasPermission(user, permission));
        if (!allowed) {
          throw new ForbiddenError();
        }
      }

      next();
    } catch (error) {
      next(error);
    }
  };
}
