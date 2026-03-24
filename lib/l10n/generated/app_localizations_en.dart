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
  String get sendMagicLink => 'Send magic link';

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
  String get taskTitleRequired => 'Title is required';

  @override
  String get markComplete => 'Mark complete';

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
  String get magicLinkSent => 'Magic link sent.';

  @override
  String get apiError => 'API error';
}
