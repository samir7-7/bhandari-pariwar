import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

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
    Locale('ne')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Bhandari Pariwar'**
  String get appTitle;

  /// No description provided for @familyTree.
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get familyTree;

  /// No description provided for @notices.
  ///
  /// In en, this message translates to:
  /// **'Notices'**
  String get notices;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @nepali.
  ///
  /// In en, this message translates to:
  /// **'Nepali'**
  String get nepali;

  /// No description provided for @familyOverview.
  ///
  /// In en, this message translates to:
  /// **'Family Overview'**
  String get familyOverview;

  /// No description provided for @historyAndSayings.
  ///
  /// In en, this message translates to:
  /// **'History & Sayings'**
  String get historyAndSayings;

  /// No description provided for @committee.
  ///
  /// In en, this message translates to:
  /// **'Committee'**
  String get committee;

  /// No description provided for @chairman.
  ///
  /// In en, this message translates to:
  /// **'Chairman'**
  String get chairman;

  /// No description provided for @noNotices.
  ///
  /// In en, this message translates to:
  /// **'No notices yet'**
  String get noNotices;

  /// No description provided for @publishedOn.
  ///
  /// In en, this message translates to:
  /// **'Published on {date}'**
  String publishedOn(String date);

  /// No description provided for @born.
  ///
  /// In en, this message translates to:
  /// **'Born'**
  String get born;

  /// No description provided for @died.
  ///
  /// In en, this message translates to:
  /// **'Died'**
  String get died;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @alive.
  ///
  /// In en, this message translates to:
  /// **'Living'**
  String get alive;

  /// No description provided for @deceased.
  ///
  /// In en, this message translates to:
  /// **'Deceased'**
  String get deceased;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth Date'**
  String get birthDate;

  /// No description provided for @deathDate.
  ///
  /// In en, this message translates to:
  /// **'Death Date'**
  String get deathDate;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @addChild.
  ///
  /// In en, this message translates to:
  /// **'Add Child'**
  String get addChild;

  /// No description provided for @addSpouse.
  ///
  /// In en, this message translates to:
  /// **'Add Spouse'**
  String get addSpouse;

  /// No description provided for @editMember.
  ///
  /// In en, this message translates to:
  /// **'Edit Member'**
  String get editMember;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

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

  /// No description provided for @adminLogin.
  ///
  /// In en, this message translates to:
  /// **'Admin Login'**
  String get adminLogin;

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

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get loginFailed;

  /// No description provided for @addNotice.
  ///
  /// In en, this message translates to:
  /// **'Add Notice'**
  String get addNotice;

  /// No description provided for @noticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noticeTitle;

  /// No description provided for @noticeBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get noticeBody;

  /// No description provided for @sendNotification.
  ///
  /// In en, this message translates to:
  /// **'Send push notification'**
  String get sendNotification;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @editContent.
  ///
  /// In en, this message translates to:
  /// **'Edit Content'**
  String get editContent;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @familyMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} family members'**
  String familyMembers(int count);

  /// No description provided for @expandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand All'**
  String get expandAll;

  /// No description provided for @collapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse All'**
  String get collapseAll;

  /// No description provided for @searchMember.
  ///
  /// In en, this message translates to:
  /// **'Search member...'**
  String get searchMember;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Bhandari Pariwar'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore your family heritage'**
  String get welcomeSubtitle;

  /// No description provided for @chooseLanguagePrompt.
  ///
  /// In en, this message translates to:
  /// **'Please choose your preferred language to continue'**
  String get chooseLanguagePrompt;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact & Feedback'**
  String get contactInfo;

  /// No description provided for @relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationship;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @spouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get spouse;

  /// No description provided for @parent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parent;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @viewFamilyTree.
  ///
  /// In en, this message translates to:
  /// **'View Family Tree'**
  String get viewFamilyTree;

  /// No description provided for @viewNotices.
  ///
  /// In en, this message translates to:
  /// **'View Notices'**
  String get viewNotices;

  /// No description provided for @aboutFamily.
  ///
  /// In en, this message translates to:
  /// **'About Family'**
  String get aboutFamily;

  /// No description provided for @totalMembers.
  ///
  /// In en, this message translates to:
  /// **'Total Members'**
  String get totalMembers;

  /// No description provided for @recentNotices.
  ///
  /// In en, this message translates to:
  /// **'Recent Notices'**
  String get recentNotices;

  /// No description provided for @quickLinks.
  ///
  /// In en, this message translates to:
  /// **'Quick Links'**
  String get quickLinks;

  /// No description provided for @seedData.
  ///
  /// In en, this message translates to:
  /// **'Load Family Data'**
  String get seedData;

  /// No description provided for @seedDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import family members into database'**
  String get seedDataSubtitle;

  /// No description provided for @seedDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will load all family members into the database. Existing members with the same IDs will be overwritten. Continue?'**
  String get seedDataConfirm;

  /// No description provided for @seedDataSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully loaded {count} family members!'**
  String seedDataSuccess(int count);

  /// No description provided for @seedDataInProgress.
  ///
  /// In en, this message translates to:
  /// **'Loading family data...'**
  String get seedDataInProgress;

  /// No description provided for @clearData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Members'**
  String get clearData;

  /// No description provided for @clearDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all family members from the database. This cannot be undone. Continue?'**
  String get clearDataConfirm;

  /// No description provided for @clearDataSuccess.
  ///
  /// In en, this message translates to:
  /// **'All family members have been removed.'**
  String get clearDataSuccess;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name...'**
  String get searchHint;

  /// No description provided for @goToInTree.
  ///
  /// In en, this message translates to:
  /// **'Go to in tree'**
  String get goToInTree;

  /// No description provided for @addChildToMember.
  ///
  /// In en, this message translates to:
  /// **'Add Child'**
  String get addChildToMember;

  /// No description provided for @addSpouseToMember.
  ///
  /// In en, this message translates to:
  /// **'Add Spouse'**
  String get addSpouseToMember;

  /// No description provided for @editThisMember.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editThisMember;

  /// No description provided for @selectParent.
  ///
  /// In en, this message translates to:
  /// **'Select Parent'**
  String get selectParent;

  /// No description provided for @selectParentHint.
  ///
  /// In en, this message translates to:
  /// **'Search and select the father/parent'**
  String get selectParentHint;

  /// No description provided for @noSpouse.
  ///
  /// In en, this message translates to:
  /// **'No spouse linked'**
  String get noSpouse;

  /// No description provided for @hasSpouseAlready.
  ///
  /// In en, this message translates to:
  /// **'This member already has a spouse'**
  String get hasSpouseAlready;

  /// No description provided for @memberAdded.
  ///
  /// In en, this message translates to:
  /// **'Member added successfully!'**
  String get memberAdded;

  /// No description provided for @spouseAdded.
  ///
  /// In en, this message translates to:
  /// **'Spouse linked successfully!'**
  String get spouseAdded;

  /// No description provided for @generation.
  ///
  /// In en, this message translates to:
  /// **'Generation'**
  String get generation;

  /// No description provided for @tapToViewDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap a member to view details'**
  String get tapToViewDetails;

  /// No description provided for @longPressToToggle.
  ///
  /// In en, this message translates to:
  /// **'Long press to expand/collapse'**
  String get longPressToToggle;

  /// No description provided for @familyName.
  ///
  /// In en, this message translates to:
  /// **'Family Name'**
  String get familyName;

  /// No description provided for @fatherName.
  ///
  /// In en, this message translates to:
  /// **'Father\'s Name'**
  String get fatherName;

  /// No description provided for @grandfatherName.
  ///
  /// In en, this message translates to:
  /// **'Grandfather\'s Name'**
  String get grandfatherName;

  /// No description provided for @matchFound.
  ///
  /// In en, this message translates to:
  /// **'Match found! Adding under {parentName}'**
  String matchFound(String parentName);

  /// No description provided for @noMatchFound.
  ///
  /// In en, this message translates to:
  /// **'No matching parent found. Please select manually.'**
  String get noMatchFound;

  /// No description provided for @confirmAddUnder.
  ///
  /// In en, this message translates to:
  /// **'Add this member under {parentName}?'**
  String confirmAddUnder(String parentName);
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
      <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
