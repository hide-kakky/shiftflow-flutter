import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SERVICE_ROLE_KEY") ?? "";
const TEST_USER_PASSWORD = Deno.env.get("TEST_USER_PASSWORD") ?? "TestPass123!";
const ORGANIZATION_ID = Deno.env.get("SHIFTFLOW_ORGANIZATION_ID") ??
  "11111111-1111-1111-1111-111111111111";

if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SERVICE_ROLE_KEY) {
  console.error(
    "SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY が必要です。",
  );
  Deno.exit(1);
}

const service = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

function createAnonClient() {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function assert(condition: boolean, message: string) {
  if (!condition) {
    throw new Error(message);
  }
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

async function ensureUnit(name: string, parentUnitId: string | null) {
  const { data: existing } = await service
    .from("units")
    .select("id,name,parent_unit_id,path_text")
    .eq("organization_id", ORGANIZATION_ID)
    .eq("name", name)
    .maybeSingle();
  if (existing?.id) return existing;

  const { data, error } = await service
    .from("units")
    .insert({
      organization_id: ORGANIZATION_ID,
      parent_unit_id: parentUnitId,
      name,
      sort_order: 0,
      is_active: true,
    })
    .select("id,name,parent_unit_id,path_text")
    .single();
  if (error) throw error;
  return data;
}

async function ensureFolder(name: string, unitId: string) {
  const { data: existing } = await service
    .from("folders")
    .select("id,name,unit_id")
    .eq("organization_id", ORGANIZATION_ID)
    .eq("name", name)
    .maybeSingle();
  if (existing?.id) {
    await service
      .from("folders")
      .update({ unit_id: unitId, is_public: false, is_active: true })
      .eq("id", existing.id);
    return existing;
  }

  const { data, error } = await service
    .from("folders")
    .insert({
      organization_id: ORGANIZATION_ID,
      name,
      unit_id: unitId,
      is_public: false,
      is_active: true,
    })
    .select("id,name,unit_id")
    .single();
  if (error) throw error;
  return data;
}

async function seedVerificationData() {
  const { data: users, error: userError } = await service
    .from("users")
    .select("id,email")
    .in("email", [
      "admin@shiftflow.local",
      "manager@shiftflow.local",
      "member@shiftflow.local",
    ]);
  if (userError) throw userError;

  const adminUser = users?.find((user) =>
    user.email === "admin@shiftflow.local"
  );
  const managerUser = users?.find((user) =>
    user.email === "manager@shiftflow.local"
  );
  const memberUser = users?.find((user) =>
    user.email === "member@shiftflow.local"
  );
  assert(
    !!adminUser?.id && !!managerUser?.id && !!memberUser?.id,
    "テストユーザーが不足しています",
  );

  const { data: memberships } = await service
    .from("memberships")
    .select("id,user_id")
    .eq("organization_id", ORGANIZATION_ID)
    .in("user_id", [adminUser!.id, managerUser!.id, memberUser!.id]);
  const adminMembership = memberships?.find((row) =>
    row.user_id === adminUser!.id
  );
  assert(!!adminMembership?.id, "admin membership が見つかりません");

  const { data: rootUnit } = await service
    .from("units")
    .select("id,name")
    .eq("organization_id", ORGANIZATION_ID)
    .is("parent_unit_id", null)
    .limit(1)
    .single();
  const rootUnitId = String(rootUnit?.id ?? "");
  assert(rootUnitId.length > 0, "root unit が見つかりません");
  const childUnit = await ensureUnit("検証用_子ユニット", rootUnitId);
  const siblingUnit = await ensureUnit("検証用_別ユニット", rootUnitId);

  await service.from("unit_memberships").upsert(
    [
      {
        unit_id: rootUnitId,
        user_id: managerUser!.id,
        role: "manager",
        status: "active",
        granted_by_membership_id: adminMembership!.id,
      },
      {
        unit_id: childUnit.id,
        user_id: memberUser!.id,
        role: "member",
        status: "active",
        granted_by_membership_id: adminMembership!.id,
      },
    ],
    { onConflict: "unit_id,user_id" },
  );

  await service
    .from("users")
    .update({
      current_organization_id: ORGANIZATION_ID,
      current_unit_id: childUnit.id,
    })
    .eq("id", memberUser!.id);

  const rootFolder = await ensureFolder("RLS-VERIFY:ROOT-FOLDER", rootUnitId);
  const childFolder = await ensureFolder(
    "RLS-VERIFY:CHILD-FOLDER",
    childUnit.id,
  );
  const siblingFolder = await ensureFolder(
    "RLS-VERIFY:SIBLING-FOLDER",
    siblingUnit.id,
  );

  await service
    .from("tasks")
    .delete()
    .eq("organization_id", ORGANIZATION_ID)
    .like("title", "RLS-VERIFY:%");
  await service
    .from("messages")
    .delete()
    .eq("organization_id", ORGANIZATION_ID)
    .like("title", "RLS-VERIFY:%");

  await service.from("tasks").insert([
    {
      organization_id: ORGANIZATION_ID,
      folder_id: rootFolder.id,
      unit_id: rootUnitId,
      title: "RLS-VERIFY:ROOT-TASK",
      created_by_user_id: adminUser!.id,
    },
    {
      organization_id: ORGANIZATION_ID,
      folder_id: childFolder.id,
      unit_id: childUnit.id,
      title: "RLS-VERIFY:CHILD-TASK",
      created_by_user_id: adminUser!.id,
    },
    {
      organization_id: ORGANIZATION_ID,
      folder_id: siblingFolder.id,
      unit_id: siblingUnit.id,
      title: "RLS-VERIFY:SIBLING-TASK",
      created_by_user_id: adminUser!.id,
    },
  ]);

  await service.from("messages").insert([
    {
      organization_id: ORGANIZATION_ID,
      folder_id: rootFolder.id,
      unit_id: rootUnitId,
      author_membership_id: adminMembership!.id,
      author_user_id: adminUser!.id,
      title: "RLS-VERIFY:ROOT-SHARED",
      body: "root",
      message_scope: "shared",
    },
    {
      organization_id: ORGANIZATION_ID,
      folder_id: childFolder.id,
      unit_id: childUnit.id,
      author_membership_id: adminMembership!.id,
      author_user_id: adminUser!.id,
      title: "RLS-VERIFY:CHILD-SHARED",
      body: "child",
      message_scope: "shared",
    },
    {
      organization_id: ORGANIZATION_ID,
      folder_id: siblingFolder.id,
      unit_id: siblingUnit.id,
      author_membership_id: adminMembership!.id,
      author_user_id: adminUser!.id,
      title: "RLS-VERIFY:SIBLING-SHARED",
      body: "sibling",
      message_scope: "shared",
    },
    {
      organization_id: ORGANIZATION_ID,
      unit_id: childUnit.id,
      author_membership_id: adminMembership!.id,
      author_user_id: adminUser!.id,
      recipient_user_id: memberUser!.id,
      title: "RLS-VERIFY:DM-TO-MEMBER",
      body: "direct member",
      message_scope: "direct",
    },
    {
      organization_id: ORGANIZATION_ID,
      unit_id: rootUnitId,
      author_membership_id: adminMembership!.id,
      author_user_id: adminUser!.id,
      recipient_user_id: managerUser!.id,
      title: "RLS-VERIFY:DM-TO-MANAGER",
      body: "direct manager",
      message_scope: "direct",
    },
  ]);
}

async function restTitles(
  client: ReturnType<typeof createAnonClient>,
  path: string,
): Promise<string[]> {
  const { data, error } = await client.from(path).select("title");
  if (error) throw error;
  return (data ?? []).map((row) => String(row.title));
}

async function restNames(
  client: ReturnType<typeof createAnonClient>,
  path: string,
): Promise<string[]> {
  const { data, error } = await client.from(path).select("name");
  if (error) throw error;
  return (data ?? []).map((row) => String(row.name));
}

try {
  await seedVerificationData();

  const member = await login("member@shiftflow.local");
  const manager = await login("manager@shiftflow.local");

  console.log("CHECK: member folders");
  const memberFolders = await restNames(member, "folders");
  assert(
    memberFolders.includes("RLS-VERIFY:CHILD-FOLDER"),
    "member が child folder を読めません",
  );
  assert(
    !memberFolders.includes("RLS-VERIFY:ROOT-FOLDER"),
    "member が root folder を読めてしまいます",
  );

  console.log("CHECK: manager folders");
  const managerFolders = await restNames(manager, "folders");
  assert(
    managerFolders.includes("RLS-VERIFY:ROOT-FOLDER"),
    "manager が root folder を読めません",
  );
  assert(
    managerFolders.includes("RLS-VERIFY:CHILD-FOLDER"),
    "manager 継承で child folder を読めません",
  );

  console.log("CHECK: member tasks");
  const memberTasks = await restTitles(member, "tasks");
  assert(
    memberTasks.includes("RLS-VERIFY:CHILD-TASK"),
    "member が child task を読めません",
  );
  assert(
    !memberTasks.includes("RLS-VERIFY:ROOT-TASK"),
    "member が root task を読めてしまいます",
  );

  console.log("CHECK: manager tasks");
  const managerTasks = await restTitles(manager, "tasks");
  assert(
    managerTasks.includes("RLS-VERIFY:ROOT-TASK"),
    "manager が root task を読めません",
  );
  assert(
    managerTasks.includes("RLS-VERIFY:CHILD-TASK"),
    "manager 継承で child task を読めません",
  );

  console.log("CHECK: member shared messages");
  const {
    data: memberShared,
    error: memberSharedError,
  } = await member.from("messages").select("title").eq(
    "message_scope",
    "shared",
  );
  if (memberSharedError) throw memberSharedError;
  const memberSharedTitles = (memberShared ?? []).map((row) =>
    String(row.title)
  );
  assert(
    memberSharedTitles.includes("RLS-VERIFY:CHILD-SHARED"),
    "member が child shared message を読めません",
  );
  assert(
    !memberSharedTitles.includes("RLS-VERIFY:ROOT-SHARED"),
    "member が root shared message を読めてしまいます",
  );

  console.log("CHECK: manager shared messages");
  const {
    data: managerShared,
    error: managerSharedError,
  } = await manager.from("messages").select("title").eq(
    "message_scope",
    "shared",
  );
  if (managerSharedError) throw managerSharedError;
  const managerSharedTitles = (managerShared ?? []).map((row) =>
    String(row.title)
  );
  assert(
    managerSharedTitles.includes("RLS-VERIFY:ROOT-SHARED"),
    "manager が root shared message を読めません",
  );
  assert(
    managerSharedTitles.includes("RLS-VERIFY:CHILD-SHARED"),
    "manager 継承で child shared message を読めません",
  );
  assert(
    managerSharedTitles.includes("RLS-VERIFY:SIBLING-SHARED"),
    "manager 継承で sibling shared message を読めません",
  );

  console.log("CHECK: member direct messages");
  const {
    data: memberDirect,
    error: memberDirectError,
  } = await member.from("messages").select("title").eq(
    "message_scope",
    "direct",
  );
  if (memberDirectError) throw memberDirectError;
  const memberDirectTitles = (memberDirect ?? []).map((row) =>
    String(row.title)
  );
  console.log("member direct titles:", memberDirectTitles.join(", "));
  assert(
    memberDirectTitles.includes("RLS-VERIFY:DM-TO-MEMBER"),
    "member が自分向け DM を読めません",
  );
  assert(
    !memberDirectTitles.includes("RLS-VERIFY:DM-TO-MANAGER"),
    "member が他人向け DM を読めてしまいます",
  );

  console.log("CHECK: manager direct messages");
  const {
    data: managerDirect,
    error: managerDirectError,
  } = await manager.from("messages").select("title").eq(
    "message_scope",
    "direct",
  );
  if (managerDirectError) throw managerDirectError;
  const managerDirectTitles = (managerDirect ?? []).map((row) =>
    String(row.title)
  );
  console.log("manager direct titles:", managerDirectTitles.join(", "));
  assert(
    managerDirectTitles.includes("RLS-VERIFY:DM-TO-MANAGER"),
    "manager が自分向け DM を読めません",
  );
  assert(
    !managerDirectTitles.includes("RLS-VERIFY:DM-TO-MEMBER"),
    "manager が他人向け DM を読めてしまいます",
  );

  console.log("v1.1 DB/RLS 境界検証はすべて成功しました。");
} catch (error) {
  console.error(
    `検証失敗: ${
      error instanceof Error ? error.message : JSON.stringify(error)
    }`,
  );
  Deno.exit(1);
}
