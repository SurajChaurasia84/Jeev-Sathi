# Jeev Sathi API — Vercel Backend

## Environment Variables Required

Copy this file to `.env.local` for local development (never commit `.env.local`).

```
# Firebase Service Account JSON (paste the full JSON as a single line)
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"..."}

# A random secret string — must match the value in Flutter's .env
API_SECRET=your-random-secret-here
```

## Local Development

```bash
npm install
npx vercel dev
```

## Deploy to Production

```bash
vercel login
vercel --prod
vercel env add FIREBASE_SERVICE_ACCOUNT
vercel env add API_SECRET
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/health | Ping / alive check |
| POST | /api/notify-all | Broadcast SOS to all users except poster |
| POST | /api/notify-user | Send targeted notification to one user |

## Security

All POST endpoints require the header:
```
x-api-secret: <API_SECRET>
```
