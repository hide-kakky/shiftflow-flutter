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
  String get sendMagicLink => 'マジックリンク送信';

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
