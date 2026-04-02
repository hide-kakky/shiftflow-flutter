const GOOGLE_OAUTH_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const GOOGLE_OAUTH_TOKEN_URL = "https://oauth2.googleapis.com/token";

let cachedAccessToken = "";
let cachedAccessTokenExpiresAt = 0;

export class FcmSendError extends Error {
  constructor(
    message: string,
    readonly statusCode?: number,
    readonly code?: string,
  ) {
    super(message);
  }
}

function requireEnv(name: string): string {
  const value = Deno.env.get(name)?.trim() ?? "";
  if (!value) {
    throw new Error(`${name} is required`);
  }
  return value;
}

function normalizePrivateKey(value: string): string {
  return value.replace(/\\n/g, "\n");
}

function toBase64Url(value: string | Uint8Array): string {
  const bytes = typeof value === "string"
    ? new TextEncoder().encode(value)
    : value;
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const raw = atob(base64);
  const bytes = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i += 1) {
    bytes[i] = raw.charCodeAt(i);
  }
  return bytes.buffer;
}

async function signJwt(assertion: string, privateKeyPem: string): Promise<string> {
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKeyPem),
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(assertion),
  );

  return toBase64Url(new Uint8Array(signature));
}

async function createServiceAccountAssertion(): Promise<string> {
  const clientEmail = requireEnv("FCM_CLIENT_EMAIL");
  const privateKeyPem = normalizePrivateKey(requireEnv("FCM_PRIVATE_KEY"));
  const now = Math.floor(Date.now() / 1000);

  const header = toBase64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = toBase64Url(JSON.stringify({
    iss: clientEmail,
    sub: clientEmail,
    aud: GOOGLE_OAUTH_TOKEN_URL,
    scope: GOOGLE_OAUTH_SCOPE,
    iat: now,
    exp: now + 3600,
  }));

  const signingInput = `${header}.${payload}`;
  const signature = await signJwt(signingInput, privateKeyPem);
  return `${signingInput}.${signature}`;
}

async function getGoogleAccessToken(): Promise<string> {
  const now = Date.now();
  if (cachedAccessToken && now < cachedAccessTokenExpiresAt - 60_000) {
    return cachedAccessToken;
  }

  const assertion = await createServiceAccountAssertion();
  const response = await fetch(GOOGLE_OAUTH_TOKEN_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  const data = await response.json().catch(() => ({})) as {
    access_token?: string;
    expires_in?: number;
    error?: string;
    error_description?: string;
  };

  if (!response.ok || !data.access_token) {
    throw new Error(
      `oauth_token_failed: ${data.error_description ?? data.error ?? response.statusText}`,
    );
  }

  cachedAccessToken = data.access_token;
  cachedAccessTokenExpiresAt = now + ((data.expires_in ?? 3600) * 1000);
  return cachedAccessToken;
}

export function isTokenInvalidError(error: unknown): boolean {
  if (!(error instanceof FcmSendError)) return false;
  return error.code === "UNREGISTERED" || error.code === "INVALID_ARGUMENT";
}

type FcmMessage = {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
};

export async function sendFcmMessage(message: FcmMessage): Promise<void> {
  const projectId = requireEnv("FCM_PROJECT_ID");
  const accessToken = await getGoogleAccessToken();

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: JSON.stringify({
        message: {
          token: message.token,
          notification: {
            title: message.title,
            body: message.body,
          },
          data: message.data ?? {},
          android: {
            priority: "high",
            notification: {
              channel_id: "messages",
            },
          },
          apns: {
            headers: {
              "apns-priority": "10",
            },
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        },
      }),
    },
  );

  const data = await response.json().catch(() => ({})) as {
    error?: {
      status?: string;
      message?: string;
    };
  };

  if (!response.ok) {
    throw new FcmSendError(
      data.error?.message ?? response.statusText,
      response.status,
      data.error?.status,
    );
  }
}
