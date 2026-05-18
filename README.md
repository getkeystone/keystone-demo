# Keystone Demo Deployment

**URL:** demo.getkeystone.ai
**Product:** Safety Procedure Assistant
**Status:** Live (v0.5.2-fc005, FC-005 remediation deployed 2026-05-17)

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

## What's live (v0.5.2-fc005)

- Alberta OHS corpus: 53 documents, hybrid retrieval (FTS + vector)
- Factual consistency scoring (HHEM-2.1-Open)
- Feedback capture with auto-creation of review tasks
- Document version tracking with temporal queries
- Review workflow with separation of duties
- 6 demo users: 4 personas (operator, supervisor, coordinator, manager) + 2 admin accounts
- **Domain scope guard** (added 2026-05-17): pre-retrieval refusal for out-of-corpus queries (TIER emissions, WCB, federal tax, IT procurement). Closes the KDAT-001B FC-005 failure.

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

# Smoke test FC-005 remediation
TOKEN=$(curl -s -X POST http://127.0.0.1:8002/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"operator1","password":"demo123"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))")
QID=$(curl -s -X POST http://127.0.0.1:8002/query \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"question":"What are our greenhouse gas reporting requirements under TIER?","mode":"operational"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('query_id',''))")
curl -s http://127.0.0.1:8002/guidance/$QID -H "Authorization: Bearer $TOKEN" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('reasonCode:', d['guidance'].get('reasonCode'))"
# Expected: reasonCode: DOMAIN_OUT_OF_SCOPE
```

## Do Not

- Put engine code in this repo
- Share volumes with other deployments
- Run commands against keystone-lrfd from this directory
