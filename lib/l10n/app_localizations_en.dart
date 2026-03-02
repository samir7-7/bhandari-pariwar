// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Bhandari Pariwar';

  @override
  String get familyTree => 'Family Tree';

  @override
  String get notices => 'Notices';

  @override
  String get about => 'About';

  @override
  String get settings => 'Settings';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get continueButton => 'Continue';

  @override
  String get english => 'English';

  @override
  String get nepali => 'Nepali';

  @override
  String get familyOverview => 'Family Overview';

  @override
  String get historyAndSayings => 'History & Sayings';

  @override
  String get committee => 'Committee';

  @override
  String get chairman => 'Chairman';

  @override
  String get noNotices => 'No notices yet';

  @override
  String publishedOn(String date) {
    return 'Published on $date';
  }

  @override
  String get born => 'Born';

  @override
  String get died => 'Died';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get alive => 'Living';

  @override
  String get deceased => 'Deceased';

  @override
  String get name => 'Name';

  @override
  String get birthDate => 'Birth Date';

  @override
  String get deathDate => 'Death Date';

  @override
  String get photo => 'Photo';

  @override
  String get addChild => 'Add Child';

  @override
  String get addSpouse => 'Add Spouse';

  @override
  String get editMember => 'Edit Member';

  @override
  String get addMember => 'Add Member';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get adminLogin => 'Admin Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get loginFailed => 'Login failed. Please check your credentials.';

  @override
  String get addNotice => 'Add Notice';

  @override
  String get noticeTitle => 'Title';

  @override
  String get noticeBody => 'Body';

  @override
  String get sendNotification => 'Send push notification';

  @override
  String get publish => 'Publish';

  @override
  String get editContent => 'Edit Content';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get appVersion => 'App Version';

  @override
  String familyMembers(int count) {
    return '$count family members';
  }

  @override
  String get expandAll => 'Expand All';

  @override
  String get collapseAll => 'Collapse All';

  @override
  String get searchMember => 'Search member...';

  @override
  String get noResults => 'No results found';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get welcomeTitle => 'Welcome to Bhandari Pariwar';

  @override
  String get welcomeSubtitle => 'Explore your family heritage';

  @override
  String get chooseLanguagePrompt =>
      'Please choose your preferred language to continue';

  @override
  String get admin => 'Admin';

  @override
  String get contactInfo => 'Contact & Feedback';

  @override
  String get relationship => 'Relationship';

  @override
  String get children => 'Children';

  @override
  String get spouse => 'Spouse';

  @override
  String get parent => 'Parent';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get viewFamilyTree => 'View Family Tree';

  @override
  String get viewNotices => 'View Notices';

  @override
  String get aboutFamily => 'About Family';

  @override
  String get totalMembers => 'Total Members';

  @override
  String get recentNotices => 'Recent Notices';

  @override
  String get quickLinks => 'Quick Links';

  @override
  String get seedData => 'Load Family Data';

  @override
  String get seedDataSubtitle => 'Import family members into database';

  @override
  String get seedDataConfirm =>
      'This will load all family members into the database. Existing members with the same IDs will be overwritten. Continue?';

  @override
  String seedDataSuccess(int count) {
    return 'Successfully loaded $count family members!';
  }

  @override
  String get seedDataInProgress => 'Loading family data...';

  @override
  String get clearData => 'Clear All Members';

  @override
  String get clearDataConfirm =>
      'This will permanently delete all family members from the database. This cannot be undone. Continue?';

  @override
  String get clearDataSuccess => 'All family members have been removed.';

  @override
  String get searchHint => 'Search by name...';

  @override
  String get goToInTree => 'Go to in tree';

  @override
  String get addChildToMember => 'Add Child';

  @override
  String get addSpouseToMember => 'Add Spouse';

  @override
  String get editThisMember => 'Edit';

  @override
  String get selectParent => 'Select Parent';

  @override
  String get selectParentHint => 'Search and select the father/parent';

  @override
  String get noSpouse => 'No spouse linked';

  @override
  String get hasSpouseAlready => 'This member already has a spouse';

  @override
  String get memberAdded => 'Member added successfully!';

  @override
  String get spouseAdded => 'Spouse linked successfully!';

  @override
  String get generation => 'Generation';

  @override
  String get tapToViewDetails => 'Tap a member to view details';

  @override
  String get longPressToToggle => 'Long press to expand/collapse';

  @override
  String get familyName => 'Family Name';

  @override
  String get fatherName => 'Father\'s Name';

  @override
  String get grandfatherName => 'Grandfather\'s Name';

  @override
  String matchFound(String parentName) {
    return 'Match found! Adding under $parentName';
  }

  @override
  String get noMatchFound =>
      'No matching parent found. Please select manually.';

  @override
  String confirmAddUnder(String parentName) {
    return 'Add this member under $parentName?';
  }
}
