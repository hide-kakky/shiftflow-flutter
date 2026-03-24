// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ShiftFlow';

  @override
  String get authTitle => 'ログイン';

  @override
  String get authDescription => 'Supabase Auth の Magic Link でログインします。';

  @override
  String get email => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get sendMagicLink => 'マジックリンク送信';

  @override
  String get signInWithPassword => 'パスワードでログイン';

  @override
  String get emailPasswordRequired => 'メールアドレスとパスワードを入力してください。';

  @override
  String get authRequestCompleted => '認証リクエストを送信しました。';

  @override
  String get qaPanelTitle => 'QA入力補助';

  @override
  String get qaPanelDescription => '検証用メールアドレスを選ぶと入力欄に反映されます。';

  @override
  String get signOut => 'ログアウト';

  @override
  String get navHome => 'ホーム';

  @override
  String get navTasks => 'タスク';

  @override
  String get navMessages => 'メッセージ';

  @override
  String get navSettings => '設定';

  @override
  String get navAdmin => '管理';

  @override
  String get refresh => '再読み込み';

  @override
  String get noData => 'データがありません';

  @override
  String get createTask => 'タスク作成';

  @override
  String get createMessage => 'メッセージ作成';

  @override
  String get title => 'タイトル';

  @override
  String get body => '本文';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get taskDueDate => '期限';

  @override
  String get selectDueDate => '期限を選択';

  @override
  String get clearDueDate => '期限をクリア';

  @override
  String get taskPriority => '優先度';

  @override
  String get priorityLow => '低';

  @override
  String get priorityMedium => '中';

  @override
  String get priorityHigh => '高';

  @override
  String get taskAssignees => '担当者';

  @override
  String get noAssigneesFound => '担当者候補が見つかりません';

  @override
  String get taskAttachments => '添付ファイル';

  @override
  String get pickAttachments => '添付ファイルを選択';

  @override
  String get taskAttachmentUploadSuccess => '添付ファイルをアップロードしました';

  @override
  String get taskAttachmentPartialUpload => '一部の添付アップロードに失敗しました';

  @override
  String get taskTitleRequired => 'タイトルは必須です';

  @override
  String get markComplete => '完了にする';

  @override
  String get theme => 'テーマ';

  @override
  String get language => '言語';

  @override
  String get role => 'ロール';

  @override
  String get permissionDenied => '権限がありません。';

  @override
  String get adminDashboard => '管理ダッシュボード';

  @override
  String get users => 'ユーザー';

  @override
  String get folders => 'フォルダ';

  @override
  String get templates => 'テンプレート';

  @override
  String get organizations => '組織';

  @override
  String get auditLogs => '監査ログ';

  @override
  String get magicLinkSent => 'マジックリンクを送信しました。';

  @override
  String get apiError => 'APIエラー';
}
