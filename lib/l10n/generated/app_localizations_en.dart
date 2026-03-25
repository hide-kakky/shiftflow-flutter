// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ShiftFlow';

  @override
  String get authTitle => 'Sign in';

  @override
  String get authDescription => 'Use Magic Link with Supabase Auth.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get sendMagicLink => 'Send magic link';

  @override
  String get signInWithPassword => 'Sign in with password';

  @override
  String get emailPasswordRequired => 'Email and password are required.';

  @override
  String get authInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get authInvalidCredentialsHint =>
      'Check your input and reset your password if needed.';

  @override
  String get authGenericError => 'Failed to sign in';

  @override
  String get authRequestCompleted => 'Authentication request sent.';

  @override
  String get qaPanelTitle => 'QA Input Helper';

  @override
  String get qaPanelDescription =>
      'Select an account email to autofill the login form.';

  @override
  String get signOut => 'Sign out';

  @override
  String get navHome => 'Home';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navMessages => 'Messages';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAdmin => 'Admin';

  @override
  String get refresh => 'Refresh';

  @override
  String get noData => 'No data';

  @override
  String get createTask => 'Create task';

  @override
  String get createMessage => 'Create message';

  @override
  String get toggleRead => 'Toggle read';

  @override
  String get pinMessage => 'Toggle pin';

  @override
  String get pinActionDenied => 'Only managers can pin messages.';

  @override
  String get readStateUpdated => 'Read state updated.';

  @override
  String get readStatus => 'Read status';

  @override
  String get readStatusLimited =>
      'Read status list is available for authorized users only.';

  @override
  String get load => 'Load';

  @override
  String get comments => 'Comments';

  @override
  String get addComment => 'Add comment';

  @override
  String get noComments => 'No comments yet';

  @override
  String get readUsers => 'Read users';

  @override
  String get unreadUsers => 'Unread users';

  @override
  String get title => 'Title';

  @override
  String get body => 'Body';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get taskDueDate => 'Due date';

  @override
  String get selectDueDate => 'Select due date';

  @override
  String get clearDueDate => 'Clear due date';

  @override
  String get taskPriority => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get taskAssignees => 'Assignees';

  @override
  String get noAssigneesFound => 'No assignees found';

  @override
  String get taskAttachments => 'Attachments';

  @override
  String get pickAttachments => 'Select attachments';

  @override
  String get taskAttachmentUploadSuccess => 'Attachments uploaded';

  @override
  String get taskAttachmentPartialUpload => 'Some attachments failed to upload';

  @override
  String get taskTitleRequired => 'Title is required';

  @override
  String get noFolderSelected => 'No folder';

  @override
  String get noTemplateSelected => 'No template';

  @override
  String get messageTitleRequired => 'Title is required';

  @override
  String get messageAttachmentUploadSuccess => 'Attachments uploaded';

  @override
  String get messageAttachmentPartialUpload =>
      'Some attachments failed to upload';

  @override
  String get messageFolderFilter => 'Folder';

  @override
  String get messageUnreadOnly => 'Unread only';

  @override
  String get taskScopeMy => 'My';

  @override
  String get taskScopeCreated => 'Created';

  @override
  String get taskScopeAll => 'All';

  @override
  String get markComplete => 'Mark complete';

  @override
  String get profile => 'Profile';

  @override
  String get displayName => 'Display name';

  @override
  String get displayNameHint => 'Name shown to the team';

  @override
  String get displayNameRequired => 'Display name is required.';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get profileUpdated => 'Profile updated.';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get role => 'Role';

  @override
  String get permissionDenied => 'You do not have permission.';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get users => 'Users';

  @override
  String get folders => 'Folders';

  @override
  String get templates => 'Templates';

  @override
  String get organizations => 'Organizations';

  @override
  String get auditLogs => 'Audit logs';

  @override
  String get adminEditUser => 'Edit user';

  @override
  String get adminUserStatus => 'Status';

  @override
  String get adminUserUpdated => 'User updated.';

  @override
  String get adminEditOrganization => 'Edit organization';

  @override
  String get adminOrganizationUpdated => 'Organization updated.';

  @override
  String get adminOrgShortName => 'Short name';

  @override
  String get adminOrgColor => 'Display color';

  @override
  String get adminOrgTimezone => 'Timezone';

  @override
  String get adminCreateFolder => 'Create folder';

  @override
  String get adminEditFolder => 'Edit folder';

  @override
  String get adminArchiveFolder => 'Archive folder';

  @override
  String get adminFolderName => 'Folder name';

  @override
  String get adminFolderColor => 'Folder color';

  @override
  String get adminIsPublic => 'Public';

  @override
  String get adminIsActive => 'Active';

  @override
  String get adminFolderCreated => 'Folder created.';

  @override
  String get adminFolderUpdated => 'Folder updated.';

  @override
  String get adminFolderArchived => 'Folder archived.';

  @override
  String get adminSelectFolder => 'Folder';

  @override
  String get adminCreateTemplate => 'Create template';

  @override
  String get adminTemplateName => 'Template name';

  @override
  String get adminTitleFormat => 'Title format';

  @override
  String get adminBodyFormat => 'Body format';

  @override
  String get adminTemplateCreated => 'Template created.';

  @override
  String get adminNoFoldersForTemplates => 'Create a folder first.';

  @override
  String get magicLinkSent => 'Magic link sent.';

  @override
  String get apiError => 'API error';
}
