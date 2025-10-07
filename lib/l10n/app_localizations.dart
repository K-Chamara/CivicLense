import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('si'),
    Locale('ta'),
  ];

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @welcomeToCivicLense.
  ///
  /// In en, this message translates to:
  /// **'Welcome to CivicLense'**
  String get welcomeToCivicLense;

  /// No description provided for @yourGovernmentTransparency.
  ///
  /// In en, this message translates to:
  /// **'Your Government Transparency Partner'**
  String get yourGovernmentTransparency;

  /// No description provided for @trackingBudget.
  ///
  /// In en, this message translates to:
  /// **'Tracking Budget'**
  String get trackingBudget;

  /// No description provided for @monitoringTenders.
  ///
  /// In en, this message translates to:
  /// **'Monitoring Tenders'**
  String get monitoringTenders;

  /// No description provided for @followingProjects.
  ///
  /// In en, this message translates to:
  /// **'Following Projects'**
  String get followingProjects;

  /// No description provided for @raisingConcerns.
  ///
  /// In en, this message translates to:
  /// **'Raising Concerns'**
  String get raisingConcerns;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

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

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @citizen.
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get citizen;

  /// No description provided for @ngo.
  ///
  /// In en, this message translates to:
  /// **'NGO/Private Contractor'**
  String get ngo;

  /// No description provided for @journalist.
  ///
  /// In en, this message translates to:
  /// **'Journalist'**
  String get journalist;

  /// No description provided for @communityLeader.
  ///
  /// In en, this message translates to:
  /// **'Community Leader'**
  String get communityLeader;

  /// No description provided for @researcher.
  ///
  /// In en, this message translates to:
  /// **'Researcher'**
  String get researcher;

  /// No description provided for @government.
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get government;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @systemAdministrator.
  ///
  /// In en, this message translates to:
  /// **'System Administrator'**
  String get systemAdministrator;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @totalBudget.
  ///
  /// In en, this message translates to:
  /// **'Total Budget'**
  String get totalBudget;

  /// No description provided for @allocatedAmount.
  ///
  /// In en, this message translates to:
  /// **'Allocated Amount'**
  String get allocatedAmount;

  /// No description provided for @remainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining Amount'**
  String get remainingAmount;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @subcategory.
  ///
  /// In en, this message translates to:
  /// **'Subcategory'**
  String get subcategory;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @tenders.
  ///
  /// In en, this message translates to:
  /// **'Tenders'**
  String get tenders;

  /// No description provided for @publicTenders.
  ///
  /// In en, this message translates to:
  /// **'Public Tenders'**
  String get publicTenders;

  /// No description provided for @tenderTitle.
  ///
  /// In en, this message translates to:
  /// **'Tender Title'**
  String get tenderTitle;

  /// No description provided for @tenderDescription.
  ///
  /// In en, this message translates to:
  /// **'Tender Description'**
  String get tenderDescription;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @estimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated Value'**
  String get estimatedValue;

  /// No description provided for @submitBid.
  ///
  /// In en, this message translates to:
  /// **'Submit Bid'**
  String get submitBid;

  /// No description provided for @viewTenders.
  ///
  /// In en, this message translates to:
  /// **'View Tenders'**
  String get viewTenders;

  /// No description provided for @bidAmount.
  ///
  /// In en, this message translates to:
  /// **'Bid Amount'**
  String get bidAmount;

  /// No description provided for @bidders.
  ///
  /// In en, this message translates to:
  /// **'Bidders'**
  String get bidders;

  /// No description provided for @totalBids.
  ///
  /// In en, this message translates to:
  /// **'Total Bids'**
  String get totalBids;

  /// No description provided for @concerns.
  ///
  /// In en, this message translates to:
  /// **'Concerns'**
  String get concerns;

  /// No description provided for @concernManagement.
  ///
  /// In en, this message translates to:
  /// **'Concern Management'**
  String get concernManagement;

  /// No description provided for @publicConcerns.
  ///
  /// In en, this message translates to:
  /// **'Public Concerns'**
  String get publicConcerns;

  /// No description provided for @myConcerns.
  ///
  /// In en, this message translates to:
  /// **'My Concerns'**
  String get myConcerns;

  /// No description provided for @concernTitle.
  ///
  /// In en, this message translates to:
  /// **'Concern Title'**
  String get concernTitle;

  /// No description provided for @concernDescription.
  ///
  /// In en, this message translates to:
  /// **'Concern Description'**
  String get concernDescription;

  /// No description provided for @concernCategory.
  ///
  /// In en, this message translates to:
  /// **'Concern Category'**
  String get concernCategory;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @communities.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get communities;

  /// No description provided for @communityManagement.
  ///
  /// In en, this message translates to:
  /// **'Community Management'**
  String get communityManagement;

  /// No description provided for @joinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join Community'**
  String get joinCommunity;

  /// No description provided for @createCommunity.
  ///
  /// In en, this message translates to:
  /// **'Create Community'**
  String get createCommunity;

  /// No description provided for @communityPosts.
  ///
  /// In en, this message translates to:
  /// **'Community Posts'**
  String get communityPosts;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @postTitle.
  ///
  /// In en, this message translates to:
  /// **'Post Title'**
  String get postTitle;

  /// No description provided for @postContent.
  ///
  /// In en, this message translates to:
  /// **'Post Content'**
  String get postContent;

  /// No description provided for @news.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get news;

  /// No description provided for @mediaHub.
  ///
  /// In en, this message translates to:
  /// **'Media Hub'**
  String get mediaHub;

  /// No description provided for @newsFeed.
  ///
  /// In en, this message translates to:
  /// **'News Feed'**
  String get newsFeed;

  /// No description provided for @articles.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get articles;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @publishReport.
  ///
  /// In en, this message translates to:
  /// **'Publish Report'**
  String get publishReport;

  /// No description provided for @articleTitle.
  ///
  /// In en, this message translates to:
  /// **'Article Title'**
  String get articleTitle;

  /// No description provided for @articleContent.
  ///
  /// In en, this message translates to:
  /// **'Article Content'**
  String get articleContent;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @uploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents'**
  String get uploadDocuments;

  /// No description provided for @viewDocuments.
  ///
  /// In en, this message translates to:
  /// **'View Documents'**
  String get viewDocuments;

  /// No description provided for @documentUpload.
  ///
  /// In en, this message translates to:
  /// **'Document Upload'**
  String get documentUpload;

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

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get updatedAt;

  /// No description provided for @operationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Operation completed successfully'**
  String get operationSuccessful;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get operationFailed;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get pleaseWait;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetSettings;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearData.
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get clearData;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @allocations.
  ///
  /// In en, this message translates to:
  /// **'Allocations'**
  String get allocations;

  /// No description provided for @activeTenders.
  ///
  /// In en, this message translates to:
  /// **'Active Tenders'**
  String get activeTenders;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @raiseConcern.
  ///
  /// In en, this message translates to:
  /// **'Raise a Concern'**
  String get raiseConcern;

  /// No description provided for @raiseConcernSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Empower transparency by reporting issues you notice'**
  String get raiseConcernSubtitle;

  /// No description provided for @concernTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Concern Title'**
  String get concernTitleLabel;

  /// No description provided for @concernTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Brief, clear description of your concern'**
  String get concernTitleHint;

  /// No description provided for @concernTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get concernTitleRequired;

  /// No description provided for @concernTitleMinLength.
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 10 characters'**
  String get concernTitleMinLength;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @analyzeTone.
  ///
  /// In en, this message translates to:
  /// **'Analyze Tone'**
  String get analyzeTone;

  /// No description provided for @toneAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Tone Analysis'**
  String get toneAnalysis;

  /// No description provided for @magnitude.
  ///
  /// In en, this message translates to:
  /// **'Magnitude'**
  String get magnitude;

  /// No description provided for @citizenEngagement.
  ///
  /// In en, this message translates to:
  /// **'Citizen Engagement'**
  String get citizenEngagement;

  /// No description provided for @communitySupport.
  ///
  /// In en, this message translates to:
  /// **'Community Support for Similar Issues'**
  String get communitySupport;

  /// No description provided for @attachEvidence.
  ///
  /// In en, this message translates to:
  /// **'Attach Evidence'**
  String get attachEvidence;

  /// No description provided for @dragDropFiles.
  ///
  /// In en, this message translates to:
  /// **'Drag & drop files here or click to browse'**
  String get dragDropFiles;

  /// No description provided for @supportedFileTypes.
  ///
  /// In en, this message translates to:
  /// **'Supports: JPG, PNG, PDF, DOC, TXT (Max 10MB)'**
  String get supportedFileTypes;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @submitAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Submit Anonymously'**
  String get submitAnonymously;

  /// No description provided for @anonymousDescription.
  ///
  /// In en, this message translates to:
  /// **'Your name will not be visible to others'**
  String get anonymousDescription;

  /// No description provided for @publishConcern.
  ///
  /// In en, this message translates to:
  /// **'Publish Concern'**
  String get publishConcern;

  /// No description provided for @concernSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Concern submitted successfully!'**
  String get concernSubmittedSuccessfully;

  /// No description provided for @concernSubmissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit concern. Please try again.'**
  String get concernSubmissionFailed;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @noConcernsFound.
  ///
  /// In en, this message translates to:
  /// **'No concerns found'**
  String get noConcernsFound;

  /// No description provided for @supports.
  ///
  /// In en, this message translates to:
  /// **'supports'**
  String get supports;

  /// No description provided for @highPriority.
  ///
  /// In en, this message translates to:
  /// **'HIGH PRIORITY'**
  String get highPriority;

  /// No description provided for @ago.
  ///
  /// In en, this message translates to:
  /// **'ago'**
  String get ago;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @dismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get dismissed;

  /// No description provided for @escalated.
  ///
  /// In en, this message translates to:
  /// **'Escalated'**
  String get escalated;

  /// No description provided for @budgetCategory.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetCategory;

  /// No description provided for @tenderCategory.
  ///
  /// In en, this message translates to:
  /// **'Tender'**
  String get tenderCategory;

  /// No description provided for @communityCategory.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityCategory;

  /// No description provided for @systemCategory.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemCategory;

  /// No description provided for @corruptionCategory.
  ///
  /// In en, this message translates to:
  /// **'Corruption'**
  String get corruptionCategory;

  /// No description provided for @transparencyCategory.
  ///
  /// In en, this message translates to:
  /// **'Transparency'**
  String get transparencyCategory;

  /// No description provided for @otherCategory.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherCategory;

  /// No description provided for @complaintType.
  ///
  /// In en, this message translates to:
  /// **'Complaint'**
  String get complaintType;

  /// No description provided for @suggestionType.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get suggestionType;

  /// No description provided for @reportType.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportType;

  /// No description provided for @questionType.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get questionType;

  /// No description provided for @feedbackType.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackType;

  /// No description provided for @lowPriority.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowPriority;

  /// No description provided for @mediumPriority.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mediumPriority;

  /// No description provided for @highPriorityLevel.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get highPriorityLevel;

  /// No description provided for @criticalPriority.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get criticalPriority;

  /// No description provided for @veryNegative.
  ///
  /// In en, this message translates to:
  /// **'Very Negative'**
  String get veryNegative;

  /// No description provided for @negative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get negative;

  /// No description provided for @neutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get neutral;

  /// No description provided for @positive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get positive;

  /// No description provided for @veryPositive.
  ///
  /// In en, this message translates to:
  /// **'Very Positive'**
  String get veryPositive;
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
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
