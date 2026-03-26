import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.8';

type Scenario = {
  email: string;
  expectedOk: boolean;
  expectedCode?: string;
};

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
const TEST_USER_PASSWORD = Deno.env.get('TEST_USER_PASSWORD') ?? 'TestPass123!';

const scenarios: Scenario[] = [
  { email: 'admin@shiftflow.local', expectedOk: true },
  { email: 'manager@shiftflow.local', expectedOk: true },
  { email: 'member@shiftflow.local', expectedOk: false, expectedCode: 'forbidden' },
];

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error('SUPABASE_URL と SUPABASE_ANON_KEY が必要です。');
  Deno.exit(1);
}

let failed = 0;

for (const scenario of scenarios) {
  const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const login = await client.auth.signInWithPassword({
    email: scenario.email,
    password: TEST_USER_PASSWORD,
  });

  if (login.error) {
    failed += 1;
    console.error(`NG: ${scenario.email} login failed: ${login.error.message}`);
    continue;
  }

  const { data, error } = await client.functions.invoke('api', {
    body: {
      route: 'adminListUsers',
      args: [{}],
    },
  });

  if (error) {
    let code = '';
    const context = (error as { context?: { json?: () => Promise<unknown> } }).context;

    if (context?.json) {
      try {
        const body = await context.json();
        code = String((body as { code?: string })?.code ?? '');
      } catch {
        // ignore JSON parse errors and fall back to message-based handling
      }
    }

    if (!scenario.expectedOk) {
      const isExpectedCode = scenario.expectedCode ? code === scenario.expectedCode : true;
      if (isExpectedCode) {
        console.log(`OK: ${scenario.email} expected failure code=${code || 'unknown'}`);
        continue;
      }
    }

    failed += 1;
    console.error(
      `NG: ${scenario.email} invoke failed: ${error.message}${code ? ` (code=${code})` : ''}`,
    );
    continue;
  }

  const ok = data?.ok === true;
  const code = String(data?.code ?? '');
  const rows = Array.isArray(data?.result?.rows) ? data.result.rows.length : 0;

  if (ok !== scenario.expectedOk) {
    failed += 1;
    console.error(
      `NG: ${scenario.email} expected ok=${scenario.expectedOk}, actual ok=${ok}, code=${code}, rows=${rows}`,
    );
    continue;
  }

  if (!scenario.expectedOk && scenario.expectedCode && code !== scenario.expectedCode) {
    failed += 1;
    console.error(
      `NG: ${scenario.email} expected code=${scenario.expectedCode}, actual code=${code}`,
    );
    continue;
  }

  console.log(
    `OK: ${scenario.email} ok=${ok}${code ? ` code=${code}` : ''}${ok ? ` rows=${rows}` : ''}`,
  );
}

if (failed > 0) {
  console.error(`検証失敗: ${failed}件`);
  Deno.exit(1);
}

console.log('認証/ロール検証はすべて成功しました。');
