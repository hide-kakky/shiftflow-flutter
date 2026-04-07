import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ShiftFlow'**
  String get appTitle;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authTitle;

  /// No description provided for @authDescription.
  ///
  /// In en, this message translates to:
  /// **'Use Magic Link with Supabase Auth.'**
  String get authDescription;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @sendMagicLink.
  ///
  /// In en, this message translates to:
  /// **'Send magic link'**
  String get sendMagicLink;

  /// No description provided for @signInWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Sign in with password'**
  String get signInWithPassword;

  /// No description provided for @emailPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Email and password are required.'**
  String get emailPasswordRequired;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authInvalidCredentials;

  /// No description provided for @authInvalidCredentialsHint.
  ///
  /// In en, this message translates to:
  /// **'Check your input and reset your password if needed.'**
  String get authInvalidCredentialsHint;

  /// No description provided for @authGenericError.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in'**
  String get authGenericError;

  /// No description provided for @authRequestCompleted.
  ///
  /// In en, this message translates to:
  /// **'Authentication request sent.'**
  String get authRequestCompleted;

  /// No description provided for @qaPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'QA Input Helper'**
  String get qaPanelTitle;

  /// No description provided for @qaPanelDescription.
  ///
  /// In en, this message translates to:
  /// **'Select an account email to autofill the login form.'**
  String get qaPanelDescription;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @homeHeroBadge.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get homeHeroBadge;

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'See today\'s work clearly, without noise.'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroDescription.
  ///
  /// In en, this message translates to:
  /// **'Review open tasks, unread messages, and pending approvals in one place, then move directly to the next screen you need.'**
  String get homeHeroDescription;

  /// No description provided for @homeHeroPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Current summary'**
  String get homeHeroPanelTitle;

  /// No description provided for @homeSectionOverviewBadge.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get homeSectionOverviewBadge;

  /// No description provided for @homeSectionOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Put the important numbers first.'**
  String get homeSectionOverviewTitle;

  /// No description provided for @homeSectionOverviewDescription.
  ///
  /// In en, this message translates to:
  /// **'This home view keeps the calm spacing and hierarchy inspired by Notion, while surfacing only the numbers needed for day-to-day decisions.'**
  String get homeSectionOverviewDescription;

  /// No description provided for @homeOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'Open tasks'**
  String get homeOpenTasks;

  /// No description provided for @homeOpenTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Tasks not yet completed. Start here to review priority and due dates.'**
  String get homeOpenTasksHint;

  /// No description provided for @homeUnreadMessages.
  ///
  /// In en, this message translates to:
  /// **'Unread messages'**
  String get homeUnreadMessages;

  /// No description provided for @homeUnreadMessagesHint.
  ///
  /// In en, this message translates to:
  /// **'Messages that still need attention. Use this to avoid missing shared updates.'**
  String get homeUnreadMessagesHint;

  /// No description provided for @homePendingUsers.
  ///
  /// In en, this message translates to:
  /// **'Pending users'**
  String get homePendingUsers;

  /// No description provided for @homePendingUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Users waiting for approval or status updates. Handle them from Admin.'**
  String get homePendingUsersHint;

  /// No description provided for @homePendingUsersHintMember.
  ///
  /// In en, this message translates to:
  /// **'This is mainly for admins. Your role does not need follow-up here.'**
  String get homePendingUsersHintMember;

  /// No description provided for @homeQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActionsTitle;

  /// No description provided for @homeQuickActionsDescription.
  ///
  /// In en, this message translates to:
  /// **'The home screen keeps the main routes explicit so you can move to the right workspace with minimal friction.'**
  String get homeQuickActionsDescription;

  /// No description provided for @homeActionTasksDescription.
  ///
  /// In en, this message translates to:
  /// **'Review due dates, assignees, and priority before working.'**
  String get homeActionTasksDescription;

  /// No description provided for @homeActionMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Check unread threads, comments, and pinned updates.'**
  String get homeActionMessagesDescription;

  /// No description provided for @homeActionSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Update display name, theme, language, and profile image.'**
  String get homeActionSettingsDescription;

  /// No description provided for @homeActionAdminDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage users, organizations, folders, and audit logs.'**
  String get homeActionAdminDescription;

  /// No description provided for @homeFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'What needs attention now'**
  String get homeFocusTitle;

  /// No description provided for @homeFocusDescription.
  ///
  /// In en, this message translates to:
  /// **'Instead of showing numbers only, the home view summarizes the next action worth taking.'**
  String get homeFocusDescription;

  /// No description provided for @homeFocusTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks are currently in progress'**
  String homeFocusTasksTitle(int count);

  /// No description provided for @homeFocusTasksDescription.
  ///
  /// In en, this message translates to:
  /// **'Open the task list and review approaching due dates or uneven task ownership.'**
  String get homeFocusTasksDescription;

  /// No description provided for @homeFocusMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} unread messages need review'**
  String homeFocusMessagesTitle(int count);

  /// No description provided for @homeFocusMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Unread items may include broad announcements or template-based posts. Review them before continuing work.'**
  String get homeFocusMessagesDescription;

  /// No description provided for @homeFocusPendingUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} users are waiting for approval'**
  String homeFocusPendingUsersTitle(int count);

  /// No description provided for @homeFocusPendingUsersDescription.
  ///
  /// In en, this message translates to:
  /// **'Admins should review user status and update organization or role settings if needed.'**
  String get homeFocusPendingUsersDescription;

  /// No description provided for @homeFocusStableTitle.
  ///
  /// In en, this message translates to:
  /// **'No major backlog is visible now'**
  String get homeFocusStableTitle;

  /// No description provided for @homeFocusStableDescription.
  ///
  /// In en, this message translates to:
  /// **'The main indicators look stable. Continue with the detailed screens as needed.'**
  String get homeFocusStableDescription;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get createTask;

  /// No description provided for @createMessage.
  ///
  /// In en, this message translates to:
  /// **'Create message'**
  String get createMessage;

  /// No description provided for @toggleRead.
  ///
  /// In en, this message translates to:
  /// **'Toggle read'**
  String get toggleRead;

  /// No description provided for @pinMessage.
  ///
  /// In en, this message translates to:
  /// **'Toggle pin'**
  String get pinMessage;

  /// No description provided for @pinActionDenied.
  ///
  /// In en, this message translates to:
  /// **'Only managers can pin messages.'**
  String get pinActionDenied;

  /// No description provided for @readStateUpdated.
  ///
  /// In en, this message translates to:
  /// **'Read state updated.'**
  String get readStateUpdated;

  /// No description provided for @readStatus.
  ///
  /// In en, this message translates to:
  /// **'Read status'**
  String get readStatus;

  /// No description provided for @readStatusLimited.
  ///
  /// In en, this message translates to:
  /// **'Read status list is available for authorized users only.'**
  String get readStatusLimited;

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get load;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add comment'**
  String get addComment;

  /// No description provided for @noComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noComments;

  /// No description provided for @readUsers.
  ///
  /// In en, this message translates to:
  /// **'Read users'**
  String get readUsers;

  /// No description provided for @unreadUsers.
  ///
  /// In en, this message translates to:
  /// **'Unread users'**
  String get unreadUsers;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @body.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get body;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @taskDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get taskDueDate;

  /// No description provided for @selectDueDate.
  ///
  /// In en, this message translates to:
  /// **'Select due date'**
  String get selectDueDate;

  /// No description provided for @clearDueDate.
  ///
  /// In en, this message translates to:
  /// **'Clear due date'**
  String get clearDueDate;

  /// No description provided for @taskPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskPriority;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @taskAssignees.
  ///
  /// In en, this message translates to:
  /// **'Assignees'**
  String get taskAssignees;

  /// No description provided for @noAssigneesFound.
  ///
  /// In en, this message translates to:
  /// **'No assignees found'**
  String get noAssigneesFound;

  /// No description provided for @taskAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get taskAttachments;

  /// No description provided for @pickAttachments.
  ///
  /// In en, this message translates to:
  /// **'Select attachments'**
  String get pickAttachments;

  /// No description provided for @taskAttachmentUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Attachments uploaded'**
  String get taskAttachmentUploadSuccess;

  /// No description provided for @taskAttachmentPartialUpload.
  ///
  /// In en, this message translates to:
  /// **'Some attachments failed to upload'**
  String get taskAttachmentPartialUpload;

  /// No description provided for @taskTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get taskTitleRequired;

  /// No description provided for @noFolderSelected.
  ///
  /// In en, this message translates to:
  /// **'No folder'**
  String get noFolderSelected;

  /// No description provided for @noTemplateSelected.
  ///
  /// In en, this message translates to:
  /// **'No template'**
  String get noTemplateSelected;

  /// No description provided for @messageTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get messageTitleRequired;

  /// No description provided for @messageAttachmentUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Attachments uploaded'**
  String get messageAttachmentUploadSuccess;

  /// No description provided for @messageAttachmentPartialUpload.
  ///
  /// In en, this message translates to:
  /// **'Some attachments failed to upload'**
  String get messageAttachmentPartialUpload;

  /// No description provided for @messageFolderFilter.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get messageFolderFilter;

  /// No description provided for @messageUnreadOnly.
  ///
  /// In en, this message translates to:
  /// **'Unread only'**
  String get messageUnreadOnly;

  /// No description provided for @taskScopeMy.
  ///
  /// In en, this message translates to:
  /// **'My'**
  String get taskScopeMy;

  /// No description provided for @taskScopeCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get taskScopeCreated;

  /// No description provided for @taskScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get taskScopeAll;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markComplete;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name shown to the team'**
  String get displayNameHint;

  /// No description provided for @displayNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Display name is required.'**
  String get displayNameRequired;

  /// No description provided for @updateProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Update profile image'**
  String get updateProfileImage;

  /// No description provided for @profileImageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile image updated.'**
  String get profileImageUpdated;

  /// No description provided for @profileImageTypeError.
  ///
  /// In en, this message translates to:
  /// **'Only PNG / JPG / WEBP images are supported.'**
  String get profileImageTypeError;

  /// No description provided for @profileImageSizeError.
  ///
  /// In en, this message translates to:
  /// **'Image size must be 2MB or less.'**
  String get profileImageSizeError;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileUpdated;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission.'**
  String get permissionDenied;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @organizations.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get organizations;

  /// No description provided for @auditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit logs'**
  String get auditLogs;

  /// No description provided for @adminEditUser.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get adminEditUser;

  /// No description provided for @adminUserStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get adminUserStatus;

  /// No description provided for @adminUserUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated.'**
  String get adminUserUpdated;

  /// No description provided for @adminEditOrganization.
  ///
  /// In en, this message translates to:
  /// **'Edit organization'**
  String get adminEditOrganization;

  /// No description provided for @adminOrganizationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Organization updated.'**
  String get adminOrganizationUpdated;

  /// No description provided for @adminOrgShortName.
  ///
  /// In en, this message translates to:
  /// **'Short name'**
  String get adminOrgShortName;

  /// No description provided for @adminOrgColor.
  ///
  /// In en, this message translates to:
  /// **'Display color'**
  String get adminOrgColor;

  /// No description provided for @adminOrgTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get adminOrgTimezone;

  /// No description provided for @adminCreateFolder.
  ///
  /// In en, this message translates to:
  /// **'Create folder'**
  String get adminCreateFolder;

  /// No description provided for @adminEditFolder.
  ///
  /// In en, this message translates to:
  /// **'Edit folder'**
  String get adminEditFolder;

  /// No description provided for @adminArchiveFolder.
  ///
  /// In en, this message translates to:
  /// **'Archive folder'**
  String get adminArchiveFolder;

  /// No description provided for @adminFolderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get adminFolderName;

  /// No description provided for @adminFolderColor.
  ///
  /// In en, this message translates to:
  /// **'Folder color'**
  String get adminFolderColor;

  /// No description provided for @adminIsPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get adminIsPublic;

  /// No description provided for @adminIsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminIsActive;

  /// No description provided for @adminFolderCreated.
  ///
  /// In en, this message translates to:
  /// **'Folder created.'**
  String get adminFolderCreated;

  /// No description provided for @adminFolderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Folder updated.'**
  String get adminFolderUpdated;

  /// No description provided for @adminFolderArchived.
  ///
  /// In en, this message translates to:
  /// **'Folder archived.'**
  String get adminFolderArchived;

  /// No description provided for @adminSelectFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get adminSelectFolder;

  /// No description provided for @adminCreateTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create template'**
  String get adminCreateTemplate;

  /// No description provided for @adminTemplateName.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get adminTemplateName;

  /// No description provided for @adminTitleFormat.
  ///
  /// In en, this message translates to:
  /// **'Title format'**
  String get adminTitleFormat;

  /// No description provided for @adminBodyFormat.
  ///
  /// In en, this message translates to:
  /// **'Body format'**
  String get adminBodyFormat;

  /// No description provided for @adminTemplateCreated.
  ///
  /// In en, this message translates to:
  /// **'Template created.'**
  String get adminTemplateCreated;

  /// No description provided for @adminNoFoldersForTemplates.
  ///
  /// In en, this message translates to:
  /// **'Create a folder first.'**
  String get adminNoFoldersForTemplates;

  /// No description provided for @magicLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Magic link sent.'**
  String get magicLinkSent;

  /// No description provided for @apiError.
  ///
  /// In en, this message translates to:
  /// **'API error'**
  String get apiError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
