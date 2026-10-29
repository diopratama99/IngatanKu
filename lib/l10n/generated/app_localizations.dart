import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

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
    Locale('id')
  ];

  /// App display name. Kept identical across locales for brand consistency.
  ///
  /// In en, this message translates to:
  /// **'IngatanKu'**
  String get appTitle;

  /// Bottom-nav label for the dashboard tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom-nav label for the saved-content (Pustaka) tab.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// Bottom-nav label for the personal notes (Catatan) tab.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navNotes;

  /// Bottom-nav label for the AI chat tab.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get navAssistant;

  /// Bottom-nav label for the user profile tab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Greeting shown before 11 a.m.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// Greeting shown 11 a.m. to 3 p.m.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// Greeting shown 3 p.m. to 6 p.m.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// Greeting shown 6 p.m. onwards.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get greetingNight;

  /// No description provided for @dashboardSectionProgress.
  ///
  /// In en, this message translates to:
  /// **'PROGRESS'**
  String get dashboardSectionProgress;

  /// No description provided for @dashboardSectionRecentNotes.
  ///
  /// In en, this message translates to:
  /// **'YOUR NOTES'**
  String get dashboardSectionRecentNotes;

  /// No description provided for @dashboardSectionFeatures.
  ///
  /// In en, this message translates to:
  /// **'FEATURES'**
  String get dashboardSectionFeatures;

  /// No description provided for @dashboardSectionStats.
  ///
  /// In en, this message translates to:
  /// **'STATS'**
  String get dashboardSectionStats;

  /// No description provided for @dashboardSectionKnowledgeMap.
  ///
  /// In en, this message translates to:
  /// **'KNOWLEDGE MAP'**
  String get dashboardSectionKnowledgeMap;

  /// No description provided for @dashboardStatNotes.
  ///
  /// In en, this message translates to:
  /// **'Saved notes'**
  String get dashboardStatNotes;

  /// No description provided for @dashboardStatTopTag.
  ///
  /// In en, this message translates to:
  /// **'Top tag'**
  String get dashboardStatTopTag;

  /// No description provided for @dashboardKnowledgeMapDetail.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get dashboardKnowledgeMapDetail;

  /// No description provided for @featureWeeklyQuiz.
  ///
  /// In en, this message translates to:
  /// **'Weekly Quiz'**
  String get featureWeeklyQuiz;

  /// No description provided for @featureManageTags.
  ///
  /// In en, this message translates to:
  /// **'Manage Tags'**
  String get featureManageTags;

  /// No description provided for @accountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your IngatanKu identity. Changes sync to the web dashboard immediately.'**
  String get accountSubtitle;

  /// No description provided for @accountSectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'IDENTITY'**
  String get accountSectionIdentity;

  /// No description provided for @accountSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get accountSectionSecurity;

  /// No description provided for @accountSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get accountSectionPreferences;

  /// No description provided for @accountFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountFieldName;

  /// No description provided for @accountFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountFieldEmail;

  /// No description provided for @accountFieldEmailCaption.
  ///
  /// In en, this message translates to:
  /// **'Contact support to change your email.'**
  String get accountFieldEmailCaption;

  /// No description provided for @accountFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountFieldPassword;

  /// No description provided for @accountFieldLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountFieldLanguage;

  /// No description provided for @localeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get localeSystem;

  /// No description provided for @localeSystemCaption.
  ///
  /// In en, this message translates to:
  /// **'Use the device language. Falls back to English.'**
  String get localeSystemCaption;

  /// No description provided for @localeIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get localeIndonesian;

  /// No description provided for @localeEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get localeEnglish;

  /// No description provided for @pickerTitleLanguage.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get pickerTitleLanguage;

  /// No description provided for @profilePageEyebrow.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profilePageEyebrow;

  /// No description provided for @profileFallbackDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get profileFallbackDisplayName;

  /// No description provided for @profileSignOutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOutTooltip;

  /// No description provided for @profileSignOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get profileSignOutDialogTitle;

  /// No description provided for @profileSignOutDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to open your notes.'**
  String get profileSignOutDialogMessage;

  /// No description provided for @profileSignOutDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileSignOutDialogCancel;

  /// No description provided for @profileSignOutDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOutDialogConfirm;

  /// No description provided for @profileSectionSettings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get profileSectionSettings;

  /// No description provided for @profileNavAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileNavAccount;

  /// No description provided for @profileNavStorage.
  ///
  /// In en, this message translates to:
  /// **'Offline storage'**
  String get profileNavStorage;

  /// No description provided for @profileNavAiSearch.
  ///
  /// In en, this message translates to:
  /// **'AI & search'**
  String get profileNavAiSearch;

  /// No description provided for @profileNavPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get profileNavPrivacy;

  /// No description provided for @profileNavAbout.
  ///
  /// In en, this message translates to:
  /// **'About IngatanKu'**
  String get profileNavAbout;

  /// No description provided for @vaultPageEyebrow.
  ///
  /// In en, this message translates to:
  /// **'LIBRARY'**
  String get vaultPageEyebrow;

  /// No description provided for @vaultPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Your notes.'**
  String get vaultPageTitle;

  /// No description provided for @vaultCountEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get vaultCountEmpty;

  /// No description provided for @vaultCountSaved.
  ///
  /// In en, this message translates to:
  /// **'{count} saved notes'**
  String vaultCountSaved(int count);

  /// No description provided for @vaultSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search title, content, or #tag…'**
  String get vaultSearchHint;

  /// No description provided for @vaultLayoutListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Detail view'**
  String get vaultLayoutListTooltip;

  /// No description provided for @vaultLayoutGridTooltip.
  ///
  /// In en, this message translates to:
  /// **'Shelf view'**
  String get vaultLayoutGridTooltip;

  /// No description provided for @vaultFabNewNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get vaultFabNewNote;

  /// No description provided for @vaultEmptyEyebrow.
  ///
  /// In en, this message translates to:
  /// **'EMPTY LIBRARY'**
  String get vaultEmptyEyebrow;

  /// No description provided for @vaultEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start\nwriting'**
  String get vaultEmptyTitle;

  /// No description provided for @vaultEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap \"New note\" at the bottom right to save your first link, you\'ll earn 10 XP.'**
  String get vaultEmptyMessage;

  /// No description provided for @vaultNotFoundEyebrow.
  ///
  /// In en, this message translates to:
  /// **'NOT FOUND'**
  String get vaultNotFoundEyebrow;

  /// No description provided for @vaultNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'\"{query}\"\nisn\'t\nhere'**
  String vaultNotFoundTitle(String query);

  /// No description provided for @vaultNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another keyword, or clear the search.'**
  String get vaultNotFoundMessage;

  /// No description provided for @noteDetailBackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get noteDetailBackTooltip;

  /// No description provided for @noteDetailMoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get noteDetailMoreTooltip;

  /// No description provided for @noteDetailUntitled.
  ///
  /// In en, this message translates to:
  /// **'(Untitled)'**
  String get noteDetailUntitled;

  /// No description provided for @noteDetailEmptyMarkdown.
  ///
  /// In en, this message translates to:
  /// **'_No notes yet._'**
  String get noteDetailEmptyMarkdown;

  /// No description provided for @noteDetailSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe to turn the page'**
  String get noteDetailSwipeHint;

  /// No description provided for @chatStarterAsk.
  ///
  /// In en, this message translates to:
  /// **'What can I ask once I\'ve saved a few notes?'**
  String get chatStarterAsk;

  /// No description provided for @chatStarterHow.
  ///
  /// In en, this message translates to:
  /// **'How do you answer my questions?'**
  String get chatStarterHow;

  /// No description provided for @chatStarterWhat.
  ///
  /// In en, this message translates to:
  /// **'What kinds of things are good to save here?'**
  String get chatStarterWhat;

  /// No description provided for @chatTagSummary.
  ///
  /// In en, this message translates to:
  /// **'Sum up my notes about #{tag}'**
  String chatTagSummary(String tag);

  /// No description provided for @chatTagList.
  ///
  /// In en, this message translates to:
  /// **'What have I saved about #{tag}?'**
  String chatTagList(String tag);

  /// No description provided for @chatTagPoints.
  ///
  /// In en, this message translates to:
  /// **'Give me 3 key points from my #{tag} notes'**
  String chatTagPoints(String tag);

  /// No description provided for @chatTagTips.
  ///
  /// In en, this message translates to:
  /// **'Show me practical tips about #{tag}'**
  String chatTagTips(String tag);

  /// No description provided for @chatTagTry.
  ///
  /// In en, this message translates to:
  /// **'What could I try from my #{tag} notes?'**
  String chatTagTry(String tag);

  /// No description provided for @chatTagPattern.
  ///
  /// In en, this message translates to:
  /// **'What do my #{tag} notes have in common?'**
  String chatTagPattern(String tag);

  /// No description provided for @chatCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare my notes on #{a} and #{b}'**
  String chatCompare(String a, String b);

  /// No description provided for @chatShared.
  ///
  /// In en, this message translates to:
  /// **'What do my #{a} and #{b} notes share?'**
  String chatShared(String a, String b);

  /// No description provided for @chatLink.
  ///
  /// In en, this message translates to:
  /// **'How are #{a} and #{b} connected in my notes?'**
  String chatLink(String a, String b);

  /// No description provided for @chatTitlePoints.
  ///
  /// In en, this message translates to:
  /// **'What are the main points of \'{title}\'?'**
  String chatTitlePoints(String title);

  /// No description provided for @chatTitleSummary.
  ///
  /// In en, this message translates to:
  /// **'Sum up \'{title}\' for me'**
  String chatTitleSummary(String title);

  /// No description provided for @chatTitleTakeaway.
  ///
  /// In en, this message translates to:
  /// **'What can I take away from \'{title}\'?'**
  String chatTitleTakeaway(String title);

  /// No description provided for @chatSource.
  ///
  /// In en, this message translates to:
  /// **'What\'s interesting in my recent {source} notes?'**
  String chatSource(String source);

  /// No description provided for @chatSourceArticle.
  ///
  /// In en, this message translates to:
  /// **'article'**
  String get chatSourceArticle;

  /// No description provided for @chatWeek.
  ///
  /// In en, this message translates to:
  /// **'What did I save this week?'**
  String get chatWeek;

  /// No description provided for @chatLatestFive.
  ///
  /// In en, this message translates to:
  /// **'Give me a 5-point summary of my latest notes'**
  String get chatLatestFive;

  /// No description provided for @chatTheme.
  ///
  /// In en, this message translates to:
  /// **'What comes up most in my latest notes?'**
  String get chatTheme;

  /// No description provided for @chatHighlight.
  ///
  /// In en, this message translates to:
  /// **'What\'s the most interesting thing I saved lately?'**
  String get chatHighlight;

  /// No description provided for @chatNextIdea.
  ///
  /// In en, this message translates to:
  /// **'Suggest something new to try or learn, based on my notes'**
  String get chatNextIdea;

  /// No description provided for @chatDig.
  ///
  /// In en, this message translates to:
  /// **'What interesting questions could I explore from my notes?'**
  String get chatDig;

  /// No description provided for @chatGaps.
  ///
  /// In en, this message translates to:
  /// **'Going by my notes, what do I still seem unsure about?'**
  String get chatGaps;

  /// No description provided for @playerPlay.
  ///
  /// In en, this message translates to:
  /// **'Play here'**
  String get playerPlay;

  /// No description provided for @playerPlaySaved.
  ///
  /// In en, this message translates to:
  /// **'Play saved copy'**
  String get playerPlaySaved;

  /// No description provided for @playerPreparing.
  ///
  /// In en, this message translates to:
  /// **'Getting it ready…'**
  String get playerPreparing;

  /// No description provided for @playerRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get playerRetry;

  /// No description provided for @playerOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Open the source'**
  String get playerOpenSource;

  /// No description provided for @playerErrRefused.
  ///
  /// In en, this message translates to:
  /// **'The server refused. Try again, or open it in its own app.'**
  String get playerErrRefused;

  /// No description provided for @playerErrForbidden.
  ///
  /// In en, this message translates to:
  /// **'Access denied (403). It may be private.'**
  String get playerErrForbidden;

  /// No description provided for @playerErrNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found (404).'**
  String get playerErrNotFound;

  /// No description provided for @playerErrTimeout.
  ///
  /// In en, this message translates to:
  /// **'That took too long. Try again in a moment.'**
  String get playerErrTimeout;

  /// No description provided for @playerErrLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the video. Try again.'**
  String get playerErrLoad;

  /// No description provided for @playerErrOther.
  ///
  /// In en, this message translates to:
  /// **'Can\'t play it here. Open the source instead.'**
  String get playerErrOther;

  /// No description provided for @playerErrWeb.
  ///
  /// In en, this message translates to:
  /// **'Playing here isn\'t available on the web yet.'**
  String get playerErrWeb;

  /// No description provided for @noteDetailMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get noteDetailMenuEdit;

  /// No description provided for @noteDetailMenuOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Open source'**
  String get noteDetailMenuOpenSource;

  /// No description provided for @noteDetailMenuSaveOffline.
  ///
  /// In en, this message translates to:
  /// **'Save offline'**
  String get noteDetailMenuSaveOffline;

  /// No description provided for @noteDetailMenuDeleteOffline.
  ///
  /// In en, this message translates to:
  /// **'Remove offline video'**
  String get noteDetailMenuDeleteOffline;

  /// No description provided for @noteDetailMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get noteDetailMenuDelete;

  /// No description provided for @noteDetailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this note?'**
  String get noteDetailDeleteTitle;

  /// No description provided for @noteDetailDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'The note will be removed from your Library. This can\'t be undone.'**
  String get noteDetailDeleteMessage;

  /// No description provided for @noteDetailDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get noteDetailDeleteCancel;

  /// No description provided for @noteDetailDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get noteDetailDeleteConfirm;

  /// No description provided for @noteDetailDeleteLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove offline video?'**
  String get noteDetailDeleteLocalTitle;

  /// No description provided for @noteDetailDeleteLocalMessage.
  ///
  /// In en, this message translates to:
  /// **'The file will be removed from your device. The note stays safe and you can re-download anytime.'**
  String get noteDetailDeleteLocalMessage;

  /// No description provided for @noteDetailDeleteLocalDone.
  ///
  /// In en, this message translates to:
  /// **'Offline video removed'**
  String get noteDetailDeleteLocalDone;

  /// No description provided for @noteDetailSaveOfflineEyebrow.
  ///
  /// In en, this message translates to:
  /// **'SAVE OFFLINE'**
  String get noteDetailSaveOfflineEyebrow;

  /// No description provided for @noteDetailDownloadSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Saved offline, plays from device'**
  String get noteDetailDownloadSavedSnack;

  /// No description provided for @noteDetailDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String noteDetailDownloadFailed(String error);

  /// No description provided for @noteDetailOpenFileFailed.
  ///
  /// In en, this message translates to:
  /// **'No app can open this file'**
  String get noteDetailOpenFileFailed;

  /// No description provided for @noteDetailShareFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Check this out'**
  String get noteDetailShareFallbackTitle;

  /// No description provided for @noteDetailLocalDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Local file deleted'**
  String get noteDetailLocalDeletedSnack;

  /// No description provided for @noteDetailDownloadIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Not saved yet'**
  String get noteDetailDownloadIdleTitle;

  /// No description provided for @noteDetailDownloadIdleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download video/photo to your device'**
  String get noteDetailDownloadIdleSubtitle;

  /// No description provided for @noteDetailDownloadAction.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOAD'**
  String get noteDetailDownloadAction;

  /// No description provided for @noteDetailDownloadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String noteDetailDownloadingProgress(int percent);

  /// No description provided for @noteDetailDownloadingPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get noteDetailDownloadingPreparing;

  /// No description provided for @noteDetailDownloadingCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get noteDetailDownloadingCancel;

  /// No description provided for @noteDetailDownloadSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved offline'**
  String get noteDetailDownloadSavedTitle;

  /// No description provided for @noteDetailDownloadOpenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get noteDetailDownloadOpenTooltip;

  /// No description provided for @noteDetailDownloadShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get noteDetailDownloadShareTooltip;

  /// No description provided for @noteDetailDownloadDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from device'**
  String get noteDetailDownloadDeleteTooltip;

  /// No description provided for @addNoteEditEyebrow.
  ///
  /// In en, this message translates to:
  /// **'EDIT NOTE'**
  String get addNoteEditEyebrow;

  /// No description provided for @addNoteNewEyebrow.
  ///
  /// In en, this message translates to:
  /// **'NEW NOTE'**
  String get addNoteNewEyebrow;

  /// No description provided for @addNoteEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit note.'**
  String get addNoteEditTitle;

  /// No description provided for @addNoteNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New note.'**
  String get addNoteNewTitle;

  /// No description provided for @addNoteTogglePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get addNoteTogglePreview;

  /// No description provided for @addNoteToggleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get addNoteToggleEdit;

  /// No description provided for @addNoteSectionSource.
  ///
  /// In en, this message translates to:
  /// **'SOURCE'**
  String get addNoteSectionSource;

  /// No description provided for @addNoteSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'TITLE (OPTIONAL)'**
  String get addNoteSectionTitle;

  /// No description provided for @addNoteSectionNotes.
  ///
  /// In en, this message translates to:
  /// **'YOUR NOTES'**
  String get addNoteSectionNotes;

  /// No description provided for @addNoteSectionTags.
  ///
  /// In en, this message translates to:
  /// **'TAGS'**
  String get addNoteSectionTags;

  /// No description provided for @quizToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Use in quizzes'**
  String get quizToggleTitle;

  /// No description provided for @quizToggleOn.
  ///
  /// In en, this message translates to:
  /// **'Questions about this note can come up in the daily quiz and the weekly feast.'**
  String get quizToggleOn;

  /// No description provided for @quizToggleOff.
  ///
  /// In en, this message translates to:
  /// **'It won\'t be quizzed. Good for links you only want to keep, like a comic or book title.'**
  String get quizToggleOff;

  /// No description provided for @formatBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get formatBold;

  /// No description provided for @formatHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get formatHeading;

  /// No description provided for @formatBullets.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get formatBullets;

  /// No description provided for @formatNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get formatNumbers;

  /// No description provided for @addNoteUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://youtube.com/shorts/…'**
  String get addNoteUrlHint;

  /// No description provided for @addNoteTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Give it a name that\'s easy to remember'**
  String get addNoteTitleHint;

  /// No description provided for @addNoteNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Write the insight, summary, or anything you want to remember from this content.'**
  String get addNoteNotesHint;

  /// No description provided for @addNoteUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'URL is required'**
  String get addNoteUrlRequired;

  /// No description provided for @addNoteUrlMustStartWithHttp.
  ///
  /// In en, this message translates to:
  /// **'Must start with http(s)'**
  String get addNoteUrlMustStartWithHttp;

  /// No description provided for @addNoteNotesMinLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum 10 characters'**
  String get addNoteNotesMinLength;

  /// No description provided for @addNoteAutoFillNeedUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid URL first'**
  String get addNoteAutoFillNeedUrl;

  /// No description provided for @addNoteAutoFillTranscribing.
  ///
  /// In en, this message translates to:
  /// **'Transcribing video…'**
  String get addNoteAutoFillTranscribing;

  /// No description provided for @addNoteAutoFillProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get addNoteAutoFillProcessing;

  /// No description provided for @addNoteAutoFillContentFound.
  ///
  /// In en, this message translates to:
  /// **'{contentLabel} found, drafting notes…'**
  String addNoteAutoFillContentFound(String contentLabel);

  /// No description provided for @addNoteAutoFillError.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill failed: {error}'**
  String addNoteAutoFillError(String error);

  /// No description provided for @addNoteAutoFillTooltipProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get addNoteAutoFillTooltipProcessing;

  /// No description provided for @addNoteAutoFillTooltipTranscribe.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill (video transcript)'**
  String get addNoteAutoFillTooltipTranscribe;

  /// No description provided for @addNoteAutoFillTooltipUrl.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill from URL'**
  String get addNoteAutoFillTooltipUrl;

  /// No description provided for @addNoteReplaceDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace current notes?'**
  String get addNoteReplaceDialogTitle;

  /// No description provided for @addNoteReplaceDialogTranscribe.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill will clear your draft, transcribe the video\'s audio, and write fresh notes.'**
  String get addNoteReplaceDialogTranscribe;

  /// No description provided for @addNoteReplaceDialogScrape.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill will clear your draft and replace it with new notes from the URL.'**
  String get addNoteReplaceDialogScrape;

  /// No description provided for @addNoteReplaceDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get addNoteReplaceDialogCancel;

  /// No description provided for @addNoteReplaceDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get addNoteReplaceDialogConfirm;

  /// No description provided for @addNotePreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'_Nothing to preview yet…_'**
  String get addNotePreviewEmpty;

  /// No description provided for @addNoteSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Note saved.'**
  String get addNoteSavedSnack;

  /// No description provided for @addNoteUpdatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get addNoteUpdatedSnack;

  /// No description provided for @addNoteSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save to Library'**
  String get addNoteSaveButton;

  /// No description provided for @addNoteUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get addNoteUpdateButton;

  /// No description provided for @personalNotesEyebrow.
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get personalNotesEyebrow;

  /// No description provided for @personalNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your thoughts.'**
  String get personalNotesTitle;

  /// No description provided for @personalNotesCountEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get personalNotesCountEmpty;

  /// No description provided for @personalNotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} notes'**
  String personalNotesCount(int count);

  /// No description provided for @personalNotesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search note, content, or #tag…'**
  String get personalNotesSearchHint;

  /// No description provided for @personalNotesPinnedEyebrow.
  ///
  /// In en, this message translates to:
  /// **'PINNED'**
  String get personalNotesPinnedEyebrow;

  /// No description provided for @personalNotesOthersEyebrow.
  ///
  /// In en, this message translates to:
  /// **'OTHERS'**
  String get personalNotesOthersEyebrow;

  /// No description provided for @personalNotesFabNew.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get personalNotesFabNew;

  /// No description provided for @personalNotesEmptyEyebrow.
  ///
  /// In en, this message translates to:
  /// **'EMPTY'**
  String get personalNotesEmptyEyebrow;

  /// No description provided for @personalNotesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Write\nyour thoughts'**
  String get personalNotesEmptyTitle;

  /// No description provided for @personalNotesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap \"New note\" to start. Free text, images, and links.'**
  String get personalNotesEmptyMessage;

  /// No description provided for @personalNotesNotFoundEyebrow.
  ///
  /// In en, this message translates to:
  /// **'NOT FOUND'**
  String get personalNotesNotFoundEyebrow;

  /// No description provided for @personalNotesNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'\"{query}\"\nisn\'t here'**
  String personalNotesNotFoundTitle(String query);

  /// No description provided for @personalNotesNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another keyword, or clear the search.'**
  String get personalNotesNotFoundMessage;

  /// No description provided for @noteEditorTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noteEditorTitleHint;

  /// No description provided for @noteEditorBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Write something…'**
  String get noteEditorBodyHint;

  /// No description provided for @noteEditorSectionLinks.
  ///
  /// In en, this message translates to:
  /// **'LINKS'**
  String get noteEditorSectionLinks;

  /// No description provided for @noteEditorSectionTags.
  ///
  /// In en, this message translates to:
  /// **'TAGS'**
  String get noteEditorSectionTags;

  /// No description provided for @noteEditorPinTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get noteEditorPinTooltip;

  /// No description provided for @noteEditorUnpinTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get noteEditorUnpinTooltip;

  /// No description provided for @noteEditorColorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get noteEditorColorTooltip;

  /// No description provided for @noteEditorDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get noteEditorDeleteTooltip;

  /// No description provided for @noteEditorAddImageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get noteEditorAddImageTooltip;

  /// No description provided for @noteEditorAddLinkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get noteEditorAddLinkTooltip;

  /// No description provided for @noteEditorRemoveLinkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get noteEditorRemoveLinkTooltip;

  /// No description provided for @noteEditorImageSourceGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get noteEditorImageSourceGallery;

  /// No description provided for @noteEditorImageSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get noteEditorImageSourceCamera;

  /// No description provided for @noteEditorImageAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add image: {error}'**
  String noteEditorImageAddFailed(String error);

  /// No description provided for @noteEditorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save: {error}'**
  String noteEditorSaveFailed(String error);

  /// No description provided for @noteEditorDiscardEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this note?'**
  String get noteEditorDiscardEditTitle;

  /// No description provided for @noteEditorDiscardNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this note?'**
  String get noteEditorDiscardNewTitle;

  /// No description provided for @noteEditorDiscardEditMessage.
  ///
  /// In en, this message translates to:
  /// **'The note and all its images will be deleted permanently.'**
  String get noteEditorDiscardEditMessage;

  /// No description provided for @noteEditorDiscardNewMessage.
  ///
  /// In en, this message translates to:
  /// **'The draft will be tossed and any attached images go with it.'**
  String get noteEditorDiscardNewMessage;

  /// No description provided for @noteEditorDiscardCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get noteEditorDiscardCancel;

  /// No description provided for @noteEditorDiscardEditConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get noteEditorDiscardEditConfirm;

  /// No description provided for @noteEditorDiscardNewConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get noteEditorDiscardNewConfirm;

  /// No description provided for @noteEditorLinkDialogAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get noteEditorLinkDialogAddTitle;

  /// No description provided for @noteEditorLinkDialogEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit link'**
  String get noteEditorLinkDialogEditTitle;

  /// No description provided for @noteEditorLinkUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://…'**
  String get noteEditorLinkUrlHint;

  /// No description provided for @noteEditorLinkLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get noteEditorLinkLabelHint;

  /// No description provided for @noteEditorLinkCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get noteEditorLinkCancel;

  /// No description provided for @noteEditorLinkSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get noteEditorLinkSave;

  /// No description provided for @noteEditorColorPickerEyebrow.
  ///
  /// In en, this message translates to:
  /// **'NOTE COLOR'**
  String get noteEditorColorPickerEyebrow;

  /// No description provided for @noteColorDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get noteColorDefault;

  /// No description provided for @noteColorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get noteColorRed;

  /// No description provided for @noteColorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get noteColorOrange;

  /// No description provided for @noteColorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get noteColorYellow;

  /// No description provided for @noteColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get noteColorGreen;

  /// No description provided for @noteColorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get noteColorTeal;

  /// No description provided for @noteColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get noteColorBlue;

  /// No description provided for @noteColorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get noteColorPurple;

  /// No description provided for @noteColorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get noteColorPink;

  /// No description provided for @noteColorBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get noteColorBrown;

  /// No description provided for @noteColorGray.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get noteColorGray;

  /// No description provided for @loginEyebrow.
  ///
  /// In en, this message translates to:
  /// **'INGATANKU'**
  String get loginEyebrow;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome\nback.'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep collecting notes.'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get loginEmailHint;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get loginEmailInvalid;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordForgot.
  ///
  /// In en, this message translates to:
  /// **'FORGOT?'**
  String get loginPasswordForgot;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get loginPasswordHint;

  /// No description provided for @loginPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get loginPasswordTooShort;

  /// No description provided for @loginSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSubmit;

  /// No description provided for @loginDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get loginDivider;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account yet?  '**
  String get loginNoAccount;

  /// No description provided for @loginSignUpAction.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get loginSignUpAction;

  /// No description provided for @signupAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'SIGN UP'**
  String get signupAppBarTitle;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create\nyour account.'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your pet is waiting to hatch. Feed it what you learn.'**
  String get signupSubtitle;

  /// No description provided for @signupUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'USERNAME'**
  String get signupUsernameLabel;

  /// No description provided for @signupUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. sari.dewi'**
  String get signupUsernameHint;

  /// No description provided for @signupUsernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 3 characters'**
  String get signupUsernameTooShort;

  /// No description provided for @signupEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get signupEmailLabel;

  /// No description provided for @signupEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get signupEmailHint;

  /// No description provided for @signupEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get signupEmailInvalid;

  /// No description provided for @signupPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get signupPasswordLabel;

  /// No description provided for @signupPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get signupPasswordHint;

  /// No description provided for @signupPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get signupPasswordTooShort;

  /// No description provided for @signupSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signupSubmit;

  /// No description provided for @forgotPasswordAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'FORGOT PASSWORD'**
  String get forgotPasswordAppBarTitle;

  /// No description provided for @forgotPasswordEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your\npassword.'**
  String get forgotPasswordEmailTitle;

  /// No description provided for @forgotPasswordEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email, we\'ll send a 6-digit code to verify.'**
  String get forgotPasswordEmailSubtitle;

  /// No description provided for @forgotPasswordEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get forgotPasswordEmailLabel;

  /// No description provided for @forgotPasswordEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get forgotPasswordEmailHint;

  /// No description provided for @forgotPasswordEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get forgotPasswordEmailInvalid;

  /// No description provided for @forgotPasswordSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send reset code'**
  String get forgotPasswordSendCode;

  /// No description provided for @forgotPasswordOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Check\nyour email.'**
  String get forgotPasswordOtpTitle;

  /// No description provided for @forgotPasswordOtpSubtitleLead.
  ///
  /// In en, this message translates to:
  /// **'A 6-digit code was sent to\n'**
  String get forgotPasswordOtpSubtitleLead;

  /// No description provided for @forgotPasswordOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'OTP CODE'**
  String get forgotPasswordOtpLabel;

  /// No description provided for @forgotPasswordOtpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get forgotPasswordOtpVerify;

  /// No description provided for @forgotPasswordOtpResendCooldown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String forgotPasswordOtpResendCooldown(int seconds);

  /// No description provided for @forgotPasswordOtpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get forgotPasswordOtpResend;

  /// No description provided for @forgotPasswordNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new\npassword.'**
  String get forgotPasswordNewTitle;

  /// No description provided for @forgotPasswordNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a password with at least 6 characters. Once saved you\'ll sign right in.'**
  String get forgotPasswordNewSubtitle;

  /// No description provided for @forgotPasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW PASSWORD'**
  String get forgotPasswordNewLabel;

  /// No description provided for @forgotPasswordNewHint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get forgotPasswordNewHint;

  /// No description provided for @forgotPasswordNewTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get forgotPasswordNewTooShort;

  /// No description provided for @forgotPasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMATION'**
  String get forgotPasswordConfirmLabel;

  /// No description provided for @forgotPasswordConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Retype the password'**
  String get forgotPasswordConfirmHint;

  /// No description provided for @forgotPasswordConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm the password'**
  String get forgotPasswordConfirmRequired;

  /// No description provided for @forgotPasswordConfirmMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get forgotPasswordConfirmMismatch;

  /// No description provided for @forgotPasswordSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save & sign in'**
  String get forgotPasswordSaveAction;

  /// No description provided for @verifyOtpAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'VERIFY'**
  String get verifyOtpAppBarTitle;

  /// No description provided for @verifyOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Check\nyour email.'**
  String get verifyOtpTitle;

  /// No description provided for @verifyOtpSubtitleLead.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to\n'**
  String get verifyOtpSubtitleLead;

  /// No description provided for @verifyOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'OTP CODE'**
  String get verifyOtpLabel;

  /// No description provided for @verifyOtpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyOtpVerify;

  /// No description provided for @verifyOtpResendCooldown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String verifyOtpResendCooldown(int seconds);

  /// No description provided for @verifyOtpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get verifyOtpResend;

  /// No description provided for @verifyOtpResentSnack.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way to your inbox'**
  String get verifyOtpResentSnack;

  /// No description provided for @storageAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'STORAGE'**
  String get storageAppBarTitle;

  /// No description provided for @storageTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline storage.'**
  String get storageTitle;

  /// No description provided for @storageEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No videos or photos saved offline yet.'**
  String get storageEmptySubtitle;

  /// No description provided for @storageUsage.
  ///
  /// In en, this message translates to:
  /// **'{count} files · {size} used'**
  String storageUsage(int count, String size);

  /// No description provided for @storageDeleteOneTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this file?'**
  String get storageDeleteOneTitle;

  /// No description provided for @storageDeleteOnePhotoBody.
  ///
  /// In en, this message translates to:
  /// **'The photo will be removed from your device. You can re-download from the note anytime.'**
  String get storageDeleteOnePhotoBody;

  /// No description provided for @storageDeleteOneVideoBody.
  ///
  /// In en, this message translates to:
  /// **'The video will be removed from your device. You can re-download from the note anytime.'**
  String get storageDeleteOneVideoBody;

  /// No description provided for @storageDeleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all media?'**
  String get storageDeleteAllTitle;

  /// No description provided for @storageDeleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'All offline videos and photos will be removed from your device. The notes stay safe and can be re-downloaded anytime.'**
  String get storageDeleteAllBody;

  /// No description provided for @storageConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get storageConfirmCancel;

  /// No description provided for @storageConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get storageConfirmDelete;

  /// No description provided for @storageDeleteAllAction.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get storageDeleteAllAction;

  /// No description provided for @storageFileDeleted.
  ///
  /// In en, this message translates to:
  /// **'File deleted'**
  String get storageFileDeleted;

  /// No description provided for @storageFilesDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} files deleted'**
  String storageFilesDeleted(int count);

  /// No description provided for @storageRowUntitled.
  ///
  /// In en, this message translates to:
  /// **'(Untitled)'**
  String get storageRowUntitled;

  /// No description provided for @storageRowOrphan.
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get storageRowOrphan;

  /// No description provided for @storageRowOrphanLabel.
  ///
  /// In en, this message translates to:
  /// **'Orphan · {ext}'**
  String storageRowOrphanLabel(String ext);

  /// No description provided for @storageRowDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from device'**
  String get storageRowDeleteTooltip;

  /// No description provided for @storageDeleteAllButton.
  ///
  /// In en, this message translates to:
  /// **'Delete all offline media'**
  String get storageDeleteAllButton;

  /// No description provided for @reindexAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'AI & SEARCH'**
  String get reindexAppBarTitle;

  /// No description provided for @reindexTitle.
  ///
  /// In en, this message translates to:
  /// **'AI index.'**
  String get reindexTitle;

  /// No description provided for @reindexSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use this when the Assistant can\'t find old notes after you change the embedding model on the backend.'**
  String get reindexSubtitle;

  /// No description provided for @reindexStatusEyebrow.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get reindexStatusEyebrow;

  /// No description provided for @reindexStatusLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get reindexStatusLoading;

  /// No description provided for @reindexStatusReady.
  ///
  /// In en, this message translates to:
  /// **'{total} notes indexed, all set'**
  String reindexStatusReady(int total);

  /// No description provided for @reindexStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'{missing} of {total} notes need re-embed'**
  String reindexStatusMissing(int missing, int total);

  /// No description provided for @reindexRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get reindexRefreshTooltip;

  /// No description provided for @reindexStep1Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'STEP 1'**
  String get reindexStep1Eyebrow;

  /// No description provided for @reindexStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Reset old embeddings'**
  String get reindexStep1Title;

  /// No description provided for @reindexStep1Description.
  ///
  /// In en, this message translates to:
  /// **'Empties the embedding column on all your notes. Safe, doesn\'t delete the notes.'**
  String get reindexStep1Description;

  /// No description provided for @reindexStep1Action.
  ///
  /// In en, this message translates to:
  /// **'Reset embeddings'**
  String get reindexStep1Action;

  /// No description provided for @reindexStep1Busy.
  ///
  /// In en, this message translates to:
  /// **'Resetting…'**
  String get reindexStep1Busy;

  /// No description provided for @reindexStep2Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'STEP 2'**
  String get reindexStep2Eyebrow;

  /// No description provided for @reindexStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Run re-embed'**
  String get reindexStep2Title;

  /// No description provided for @reindexStep2Description.
  ///
  /// In en, this message translates to:
  /// **'Refills the embedding column on every empty note using the AI model that\'s currently active. Can take several minutes for large libraries.'**
  String get reindexStep2Description;

  /// No description provided for @reindexStep2Action.
  ///
  /// In en, this message translates to:
  /// **'Run re-embed'**
  String get reindexStep2Action;

  /// No description provided for @reindexStep2Busy.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get reindexStep2Busy;

  /// No description provided for @reindexResetDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all embeddings?'**
  String get reindexResetDialogTitle;

  /// No description provided for @reindexResetDialogBody.
  ///
  /// In en, this message translates to:
  /// **'All your notes will have their embedding column cleared. The AI assistant won\'t be able to find notes until the re-embed step completes.'**
  String get reindexResetDialogBody;

  /// No description provided for @reindexResetDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reindexResetDialogConfirm;

  /// No description provided for @reindexConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get reindexConfirmCancel;

  /// No description provided for @reindexNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get reindexNotLoggedIn;

  /// No description provided for @reindexResetDoneNudge.
  ///
  /// In en, this message translates to:
  /// **'Embeddings reset. Tap \"Run re-embed\" now.'**
  String get reindexResetDoneNudge;

  /// No description provided for @reindexResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Reset failed: {error}'**
  String reindexResetFailed(String error);

  /// No description provided for @reindexRunFailed.
  ///
  /// In en, this message translates to:
  /// **'Re-embed failed: {error}'**
  String reindexRunFailed(String error);

  /// No description provided for @reindexRunDone.
  ///
  /// In en, this message translates to:
  /// **'Re-embed completed.'**
  String get reindexRunDone;

  /// No description provided for @reindexRunDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{count} notes processed.'**
  String reindexRunDoneCount(Object count);

  /// No description provided for @reindexRunSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count} skipped: no title or text yet.'**
  String reindexRunSkipped(int count);

  /// No description provided for @reindexRunErrors.
  ///
  /// In en, this message translates to:
  /// **'{count} failed, try running it again.'**
  String reindexRunErrors(int count);

  /// No description provided for @reindexStatusEmpty.
  ///
  /// In en, this message translates to:
  /// **'{count} notes with no title or text can\'t be indexed.'**
  String reindexStatusEmpty(int count);

  /// No description provided for @privacyAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get privacyAppBarTitle;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy\n& data.'**
  String get privacyTitle;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Your notes belong to you. We store as little as possible and don\'t sell your data to third parties.'**
  String get privacyIntro;

  /// No description provided for @privacySectionGiven.
  ///
  /// In en, this message translates to:
  /// **'WHAT YOU GIVE'**
  String get privacySectionGiven;

  /// No description provided for @privacyGiven1.
  ///
  /// In en, this message translates to:
  /// **'Email for sign-in and important emails (verification, password reset).'**
  String get privacyGiven1;

  /// No description provided for @privacyGiven2.
  ///
  /// In en, this message translates to:
  /// **'Username shown on your dashboard.'**
  String get privacyGiven2;

  /// No description provided for @privacyGiven3.
  ///
  /// In en, this message translates to:
  /// **'Notes: links, titles, manual content, and tags. All yours, accessible and deletable any time.'**
  String get privacyGiven3;

  /// No description provided for @privacyGiven4.
  ///
  /// In en, this message translates to:
  /// **'Note embeddings, the numeric vectors the \"Assistant\" uses to find related notes.'**
  String get privacyGiven4;

  /// No description provided for @privacySectionWhere.
  ///
  /// In en, this message translates to:
  /// **'WHERE IT LIVES'**
  String get privacySectionWhere;

  /// No description provided for @privacyWhereBody.
  ///
  /// In en, this message translates to:
  /// **'Postgres + pgvector on Supabase (Southeast Asia region). All connections over HTTPS. Every row is tagged with your user ID and protected by Row Level Security, so you only see your own notes. A copy of your notes is also kept on this phone (inside the app, shown only to your account) so they work offline; it goes when the app is uninstalled.'**
  String get privacyWhereBody;

  /// No description provided for @privacySectionDont.
  ///
  /// In en, this message translates to:
  /// **'WHAT WE DON\'T DO'**
  String get privacySectionDont;

  /// No description provided for @privacyDont1.
  ///
  /// In en, this message translates to:
  /// **'No ad tracking or third-party analytics.'**
  String get privacyDont1;

  /// No description provided for @privacyDont2.
  ///
  /// In en, this message translates to:
  /// **'No data selling.'**
  String get privacyDont2;

  /// No description provided for @privacyDont3.
  ///
  /// In en, this message translates to:
  /// **'No sending your notes to external services beyond AI features you trigger yourself (e.g. \"Ask the assistant\").'**
  String get privacyDont3;

  /// No description provided for @privacySectionRights.
  ///
  /// In en, this message translates to:
  /// **'YOUR RIGHTS'**
  String get privacySectionRights;

  /// No description provided for @privacyRights1.
  ///
  /// In en, this message translates to:
  /// **'Edit or delete notes any time from the Library.'**
  String get privacyRights1;

  /// No description provided for @privacyRights2.
  ///
  /// In en, this message translates to:
  /// **'Delete your account and all associated notes. The button is coming soon, for now reach out via the contact below.'**
  String get privacyRights2;

  /// No description provided for @privacyRights3.
  ///
  /// In en, this message translates to:
  /// **'Request a copy of your data by contacting us.'**
  String get privacyRights3;

  /// No description provided for @privacySectionContact.
  ///
  /// In en, this message translates to:
  /// **'CONTACT'**
  String get privacySectionContact;

  /// No description provided for @privacyContactBody.
  ///
  /// In en, this message translates to:
  /// **'Questions, export requests, or data deletion: reach out to TemanLabs via the About IngatanKu page.'**
  String get privacyContactBody;

  /// No description provided for @aboutAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get aboutAppBarTitle;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About\nIngatanKu.'**
  String get aboutTitle;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'A little pet that grows with what you learn'**
  String get aboutTagline;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Save links and videos once. Your pet writes them up, eats them and grows, and the assistant already knows your whole collection.'**
  String get aboutDescription;

  /// No description provided for @aboutSectionMaker.
  ///
  /// In en, this message translates to:
  /// **'MADE BY'**
  String get aboutSectionMaker;

  /// No description provided for @aboutMakerName.
  ///
  /// In en, this message translates to:
  /// **'TemanLabs'**
  String get aboutMakerName;

  /// No description provided for @aboutMakerRole.
  ///
  /// In en, this message translates to:
  /// **'Makers of IngatanKu'**
  String get aboutMakerRole;

  /// No description provided for @aboutMakerBody.
  ///
  /// In en, this message translates to:
  /// **'Built wholeheartedly for curious people who want to turn daily scrolling into long-term memory.'**
  String get aboutMakerBody;

  /// No description provided for @aboutSectionVersion.
  ///
  /// In en, this message translates to:
  /// **'VERSION'**
  String get aboutSectionVersion;

  /// No description provided for @aboutVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'early release'**
  String get aboutVersionLabel;

  /// No description provided for @aboutSectionThanks.
  ///
  /// In en, this message translates to:
  /// **'THANKS'**
  String get aboutSectionThanks;

  /// No description provided for @aboutThanksBody.
  ///
  /// In en, this message translates to:
  /// **'To the open-source community and everyone who\'s been trying IngatanKu since day one.'**
  String get aboutThanksBody;

  /// No description provided for @aboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} TemanLabs'**
  String aboutCopyright(int year);

  /// No description provided for @weeklyQuizAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY QUIZ'**
  String get weeklyQuizAppBarTitle;

  /// No description provided for @weeklyQuizPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz this week.'**
  String get weeklyQuizPageTitle;

  /// No description provided for @weeklyQuizSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Five questions from notes you saved this week. Tap an option to answer.'**
  String get weeklyQuizSubtitle;

  /// No description provided for @weeklyQuizGenerateCta.
  ///
  /// In en, this message translates to:
  /// **'Generate quiz'**
  String get weeklyQuizGenerateCta;

  /// No description provided for @weeklyQuizRetryCta.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get weeklyQuizRetryCta;

  /// No description provided for @weeklyQuizScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get weeklyQuizScoreLabel;

  /// No description provided for @weeklyQuizCorrectLabel.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get weeklyQuizCorrectLabel;

  /// No description provided for @weeklyQuizExplanationLabel.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get weeklyQuizExplanationLabel;

  /// No description provided for @weeklyQuizSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source note'**
  String get weeklyQuizSourceLabel;

  /// No description provided for @weeklyQuizDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz complete.'**
  String get weeklyQuizDoneTitle;

  /// No description provided for @weeklyQuizDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Come back next week for a fresh set.'**
  String get weeklyQuizDoneSubtitle;

  /// No description provided for @weeklyQuizNotEnoughNotes.
  ///
  /// In en, this message translates to:
  /// **'Save at least 3 notes this week to unlock the quiz.'**
  String get weeklyQuizNotEnoughNotes;

  /// No description provided for @weeklyQuizGenerating.
  ///
  /// In en, this message translates to:
  /// **'Building your quiz, this takes a few seconds.'**
  String get weeklyQuizGenerating;

  /// No description provided for @weeklyQuizGenericError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate the quiz. Try again in a bit.'**
  String get weeklyQuizGenericError;

  /// No description provided for @weeklyQuizQuestionProgress.
  ///
  /// In en, this message translates to:
  /// **'QUESTION {current} / {total}'**
  String weeklyQuizQuestionProgress(int current, int total);

  /// No description provided for @weeklyQuizReviewBadge.
  ///
  /// In en, this message translates to:
  /// **'REVIEW'**
  String get weeklyQuizReviewBadge;

  /// No description provided for @weeklyQuizCheckCta.
  ///
  /// In en, this message translates to:
  /// **'CHECK'**
  String get weeklyQuizCheckCta;

  /// No description provided for @weeklyQuizNextCta.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get weeklyQuizNextCta;

  /// No description provided for @weeklyQuizFinishCta.
  ///
  /// In en, this message translates to:
  /// **'FINISH'**
  String get weeklyQuizFinishCta;

  /// No description provided for @weeklyQuizSubmitCta.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT QUIZ'**
  String get weeklyQuizSubmitCta;

  /// No description provided for @weeklyQuizSubmittingCta.
  ///
  /// In en, this message translates to:
  /// **'SUBMITTING…'**
  String get weeklyQuizSubmittingCta;

  /// No description provided for @weeklyQuizPrevCta.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get weeklyQuizPrevCta;

  /// No description provided for @weeklyQuizCorrectBadge.
  ///
  /// In en, this message translates to:
  /// **'CORRECT'**
  String get weeklyQuizCorrectBadge;

  /// No description provided for @weeklyQuizWrongBadge.
  ///
  /// In en, this message translates to:
  /// **'WRONG'**
  String get weeklyQuizWrongBadge;

  /// No description provided for @weeklyQuizScoreEyebrow.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK\'S SCORE'**
  String get weeklyQuizScoreEyebrow;

  /// No description provided for @weeklyQuizResultPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect! Your notes really stuck.'**
  String get weeklyQuizResultPerfect;

  /// No description provided for @weeklyQuizResultGood.
  ///
  /// In en, this message translates to:
  /// **'Nice, you absorbed most of it.'**
  String get weeklyQuizResultGood;

  /// No description provided for @weeklyQuizResultRetry.
  ///
  /// In en, this message translates to:
  /// **'Time to revisit the weaker notes.'**
  String get weeklyQuizResultRetry;

  /// No description provided for @weeklyQuizSummaryEyebrow.
  ///
  /// In en, this message translates to:
  /// **'BREAKDOWN'**
  String get weeklyQuizSummaryEyebrow;

  /// No description provided for @weeklyQuizCloseCta.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get weeklyQuizCloseCta;

  /// No description provided for @weeklyQuizReviewCta.
  ///
  /// In en, this message translates to:
  /// **'REVIEW ANSWERS'**
  String get weeklyQuizReviewCta;

  /// No description provided for @weeklyQuizLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Generating a quiz from this week\'s notes…'**
  String get weeklyQuizLoadingMessage;

  /// No description provided for @weeklyQuizErrorRetryCta.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get weeklyQuizErrorRetryCta;

  /// No description provided for @chatAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'ASK YOUR ASSISTANT'**
  String get chatAppBarTitle;

  /// No description provided for @chatPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask your\nassistant.'**
  String get chatPageTitle;

  /// No description provided for @chatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The AI searches across every note you\'ve saved and answers with direct references.'**
  String get chatSubtitle;

  /// No description provided for @chatTrySection.
  ///
  /// In en, this message translates to:
  /// **'TRY ASKING'**
  String get chatTrySection;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask {name} about your notes…'**
  String chatInputHint(String name);

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask {name}'**
  String chatTitle(String name);

  /// No description provided for @chatResetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Start a new session'**
  String get chatResetTooltip;

  /// No description provided for @tagChipHint.
  ///
  /// In en, this message translates to:
  /// **'Add a tag, press enter'**
  String get tagChipHint;

  /// No description provided for @tagChipSuggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'SUGGESTED'**
  String get tagChipSuggestionsLabel;

  /// No description provided for @timeAgoJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeAgoJustNow;

  /// No description provided for @timeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String timeAgoMinutes(int count);

  /// No description provided for @timeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String timeAgoHours(int count);

  /// No description provided for @timeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String timeAgoDays(int count);

  /// No description provided for @timeAgoWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count}w'**
  String timeAgoWeeks(int count);

  /// No description provided for @monthShortJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthShortJan;

  /// No description provided for @monthShortFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthShortFeb;

  /// No description provided for @monthShortMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthShortMar;

  /// No description provided for @monthShortApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthShortApr;

  /// No description provided for @monthShortMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthShortMay;

  /// No description provided for @monthShortJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthShortJun;

  /// No description provided for @monthShortJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthShortJul;

  /// No description provided for @monthShortAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthShortAug;

  /// No description provided for @monthShortSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthShortSep;

  /// No description provided for @monthShortOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthShortOct;

  /// No description provided for @monthShortNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthShortNov;

  /// No description provided for @monthShortDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthShortDec;

  /// No description provided for @dayShortSun.
  ///
  /// In en, this message translates to:
  /// **'SUN'**
  String get dayShortSun;

  /// No description provided for @dayShortMon.
  ///
  /// In en, this message translates to:
  /// **'MON'**
  String get dayShortMon;

  /// No description provided for @dayShortTue.
  ///
  /// In en, this message translates to:
  /// **'TUE'**
  String get dayShortTue;

  /// No description provided for @dayShortWed.
  ///
  /// In en, this message translates to:
  /// **'WED'**
  String get dayShortWed;

  /// No description provided for @dayShortThu.
  ///
  /// In en, this message translates to:
  /// **'THU'**
  String get dayShortThu;

  /// No description provided for @dayShortFri.
  ///
  /// In en, this message translates to:
  /// **'FRI'**
  String get dayShortFri;

  /// No description provided for @dayShortSat.
  ///
  /// In en, this message translates to:
  /// **'SAT'**
  String get dayShortSat;

  /// No description provided for @monthShortUpperJan.
  ///
  /// In en, this message translates to:
  /// **'JAN'**
  String get monthShortUpperJan;

  /// No description provided for @monthShortUpperFeb.
  ///
  /// In en, this message translates to:
  /// **'FEB'**
  String get monthShortUpperFeb;

  /// No description provided for @monthShortUpperMar.
  ///
  /// In en, this message translates to:
  /// **'MAR'**
  String get monthShortUpperMar;

  /// No description provided for @monthShortUpperApr.
  ///
  /// In en, this message translates to:
  /// **'APR'**
  String get monthShortUpperApr;

  /// No description provided for @monthShortUpperMay.
  ///
  /// In en, this message translates to:
  /// **'MAY'**
  String get monthShortUpperMay;

  /// No description provided for @monthShortUpperJun.
  ///
  /// In en, this message translates to:
  /// **'JUN'**
  String get monthShortUpperJun;

  /// No description provided for @monthShortUpperJul.
  ///
  /// In en, this message translates to:
  /// **'JUL'**
  String get monthShortUpperJul;

  /// No description provided for @monthShortUpperAug.
  ///
  /// In en, this message translates to:
  /// **'AUG'**
  String get monthShortUpperAug;

  /// No description provided for @monthShortUpperSep.
  ///
  /// In en, this message translates to:
  /// **'SEP'**
  String get monthShortUpperSep;

  /// No description provided for @monthShortUpperOct.
  ///
  /// In en, this message translates to:
  /// **'OCT'**
  String get monthShortUpperOct;

  /// No description provided for @monthShortUpperNov.
  ///
  /// In en, this message translates to:
  /// **'NOV'**
  String get monthShortUpperNov;

  /// No description provided for @monthShortUpperDec.
  ///
  /// In en, this message translates to:
  /// **'DEC'**
  String get monthShortUpperDec;

  /// No description provided for @tagsPageEyebrow.
  ///
  /// In en, this message translates to:
  /// **'MANAGE TAGS'**
  String get tagsPageEyebrow;

  /// No description provided for @tagsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags.'**
  String get tagsPageTitle;

  /// No description provided for @tagsPageSummary.
  ///
  /// In en, this message translates to:
  /// **'{tagCount} tags · {noteCount} notes'**
  String tagsPageSummary(int tagCount, int noteCount);

  /// No description provided for @tagsRowNoteCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note} other{{count} notes}}'**
  String tagsRowNoteCount(int count);

  /// No description provided for @tagsEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rename tag'**
  String get tagsEditTooltip;

  /// No description provided for @tagsDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete tag'**
  String get tagsDeleteTooltip;

  /// No description provided for @tagsRenameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename tag'**
  String get tagsRenameDialogTitle;

  /// No description provided for @tagsRenameDialogHint.
  ///
  /// In en, this message translates to:
  /// **'New tag name'**
  String get tagsRenameDialogHint;

  /// No description provided for @tagsRenameDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tagsRenameDialogCancel;

  /// No description provided for @tagsRenameDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get tagsRenameDialogConfirm;

  /// No description provided for @tagsDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete tag?'**
  String get tagsDeleteDialogTitle;

  /// No description provided for @tagsDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'The tag will be removed from every note.'**
  String get tagsDeleteDialogBody;

  /// No description provided for @tagsDeleteDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tagsDeleteDialogCancel;

  /// No description provided for @tagsDeleteDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tagsDeleteDialogConfirm;

  /// No description provided for @tagDetailEyebrow.
  ///
  /// In en, this message translates to:
  /// **'TAG'**
  String get tagDetailEyebrow;

  /// No description provided for @tagDetailNoteCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 related note} other{{count} related notes}}'**
  String tagDetailNoteCount(int count);

  /// No description provided for @tagDetailEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes with this tag yet.'**
  String get tagDetailEmpty;

  /// No description provided for @sourceLabelArticle.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get sourceLabelArticle;

  /// No description provided for @quizSelfRatingPrompt.
  ///
  /// In en, this message translates to:
  /// **'How well do you know this?'**
  String get quizSelfRatingPrompt;

  /// No description provided for @quizSelfRatingEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get quizSelfRatingEasy;

  /// No description provided for @quizSelfRatingMedium.
  ///
  /// In en, this message translates to:
  /// **'Just right'**
  String get quizSelfRatingMedium;

  /// No description provided for @quizSelfRatingHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get quizSelfRatingHard;

  /// No description provided for @quizResultHardCarryNone.
  ///
  /// In en, this message translates to:
  /// **'Nice. No items to carry over next week.'**
  String get quizResultHardCarryNone;

  /// No description provided for @quizResultHardCarry.
  ///
  /// In en, this message translates to:
  /// **'{count} hard item(s) will return next week as a refresher.'**
  String quizResultHardCarry(int count);

  /// No description provided for @homeActionWardrobe.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe'**
  String get homeActionWardrobe;

  /// No description provided for @petDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Bolubi'**
  String get petDefaultName;

  /// No description provided for @petSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, your pet. Stroke to pet; a tap is a smack.'**
  String petSemantics(String name);

  /// No description provided for @petMeterFullness.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get petMeterFullness;

  /// No description provided for @petMeterHappiness.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get petMeterHappiness;

  /// No description provided for @petMeterGrowth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get petMeterGrowth;

  /// No description provided for @petStageEgg.
  ///
  /// In en, this message translates to:
  /// **'Egg'**
  String get petStageEgg;

  /// No description provided for @petStageBaby.
  ///
  /// In en, this message translates to:
  /// **'Baby'**
  String get petStageBaby;

  /// No description provided for @petStageKid.
  ///
  /// In en, this message translates to:
  /// **'Kid'**
  String get petStageKid;

  /// No description provided for @petStageTeen.
  ///
  /// In en, this message translates to:
  /// **'Teen'**
  String get petStageTeen;

  /// No description provided for @petStageAdult.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get petStageAdult;

  /// No description provided for @petStageSage.
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get petStageSage;

  /// No description provided for @petGrowthNext.
  ///
  /// In en, this message translates to:
  /// **'Growing into {stage}'**
  String petGrowthNext(String stage);

  /// No description provided for @petGrowthMax.
  ///
  /// In en, this message translates to:
  /// **'Fully grown'**
  String get petGrowthMax;

  /// No description provided for @petFoodBento.
  ///
  /// In en, this message translates to:
  /// **'Bento'**
  String get petFoodBento;

  /// No description provided for @petFoodSandwich.
  ///
  /// In en, this message translates to:
  /// **'Sandwich'**
  String get petFoodSandwich;

  /// No description provided for @petFoodOnigiri.
  ///
  /// In en, this message translates to:
  /// **'Onigiri'**
  String get petFoodOnigiri;

  /// No description provided for @petFoodDonut.
  ///
  /// In en, this message translates to:
  /// **'Donut'**
  String get petFoodDonut;

  /// No description provided for @petFoodCookie.
  ///
  /// In en, this message translates to:
  /// **'Cookie'**
  String get petFoodCookie;

  /// No description provided for @petFoodChips.
  ///
  /// In en, this message translates to:
  /// **'Chips'**
  String get petFoodChips;

  /// No description provided for @petWardrobeTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s wardrobe'**
  String petWardrobeTitle(String name);

  /// No description provided for @petNameLabel.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get petNameLabel;

  /// No description provided for @petNamingTitle.
  ///
  /// In en, this message translates to:
  /// **'Give it a name'**
  String get petNamingTitle;

  /// No description provided for @petNamingBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s what its room is called and how it answers you. You can change it any time from its profile.'**
  String get petNamingBody;

  /// No description provided for @petNamingSave.
  ///
  /// In en, this message translates to:
  /// **'Save name'**
  String get petNamingSave;

  /// No description provided for @petColorLabel.
  ///
  /// In en, this message translates to:
  /// **'COLOR'**
  String get petColorLabel;

  /// No description provided for @petAccessoryLabel.
  ///
  /// In en, this message translates to:
  /// **'ACCESSORY'**
  String get petAccessoryLabel;

  /// No description provided for @petLocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocks when {name} becomes a {stage}.'**
  String petLocked(String name, String stage);

  /// No description provided for @petStatAge.
  ///
  /// In en, this message translates to:
  /// **'AGE'**
  String get petStatAge;

  /// No description provided for @petStatCare.
  ///
  /// In en, this message translates to:
  /// **'CARED FOR'**
  String get petStatCare;

  /// No description provided for @petStatDigested.
  ///
  /// In en, this message translates to:
  /// **'DIGESTED'**
  String get petStatDigested;

  /// No description provided for @petStatPets.
  ///
  /// In en, this message translates to:
  /// **'PETS'**
  String get petStatPets;

  /// No description provided for @petStatDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String petStatDays(int days);

  /// No description provided for @petStatCareSemantics.
  ///
  /// In en, this message translates to:
  /// **'Fed {days} days in a row'**
  String petStatCareSemantics(int days);

  /// No description provided for @petColorMatcha.
  ///
  /// In en, this message translates to:
  /// **'Matcha'**
  String get petColorMatcha;

  /// No description provided for @petColorPeach.
  ///
  /// In en, this message translates to:
  /// **'Peach'**
  String get petColorPeach;

  /// No description provided for @petColorSky.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get petColorSky;

  /// No description provided for @petColorTaro.
  ///
  /// In en, this message translates to:
  /// **'Taro'**
  String get petColorTaro;

  /// No description provided for @petColorHoney.
  ///
  /// In en, this message translates to:
  /// **'Honey'**
  String get petColorHoney;

  /// No description provided for @petColorMocha.
  ///
  /// In en, this message translates to:
  /// **'Mocha'**
  String get petColorMocha;

  /// No description provided for @petColorMochi.
  ///
  /// In en, this message translates to:
  /// **'Mochi'**
  String get petColorMochi;

  /// No description provided for @petAccessoryNone.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get petAccessoryNone;

  /// No description provided for @petAccessorySprout.
  ///
  /// In en, this message translates to:
  /// **'Sprout'**
  String get petAccessorySprout;

  /// No description provided for @petAccessoryBow.
  ///
  /// In en, this message translates to:
  /// **'Bow'**
  String get petAccessoryBow;

  /// No description provided for @petAccessoryGlasses.
  ///
  /// In en, this message translates to:
  /// **'Glasses'**
  String get petAccessoryGlasses;

  /// No description provided for @petAccessoryScarf.
  ///
  /// In en, this message translates to:
  /// **'Scarf'**
  String get petAccessoryScarf;

  /// No description provided for @petAccessoryBeanie.
  ///
  /// In en, this message translates to:
  /// **'Beanie'**
  String get petAccessoryBeanie;

  /// No description provided for @petAccessoryHeadphones.
  ///
  /// In en, this message translates to:
  /// **'Headphones'**
  String get petAccessoryHeadphones;

  /// No description provided for @petAccessoryCrown.
  ///
  /// In en, this message translates to:
  /// **'Crown'**
  String get petAccessoryCrown;

  /// No description provided for @petAccessoryChefHat.
  ///
  /// In en, this message translates to:
  /// **'Chef hat'**
  String get petAccessoryChefHat;

  /// No description provided for @petAccessoryPartyHat.
  ///
  /// In en, this message translates to:
  /// **'Party hat'**
  String get petAccessoryPartyHat;

  /// No description provided for @petAccessoryCatEars.
  ///
  /// In en, this message translates to:
  /// **'Cat ears'**
  String get petAccessoryCatEars;

  /// No description provided for @petAccessoryFlower.
  ///
  /// In en, this message translates to:
  /// **'Flower'**
  String get petAccessoryFlower;

  /// No description provided for @petAccessoryPeci.
  ///
  /// In en, this message translates to:
  /// **'Peci'**
  String get petAccessoryPeci;

  /// No description provided for @petAccessoryWitchHat.
  ///
  /// In en, this message translates to:
  /// **'Witch hat'**
  String get petAccessoryWitchHat;

  /// No description provided for @petAccessorySantaHat.
  ///
  /// In en, this message translates to:
  /// **'Santa hat'**
  String get petAccessorySantaHat;

  /// No description provided for @petOutfitLabel.
  ///
  /// In en, this message translates to:
  /// **'OUTFIT'**
  String get petOutfitLabel;

  /// No description provided for @petOutfitNone.
  ///
  /// In en, this message translates to:
  /// **'No outfit'**
  String get petOutfitNone;

  /// No description provided for @petOutfitHoodie.
  ///
  /// In en, this message translates to:
  /// **'Hoodie'**
  String get petOutfitHoodie;

  /// No description provided for @petOutfitStripedTee.
  ///
  /// In en, this message translates to:
  /// **'Striped tee'**
  String get petOutfitStripedTee;

  /// No description provided for @petOutfitOveralls.
  ///
  /// In en, this message translates to:
  /// **'Overalls'**
  String get petOutfitOveralls;

  /// No description provided for @petOutfitSweater.
  ///
  /// In en, this message translates to:
  /// **'Knit sweater'**
  String get petOutfitSweater;

  /// No description provided for @petOutfitBatik.
  ///
  /// In en, this message translates to:
  /// **'Batik'**
  String get petOutfitBatik;

  /// No description provided for @petOutfitDino.
  ///
  /// In en, this message translates to:
  /// **'Dino costume'**
  String get petOutfitDino;

  /// No description provided for @petOutfitFrog.
  ///
  /// In en, this message translates to:
  /// **'Frog costume'**
  String get petOutfitFrog;

  /// No description provided for @petOutfitBee.
  ///
  /// In en, this message translates to:
  /// **'Bee costume'**
  String get petOutfitBee;

  /// No description provided for @petOutfitAstronaut.
  ///
  /// In en, this message translates to:
  /// **'Astronaut'**
  String get petOutfitAstronaut;

  /// No description provided for @petOutfitRaincoat.
  ///
  /// In en, this message translates to:
  /// **'Raincoat'**
  String get petOutfitRaincoat;

  /// No description provided for @petOutfitKoko.
  ///
  /// In en, this message translates to:
  /// **'Koko shirt'**
  String get petOutfitKoko;

  /// No description provided for @petOutfitPumpkin.
  ///
  /// In en, this message translates to:
  /// **'Pumpkin costume'**
  String get petOutfitPumpkin;

  /// No description provided for @petOutfitGroupEveryday.
  ///
  /// In en, this message translates to:
  /// **'Everyday'**
  String get petOutfitGroupEveryday;

  /// No description provided for @petOutfitGroupCostume.
  ///
  /// In en, this message translates to:
  /// **'Costumes'**
  String get petOutfitGroupCostume;

  /// No description provided for @petOutfitGroupSeasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal'**
  String get petOutfitGroupSeasonal;

  /// No description provided for @petPremiumBadge.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get petPremiumBadge;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Boutique'**
  String get shopTitle;

  /// No description provided for @shopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Boutique: accessories & outfits'**
  String get shopTooltip;

  /// No description provided for @shopTakeOff.
  ///
  /// In en, this message translates to:
  /// **'Take it off'**
  String get shopTakeOff;

  /// No description provided for @shopShelfAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get shopShelfAll;

  /// No description provided for @shopShelfHats.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get shopShelfHats;

  /// No description provided for @shopPetLine1.
  ///
  /// In en, this message translates to:
  /// **'Which one shall I try?'**
  String get shopPetLine1;

  /// No description provided for @shopPetLine2.
  ///
  /// In en, this message translates to:
  /// **'Tap something below and I\'ll try it on.'**
  String get shopPetLine2;

  /// No description provided for @shopPetPetted.
  ///
  /// In en, this message translates to:
  /// **'Hey, don\'t crease it!'**
  String get shopPetPetted;

  /// No description provided for @shopPetReact1.
  ///
  /// In en, this message translates to:
  /// **'Does it suit me?'**
  String get shopPetReact1;

  /// No description provided for @shopPetReact2.
  ///
  /// In en, this message translates to:
  /// **'Cute, right?'**
  String get shopPetReact2;

  /// No description provided for @shopPetReact3.
  ///
  /// In en, this message translates to:
  /// **'I like this one!'**
  String get shopPetReact3;

  /// No description provided for @shopPetMirror.
  ///
  /// In en, this message translates to:
  /// **'Hmm, not bad…'**
  String get shopPetMirror;

  /// No description provided for @shopBarSoon.
  ///
  /// In en, this message translates to:
  /// **'For sale soon'**
  String get shopBarSoon;

  /// No description provided for @shopOwned.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get shopOwned;

  /// No description provided for @shopWear.
  ///
  /// In en, this message translates to:
  /// **'Wear it'**
  String get shopWear;

  /// No description provided for @shopWearing.
  ///
  /// In en, this message translates to:
  /// **'Wearing it'**
  String get shopWearing;

  /// No description provided for @wardrobeShopCta.
  ///
  /// In en, this message translates to:
  /// **'Fancy something new? Visit the boutique'**
  String get wardrobeShopCta;

  /// No description provided for @vaultRowDigested.
  ///
  /// In en, this message translates to:
  /// **'Digested'**
  String get vaultRowDigested;

  /// No description provided for @profileRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s room'**
  String profileRoomTitle(String name);

  /// No description provided for @homeTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved today'**
  String get homeTodayTitle;

  /// No description provided for @homeTodayRange.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to} of {total}'**
  String homeTodayRange(int from, int to, int total);

  /// No description provided for @homeTodayOpenLibrary.
  ///
  /// In en, this message translates to:
  /// **'Open Library'**
  String get homeTodayOpenLibrary;

  /// No description provided for @homeRest.
  ///
  /// In en, this message translates to:
  /// **'Put to bed'**
  String get homeRest;

  /// No description provided for @homeWake.
  ///
  /// In en, this message translates to:
  /// **'Wake up'**
  String get homeWake;

  /// No description provided for @homeQuickSaveHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a link here…'**
  String get homeQuickSaveHint;

  /// No description provided for @homeQuickSaveSend.
  ///
  /// In en, this message translates to:
  /// **'Write it up'**
  String get homeQuickSaveSend;

  /// No description provided for @homeQuickSavePaste.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get homeQuickSavePaste;

  /// No description provided for @petStatusEgg.
  ///
  /// In en, this message translates to:
  /// **'The egg feels warm… save your first link to hatch it.'**
  String get petStatusEgg;

  /// No description provided for @petStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Keeping your notes safe'**
  String get petStatusReady;

  /// No description provided for @petStatusHappy.
  ///
  /// In en, this message translates to:
  /// **'Full and happy'**
  String get petStatusHappy;

  /// No description provided for @petStatusHungry.
  ///
  /// In en, this message translates to:
  /// **'Hungry for something new to learn…'**
  String get petStatusHungry;

  /// No description provided for @petStatusLonely.
  ///
  /// In en, this message translates to:
  /// **'A little lonely — a pat, maybe?'**
  String get petStatusLonely;

  /// No description provided for @petStatusResting.
  ///
  /// In en, this message translates to:
  /// **'Napping on its cushion…'**
  String get petStatusResting;

  /// No description provided for @petStatusWoke.
  ///
  /// In en, this message translates to:
  /// **'Oh — awake!'**
  String get petStatusWoke;

  /// No description provided for @petStatusPetted.
  ///
  /// In en, this message translates to:
  /// **'Loves the pats'**
  String get petStatusPetted;

  /// No description provided for @petStatusPlayed.
  ///
  /// In en, this message translates to:
  /// **'Wheee, again!'**
  String get petStatusPlayed;

  /// No description provided for @petStatusNewLink.
  ///
  /// In en, this message translates to:
  /// **'Ooh, something new!'**
  String get petStatusNewLink;

  /// No description provided for @petStatusAte.
  ///
  /// In en, this message translates to:
  /// **'Nom! A tasty little snack.'**
  String get petStatusAte;

  /// No description provided for @petStatusAteMany.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Nom! 1 tasty snack.} other{Nom! {count} tasty snacks.}}'**
  String petStatusAteMany(int count);

  /// No description provided for @petStatusFull.
  ///
  /// In en, this message translates to:
  /// **'Too full — saving it for later.'**
  String get petStatusFull;

  /// No description provided for @petStatusHatched.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m {name}. Thanks for my first bite!'**
  String petStatusHatched(String name);

  /// No description provided for @petStatusEvolved.
  ///
  /// In en, this message translates to:
  /// **'I grew into a {stage}!'**
  String petStatusEvolved(String stage);

  /// No description provided for @petStatusNotLink.
  ///
  /// In en, this message translates to:
  /// **'Hmm, that\'s not a link.'**
  String get petStatusNotLink;

  /// No description provided for @petStatusClipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your clipboard is empty.'**
  String get petStatusClipboardEmpty;

  /// No description provided for @petStatusSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that. Try again?'**
  String get petStatusSaveFailed;

  /// No description provided for @petStatusNothingToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved today yet.'**
  String get petStatusNothingToday;

  /// No description provided for @vaultAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get vaultAll;

  /// No description provided for @vaultGroupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get vaultGroupToday;

  /// No description provided for @vaultGroupYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get vaultGroupYesterday;

  /// No description provided for @vaultGroupWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get vaultGroupWeek;

  /// No description provided for @vaultGroupOlder.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get vaultGroupOlder;

  /// No description provided for @vaultUntitled.
  ///
  /// In en, this message translates to:
  /// **'(Untitled)'**
  String get vaultUntitled;

  /// No description provided for @vaultRowNotDigested.
  ///
  /// In en, this message translates to:
  /// **'Not digested yet'**
  String get vaultRowNotDigested;

  /// No description provided for @homeTvCaption.
  ///
  /// In en, this message translates to:
  /// **'saved today'**
  String get homeTvCaption;

  /// No description provided for @notesPetEmpty.
  ///
  /// In en, this message translates to:
  /// **'My notebook\'s empty. Let\'s write the first note!'**
  String get notesPetEmpty;

  /// No description provided for @notesPetWriting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Writing away… 1 note so far.} other{Writing away… {count} notes so far.}}'**
  String notesPetWriting(int count);

  /// No description provided for @notesPetCopying.
  ///
  /// In en, this message translates to:
  /// **'Psst, I\'m copying down your ideas.'**
  String get notesPetCopying;

  /// No description provided for @notesPetPetted.
  ///
  /// In en, this message translates to:
  /// **'Hehe, careful — I\'m writing!'**
  String get notesPetPetted;

  /// No description provided for @libraryPetEmpty.
  ///
  /// In en, this message translates to:
  /// **'My shelves are empty. Save your first link!'**
  String get libraryPetEmpty;

  /// No description provided for @libraryPetCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 find on my shelves.} other{{count} finds on my shelves.}}'**
  String libraryPetCount(int count);

  /// No description provided for @libraryPetReading.
  ///
  /// In en, this message translates to:
  /// **'Reading “{title}”…'**
  String libraryPetReading(String title);

  /// No description provided for @chatPetIdle.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything — I answer from the notes I\'ve eaten.'**
  String get chatPetIdle;

  /// No description provided for @chatPetAnswering.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what I remember…'**
  String get chatPetAnswering;

  /// No description provided for @chatPetDone.
  ///
  /// In en, this message translates to:
  /// **'Hope that helps! Anything else?'**
  String get chatPetDone;

  /// No description provided for @chatPetError.
  ///
  /// In en, this message translates to:
  /// **'Oops, I lost my train of thought. Try again?'**
  String get chatPetError;

  /// No description provided for @chatPetPetted.
  ///
  /// In en, this message translates to:
  /// **'Hehe, I\'m listening.'**
  String get chatPetPetted;

  /// No description provided for @petStatusLifted.
  ///
  /// In en, this message translates to:
  /// **'Whoa! Put me down!'**
  String get petStatusLifted;

  /// No description provided for @petStatusDizzy.
  ///
  /// In en, this message translates to:
  /// **'Everything\'s spinning…'**
  String get petStatusDizzy;

  /// No description provided for @petStatusGrumpy.
  ///
  /// In en, this message translates to:
  /// **'Hmph! Don\'t drop me like that!'**
  String get petStatusGrumpy;

  /// No description provided for @petStatusPutDown.
  ///
  /// In en, this message translates to:
  /// **'Hmph… gently next time.'**
  String get petStatusPutDown;

  /// No description provided for @libraryPetShush.
  ///
  /// In en, this message translates to:
  /// **'Shh! It\'s a library — keep it down.'**
  String get libraryPetShush;

  /// No description provided for @libraryPetAngry.
  ///
  /// In en, this message translates to:
  /// **'Hey! I\'m trying to read here!'**
  String get libraryPetAngry;

  /// No description provided for @petStatusSharedLink.
  ///
  /// In en, this message translates to:
  /// **'A link came in! Tap the check and I\'ll write it up.'**
  String get petStatusSharedLink;

  /// No description provided for @petScribeStart.
  ///
  /// In en, this message translates to:
  /// **'One sec, let me take notes…'**
  String get petScribeStart;

  /// No description provided for @petScribeFound.
  ///
  /// In en, this message translates to:
  /// **'Found the {label} — writing it up…'**
  String petScribeFound(String label);

  /// No description provided for @petScribeDone.
  ///
  /// In en, this message translates to:
  /// **'Ta-da! Here\'s my note.'**
  String get petScribeDone;

  /// No description provided for @petScribePartial.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read all of it, but here\'s my note.'**
  String get petScribePartial;

  /// No description provided for @petScribeOutOfQuota.
  ///
  /// In en, this message translates to:
  /// **'I\'ve written all I can for today. Can you fill this one in?'**
  String get petScribeOutOfQuota;

  /// No description provided for @petScribeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Okay, I\'ll leave the link here for now.'**
  String get petScribeCancelled;

  /// No description provided for @scribeSheetEyebrow.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s note'**
  String scribeSheetEyebrow(String name);

  /// No description provided for @scribeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Check it before I eat it'**
  String get scribeSheetTitle;

  /// No description provided for @scribeSheetNoSummary.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t summarise this one — add your own notes if you like.'**
  String get scribeSheetNoSummary;

  /// No description provided for @scribeSheetOutOfQuota.
  ///
  /// In en, this message translates to:
  /// **'That\'s all my write-ups for today — add your own notes, or share it again tomorrow.'**
  String get scribeSheetOutOfQuota;

  /// No description provided for @scribeSheetSave.
  ///
  /// In en, this message translates to:
  /// **'Save & feed {name}'**
  String scribeSheetSave(String name);

  /// No description provided for @petStatusQuizReady.
  ///
  /// In en, this message translates to:
  /// **'I\'m hungry! Today\'s meal is waiting down here.'**
  String get petStatusQuizReady;

  /// No description provided for @homeShelfSemantics.
  ///
  /// In en, this message translates to:
  /// **'Bookshelf — open your collections'**
  String get homeShelfSemantics;

  /// No description provided for @petIdleTv.
  ///
  /// In en, this message translates to:
  /// **'Ooh, what\'s on TV?'**
  String get petIdleTv;

  /// No description provided for @petIdleShelf.
  ///
  /// In en, this message translates to:
  /// **'Hmm, which book next…'**
  String get petIdleShelf;

  /// No description provided for @petIdleYawn.
  ///
  /// In en, this message translates to:
  /// **'Yaawn…'**
  String get petIdleYawn;

  /// No description provided for @petIdleDance.
  ///
  /// In en, this message translates to:
  /// **'A little dance!'**
  String get petIdleDance;

  /// No description provided for @petIdleSneeze.
  ///
  /// In en, this message translates to:
  /// **'Achoo!'**
  String get petIdleSneeze;

  /// No description provided for @petIdleWave.
  ///
  /// In en, this message translates to:
  /// **'Hi there!'**
  String get petIdleWave;

  /// No description provided for @petStatusHowTo.
  ///
  /// In en, this message translates to:
  /// **'Stroke me for a pat, pick me up, or feed me a link!'**
  String get petStatusHowTo;

  /// No description provided for @petWardrobeHint.
  ///
  /// In en, this message translates to:
  /// **'Colours and accessories to try on.'**
  String get petWardrobeHint;

  /// No description provided for @petVitalsLabel.
  ///
  /// In en, this message translates to:
  /// **'HOW IT\'S DOING'**
  String get petVitalsLabel;

  /// No description provided for @petStatsLabel.
  ///
  /// In en, this message translates to:
  /// **'ITS STORY'**
  String get petStatsLabel;

  /// No description provided for @petStatusBonk.
  ///
  /// In en, this message translates to:
  /// **'Ow! What was that for?'**
  String get petStatusBonk;

  /// No description provided for @petStatusBonkAngry.
  ///
  /// In en, this message translates to:
  /// **'Hey! Stop hitting me!'**
  String get petStatusBonkAngry;

  /// No description provided for @petStatusCry.
  ///
  /// In en, this message translates to:
  /// **'Waaah… it hurts! Pet me better…'**
  String get petStatusCry;

  /// No description provided for @petStatusCrySoothe.
  ///
  /// In en, this message translates to:
  /// **'Sniff… sniff…'**
  String get petStatusCrySoothe;

  /// No description provided for @petStatusComforted.
  ///
  /// In en, this message translates to:
  /// **'Thank you… but please don\'t hit me again.'**
  String get petStatusComforted;

  /// No description provided for @petIdleRoll.
  ///
  /// In en, this message translates to:
  /// **'Wheee~ rolling!'**
  String get petIdleRoll;

  /// No description provided for @petIdleRollBack.
  ///
  /// In en, this message translates to:
  /// **'Hehe, I\'m back!'**
  String get petIdleRollBack;

  /// No description provided for @petStatusMosquito.
  ///
  /// In en, this message translates to:
  /// **'Hey, a mosquito!'**
  String get petStatusMosquito;

  /// No description provided for @petStatusMosquitoChase.
  ///
  /// In en, this message translates to:
  /// **'Come back here!'**
  String get petStatusMosquitoChase;

  /// No description provided for @petStatusMosquitoCaught.
  ///
  /// In en, this message translates to:
  /// **'Hap! Gotcha~'**
  String get petStatusMosquitoCaught;

  /// No description provided for @petStatusMosquitoAfter.
  ///
  /// In en, this message translates to:
  /// **'Hmm… not very filling, though.'**
  String get petStatusMosquitoAfter;

  /// No description provided for @homeBoardSemantics.
  ///
  /// In en, this message translates to:
  /// **'Pegboard: {count} saved today. Tap to see them.'**
  String homeBoardSemantics(int count);

  /// No description provided for @homeTvChannel.
  ///
  /// In en, this message translates to:
  /// **'TV — tap to change the channel'**
  String get homeTvChannel;

  /// No description provided for @homeHouseTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s place'**
  String homeHouseTitle(String name);

  /// No description provided for @homeGreetNight.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetNight;

  /// No description provided for @homeGeckoChirp.
  ///
  /// In en, this message translates to:
  /// **'tchk tchk tchk'**
  String get homeGeckoChirp;

  /// No description provided for @petStatusGecko.
  ///
  /// In en, this message translates to:
  /// **'Ooh, a gecko!'**
  String get petStatusGecko;

  /// No description provided for @homeClockSemantics.
  ///
  /// In en, this message translates to:
  /// **'Clock, {time}'**
  String homeClockSemantics(String time);

  /// No description provided for @homePetInfo.
  ///
  /// In en, this message translates to:
  /// **'{name} — see its info'**
  String homePetInfo(String name);

  /// No description provided for @homeInbox.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get homeInbox;

  /// No description provided for @homeInboxUnread.
  ///
  /// In en, this message translates to:
  /// **'News — something new'**
  String get homeInboxUnread;

  /// No description provided for @petStatusFeedMe.
  ///
  /// In en, this message translates to:
  /// **'Paste a link down here — I\'m hungry!'**
  String get petStatusFeedMe;

  /// No description provided for @inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'News from {name}'**
  String inboxTitle(String name);

  /// No description provided for @inboxEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'All quiet'**
  String get inboxEmptyTitle;

  /// No description provided for @inboxEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will let you know here.'**
  String inboxEmptyBody(String name);

  /// No description provided for @inboxNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get inboxNow;

  /// No description provided for @inboxMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String inboxMinutesAgo(int count);

  /// No description provided for @inboxHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String inboxHoursAgo(int count);

  /// No description provided for @inboxYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get inboxYesterday;

  /// No description provided for @inboxDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String inboxDaysAgo(int count);

  /// No description provided for @noticeHungryTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is hungry'**
  String noticeHungryTitle(String name);

  /// No description provided for @noticeHungryBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s quiz is its meal — three quick questions.'**
  String get noticeHungryBody;

  /// No description provided for @noticeLonelyTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} feels a bit lonely'**
  String noticeLonelyTitle(String name);

  /// No description provided for @noticeLonelyBody.
  ///
  /// In en, this message translates to:
  /// **'Give it a little stroke.'**
  String get noticeLonelyBody;

  /// No description provided for @noticeUnfedTitle.
  ///
  /// In en, this message translates to:
  /// **'No meal yet today'**
  String get noticeUnfedTitle;

  /// No description provided for @noticeUnfedBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Keep your 1-day care streak going — finish today\'s quiz.} other{Keep your {count}-day care streak going — finish today\'s quiz.}}'**
  String noticeUnfedBody(int count);

  /// No description provided for @noticeQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s meal is ready'**
  String get noticeQuizTitle;

  /// No description provided for @noticeQuizBody.
  ///
  /// In en, this message translates to:
  /// **'Three quick questions from your notes.'**
  String get noticeQuizBody;

  /// No description provided for @noticeHatchedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} hatched!'**
  String noticeHatchedTitle(String name);

  /// No description provided for @noticeHatchedBody.
  ///
  /// In en, this message translates to:
  /// **'Say hi — then feed it your first finds.'**
  String get noticeHatchedBody;

  /// No description provided for @noticeEvolvedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} grew into {stage}'**
  String noticeEvolvedTitle(String name, String stage);

  /// No description provided for @noticeEvolvedBody.
  ///
  /// In en, this message translates to:
  /// **'New accessories may have opened up in the wardrobe.'**
  String get noticeEvolvedBody;

  /// No description provided for @noticeStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} days of care!'**
  String noticeStreakTitle(int count);

  /// No description provided for @noticeStreakBody.
  ///
  /// In en, this message translates to:
  /// **'{name} loves having you around.'**
  String noticeStreakBody(String name);

  /// No description provided for @profileSoundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get profileSoundEffects;

  /// No description provided for @profileRoomAmbience.
  ///
  /// In en, this message translates to:
  /// **'Room ambience'**
  String get profileRoomAmbience;

  /// No description provided for @profileBackgroundMusic.
  ///
  /// In en, this message translates to:
  /// **'Background music'**
  String get profileBackgroundMusic;

  /// No description provided for @profileGroupSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get profileGroupSound;

  /// No description provided for @profileGroupYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get profileGroupYou;

  /// No description provided for @profileGroupNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes & library'**
  String get profileGroupNotes;

  /// No description provided for @profileGroupMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get profileGroupMore;

  /// No description provided for @profileSoundOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get profileSoundOn;

  /// No description provided for @profileSoundOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get profileSoundOff;

  /// No description provided for @profileLanguageInUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get profileLanguageInUse;

  /// No description provided for @profileLanguagePick.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get profileLanguagePick;

  /// No description provided for @noteEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get noteEditorNewTitle;

  /// No description provided for @noteEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get noteEditorEditTitle;

  /// No description provided for @noteEditorAutoSave.
  ///
  /// In en, this message translates to:
  /// **'Saved as you go'**
  String get noteEditorAutoSave;

  /// No description provided for @noteEditorSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get noteEditorSaving;

  /// No description provided for @onboardSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardSkip;

  /// No description provided for @onboardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardNext;

  /// No description provided for @onboardStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get onboardStart;

  /// No description provided for @onboardMeetTitle.
  ///
  /// In en, this message translates to:
  /// **'Meet your\nlittle pet.'**
  String get onboardMeetTitle;

  /// No description provided for @onboardMeetBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s still in its egg, and it only eats one thing: what you learn.'**
  String get onboardMeetBody;

  /// No description provided for @onboardFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed it what\nyou find.'**
  String get onboardFeedTitle;

  /// No description provided for @onboardFeedBody.
  ///
  /// In en, this message translates to:
  /// **'Share a video or paste a link. Your pet writes down the title, summary and tags, then nibbles it as a snack.'**
  String get onboardFeedBody;

  /// No description provided for @onboardGrowTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch it\ngrow up.'**
  String get onboardGrowTitle;

  /// No description provided for @onboardGrowBody.
  ///
  /// In en, this message translates to:
  /// **'Every note helps it grow, from a tiny egg to a wise old sage. Keep it fed and happy!'**
  String get onboardGrowBody;

  /// No description provided for @onboardAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask, then\ntest yourself.'**
  String get onboardAskTitle;

  /// No description provided for @onboardAskBody.
  ///
  /// In en, this message translates to:
  /// **'Its real meal is a 3-question quiz from your notes every day, so what you save actually sticks. You can ask the assistant anything, too.'**
  String get onboardAskBody;

  /// No description provided for @onboardAskBubble.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything!'**
  String get onboardAskBubble;

  /// No description provided for @chatSourcesLabel.
  ///
  /// In en, this message translates to:
  /// **'FROM YOUR NOTES'**
  String get chatSourcesLabel;

  /// No description provided for @tagsEmptyEyebrow.
  ///
  /// In en, this message translates to:
  /// **'NO TAGS YET'**
  String get tagsEmptyEyebrow;

  /// No description provided for @tagsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tags\nyet.'**
  String get tagsEmptyTitle;

  /// No description provided for @tagsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tags show up here once you add them to your notes. Add them when you save or edit a note.'**
  String get tagsEmptyBody;

  /// No description provided for @notesIdleSip.
  ///
  /// In en, this message translates to:
  /// **'Tea break.'**
  String get notesIdleSip;

  /// No description provided for @notesIdleThink.
  ///
  /// In en, this message translates to:
  /// **'Hmm… how do I put this?'**
  String get notesIdleThink;

  /// No description provided for @notesIdleIdea.
  ///
  /// In en, this message translates to:
  /// **'Oh! Got it.'**
  String get notesIdleIdea;

  /// No description provided for @notesIdleBoard.
  ///
  /// In en, this message translates to:
  /// **'Let me check the pinboard.'**
  String get notesIdleBoard;

  /// No description provided for @notesIdleDoze.
  ///
  /// In en, this message translates to:
  /// **'Huh? I\'m awake, I\'m awake!'**
  String get notesIdleDoze;

  /// No description provided for @libraryIdleDoze.
  ///
  /// In en, this message translates to:
  /// **'Zz… just resting my eyes.'**
  String get libraryIdleDoze;

  /// No description provided for @libraryIdleGiggle.
  ///
  /// In en, this message translates to:
  /// **'Hehe, this part\'s funny.'**
  String get libraryIdleGiggle;

  /// No description provided for @libraryIdleSneeze.
  ///
  /// In en, this message translates to:
  /// **'Achoo! Dusty pages.'**
  String get libraryIdleSneeze;

  /// No description provided for @chatIdleSip.
  ///
  /// In en, this message translates to:
  /// **'Mm, the tea\'s still warm.'**
  String get chatIdleSip;

  /// No description provided for @visitHello.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}!'**
  String visitHello(String name);

  /// No description provided for @visitHelloBack.
  ///
  /// In en, this message translates to:
  /// **'Oh, {name}! Hi there!'**
  String visitHelloBack(String name);

  /// No description provided for @visitAskFood.
  ///
  /// In en, this message translates to:
  /// **'What did you eat today?'**
  String get visitAskFood;

  /// No description provided for @visitAskLearn.
  ///
  /// In en, this message translates to:
  /// **'Learned anything new today?'**
  String get visitAskLearn;

  /// No description provided for @visitAskRoom.
  ///
  /// In en, this message translates to:
  /// **'Your room\'s so cozy!'**
  String get visitAskRoom;

  /// No description provided for @visitReplyAte.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One tasty note!} other{{count} tasty notes!}}'**
  String visitReplyAte(int count);

  /// No description provided for @visitReplyHungry.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet… I\'m starving.'**
  String get visitReplyHungry;

  /// No description provided for @visitReplyRoom.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Come by anytime.'**
  String get visitReplyRoom;

  /// No description provided for @visitWow.
  ///
  /// In en, this message translates to:
  /// **'Wow, I\'m jealous!'**
  String get visitWow;

  /// No description provided for @visitAww.
  ///
  /// In en, this message translates to:
  /// **'Aww, hope you get fed soon.'**
  String get visitAww;

  /// No description provided for @visitBye.
  ///
  /// In en, this message translates to:
  /// **'Gotta go. See you!'**
  String get visitBye;

  /// No description provided for @visitByeBack.
  ///
  /// In en, this message translates to:
  /// **'Bye-bye!'**
  String get visitByeBack;

  /// No description provided for @visitSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, a friend dropping by'**
  String visitSemantics(String name);

  /// No description provided for @homeCalendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today is {date}.'**
  String homeCalendarToday(String date);

  /// No description provided for @petStatusSnackEnough.
  ///
  /// In en, this message translates to:
  /// **'That\'s enough snacks today — I\'m saving room for my quiz meal!'**
  String get petStatusSnackEnough;

  /// No description provided for @petStatusMealLocked.
  ///
  /// In en, this message translates to:
  /// **'Save {count} notes and I can have real meals — quizzes!'**
  String petStatusMealLocked(int count);

  /// No description provided for @homeMealReady.
  ///
  /// In en, this message translates to:
  /// **'Today\'s meal'**
  String get homeMealReady;

  /// No description provided for @homeMealReadySub.
  ///
  /// In en, this message translates to:
  /// **'3 quick questions'**
  String get homeMealReadySub;

  /// No description provided for @homeFeastReady.
  ///
  /// In en, this message translates to:
  /// **'Weekly feast'**
  String get homeFeastReady;

  /// No description provided for @homeFeastReadySub.
  ///
  /// In en, this message translates to:
  /// **'A longer quiz, big growth'**
  String get homeFeastReadySub;

  /// No description provided for @homeMealDone.
  ///
  /// In en, this message translates to:
  /// **'Fed for today'**
  String get homeMealDone;

  /// No description provided for @homeMealLocked.
  ///
  /// In en, this message translates to:
  /// **'Meals open soon'**
  String get homeMealLocked;

  /// No description provided for @homeMealLockedSub.
  ///
  /// In en, this message translates to:
  /// **'{count}/{need} notes saved'**
  String homeMealLockedSub(int count, int need);

  /// No description provided for @quizMealTitle.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S MEAL'**
  String get quizMealTitle;

  /// No description provided for @quizFeastTitle.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY FEAST'**
  String get quizFeastTitle;

  /// No description provided for @quizMealLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing today\'s meal…'**
  String get quizMealLoading;

  /// No description provided for @quizGainFull.
  ///
  /// In en, this message translates to:
  /// **'+{count} full'**
  String quizGainFull(int count);

  /// No description provided for @quizGainGrowth.
  ///
  /// In en, this message translates to:
  /// **'+{count} growth'**
  String quizGainGrowth(int count);

  /// No description provided for @quizResultHardCarryDaily.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tricky question will come back tomorrow.} other{{count} tricky questions will come back tomorrow.}}'**
  String quizResultHardCarryDaily(int count);

  /// No description provided for @quizResultHardCarryNoneDaily.
  ///
  /// In en, this message translates to:
  /// **'All clear — nothing tricky to bring back.'**
  String get quizResultHardCarryNoneDaily;

  /// No description provided for @petStatusFullRefuse.
  ///
  /// In en, this message translates to:
  /// **'Nope, I\'m full! A snack would be nice, though — save a new note.'**
  String get petStatusFullRefuse;

  /// No description provided for @petStatusFeastNudge.
  ///
  /// In en, this message translates to:
  /// **'Want me to grow up fast? Do this week\'s feast quiz!'**
  String get petStatusFeastNudge;

  /// No description provided for @petStatusFeastLocked.
  ///
  /// In en, this message translates to:
  /// **'Save {count} notes this week, then we\'ll have a feast!'**
  String petStatusFeastLocked(int count);

  /// No description provided for @quizPetStart.
  ///
  /// In en, this message translates to:
  /// **'Mealtime! Let\'s go.'**
  String get quizPetStart;

  /// No description provided for @quizPetFeastStart.
  ///
  /// In en, this message translates to:
  /// **'Feast time! I\'m starving.'**
  String get quizPetFeastStart;

  /// No description provided for @quizPetLast.
  ///
  /// In en, this message translates to:
  /// **'Last bite!'**
  String get quizPetLast;

  /// No description provided for @quizPetPicked.
  ///
  /// In en, this message translates to:
  /// **'Ooh, that one?'**
  String get quizPetPicked;

  /// No description provided for @quizPetHurry.
  ///
  /// In en, this message translates to:
  /// **'Hurry up, I\'m hungry!'**
  String get quizPetHurry;

  /// No description provided for @quizPetHurryAgain.
  ///
  /// In en, this message translates to:
  /// **'My tummy\'s rumbling…'**
  String get quizPetHurryAgain;

  /// No description provided for @quizPetYum.
  ///
  /// In en, this message translates to:
  /// **'Mmm, tasty!'**
  String get quizPetYum;

  /// No description provided for @quizPetYuck.
  ///
  /// In en, this message translates to:
  /// **'Hmm… that tasted a bit off.'**
  String get quizPetYuck;

  /// No description provided for @quizPetBurp.
  ///
  /// In en, this message translates to:
  /// **'*Burp!* Oops, excuse me.'**
  String get quizPetBurp;

  /// No description provided for @quizPetFull.
  ///
  /// In en, this message translates to:
  /// **'So full… thank you!'**
  String get quizPetFull;

  /// No description provided for @quizPetDoneGood.
  ///
  /// In en, this message translates to:
  /// **'That was a good meal!'**
  String get quizPetDoneGood;

  /// No description provided for @quizPetDoneMeh.
  ///
  /// In en, this message translates to:
  /// **'Still a little hungry… let\'s study more!'**
  String get quizPetDoneMeh;

  /// No description provided for @libraryPetTease.
  ///
  /// In en, this message translates to:
  /// **'Sure you can make me full today?'**
  String get libraryPetTease;

  /// No description provided for @libraryPetTeaseFed.
  ///
  /// In en, this message translates to:
  /// **'That\'s all? I want more tomorrow.'**
  String get libraryPetTeaseFed;

  /// No description provided for @offlineNeedInternet.
  ///
  /// In en, this message translates to:
  /// **'I need the internet to {what}. Turn on Wi-Fi or mobile data first!'**
  String offlineNeedInternet(String what);

  /// No description provided for @offlineWhatAssistant.
  ///
  /// In en, this message translates to:
  /// **'think up an answer'**
  String get offlineWhatAssistant;

  /// No description provided for @offlineWhatMealQuiz.
  ///
  /// In en, this message translates to:
  /// **'cook up today\'s quiz'**
  String get offlineWhatMealQuiz;

  /// No description provided for @offlineWhatFeastQuiz.
  ///
  /// In en, this message translates to:
  /// **'set up the weekly feast'**
  String get offlineWhatFeastQuiz;

  /// No description provided for @offlineWhatSummary.
  ///
  /// In en, this message translates to:
  /// **'read and summarize the link'**
  String get offlineWhatSummary;

  /// No description provided for @offlineWhatPreview.
  ///
  /// In en, this message translates to:
  /// **'peek at the link'**
  String get offlineWhatPreview;

  /// No description provided for @offlineWhatVideo.
  ///
  /// In en, this message translates to:
  /// **'play the video'**
  String get offlineWhatVideo;

  /// No description provided for @offlineWhatDownload.
  ///
  /// In en, this message translates to:
  /// **'download the video'**
  String get offlineWhatDownload;

  /// No description provided for @offlineWhatReindex.
  ///
  /// In en, this message translates to:
  /// **'re-index your notes'**
  String get offlineWhatReindex;

  /// No description provided for @offlineWhatAccount.
  ///
  /// In en, this message translates to:
  /// **'update your account'**
  String get offlineWhatAccount;

  /// No description provided for @offlineWhatSignUp.
  ///
  /// In en, this message translates to:
  /// **'create your account'**
  String get offlineWhatSignUp;

  /// No description provided for @offlineWhatSignIn.
  ///
  /// In en, this message translates to:
  /// **'sign you in'**
  String get offlineWhatSignIn;

  /// No description provided for @offlineSafeNote.
  ///
  /// In en, this message translates to:
  /// **'Your notes are safe on this phone, and they sync by themselves once you\'re back online.'**
  String get offlineSafeNote;

  /// No description provided for @offlineBackOnline.
  ///
  /// In en, this message translates to:
  /// **'Yay, we\'re back online!'**
  String get offlineBackOnline;

  /// No description provided for @offlineStill.
  ///
  /// In en, this message translates to:
  /// **'Still offline… try again in a bit?'**
  String get offlineStill;

  /// No description provided for @offlineOk.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get offlineOk;

  /// No description provided for @offlineRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get offlineRetry;

  /// No description provided for @offlineContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get offlineContinue;

  /// No description provided for @offlineTag.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineTag;

  /// No description provided for @petStatusOfflineSaved.
  ///
  /// In en, this message translates to:
  /// **'We\'re offline, so I can\'t summarize it yet. I saved the link for now!'**
  String get petStatusOfflineSaved;

  /// No description provided for @petStatusWentOffline.
  ///
  /// In en, this message translates to:
  /// **'We\'re offline. You can still save notes, I\'ll keep them safe!'**
  String get petStatusWentOffline;

  /// No description provided for @petStatusBackOnline.
  ///
  /// In en, this message translates to:
  /// **'Back online! Sending your notes up now.'**
  String get petStatusBackOnline;

  /// No description provided for @petStatusCoinsFalling.
  ///
  /// In en, this message translates to:
  /// **'Hey, my coins are falling out! Stop shaking me!'**
  String get petStatusCoinsFalling;

  /// No description provided for @petStatusCoinsGather.
  ///
  /// In en, this message translates to:
  /// **'My coins! My coins!'**
  String get petStatusCoinsGather;

  /// No description provided for @petStatusCoinsCounted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{My one coin, safe and sound!} other{{count} coins, all here!}} Don\'t you steal my money!'**
  String petStatusCoinsCounted(int count);

  /// No description provided for @petStatusCoinsMine.
  ///
  /// In en, this message translates to:
  /// **'Don\'t steal my money!'**
  String get petStatusCoinsMine;

  /// No description provided for @petStatusCoinsSavings.
  ///
  /// In en, this message translates to:
  /// **'That\'s my savings! Hands off!'**
  String get petStatusCoinsSavings;

  /// No description provided for @noteDetailPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {position} of {count}'**
  String noteDetailPageOf(int position, int count);

  /// No description provided for @noteDetailPrevPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get noteDetailPrevPage;

  /// No description provided for @noteDetailNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get noteDetailNextPage;

  /// No description provided for @avatarPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your avatar'**
  String get avatarPickerTitle;

  /// No description provided for @avatarPickerBody.
  ///
  /// In en, this message translates to:
  /// **'A little animal to stand in for you.'**
  String get avatarPickerBody;

  /// No description provided for @avatarPickerUse.
  ///
  /// In en, this message translates to:
  /// **'Use this avatar'**
  String get avatarPickerUse;

  /// No description provided for @accountCardEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Member card'**
  String get accountCardEyebrow;

  /// No description provided for @accountChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change avatar'**
  String get accountChangeAvatar;

  /// No description provided for @avatarCat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get avatarCat;

  /// No description provided for @avatarDog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get avatarDog;

  /// No description provided for @avatarBear.
  ///
  /// In en, this message translates to:
  /// **'Bear'**
  String get avatarBear;

  /// No description provided for @avatarBunny.
  ///
  /// In en, this message translates to:
  /// **'Bunny'**
  String get avatarBunny;

  /// No description provided for @avatarPanda.
  ///
  /// In en, this message translates to:
  /// **'Panda'**
  String get avatarPanda;

  /// No description provided for @avatarFox.
  ///
  /// In en, this message translates to:
  /// **'Fox'**
  String get avatarFox;

  /// No description provided for @avatarFrog.
  ///
  /// In en, this message translates to:
  /// **'Frog'**
  String get avatarFrog;

  /// No description provided for @avatarOwl.
  ///
  /// In en, this message translates to:
  /// **'Owl'**
  String get avatarOwl;

  /// No description provided for @avatarKoala.
  ///
  /// In en, this message translates to:
  /// **'Koala'**
  String get avatarKoala;

  /// No description provided for @avatarPig.
  ///
  /// In en, this message translates to:
  /// **'Pig'**
  String get avatarPig;

  /// No description provided for @avatarPenguin.
  ///
  /// In en, this message translates to:
  /// **'Penguin'**
  String get avatarPenguin;

  /// No description provided for @avatarLion.
  ///
  /// In en, this message translates to:
  /// **'Lion'**
  String get avatarLion;

  /// No description provided for @petIdleTour.
  ///
  /// In en, this message translates to:
  /// **'A little tour of the room~'**
  String get petIdleTour;

  /// No description provided for @petIdleTourLook.
  ///
  /// In en, this message translates to:
  /// **'Hmm, what\'s over here…'**
  String get petIdleTourLook;

  /// No description provided for @petIdleTourDone.
  ///
  /// In en, this message translates to:
  /// **'Tour done! My place looks nice.'**
  String get petIdleTourDone;

  /// No description provided for @petIdleShelfAfter.
  ///
  /// In en, this message translates to:
  /// **'Maybe later… I\'ll wait for you to read them, hehe~'**
  String get petIdleShelfAfter;

  /// No description provided for @petIdleTvAfter.
  ///
  /// In en, this message translates to:
  /// **'Meh, nothing good on. TV\'s no fun anymore.'**
  String get petIdleTvAfter;

  /// No description provided for @petIdleFull.
  ///
  /// In en, this message translates to:
  /// **'Hehe, so full and happy~'**
  String get petIdleFull;

  /// No description provided for @petIdleHum.
  ///
  /// In en, this message translates to:
  /// **'La la la~ ♪'**
  String get petIdleHum;

  /// No description provided for @coachNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get coachNext;

  /// No description provided for @coachSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get coachSkip;

  /// No description provided for @coachDone.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get coachDone;

  /// No description provided for @quizCoachFeed.
  ///
  /// In en, this message translates to:
  /// **'From now on you can feed {name} every day! Its meal is a 3-question quiz on your notes.'**
  String quizCoachFeed(String name);

  /// No description provided for @quizCoachAnswer.
  ///
  /// In en, this message translates to:
  /// **'Pick an answer, then tap Check. A right one is a tasty bite; a wrong one still gets eaten, but it tastes funny.'**
  String get quizCoachAnswer;

  /// No description provided for @quizCoachSteps.
  ///
  /// In en, this message translates to:
  /// **'Finish all three to fill {name} up. There\'ll be new questions tomorrow.'**
  String quizCoachSteps(String name);

  /// No description provided for @homeCoachEgg.
  ///
  /// In en, this message translates to:
  /// **'Paste your first link here to hatch the egg.'**
  String get homeCoachEgg;

  /// No description provided for @homeCoachSave.
  ///
  /// In en, this message translates to:
  /// **'Every link you save is a snack for {name}. Paste one here any time.'**
  String homeCoachSave(String name);

  /// No description provided for @homeCoachMeal.
  ///
  /// In en, this message translates to:
  /// **'This is {name}\'s daily meal. Once you have 3 notes, tap it for the day\'s quiz.'**
  String homeCoachMeal(String name);

  /// No description provided for @homeCoachFeast.
  ///
  /// In en, this message translates to:
  /// **'The weekly feast: a longer quiz on the past week\'s notes. It makes {name} grow fast.'**
  String homeCoachFeast(String name);

  /// No description provided for @homeCoachVitals.
  ///
  /// In en, this message translates to:
  /// **'How full, happy and grown {name} is shows here. Tap its name for its profile.'**
  String homeCoachVitals(String name);

  /// No description provided for @homeCoachShare.
  ///
  /// In en, this message translates to:
  /// **'Even easier: in YouTube, TikTok or Instagram, tap Share and pick IngatanKu. No need to copy the link.'**
  String get homeCoachShare;

  /// No description provided for @coachShareTap.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get coachShareTap;

  /// No description provided for @widgetEggTitle.
  ///
  /// In en, this message translates to:
  /// **'The egg is waiting'**
  String get widgetEggTitle;

  /// No description provided for @widgetEggBody.
  ///
  /// In en, this message translates to:
  /// **'Save your first link to hatch {name}.'**
  String widgetEggBody(String name);

  /// No description provided for @widgetLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is snacking'**
  String widgetLockedTitle(String name);

  /// No description provided for @widgetLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Save 3 notes to open its daily quiz.'**
  String get widgetLockedBody;

  /// No description provided for @widgetReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is hungry!'**
  String widgetReadyTitle(String name);

  /// No description provided for @widgetReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s quiz is ready. Just 3 questions.'**
  String get widgetReadyBody;

  /// No description provided for @widgetLateTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is still waiting…'**
  String widgetLateTitle(String name);

  /// No description provided for @widgetLateBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing to eat all day. There\'s still time!'**
  String get widgetLateBody;

  /// No description provided for @widgetFullTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is full'**
  String widgetFullTitle(String name);

  /// No description provided for @widgetFullBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s meal is done. See you tomorrow!'**
  String get widgetFullBody;

  /// No description provided for @widgetFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed it'**
  String get widgetFeed;

  /// No description provided for @widgetSave.
  ///
  /// In en, this message translates to:
  /// **'Save a link'**
  String get widgetSave;

  /// No description provided for @widgetStreak.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak'**
  String widgetStreak(int days);

  /// No description provided for @authContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueGoogle;

  /// No description provided for @authGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in with Google. Try again?'**
  String get authGoogleFailed;

  /// No description provided for @accountFieldSignIn.
  ///
  /// In en, this message translates to:
  /// **'Signs in with'**
  String get accountFieldSignIn;

  /// No description provided for @accountFieldSignInGoogleCaption.
  ///
  /// In en, this message translates to:
  /// **'Your Google account keeps this account safe.'**
  String get accountFieldSignInGoogleCaption;

  /// No description provided for @quizMealScoreEyebrow.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S SCORE'**
  String get quizMealScoreEyebrow;
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
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
