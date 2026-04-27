# Keystone Demo Deployment

**URL:** demo.getkeystone.ai
**Product:** Safety Procedure Assistant
**Status:** Live, security hardened (v0.5.1-review)

## What This Repo Contains

Deployment configuration only. No engine code.

- `docker-compose.yml` -- Container orchestration
- `deployments/alberta-demo/deployment.yaml` -- Branding, roles, modes, queries
- `initdb/` -- Database migrations
- `caddy/` -- Reverse proxy config + console build
- `.env` -- Secrets (gitignored)

## Engine Source

- API: `../keystone-gov/api` (built via Docker)
- Console: `../keystone-console` (built via npm, copied to caddy/dist/)

## Stack

| Service | Port | Purpose |
|---------|------|---------|
| postgres | 5433 | keystone_dev database |
| api | 8002 | Safety Procedure Assistant API |
| web | 8082 | Caddy reverse proxy + console |

## What's live (v0.5.1-review)

- Alberta OHS corpus: 53 documents, hybrid retrieval (FTS + vector)
- Factual consistency scoring (HHEM-2.1-Open)
- Feedback capture with auto-creation of review tasks
- Document version tracking with temporal queries
- Review workflow with separation of duties
- 6 demo users: 4 personas (operator, supervisor, coordinator, manager) + 2 admin accounts

## Operations
```bash
# Start
docker compose up -d

# Rebuild API after keystone-gov changes
docker compose build api && docker compose up -d api

# Rebuild console after keystone-console changes
cd ../keystone-console && npm run build
cp -r dist/* ../keystone-demo/caddy/dist/
cd ../keystone-demo && docker compose restart web

# Check health
curl -sf http://localhost:8082/api/config | jq '.deployment.name'
```

## Do Not

- Put engine code in this repo
- Share volumes with other deployments
- Run commands against keystone-lrfd from this directory
