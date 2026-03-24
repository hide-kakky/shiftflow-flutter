import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.8';

type UserRole = 'admin' | 'manager' | 'member';

type TestUser = {
  label: string;
  email: string;
  displayName: string;
  role: UserRole;
};

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SERVICE_ROLE_KEY =
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SERVICE_ROLE_KEY') ?? '';
const TEST_USER_PASSWORD = Deno.env.get('TEST_USER_PASSWORD') ?? 'TestPass123!';
const ORGANIZATION_ID =
  Deno.env.get('SHIFTFLOW_ORGANIZATION_ID') ?? '11111111-1111-1111-1111-111111111111';

const users: TestUser[] = [
  {
    label: 'Admin',
    email: 'admin@shiftflow.local',
    displayName: 'ShiftFlow Admin',
    role: 'admin',
  },
  {
    label: 'Manager',
    email: 'manager@shiftflow.local',
    displayName: 'ShiftFlow Manager',
    role: 'manager',
  },
  {
    label: 'Member',
    email: 'member@shiftflow.local',
    displayName: 'ShiftFlow Member',
    role: 'member',
  },
];

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  console.error('SUPABASE_URL と SUPABASE_SERVICE_ROLE_KEY(または SERVICE_ROLE_KEY) が必要です。');
  console.error('例: set -a; source supabase/.env; set +a; deno run --allow-env --allow-net scripts/create_test_users.ts');
  Deno.exit(1);
}

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

async function ensureAuthUser(email: string): Promise<string> {
  const { data, error } = await admin.auth.admin.listUsers({ page: 1, perPage: 1000 });
  if (error) throw error;

  const existing = data.users.find((user) => user.email === email);
  if (existing) {
    const { error: updateError } = await admin.auth.admin.updateUserById(existing.id, {
      password: TEST_USER_PASSWORD,
      email_confirm: true,
    });
    if (updateError) throw updateError;
    return existing.id;
  }

  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email,
    password: TEST_USER_PASSWORD,
    email_confirm: true,
  });
  if (createError) throw createError;

  return created.user.id;
}

async function ensureProfileAndMembership(user: TestUser): Promise<void> {
  const authUserId = await ensureAuthUser(user.email);

  const { data: existingProfile, error: profileSelectError } = await admin
    .from('users')
    .select('id')
    .eq('email', user.email)
    .maybeSingle();
  if (profileSelectError) throw profileSelectError;

  let profileId = authUserId;

  if (existingProfile != null) {
    profileId = existingProfile.id as string;

    const { error: profileUpdateError } = await admin
      .from('users')
      .update({
        auth_user_id: authUserId,
        display_name: user.displayName,
        status: 'active',
        is_active: true,
      })
      .eq('id', profileId);
    if (profileUpdateError) throw profileUpdateError;
  } else {
    const { error: profileInsertError } = await admin.from('users').insert({
      id: authUserId,
      auth_user_id: authUserId,
      email: user.email,
      display_name: user.displayName,
      status: 'active',
      is_active: true,
      language: 'ja',
      theme: 'system',
    });
    if (profileInsertError) throw profileInsertError;
  }

  const { error: membershipError } = await admin.from('memberships').upsert(
    {
      organization_id: ORGANIZATION_ID,
      user_id: profileId,
      role: user.role,
      status: 'active',
    },
    { onConflict: 'organization_id,user_id' },
  );
  if (membershipError) throw membershipError;

  console.log(`OK: ${user.label} (${user.email})`);
}

for (const user of users) {
  await ensureProfileAndMembership(user);
}

console.log('テストユーザー作成/更新が完了しました。');
console.log(`共通パスワード: ${TEST_USER_PASSWORD}`);
