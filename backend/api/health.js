/**
 * GET /api/health
 * Simple ping to confirm the Vercel function is alive.
 */
export default function handler(req, res) {
  return res.status(200).json({
    status: 'ok',
    service: 'jeev-sathi-api',
    timestamp: new Date().toISOString(),
  });
}
