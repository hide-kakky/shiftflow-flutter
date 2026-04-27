import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const TEST_USER_PASSWORD = Deno.env.get("TEST_USER_PASSWORD") ?? "TestPass123!";

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error("SUPABASE_URL と SUPABASE_ANON_KEY が必要です。");
  Deno.exit(1);
}

function createAnonClient() {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

async function login(email: string) {
  const client = createAnonClient();
  const { error } = await client.auth.signInWithPassword({
    email,
    password: TEST_USER_PASSWORD,
  });
  if (error) throw error;
  return client;
}

async function invokeRoute(
  client: ReturnType<typeof createAnonClient>,
  route: string,
  args: unknown[] = [],
) {
  const { data, error } = await client.functions.invoke("api", {
    body: { route, args },
  });
  if (error) {
    throw new Error(`${route}: ${error.message}`);
  }
  if (data?.ok !== true) {
    throw new Error(`${route}: ${data?.code ?? "unknown_error"}`);
  }
  return data.result;
}

function assert(condition: boolean, message: string) {
  if (!condition) {
    throw new Error(message);
  }
}

async function verifyAdminRoutes() {
  const admin = await login("admin@shiftflow.local");
  const bootstrap = await invokeRoute(admin, "getBootstrapData");
  assert(
    bootstrap.participation?.canUseApp === true,
    "admin bootstrap canUseApp が false です",
  );
  assert(
    !!bootstrap.currentOrganization?.id,
    "admin bootstrap currentOrganization がありません",
  );
  assert(
    !!bootstrap.currentUnit?.id,
    "admin bootstrap currentUnit がありません",
  );

  const joinRequests = await invokeRoute(admin, "listJoinRequests");
  assert(
    Array.isArray(joinRequests),
    "listJoinRequests が配列を返していません",
  );

  const units = await invokeRoute(admin, "listUnits");
  assert(Array.isArray(units) && units.length > 0, "listUnits が空です");

  const invites = await invokeRoute(admin, "listOrganizationInvites");
  assert(
    Array.isArray(invites),
    "listOrganizationInvites が配列を返していません",
  );

  console.log("OK: admin bootstrap / joinRequests / units / invites");
}

async function verifyMemberRoutes() {
  const member = await login("member@shiftflow.local");
  const bootstrap = await invokeRoute(member, "getBootstrapData");
  const currentUnitId = String(bootstrap.currentUnit?.id ?? "");
  assert(
    bootstrap.participation?.status === "active",
    "member bootstrap status が active ではありません",
  );
  assert(currentUnitId.length > 0, "member currentUnit がありません");

  const sharedMessages = await invokeRoute(member, "getMessages", [
    {
      currentUnitId,
      tab: "current",
      scope: "shared",
      unreadOnly: false,
      keyword: "",
    },
  ]);
  assert(
    Array.isArray(sharedMessages),
    "member shared messages が配列を返していません",
  );

  const directMessages = await invokeRoute(member, "getMessages", [
    {
      currentUnitId,
      tab: "current",
      scope: "direct",
      unreadOnly: false,
      keyword: "",
    },
  ]);
  assert(
    Array.isArray(directMessages),
    "member direct messages が配列を返していません",
  );

  const availableUnits = Array.isArray(bootstrap.availableUnits)
    ? bootstrap.availableUnits
    : [];
  if (availableUnits.length > 0) {
    const targetUnitId = String(availableUnits[0]?.["id"] ?? "");
    if (targetUnitId.length > 0) {
      const changed = await invokeRoute(member, "changeCurrentUnit", [
        { "unitId": targetUnitId },
      ]);
      assert(
        changed["success"] == true,
        "changeCurrentUnit が成功しませんでした",
      );
    }
  }

  console.log("OK: member bootstrap / getMessages / changeCurrentUnit");
}

try {
  await verifyAdminRoutes();
  await verifyMemberRoutes();
  console.log("v1.1 API ルート検証はすべて成功しました。");
} catch (error) {
  console.error(
    `検証失敗: ${
      error instanceof Error ? error.message : JSON.stringify(error)
    }`,
  );
  Deno.exit(1);
}
