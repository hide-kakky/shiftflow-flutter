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
  String get authInvalidCredentials => 'メールアドレスまたはパスワードが正しくありません。';

  @override
  String get authInvalidCredentialsHint => '入力内容を確認し、必要ならパスワード再設定を行ってください。';

  @override
  String get authGenericError => 'ログインに失敗しました';

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
  String get toggleRead => '既読切替';

  @override
  String get pinMessage => 'ピン留め切替';

  @override
  String get pinActionDenied => 'ピン操作は管理者のみ実行できます。';

  @override
  String get readStateUpdated => '既読状態を更新しました。';

  @override
  String get readStatus => '既読状況';

  @override
  String get readStatusLimited => '既読一覧は権限のあるユーザーのみ表示できます。';

  @override
  String get load => '読み込み';

  @override
  String get comments => 'コメント';

  @override
  String get addComment => 'コメント追加';

  @override
  String get noComments => 'コメントはまだありません';

  @override
  String get readUsers => '既読ユーザー';

  @override
  String get unreadUsers => '未読ユーザー';

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
  String get taskScopeMy => 'My';

  @override
  String get taskScopeCreated => 'Created';

  @override
  String get taskScopeAll => 'All';

  @override
  String get markComplete => '完了にする';

  @override
  String get profile => 'プロフィール';

  @override
  String get displayName => '表示名';

  @override
  String get displayNameHint => 'チームで表示される名前';

  @override
  String get displayNameRequired => '表示名を入力してください。';

  @override
  String get updateProfileImage => 'プロフィール画像を更新';

  @override
  String get profileImageUpdated => 'プロフィール画像を更新しました。';

  @override
  String get profileImageTypeError => '画像は PNG / JPG / WEBP のみ対応です。';

  @override
  String get profileImageSizeError => '画像サイズは2MB以下にしてください。';

  @override
  String get saveProfile => 'プロフィールを保存';

  @override
  String get profileUpdated => 'プロフィールを更新しました。';

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
  String get adminEditUser => 'ユーザー編集';

  @override
  String get adminUserStatus => 'ステータス';

  @override
  String get adminUserUpdated => 'ユーザー情報を更新しました。';

  @override
  String get adminEditOrganization => '組織編集';

  @override
  String get adminOrganizationUpdated => '組織情報を更新しました。';

  @override
  String get adminOrgShortName => '短縮名';

  @override
  String get adminOrgColor => '表示カラー';

  @override
  String get adminOrgTimezone => 'タイムゾーン';

  @override
  String get adminCreateFolder => 'フォルダ作成';

  @override
  String get adminEditFolder => 'フォルダ編集';

  @override
  String get adminArchiveFolder => 'フォルダをアーカイブ';

  @override
  String get adminFolderName => 'フォルダ名';

  @override
  String get adminFolderColor => 'フォルダカラー';

  @override
  String get adminIsPublic => '公開';

  @override
  String get adminIsActive => '有効';

  @override
  String get adminFolderCreated => 'フォルダを作成しました。';

  @override
  String get adminFolderUpdated => 'フォルダを更新しました。';

  @override
  String get adminFolderArchived => 'フォルダをアーカイブしました。';

  @override
  String get adminSelectFolder => '対象フォルダ';

  @override
  String get adminCreateTemplate => 'テンプレート作成';

  @override
  String get adminTemplateName => 'テンプレート名';

  @override
  String get adminTitleFormat => 'タイトル書式';

  @override
  String get adminBodyFormat => '本文書式';

  @override
  String get adminTemplateCreated => 'テンプレートを作成しました。';

  @override
  String get adminNoFoldersForTemplates => '先にフォルダを作成してください。';

  @override
  String get magicLinkSent => 'マジックリンクを送信しました。';

  @override
  String get apiError => 'APIエラー';
}
