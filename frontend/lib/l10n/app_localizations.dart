import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isSwahili => locale.languageCode == 'sw';

  String t(String en, String sw) => isSwahili ? sw : en;

  // ─── App General ────────────────────────────────────────────────
  String get appName => t('Citizen Voice', 'Sauti ya Raia');
  String get appTagline =>
      t('Your voice matters', 'Sauti yako ina umuhimu');
  String get loading => t('Loading...', 'Inapakia...');
  String get save => t('Save', 'Hifadhi');
  String get cancel => t('Cancel', 'Ghairi');
  String get submit => t('Submit', 'Wasilisha');
  String get confirm => t('Confirm', 'Thibitisha');
  String get back => t('Back', 'Rudi');
  String get next => t('Next', 'Endelea');
  String get done => t('Done', 'Imekamilika');
  String get error => t('Error', 'Hitilafu');
  String get success => t('Success', 'Imefanikiwa');
  String get retry => t('Retry', 'Jaribu Tena');
  String get search => t('Search', 'Tafuta');
  String get filter => t('Filter', 'Chagua');
  String get all => t('All', 'Zote');
  String get close => t('Close', 'Funga');
  String get yes => t('Yes', 'Ndiyo');
  String get no => t('No', 'Hapana');

  // ─── Auth ────────────────────────────────────────────────────────
  String get login => t('Login', 'Ingia');
  String get logout => t('Logout', 'Toka');
  String get register => t('Register', 'Jisajili');
  String get phoneNumber => t('Phone Number', 'Nambari ya Simu');
  String get password => t('Password', 'Nenosiri');
  String get confirmPassword => t('Confirm Password', 'Thibitisha Nenosiri');
  String get fullName => t('Full Name', 'Jina Kamili');
  String get nationalId => t('National ID', 'Namba ya Kitambulisho');
  String get dontHaveAccount =>
      t("Don't have an account?", 'Huna akaunti?');
  String get alreadyHaveAccount =>
      t('Already have an account?', 'Una akaunti tayari?');
  String get forgotPassword => t('Forgot Password?', 'Umesahau Nenosiri?');
  String get createAccount => t('Create Account', 'Fungua Akaunti');
  String get verifyPhone => t('Verify Phone', 'Thibitisha Simu');
  String get enterOtp => t('Enter OTP Code', 'Weka Nambari ya OTP');
  String get resendOtp => t('Resend OTP', 'Tuma OTP Tena');

  // ─── Navigation ──────────────────────────────────────────────────
  String get home => t('Home', 'Nyumbani');
  String get myComplaints => t('My Complaints', 'Malalamiko Yangu');
  String get newComplaint => t('New Complaint', 'Lalamiko Jipya');
  String get track => t('Track', 'Fuatilia');
  String get profile => t('Profile', 'Wasifu');
  String get notifications => t('Notifications', 'Arifa');
  String get settings => t('Settings', 'Mipangilio');

  // ─── Dashboard ───────────────────────────────────────────────────
  String get welcome => t('Welcome', 'Karibu');
  String get goodMorning => t('Good Morning', 'Habari za Asubuhi');
  String get goodAfternoon => t('Good Afternoon', 'Habari za Mchana');
  String get goodEvening => t('Good Evening', 'Habari za Jioni');
  String get totalComplaints => t('Total Complaints', 'Jumla ya Malalamiko');
  String get pendingComplaints =>
      t('Pending', 'Yanayosubiri');
  String get inProgressComplaints =>
      t('In Progress', 'Yanayoshughulikiwa');
  String get resolvedComplaints => t('Resolved', 'Yaliyosuluhiwa');
  String get escalatedComplaints => t('Escalated', 'Yaliyopandishwa');
  String get recentComplaints => t('Recent Complaints', 'Malalamiko ya Hivi Karibuni');
  String get viewAll => t('View All', 'Ona Yote');
  String get quickStats => t('Quick Stats', 'Takwimu za Haraka');

  // ─── Complaint Form ───────────────────────────────────────────────
  String get submitComplaint =>
      t('Submit Complaint', 'Wasilisha Lalamiko');
  String get complaintTitle => t('Complaint Title', 'Kichwa cha Lalamiko');
  String get complaintDescription =>
      t('Description', 'Maelezo ya Kina');
  String get category => t('Category', 'Aina');
  String get selectCategory => t('Select Category', 'Chagua Aina');
  String get location => t('Location', 'Mahali');
  String get mtaa => t('Mtaa / Street', 'Mtaa');
  String get ward => t('Ward', 'Kata');
  String get district => t('District', 'Wilaya');
  String get region => t('Region', 'Mkoa');
  String get attachments => t('Attachments', 'Viambatisho');
  String get addPhoto => t('Add Photo', 'Ongeza Picha');
  String get addFile => t('Add File', 'Ongeza Faili');
  String get submitAnonymously =>
      t('Submit Anonymously', 'Wasilisha Bila Jina');
  String get markUrgent => t('Mark as Urgent', 'Ikiwa ni Dharura');
  String get characterCount => t('characters', 'herufi');
  String get titleHint =>
      t('Brief title of your complaint', 'Kichwa kifupi cha lalamiko lako');
  String get descriptionHint => t(
      'Describe your complaint in detail...',
      'Elezea lalamiko lako kwa undani...');
  String get mtaaHint =>
      t('Enter your mtaa/street name', 'Weka jina la mtaa wako');

  // ─── Categories ──────────────────────────────────────────────────
  String get catInfrastructure => t('Infrastructure', 'Miundombinu');
  String get catWater => t('Water', 'Maji');
  String get catElectricity => t('Electricity', 'Umeme');
  String get catHealth => t('Health', 'Afya');
  String get catEducation => t('Education', 'Elimu');
  String get catSecurity => t('Security', 'Usalama');
  String get catEnvironment => t('Environment', 'Mazingira');
  String get catSocialServices => t('Social Services', 'Huduma za Jamii');
  String get catCorruption => t('Corruption', 'Rushwa');
  String get catOther => t('Other', 'Nyingine');

  // ─── Status Labels ───────────────────────────────────────────────
  String get statusPending => t('Pending', 'Inasubiri');
  String get statusInProgress => t('In Progress', 'Inashughulikiwa');
  String get statusEscalated => t('Escalated', 'Imepandishwa');
  String get statusResolved => t('Resolved', 'Imesuluhiwa');
  String get statusClosed => t('Closed', 'Imefungwa');

  // ─── Escalation ──────────────────────────────────────────────────
  String get escalationJourney =>
      t('Escalation Journey', 'Safari ya Kupandishwa');
  String get currentLevel => t('Current Level', 'Kiwango cha Sasa');
  String get nextEscalation =>
      t('Next Escalation', 'Kupandishwa Ijayo');
  String get daysRemaining => t('days remaining', 'siku zilizobaki');
  String get escalatedFrom => t('Escalated from', 'Imepandishwa kutoka');
  String get autoEscalation =>
      t('Auto-Escalation', 'Kupandishwa Kiotomatiki');
  String get escalationInfo => t(
      'Complaints are automatically escalated if not addressed within the specified timeframe',
      'Malalamiko hupandishwa kiotomatiki kama hayashughulikiwa ndani ya muda uliowekwa');

  // ─── Tracking ────────────────────────────────────────────────────
  String get trackComplaint =>
      t('Track Complaint', 'Fuatilia Lalamiko');
  String get trackingCode => t('Tracking Code', 'Nambari ya Ufuatiliaji');
  String get enterTrackingCode =>
      t('Enter tracking code', 'Weka nambari ya ufuatiliaji');
  String get trackNow => t('Track Now', 'Fuatilia Sasa');
  String get complaintNotFound =>
      t('Complaint not found', 'Lalamiko halipatikani');
  String get yourTrackingCode =>
      t('Your Tracking Code', 'Nambari Yako ya Ufuatiliaji');

  // ─── Comments ────────────────────────────────────────────────────
  String get comments => t('Comments', 'Maoni');
  String get addComment => t('Add Comment', 'Ongeza Maoni');
  String get writeComment =>
      t('Write a comment...', 'Andika maoni...');
  String get officialResponse =>
      t('Official Response', 'Majibu Rasmi');
  String get noComments =>
      t('No comments yet', 'Hakuna maoni bado');

  // ─── Profile ─────────────────────────────────────────────────────
  String get editProfile => t('Edit Profile', 'Hariri Wasifu');
  String get language => t('Language', 'Lugha');
  String get darkMode => t('Dark Mode', 'Hali ya Usiku');
  String get notifications2 => t('Notifications', 'Arifa');
  String get aboutApp => t('About App', 'Kuhusu Programu');
  String get version => t('Version', 'Toleo');
  String get privacyPolicy => t('Privacy Policy', 'Sera ya Faragha');
  String get termsOfService =>
      t('Terms of Service', 'Masharti ya Huduma');
  String get contactSupport =>
      t('Contact Support', 'Wasiliana na Msaada');

  // ─── Levels ──────────────────────────────────────────────────────
  String get levelMtaa => t('Mtaa Level', 'Ngazi ya Mtaa');
  String get levelWard => t('Ward Level', 'Ngazi ya Kata');
  String get levelDistrict => t('District Level', 'Ngazi ya Wilaya');
  String get levelRegion => t('Regional Level', 'Ngazi ya Mkoa');
  String get levelNational => t('National Level', 'Ngazi ya Taifa');

  // ─── Errors & Validation ─────────────────────────────────────────
  String get fieldRequired => t('This field is required', 'Sehemu hii inahitajika');
  String get invalidPhone => t('Invalid phone number', 'Nambari ya simu si sahihi');
  String get passwordTooShort =>
      t('Password must be at least 6 characters', 'Nenosiri lazima liwe na herufi 6+');
  String get passwordsDoNotMatch => t('Passwords do not match', 'Manenosiri hayafanani');
  String get somethingWentWrong =>
      t('Something went wrong', 'Kuna hitilafu fulani');

  // ─── Confirmation ─────────────────────────────────────────────────
  String get complaintSubmitted =>
      t('Complaint Submitted!', 'Lalamiko Limewasilishwa!');
  String get complaintSubmittedDesc => t(
      'Your complaint has been submitted and will be reviewed by the Mtaa authority.',
      'Lalamiko lako limewasilishwa na litapitiwa na mamlaka ya Mtaa.');
  String get saveTrackingCode =>
      t('Save your tracking code:', 'Hifadhi nambari yako ya ufuatiliaji:');
  String get upvotes => t('Upvotes', 'Idhini');
  String get submittedOn => t('Submitted on', 'Iliwasilishwa');
  String get lastUpdated => t('Last updated', 'Ilisasishwa mwisho');
  String get noComplaintsYet =>
      t('No complaints yet', 'Hakuna malalamiko bado');
  String get submitFirstComplaint => t(
      'Tap the + button to submit your first complaint',
      'Bonyeza kitufe cha + kuwasilisha lalamiko lako la kwanza');
  String get complaintDetails => t('Complaint Details', 'Maelezo ya Lalamiko');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'sw'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
