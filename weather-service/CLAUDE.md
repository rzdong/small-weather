# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Backend service for "小天气 (Small Weather)" app — a Go/Gin weather application that proxies QWeather API data and manages user authentication, cities, settings, and avatar uploads. Part of the pencil-gallery organization.

## Commands

```bash
go mod download          # Install dependencies
go run main.go           # Run dev server (port 3001)
go build -o weather-service  # Build binary
```

No test suite, linter config, or Makefile exists.

## Architecture

**Entry point:** `main.go` — sets up Gin router with CORS, request logging middleware, and all route groups under `/api`.

**Route groups:**
- `/api/auth` — public: login, register (with email verification code), password reset, logout
- `/api/user` — auth-required (`RequireAuth` middleware): profile, cities CRUD, settings, avatar STS
- `/api/weather` — public: QWeather API proxy (geo lookup, top cities, now/24h/7d forecasts)

**Handlers package (`handlers/`):** All business logic lives here. Shared `DB *sql.DB` global initialized by `InitDB()`.

| File | Responsibility |
|---|---|
| `store.go` | DB init (MySQL via `go-sql-driver/mysql`), model structs (`User`, `City`, `UserPreferences`), schema auto-migration (`ensureSchema`) |
| `auth.go` | Register/login, password reset, profile CRUD, verification code lifecycle (generate/verify/consume/cleanup) |
| `jwt.go` | Custom JWT implementation using HMAC-SHA256 (no third-party JWT library). 30-day token expiry. Signs/validates manually with base64 + HMAC |
| `mailer.go` | SMTP email sending with HTML templates. Supports implicit TLS (port 465) and STARTTLS |
| `weather.go` | QWeather API proxy — forwards query params and injects API key. Base URL: `https://pf5vxbpy5n.re.qweatherapi.com` |
| `city.go` | User cities CRUD + settings (language, dark mode, light angle, shadow intensity) |
| `avatar_sts.go` | Tencent Cloud COS STS temporary credential issuance scoped to user's avatar prefix |

**Middleware (`middleware/`):**
- `auth.go` — `RequireAuth()`: validates Bearer token via `handlers.ValidateJWTForMiddleware`, sets `userID`/`userEmail`/`userName` in Gin context
- `request_logger.go` — logs full request/response to `logs/YYYY-MM-DD.log` as JSON lines

**Database:** MySQL with `database/sql` directly (no ORM). Schema in `db.sql`. Tables: `users`, `user_settings`, `user_cities`, `sessions`, `verification_codes`. Uses `utf8mb4` charset.

**Config:** Environment variables loaded from `.env` via `godotenv`. Required vars: `MYSQL_*`, `JWT_SECRET`, `SMTP_*`, `COS_*`, `QWEATHER_KEY`.

## Key Patterns

- Auth context: `RequireAuth` middleware sets `c.GetInt("userID")` — handlers read this directly
- API responses consistently use `{"success": bool, "data": ..., "message": ...}` format
- Verification codes are 6-digit numbers with 10-minute TTL, stored in DB, auto-cleaned daily at noon
- Password hashing uses bcrypt; `comparePassword` also supports plaintext fallback for legacy data
- JWT is hand-rolled (not a library) — changes to token format must maintain the 3-part `header.payload.signature` structure
