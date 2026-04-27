import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

type UserRole = "admin" | "manager" | "member";
type UnitRole = "manager" | "member";

type UserSeed = {
  email: string;
  displayName: string;
  orgRole: UserRole;
  currentUnitKey: string;
};

type UnitSeed = {
  key: string;
  name: string;
  parentKey: string | null;
  sortOrder: number;
  memberships?: Array<{ email: string; role: UnitRole }>;
};

type FolderSeed = {
  name: string;
  unitKey: string;
  color: string;
  sortOrder: number;
  isPublic?: boolean;
  notes?: string;
};

type TaskSeed = {
  title: string;
  description: string;
  unitKey: string;
  folderName: string;
  createdByEmail: string;
  status: "open" | "in_progress" | "completed" | "canceled";
  priority: "low" | "medium" | "high";
  dueOffsetDays?: number;
};

type SharedMessageSeed = {
  title: string;
  body: string;
  unitKey: string;
  folderName: string;
  authorEmail: string;
  priority: "low" | "medium" | "high";
  isPinned?: boolean;
};

type DirectMessageSeed = {
  title: string;
  body: string;
  unitKey: string;
  authorEmail: string;
  recipientEmail: string;
  priority: "low" | "medium" | "high";
  isPinned?: boolean;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SERVICE_ROLE_KEY") ?? "";
const ORGANIZATION_ID = Deno.env.get("SHIFTFLOW_ORGANIZATION_ID") ??
  "11111111-1111-1111-1111-111111111111";

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  console.error("SUPABASE_URL と SUPABASE_SERVICE_ROLE_KEY が必要です。");
  Deno.exit(1);
}

const service = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const usersToEnsure: UserSeed[] = [
  {
    email: "admin@shiftflow.local",
    displayName: "ShiftFlow Admin",
    orgRole: "admin",
    currentUnitKey: "hq",
  },
  {
    email: "manager@shiftflow.local",
    displayName: "ShiftFlow Manager",
    orgRole: "manager",
    currentUnitKey: "east_area",
  },
  {
    email: "member@shiftflow.local",
    displayName: "ShiftFlow Member",
    orgRole: "member",
    currentUnitKey: "shinjuku_store",
  },
];

const unitSeeds: UnitSeed[] = [
  {
    key: "hq",
    name: "本部",
    parentKey: null,
    sortOrder: 10,
    memberships: [{ email: "admin@shiftflow.local", role: "manager" }, {
      email: "manager@shiftflow.local",
      role: "manager",
    }],
  },
  {
    key: "ops",
    name: "運営企画",
    parentKey: "hq",
    sortOrder: 20,
    memberships: [{ email: "admin@shiftflow.local", role: "manager" }, {
      email: "manager@shiftflow.local",
      role: "member",
    }],
  },
  {
    key: "hr",
    name: "人事総務",
    parentKey: "hq",
    sortOrder: 30,
    memberships: [{ email: "admin@shiftflow.local", role: "manager" }],
  },
  {
    key: "east_area",
    name: "東日本エリア",
    parentKey: null,
    sortOrder: 40,
    memberships: [{ email: "admin@shiftflow.local", role: "manager" }, {
      email: "manager@shiftflow.local",
      role: "manager",
    }],
  },
  {
    key: "west_area",
    name: "西日本エリア",
    parentKey: null,
    sortOrder: 50,
    memberships: [{ email: "admin@shiftflow.local", role: "manager" }],
  },
  {
    key: "shinjuku_store",
    name: "新宿店",
    parentKey: "east_area",
    sortOrder: 60,
    memberships: [{ email: "manager@shiftflow.local", role: "manager" }, {
      email: "member@shiftflow.local",
      role: "member",
    }],
  },
  {
    key: "shibuya_store",
    name: "渋谷店",
    parentKey: "east_area",
    sortOrder: 70,
    memberships: [{ email: "manager@shiftflow.local", role: "manager" }],
  },
  {
    key: "ikebukuro_store",
    name: "池袋店",
    parentKey: "east_area",
    sortOrder: 80,
    memberships: [{ email: "manager@shiftflow.local", role: "manager" }],
  },
  {
    key: "umeda_store",
    name: "梅田店",
    parentKey: "west_area",
    sortOrder: 90,
    memberships: [{ email: "admin@shiftflow.local", role: "manager" }],
  },
  {
    key: "namba_store",
    name: "難波店",
    parentKey: "west_area",
    sortOrder: 100,
    memberships: [{ email: "admin@shiftflow.local", role: "manager" }],
  },
  {
    key: "shinjuku_floor",
    name: "新宿店 ホール",
    parentKey: "shinjuku_store",
    sortOrder: 110,
    memberships: [{ email: "member@shiftflow.local", role: "member" }],
  },
  {
    key: "shinjuku_kitchen",
    name: "新宿店 キッチン",
    parentKey: "shinjuku_store",
    sortOrder: 120,
    memberships: [{ email: "member@shiftflow.local", role: "member" }],
  },
];

const folderSeeds: FolderSeed[] = [
  {
    name: "全社アナウンス",
    unitKey: "hq",
    color: "#517CB2",
    sortOrder: 10,
    isPublic: true,
    notes: "全社向け共有",
  },
  {
    name: "本部週次",
    unitKey: "hq",
    color: "#395C8A",
    sortOrder: 20,
    isPublic: false,
    notes: "本部週次レビュー",
  },
  {
    name: "運営改善",
    unitKey: "ops",
    color: "#5F88C8",
    sortOrder: 30,
    isPublic: false,
  },
  {
    name: "人事通達",
    unitKey: "hr",
    color: "#748FBC",
    sortOrder: 40,
    isPublic: false,
  },
  {
    name: "東日本エリア共有",
    unitKey: "east_area",
    color: "#5A91A9",
    sortOrder: 50,
    isPublic: false,
  },
  {
    name: "西日本エリア共有",
    unitKey: "west_area",
    color: "#6F90B5",
    sortOrder: 60,
    isPublic: false,
  },
  {
    name: "新宿店 連絡",
    unitKey: "shinjuku_store",
    color: "#7BAE73",
    sortOrder: 70,
    isPublic: false,
  },
  {
    name: "新宿店 シフト",
    unitKey: "shinjuku_store",
    color: "#6FB26D",
    sortOrder: 80,
    isPublic: false,
  },
  {
    name: "渋谷店 連絡",
    unitKey: "shibuya_store",
    color: "#85A869",
    sortOrder: 90,
    isPublic: false,
  },
  {
    name: "池袋店 連絡",
    unitKey: "ikebukuro_store",
    color: "#8EA168",
    sortOrder: 100,
    isPublic: false,
  },
  {
    name: "池袋店 シフト",
    unitKey: "ikebukuro_store",
    color: "#93B37D",
    sortOrder: 105,
    isPublic: false,
  },
  {
    name: "梅田店 連絡",
    unitKey: "umeda_store",
    color: "#B78C64",
    sortOrder: 110,
    isPublic: false,
  },
  {
    name: "梅田店 シフト",
    unitKey: "umeda_store",
    color: "#C59B73",
    sortOrder: 115,
    isPublic: false,
  },
  {
    name: "難波店 連絡",
    unitKey: "namba_store",
    color: "#C0836B",
    sortOrder: 120,
    isPublic: false,
  },
  {
    name: "難波店 シフト",
    unitKey: "namba_store",
    color: "#CC8C77",
    sortOrder: 125,
    isPublic: false,
  },
  {
    name: "ホール共有",
    unitKey: "shinjuku_floor",
    color: "#B98EC9",
    sortOrder: 130,
    isPublic: false,
  },
  {
    name: "キッチン共有",
    unitKey: "shinjuku_kitchen",
    color: "#B98CB2",
    sortOrder: 140,
    isPublic: false,
  },
];

const taskSeeds: TaskSeed[] = [
  {
    title: "4月最終週の全社通達を確認",
    description: "新しい申請導線とメッセージ運用ルールを全ユニットへ共有する。",
    unitKey: "hq",
    folderName: "全社アナウンス",
    createdByEmail: "admin@shiftflow.local",
    status: "open",
    priority: "high",
    dueOffsetDays: 1,
  },
  {
    title: "来月の重点施策を本部週次で確定",
    description: "KPI、責任者、周知タイミングを整理する。",
    unitKey: "hq",
    folderName: "本部週次",
    createdByEmail: "admin@shiftflow.local",
    status: "in_progress",
    priority: "high",
    dueOffsetDays: 2,
  },
  {
    title: "朝礼テンプレートを更新",
    description: "店舗向けの連絡フォーマットを v1.1 前提に見直す。",
    unitKey: "ops",
    folderName: "運営改善",
    createdByEmail: "manager@shiftflow.local",
    status: "open",
    priority: "medium",
    dueOffsetDays: 3,
  },
  {
    title: "新規メンバー向け onboarding 文面を調整",
    description: "招待受諾後の案内文と初回導線を整える。",
    unitKey: "hr",
    folderName: "人事通達",
    createdByEmail: "admin@shiftflow.local",
    status: "open",
    priority: "medium",
    dueOffsetDays: 4,
  },
  {
    title: "東日本エリア売上速報の確認",
    description: "土日の速報値を確認し、必要なら店舗へフォローを入れる。",
    unitKey: "east_area",
    folderName: "東日本エリア共有",
    createdByEmail: "manager@shiftflow.local",
    status: "in_progress",
    priority: "high",
    dueOffsetDays: 1,
  },
  {
    title: "西日本エリアの欠員状況を確認",
    description: "梅田店と難波店の来週シフトを比較する。",
    unitKey: "west_area",
    folderName: "西日本エリア共有",
    createdByEmail: "admin@shiftflow.local",
    status: "open",
    priority: "medium",
    dueOffsetDays: 2,
  },
  {
    title: "新宿店のレジ締め手順を再確認",
    description: "閉店時の手順差分をホール共有へ展開する。",
    unitKey: "shinjuku_store",
    folderName: "新宿店 連絡",
    createdByEmail: "manager@shiftflow.local",
    status: "open",
    priority: "medium",
    dueOffsetDays: 1,
  },
  {
    title: "来週シフトの未回答者へ声かけ",
    description: "未提出メンバーへ DM 送信前の確認まで行う。",
    unitKey: "shinjuku_store",
    folderName: "新宿店 シフト",
    createdByEmail: "manager@shiftflow.local",
    status: "in_progress",
    priority: "high",
    dueOffsetDays: 1,
  },
  {
    title: "渋谷店の冷蔵庫点検",
    description: "温度ログの未記入欄を補完する。",
    unitKey: "shibuya_store",
    folderName: "渋谷店 連絡",
    createdByEmail: "manager@shiftflow.local",
    status: "completed",
    priority: "low",
    dueOffsetDays: -1,
  },
  {
    title: "池袋店の新人教育チェック",
    description: "初回レジ対応のフォロー項目を確認する。",
    unitKey: "ikebukuro_store",
    folderName: "池袋店 連絡",
    createdByEmail: "manager@shiftflow.local",
    status: "open",
    priority: "medium",
    dueOffsetDays: 5,
  },
  {
    title: "梅田店の販促物差し替え",
    description: "レジ前 POP を新デザインに差し替える。",
    unitKey: "umeda_store",
    folderName: "梅田店 連絡",
    createdByEmail: "admin@shiftflow.local",
    status: "open",
    priority: "medium",
    dueOffsetDays: 2,
  },
  {
    title: "難波店の深夜帯応援調整",
    description: "人員不足が出る日だけ臨時応援を割り当てる。",
    unitKey: "namba_store",
    folderName: "難波店 連絡",
    createdByEmail: "admin@shiftflow.local",
    status: "canceled",
    priority: "low",
    dueOffsetDays: 6,
  },
  {
    title: "ホールの案内導線を見直す",
    description: "入口の案内板とオーダー待機列を再配置する。",
    unitKey: "shinjuku_floor",
    folderName: "ホール共有",
    createdByEmail: "member@shiftflow.local",
    status: "open",
    priority: "medium",
    dueOffsetDays: 3,
  },
  {
    title: "キッチン仕込み表を更新",
    description: "土日用の仕込み量を反映して印刷し直す。",
    unitKey: "shinjuku_kitchen",
    folderName: "キッチン共有",
    createdByEmail: "member@shiftflow.local",
    status: "completed",
    priority: "low",
    dueOffsetDays: -2,
  },
  {
    title: "池袋店 来週シフトの最終確認",
    description: "深夜帯の不足枠が埋まっているか確認する。",
    unitKey: "ikebukuro_store",
    folderName: "池袋店 シフト",
    createdByEmail: "manager@shiftflow.local",
    status: "open",
    priority: "high",
    dueOffsetDays: 2,
  },
  {
    title: "梅田店 GW前の仕込み増量確認",
    description: "来客増に備えて仕込み量と発注数を再確認する。",
    unitKey: "umeda_store",
    folderName: "梅田店 シフト",
    createdByEmail: "admin@shiftflow.local",
    status: "in_progress",
    priority: "high",
    dueOffsetDays: 1,
  },
  {
    title: "難波店 シフト交換依頼の整理",
    description: "交換希望を一覧化し、承認済みだけ確定版へ反映する。",
    unitKey: "namba_store",
    folderName: "難波店 シフト",
    createdByEmail: "admin@shiftflow.local",
    status: "open",
    priority: "medium",
    dueOffsetDays: 3,
  },
  {
    title: "本部向け週次レポートのドラフト作成",
    description: "東西エリアの差分と改善提案を 1 ページにまとめる。",
    unitKey: "ops",
    folderName: "運営改善",
    createdByEmail: "manager@shiftflow.local",
    status: "open",
    priority: "medium",
    dueOffsetDays: 4,
  },
  {
    title: "新宿店 ホールの新人フォロー面談",
    description: "導線案内とピーク帯の立ち位置を中心に確認する。",
    unitKey: "shinjuku_floor",
    folderName: "ホール共有",
    createdByEmail: "member@shiftflow.local",
    status: "in_progress",
    priority: "medium",
    dueOffsetDays: 2,
  },
  {
    title: "新宿店 キッチンの洗い場動線見直し",
    description: "ピーク後の詰まりを解消するため、物の置き場所を変更する。",
    unitKey: "shinjuku_kitchen",
    folderName: "キッチン共有",
    createdByEmail: "member@shiftflow.local",
    status: "open",
    priority: "low",
    dueOffsetDays: 5,
  },
];

const sharedMessageSeeds: SharedMessageSeed[] = [
  {
    title: "【全社】v1.1 開発検証の共有",
    body: "ホーム・メッセージ・管理の新構成を今週中に確認してください。",
    unitKey: "hq",
    folderName: "全社アナウンス",
    authorEmail: "admin@shiftflow.local",
    priority: "high",
    isPinned: true,
  },
  {
    title: "本部週次 4/26",
    body: "今週は参加導線と権限まわりの確認を優先します。",
    unitKey: "hq",
    folderName: "本部週次",
    authorEmail: "admin@shiftflow.local",
    priority: "medium",
    isPinned: true,
  },
  {
    title: "朝礼テンプレートの修正版",
    body: "店舗向けの共有文面を簡潔にし、確認項目を先頭に寄せました。",
    unitKey: "ops",
    folderName: "運営改善",
    authorEmail: "manager@shiftflow.local",
    priority: "medium",
  },
  {
    title: "入社初日案内の更新",
    body: "招待リンク受諾後に最初に見る案内文を更新しました。",
    unitKey: "hr",
    folderName: "人事通達",
    authorEmail: "admin@shiftflow.local",
    priority: "medium",
  },
  {
    title: "東日本エリア 速報共有",
    body: "新宿店の土日売上が計画比 108% でした。渋谷店は客数回復待ちです。",
    unitKey: "east_area",
    folderName: "東日本エリア共有",
    authorEmail: "manager@shiftflow.local",
    priority: "high",
    isPinned: true,
  },
  {
    title: "西日本エリア 深夜帯フォロー",
    body: "難波店の深夜帯応援は一旦保留、梅田店の応援を優先します。",
    unitKey: "west_area",
    folderName: "西日本エリア共有",
    authorEmail: "admin@shiftflow.local",
    priority: "medium",
  },
  {
    title: "新宿店 連絡ノート更新",
    body: "レジ締め後の確認項目を 3 点に整理しました。",
    unitKey: "shinjuku_store",
    folderName: "新宿店 連絡",
    authorEmail: "manager@shiftflow.local",
    priority: "medium",
  },
  {
    title: "新宿店 来週シフト確認",
    body: "未提出者は本日 18 時までに返信をお願いします。",
    unitKey: "shinjuku_store",
    folderName: "新宿店 シフト",
    authorEmail: "manager@shiftflow.local",
    priority: "high",
    isPinned: true,
  },
  {
    title: "渋谷店 昼ピーク共有",
    body: "レジ前の待機列を入口側へ移し、動線を広く使ってください。",
    unitKey: "shibuya_store",
    folderName: "渋谷店 連絡",
    authorEmail: "manager@shiftflow.local",
    priority: "medium",
  },
  {
    title: "池袋店 新人フォロー",
    body: "初回レジ対応のメモをフォルダに追加しました。",
    unitKey: "ikebukuro_store",
    folderName: "池袋店 連絡",
    authorEmail: "manager@shiftflow.local",
    priority: "low",
  },
  {
    title: "梅田店 販促差し替え",
    body: "本日閉店後に POP 差し替えを実施してください。",
    unitKey: "umeda_store",
    folderName: "梅田店 連絡",
    authorEmail: "admin@shiftflow.local",
    priority: "medium",
  },
  {
    title: "難波店 深夜帯メモ",
    body: "当面は応援を固定せず、前日 15 時時点で再判断します。",
    unitKey: "namba_store",
    folderName: "難波店 連絡",
    authorEmail: "admin@shiftflow.local",
    priority: "low",
  },
  {
    title: "ホール改善案",
    body: "入口前の案内板を 1 枚減らして導線を広く取ります。",
    unitKey: "shinjuku_floor",
    folderName: "ホール共有",
    authorEmail: "member@shiftflow.local",
    priority: "medium",
  },
  {
    title: "キッチン仕込み数",
    body: "土日は鶏ももを +15、ソースを +2 バッチで準備します。",
    unitKey: "shinjuku_kitchen",
    folderName: "キッチン共有",
    authorEmail: "member@shiftflow.local",
    priority: "medium",
  },
  {
    title: "池袋店 シフト未回答リマインド",
    body: "未回答のメンバーは本日 17 時までに入力をお願いします。",
    unitKey: "ikebukuro_store",
    folderName: "池袋店 シフト",
    authorEmail: "manager@shiftflow.local",
    priority: "high",
    isPinned: true,
  },
  {
    title: "梅田店 GW前の共有",
    body: "仕込み量を 1.2 倍にし、閉店後の補充を 1 回追加で行います。",
    unitKey: "umeda_store",
    folderName: "梅田店 シフト",
    authorEmail: "admin@shiftflow.local",
    priority: "high",
  },
  {
    title: "難波店 シフト交換の締切",
    body: "交換依頼は木曜 12 時で締めます。それ以降は店長判断です。",
    unitKey: "namba_store",
    folderName: "難波店 シフト",
    authorEmail: "admin@shiftflow.local",
    priority: "medium",
  },
  {
    title: "本部 週次レポートひな形",
    body: "来週から東西エリア共通フォーマットで提出してください。",
    unitKey: "ops",
    folderName: "運営改善",
    authorEmail: "admin@shiftflow.local",
    priority: "medium",
  },
  {
    title: "ホール案内の新配置",
    body: "入口看板を左寄せにし、待機列をレジ側へ流す運用に変えます。",
    unitKey: "shinjuku_floor",
    folderName: "ホール共有",
    authorEmail: "member@shiftflow.local",
    priority: "low",
  },
  {
    title: "キッチン洗い場の改善案",
    body: "ピーク後の返却動線を短くするため、バット置き場を右側へ移します。",
    unitKey: "shinjuku_kitchen",
    folderName: "キッチン共有",
    authorEmail: "member@shiftflow.local",
    priority: "low",
  },
];

const directMessageSeeds: DirectMessageSeed[] = [
  {
    title: "新宿店シフト未提出者の確認",
    body: "未提出者への声かけは 17 時までで大丈夫です。",
    unitKey: "shinjuku_store",
    authorEmail: "manager@shiftflow.local",
    recipientEmail: "member@shiftflow.local",
    priority: "high",
  },
  {
    title: "売上速報の補足",
    body: "東日本エリアの速報値は 11 時に更新版を出します。",
    unitKey: "east_area",
    authorEmail: "admin@shiftflow.local",
    recipientEmail: "manager@shiftflow.local",
    priority: "medium",
  },
  {
    title: "キッチン仕込み表ありがとう",
    body: "更新版を見ました。週末分もこのままで進めてください。",
    unitKey: "shinjuku_kitchen",
    authorEmail: "manager@shiftflow.local",
    recipientEmail: "member@shiftflow.local",
    priority: "low",
  },
  {
    title: "来週の店舗巡回",
    body: "火曜は新宿店、水曜は渋谷店の順で見に行きます。",
    unitKey: "east_area",
    authorEmail: "admin@shiftflow.local",
    recipientEmail: "manager@shiftflow.local",
    priority: "medium",
    isPinned: true,
  },
  {
    title: "池袋店シフト確認ありがとう",
    body: "不足枠の洗い出し助かりました。深夜帯だけ追加で確認してください。",
    unitKey: "ikebukuro_store",
    authorEmail: "manager@shiftflow.local",
    recipientEmail: "member@shiftflow.local",
    priority: "medium",
  },
  {
    title: "西日本エリアの応援相談",
    body: "梅田店の応援は金曜だけ先に確定したいです。",
    unitKey: "west_area",
    authorEmail: "admin@shiftflow.local",
    recipientEmail: "manager@shiftflow.local",
    priority: "medium",
  },
  {
    title: "ホール動線の写真共有お願い",
    body: "改善前後が分かる写真を 2 枚だけ送ってください。",
    unitKey: "shinjuku_floor",
    authorEmail: "manager@shiftflow.local",
    recipientEmail: "member@shiftflow.local",
    priority: "low",
  },
];

function assert(condition: boolean, message: string) {
  if (!condition) throw new Error(message);
}

function daysFromNow(days: number) {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString();
}

async function loadUsers() {
  const emails = usersToEnsure.map((user) => user.email);
  const { data, error } = await service
    .from("users")
    .select("id,email,display_name")
    .in("email", emails);
  if (error) throw error;
  const map = new Map<
    string,
    { id: string; email: string; display_name: string | null }
  >();
  for (const row of data ?? []) {
    map.set(String(row.email), {
      id: String(row.id),
      email: String(row.email),
      display_name: row.display_name?.toString() ?? null,
    });
  }
  for (const user of usersToEnsure) {
    assert(map.has(user.email), `ユーザーが見つかりません: ${user.email}`);
  }
  return map;
}

async function loadMemberships(userMap: Map<string, { id: string }>) {
  const { data, error } = await service
    .from("memberships")
    .select("id,user_id,role,organization_role")
    .eq("organization_id", ORGANIZATION_ID);
  if (error) throw error;
  const membershipMap = new Map<string, { id: string; userId: string }>();
  for (const row of data ?? []) {
    membershipMap.set(String(row.user_id), {
      id: String(row.id),
      userId: String(row.user_id),
    });
  }
  for (const user of usersToEnsure) {
    const userId = userMap.get(user.email)?.id;
    assert(
      !!userId && membershipMap.has(userId),
      `membership が見つかりません: ${user.email}`,
    );
  }
  return membershipMap;
}

async function loadRootUnit() {
  const { data, error } = await service
    .from("units")
    .select("id,name")
    .eq("organization_id", ORGANIZATION_ID)
    .is("parent_unit_id", null)
    .order("created_at", { ascending: true })
    .limit(1)
    .single();
  if (error) throw error;
  return { id: String(data.id), name: String(data.name) };
}

async function resetOrgData(rootUnitId: string) {
  const { data: unitsToDelete, error: unitsError } = await service
    .from("units")
    .select("id")
    .eq("organization_id", ORGANIZATION_ID)
    .neq("id", rootUnitId);
  if (unitsError) throw unitsError;
  const unitIds = (unitsToDelete ?? []).map((row) => String(row.id));

  await service.from("organization_invites").delete().eq(
    "organization_id",
    ORGANIZATION_ID,
  );
  await service.from("join_requests").delete().eq(
    "organization_id",
    ORGANIZATION_ID,
  );
  await service.from("attachments").delete().eq(
    "organization_id",
    ORGANIZATION_ID,
  );
  await service.from("message_comments").delete().eq(
    "organization_id",
    ORGANIZATION_ID,
  );
  await service.from("message_reads").delete().in(
    "message_id",
    (await service.from("messages").select("id").eq(
      "organization_id",
      ORGANIZATION_ID,
    )).data?.map((row) => row.id) ?? ["00000000-0000-0000-0000-000000000000"],
  );
  await service.from("tasks").delete().eq("organization_id", ORGANIZATION_ID);
  await service.from("messages").delete().eq(
    "organization_id",
    ORGANIZATION_ID,
  );
  await service.from("templates").delete().eq(
    "organization_id",
    ORGANIZATION_ID,
  );
  await service.from("folders").delete().eq("organization_id", ORGANIZATION_ID);

  if (unitIds.length > 0) {
    await service.from("unit_memberships").delete().in("unit_id", unitIds);
    await service.from("units").delete().in("id", unitIds);
  }

  await service
    .from("users")
    .update({
      current_organization_id: ORGANIZATION_ID,
      current_unit_id: rootUnitId,
    })
    .in("email", usersToEnsure.map((user) => user.email));
}

async function createUnits(rootUnitId: string) {
  const created = new Map<string, { id: string; name: string }>();
  created.set("root", { id: rootUnitId, name: "root" });

  for (const seed of unitSeeds) {
    const parentId = seed.parentKey == null
      ? rootUnitId
      : created.get(seed.parentKey)?.id;
    assert(!!parentId, `parent unit が見つかりません: ${seed.key}`);

    const { data, error } = await service
      .from("units")
      .insert({
        organization_id: ORGANIZATION_ID,
        parent_unit_id: parentId,
        name: seed.name,
        sort_order: seed.sortOrder,
        is_active: true,
      })
      .select("id,name")
      .single();
    if (error) throw error;
    created.set(seed.key, { id: String(data.id), name: String(data.name) });
  }

  return created;
}

async function assignUnitMemberships(
  unitMap: Map<string, { id: string }>,
  userMap: Map<string, { id: string }>,
  membershipMap: Map<string, { id: string }>,
) {
  const rows: Array<Record<string, unknown>> = [];
  for (const seed of unitSeeds) {
    for (const membership of seed.memberships ?? []) {
      const unitId = unitMap.get(seed.key)?.id;
      const userId = userMap.get(membership.email)?.id;
      assert(
        !!unitId && !!userId,
        `unit membership の元データが不足しています: ${seed.key}/${membership.email}`,
      );
      rows.push({
        unit_id: unitId,
        user_id: userId,
        role: membership.role,
        status: "active",
        granted_by_membership_id:
          membershipMap.get(userMap.get("admin@shiftflow.local")!.id)?.id ??
            null,
      });
    }
  }
  if (rows.length > 0) {
    const { error } = await service.from("unit_memberships").insert(rows);
    if (error) throw error;
  }
}

async function createFolders(unitMap: Map<string, { id: string }>) {
  const folderMap = new Map<string, { id: string; unitId: string }>();
  for (const seed of folderSeeds) {
    const unitId = unitMap.get(seed.unitKey)?.id;
    assert(!!unitId, `folder の unit が見つかりません: ${seed.name}`);
    const { data, error } = await service
      .from("folders")
      .insert({
        organization_id: ORGANIZATION_ID,
        unit_id: unitId,
        name: seed.name,
        sort_order: seed.sortOrder,
        color: seed.color,
        is_active: true,
        is_public: seed.isPublic ?? false,
        is_system: false,
        notes: seed.notes ?? null,
      })
      .select("id,unit_id,name")
      .single();
    if (error) throw error;
    folderMap.set(seed.name, {
      id: String(data.id),
      unitId: String(data.unit_id),
    });
  }
  return folderMap;
}

async function createTasks(
  unitMap: Map<string, { id: string }>,
  folderMap: Map<string, { id: string }>,
  userMap: Map<string, { id: string }>,
) {
  const rows = taskSeeds.map((seed) => ({
    organization_id: ORGANIZATION_ID,
    unit_id: unitMap.get(seed.unitKey)?.id,
    folder_id: folderMap.get(seed.folderName)?.id,
    title: seed.title,
    description: seed.description,
    status: seed.status,
    priority: seed.priority,
    created_by_user_id: userMap.get(seed.createdByEmail)?.id,
    due_at: seed.dueOffsetDays == null ? null : daysFromNow(seed.dueOffsetDays),
  }));
  const { error } = await service.from("tasks").insert(rows);
  if (error) throw error;
}

async function createMessages(
  unitMap: Map<string, { id: string }>,
  folderMap: Map<string, { id: string }>,
  userMap: Map<string, { id: string }>,
  membershipMap: Map<string, { id: string }>,
) {
  const sharedRows = sharedMessageSeeds.map((seed) => {
    const userId = userMap.get(seed.authorEmail)?.id;
    assert(
      !!userId,
      `shared message user が見つかりません: ${seed.authorEmail}`,
    );
    const membershipId = membershipMap.get(userId ?? "")?.id ?? null;
    return {
      organization_id: ORGANIZATION_ID,
      unit_id: unitMap.get(seed.unitKey)?.id,
      folder_id: folderMap.get(seed.folderName)?.id,
      author_user_id: userId,
      author_membership_id: membershipId,
      title: seed.title,
      body: seed.body,
      priority: seed.priority,
      is_pinned: seed.isPinned ?? false,
      message_scope: "shared",
    };
  });

  const directRows = directMessageSeeds.map((seed) => {
    const authorUserId = userMap.get(seed.authorEmail)?.id;
    const recipientUserId = userMap.get(seed.recipientEmail)?.id;
    assert(
      !!authorUserId && !!recipientUserId,
      `direct message user が見つかりません: ${seed.authorEmail}/${seed.recipientEmail}`,
    );
    const membershipId = membershipMap.get(authorUserId ?? "")?.id ?? null;
    return {
      organization_id: ORGANIZATION_ID,
      unit_id: unitMap.get(seed.unitKey)?.id,
      folder_id: null,
      author_user_id: authorUserId,
      author_membership_id: membershipId,
      recipient_user_id: recipientUserId,
      title: seed.title,
      body: seed.body,
      priority: seed.priority,
      is_pinned: seed.isPinned ?? false,
      message_scope: "direct",
    };
  });

  const { error } = await service.from("messages").insert([
    ...sharedRows,
    ...directRows,
  ]);
  if (error) throw error;
}

async function updateCurrentUnits(
  unitMap: Map<string, { id: string }>,
  userMap: Map<string, { id: string }>,
) {
  for (const user of usersToEnsure) {
    const userId = userMap.get(user.email)?.id;
    const unitId = unitMap.get(user.currentUnitKey)?.id;
    assert(
      !!userId && !!unitId,
      `current unit 更新対象が不足しています: ${user.email}`,
    );
    const { error } = await service
      .from("users")
      .update({
        current_organization_id: ORGANIZATION_ID,
        current_unit_id: unitId,
        last_context_changed_at: new Date().toISOString(),
      })
      .eq("id", userId);
    if (error) throw error;
  }
}

async function main() {
  const rootUnit = await loadRootUnit();
  await resetOrgData(rootUnit.id);

  const userMap = await loadUsers();
  const membershipMap = await loadMemberships(userMap);
  const unitMap = await createUnits(rootUnit.id);
  await assignUnitMemberships(unitMap, userMap, membershipMap);
  const folderMap = await createFolders(unitMap);
  await createTasks(unitMap, folderMap, userMap);
  await createMessages(unitMap, folderMap, userMap, membershipMap);
  await updateCurrentUnits(unitMap, userMap);

  console.log("OK: ShiftFlow Dev Org の v1.1 開発データを再投入しました。");
  console.log(`ユニット数: ${unitSeeds.length}`);
  console.log(`フォルダ数: ${folderSeeds.length}`);
  console.log(`タスク数: ${taskSeeds.length}`);
  console.log(
    `メッセージ数: ${sharedMessageSeeds.length + directMessageSeeds.length}`,
  );
  console.log("主な確認先:");
  console.log("- admin@shiftflow.local -> 本部");
  console.log("- manager@shiftflow.local -> 東日本エリア");
  console.log("- member@shiftflow.local -> 新宿店");
}

await main();
