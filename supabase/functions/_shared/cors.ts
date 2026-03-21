export const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
};

export function jsonResponse(status: number, payload: unknown) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json; charset=utf-8',
    },
  });
}

export function readBearerToken(request: Request): string {
  const auth = request.headers.get('Authorization') ?? '';
  if (!auth.startsWith('Bearer ')) return '';
  return auth.slice(7).trim();
}

export function decodeJwtPayload(token: string): Record<string, unknown> {
  if (!token) return {};
  const parts = token.split('.');
  if (parts.length < 2) return {};
  try {
    const raw = atob(parts[1].replace(/-/g, '+').replace(/_/g, '/'));
    return JSON.parse(raw) as Record<string, unknown>;
  } catch (_error) {
    return {};
  }
}
