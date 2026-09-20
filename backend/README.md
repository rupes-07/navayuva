# Nawa Yuba Club Backend

Modular TypeScript/Express backend for the Nawa Yuba Club civic and youth community platform.

## Run locally

```bash
cp .env.example .env
npm install
npm run db:migrate
npm run db:seed
npm run dev
```

The API is served at `http://localhost:5000/api/v1`. The health endpoint is `GET /api/v1/health`.

## Scripts

- `npm run dev` - watch-mode development server
- `npm run build` - strict TypeScript build
- `npm run db:migrate` - apply ordered SQL migrations
- `npm run db:seed` - insert system roles, permissions, locations, categories, tiers, badges, and configuration
- `npm run lint` - ESLint
- `npm run format:check` - Prettier check
- `npm test` - Vitest suite

## Architecture

Controllers translate HTTP requests, services own business rules, repositories own persistence, and SQL migrations own schema evolution. Supabase Auth owns identity; PostgreSQL owns application authorization and domain data. Sensitive service credentials remain server-side only.

See `docs/ARCHITECTURE.md`, `docs/SECURITY.md`, and `docs/DATABASE.md` for the design and operating contract.
