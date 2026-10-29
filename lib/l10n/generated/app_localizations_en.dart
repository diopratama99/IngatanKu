// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'IngatanKu';

  @override
  String get navHome => 'Home';

  @override
  String get navLibrary => 'Library';

  @override
  String get navNotes => 'Notes';

  @override
  String get navAssistant => 'Assistant';

  @override
  String get navProfile => 'Profile';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingNight => 'Good night';

  @override
  String get dashboardSectionProgress => 'PROGRESS';

  @override
  String get dashboardSectionRecentNotes => 'YOUR NOTES';

  @override
  String get dashboardSectionFeatures => 'FEATURES';

  @override
  String get dashboardSectionStats => 'STATS';

  @override
  String get dashboardSectionKnowledgeMap => 'KNOWLEDGE MAP';

  @override
  String get dashboardStatNotes => 'Saved notes';

  @override
  String get dashboardStatTopTag => 'Top tag';

  @override
  String get dashboardKnowledgeMapDetail => 'DETAILS';

  @override
  String get featureWeeklyQuiz => 'Weekly Quiz';

  @override
  String get featureManageTags => 'Manage Tags';

  @override
  String get accountSubtitle =>
      'Manage your IngatanKu identity. Changes sync to the web dashboard immediately.';

  @override
  String get accountSectionIdentity => 'IDENTITY';

  @override
  String get accountSectionSecurity => 'SECURITY';

  @override
  String get accountSectionPreferences => 'PREFERENCES';

  @override
  String get accountFieldName => 'Name';

  @override
  String get accountFieldEmail => 'Email';

  @override
  String get accountFieldEmailCaption =>
      'Contact support to change your email.';

  @override
  String get accountFieldPassword => 'Password';

  @override
  String get accountFieldLanguage => 'Language';

  @override
  String get localeSystem => 'Follow system';

  @override
  String get localeSystemCaption =>
      'Use the device language. Falls back to English.';

  @override
  String get localeIndonesian => 'Bahasa Indonesia';

  @override
  String get localeEnglish => 'English';

  @override
  String get pickerTitleLanguage => 'LANGUAGE';

  @override
  String get profilePageEyebrow => 'PROFILE';

  @override
  String get profileFallbackDisplayName => 'Anonymous';

  @override
  String get profileSignOutTooltip => 'Sign out';

  @override
  String get profileSignOutDialogTitle => 'Sign out?';

  @override
  String get profileSignOutDialogMessage =>
      'You\'ll need to sign in again to open your notes.';

  @override
  String get profileSignOutDialogCancel => 'Cancel';

  @override
  String get profileSignOutDialogConfirm => 'Sign out';

  @override
  String get profileSectionSettings => 'SETTINGS';

  @override
  String get profileNavAccount => 'Account';

  @override
  String get profileNavStorage => 'Offline storage';

  @override
  String get profileNavAiSearch => 'AI & search';

  @override
  String get profileNavPrivacy => 'Privacy & data';

  @override
  String get profileNavAbout => 'About IngatanKu';

  @override
  String get vaultPageEyebrow => 'LIBRARY';

  @override
  String get vaultPageTitle => 'Your notes.';

  @override
  String get vaultCountEmpty => 'No notes yet';

  @override
  String vaultCountSaved(int count) {
    return '$count saved notes';
  }

  @override
  String get vaultSearchHint => 'Search title, content, or #tag…';

  @override
  String get vaultLayoutListTooltip => 'Detail view';

  @override
  String get vaultLayoutGridTooltip => 'Shelf view';

  @override
  String get vaultFabNewNote => 'New note';

  @override
  String get vaultEmptyEyebrow => 'EMPTY LIBRARY';

  @override
  String get vaultEmptyTitle => 'Start\nwriting';

  @override
  String get vaultEmptyMessage =>
      'Tap \"New note\" at the bottom right to save your first link, you\'ll earn 10 XP.';

  @override
  String get vaultNotFoundEyebrow => 'NOT FOUND';

  @override
  String vaultNotFoundTitle(String query) {
    return '\"$query\"\nisn\'t\nhere';
  }

  @override
  String get vaultNotFoundMessage =>
      'Try another keyword, or clear the search.';

  @override
  String get noteDetailBackTooltip => 'Back';

  @override
  String get noteDetailMoreTooltip => 'More actions';

  @override
  String get noteDetailUntitled => '(Untitled)';

  @override
  String get noteDetailEmptyMarkdown => '_No notes yet._';

  @override
  String get noteDetailSwipeHint => 'Swipe to turn the page';

  @override
  String get chatStarterAsk => 'What can I ask once I\'ve saved a few notes?';

  @override
  String get chatStarterHow => 'How do you answer my questions?';

  @override
  String get chatStarterWhat => 'What kinds of things are good to save here?';

  @override
  String chatTagSummary(String tag) {
    return 'Sum up my notes about #$tag';
  }

  @override
  String chatTagList(String tag) {
    return 'What have I saved about #$tag?';
  }

  @override
  String chatTagPoints(String tag) {
    return 'Give me 3 key points from my #$tag notes';
  }

  @override
  String chatTagTips(String tag) {
    return 'Show me practical tips about #$tag';
  }

  @override
  String chatTagTry(String tag) {
    return 'What could I try from my #$tag notes?';
  }

  @override
  String chatTagPattern(String tag) {
    return 'What do my #$tag notes have in common?';
  }

  @override
  String chatCompare(String a, String b) {
    return 'Compare my notes on #$a and #$b';
  }

  @override
  String chatShared(String a, String b) {
    return 'What do my #$a and #$b notes share?';
  }

  @override
  String chatLink(String a, String b) {
    return 'How are #$a and #$b connected in my notes?';
  }

  @override
  String chatTitlePoints(String title) {
    return 'What are the main points of \'$title\'?';
  }

  @override
  String chatTitleSummary(String title) {
    return 'Sum up \'$title\' for me';
  }

  @override
  String chatTitleTakeaway(String title) {
    return 'What can I take away from \'$title\'?';
  }

  @override
  String chatSource(String source) {
    return 'What\'s interesting in my recent $source notes?';
  }

  @override
  String get chatSourceArticle => 'article';

  @override
  String get chatWeek => 'What did I save this week?';

  @override
  String get chatLatestFive => 'Give me a 5-point summary of my latest notes';

  @override
  String get chatTheme => 'What comes up most in my latest notes?';

  @override
  String get chatHighlight =>
      'What\'s the most interesting thing I saved lately?';

  @override
  String get chatNextIdea =>
      'Suggest something new to try or learn, based on my notes';

  @override
  String get chatDig =>
      'What interesting questions could I explore from my notes?';

  @override
  String get chatGaps =>
      'Going by my notes, what do I still seem unsure about?';

  @override
  String get playerPlay => 'Play here';

  @override
  String get playerPlaySaved => 'Play saved copy';

  @override
  String get playerPreparing => 'Getting it ready…';

  @override
  String get playerRetry => 'Try again';

  @override
  String get playerOpenSource => 'Open the source';

  @override
  String get playerErrRefused =>
      'The server refused. Try again, or open it in its own app.';

  @override
  String get playerErrForbidden => 'Access denied (403). It may be private.';

  @override
  String get playerErrNotFound => 'Not found (404).';

  @override
  String get playerErrTimeout => 'That took too long. Try again in a moment.';

  @override
  String get playerErrLoad => 'Couldn\'t load the video. Try again.';

  @override
  String get playerErrOther => 'Can\'t play it here. Open the source instead.';

  @override
  String get playerErrWeb => 'Playing here isn\'t available on the web yet.';

  @override
  String get noteDetailMenuEdit => 'Edit note';

  @override
  String get noteDetailMenuOpenSource => 'Open source';

  @override
  String get noteDetailMenuSaveOffline => 'Save offline';

  @override
  String get noteDetailMenuDeleteOffline => 'Remove offline video';

  @override
  String get noteDetailMenuDelete => 'Delete note';

  @override
  String get noteDetailDeleteTitle => 'Delete this note?';

  @override
  String get noteDetailDeleteMessage =>
      'The note will be removed from your Library. This can\'t be undone.';

  @override
  String get noteDetailDeleteCancel => 'Cancel';

  @override
  String get noteDetailDeleteConfirm => 'Delete';

  @override
  String get noteDetailDeleteLocalTitle => 'Remove offline video?';

  @override
  String get noteDetailDeleteLocalMessage =>
      'The file will be removed from your device. The note stays safe and you can re-download anytime.';

  @override
  String get noteDetailDeleteLocalDone => 'Offline video removed';

  @override
  String get noteDetailSaveOfflineEyebrow => 'SAVE OFFLINE';

  @override
  String get noteDetailDownloadSavedSnack => 'Saved offline, plays from device';

  @override
  String noteDetailDownloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get noteDetailOpenFileFailed => 'No app can open this file';

  @override
  String get noteDetailShareFallbackTitle => 'Check this out';

  @override
  String get noteDetailLocalDeletedSnack => 'Local file deleted';

  @override
  String get noteDetailDownloadIdleTitle => 'Not saved yet';

  @override
  String get noteDetailDownloadIdleSubtitle =>
      'Download video/photo to your device';

  @override
  String get noteDetailDownloadAction => 'DOWNLOAD';

  @override
  String noteDetailDownloadingProgress(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get noteDetailDownloadingPreparing => 'Preparing…';

  @override
  String get noteDetailDownloadingCancel => 'CANCEL';

  @override
  String get noteDetailDownloadSavedTitle => 'Saved offline';

  @override
  String get noteDetailDownloadOpenTooltip => 'Open';

  @override
  String get noteDetailDownloadShareTooltip => 'Share';

  @override
  String get noteDetailDownloadDeleteTooltip => 'Remove from device';

  @override
  String get addNoteEditEyebrow => 'EDIT NOTE';

  @override
  String get addNoteNewEyebrow => 'NEW NOTE';

  @override
  String get addNoteEditTitle => 'Edit note.';

  @override
  String get addNoteNewTitle => 'New note.';

  @override
  String get addNoteTogglePreview => 'Preview';

  @override
  String get addNoteToggleEdit => 'Edit';

  @override
  String get addNoteSectionSource => 'SOURCE';

  @override
  String get addNoteSectionTitle => 'TITLE (OPTIONAL)';

  @override
  String get addNoteSectionNotes => 'YOUR NOTES';

  @override
  String get addNoteSectionTags => 'TAGS';

  @override
  String get quizToggleTitle => 'Use in quizzes';

  @override
  String get quizToggleOn =>
      'Questions about this note can come up in the daily quiz and the weekly feast.';

  @override
  String get quizToggleOff =>
      'It won\'t be quizzed. Good for links you only want to keep, like a comic or book title.';

  @override
  String get formatBold => 'Bold';

  @override
  String get formatHeading => 'Heading';

  @override
  String get formatBullets => 'Bulleted list';

  @override
  String get formatNumbers => 'Numbered list';

  @override
  String get addNoteUrlHint => 'https://youtube.com/shorts/…';

  @override
  String get addNoteTitleHint => 'Give it a name that\'s easy to remember';

  @override
  String get addNoteNotesHint =>
      'Write the insight, summary, or anything you want to remember from this content.';

  @override
  String get addNoteUrlRequired => 'URL is required';

  @override
  String get addNoteUrlMustStartWithHttp => 'Must start with http(s)';

  @override
  String get addNoteNotesMinLength => 'Minimum 10 characters';

  @override
  String get addNoteAutoFillNeedUrl => 'Enter a valid URL first';

  @override
  String get addNoteAutoFillTranscribing => 'Transcribing video…';

  @override
  String get addNoteAutoFillProcessing => 'Processing…';

  @override
  String addNoteAutoFillContentFound(String contentLabel) {
    return '$contentLabel found, drafting notes…';
  }

  @override
  String addNoteAutoFillError(String error) {
    return 'Auto-fill failed: $error';
  }

  @override
  String get addNoteAutoFillTooltipProcessing => 'Processing…';

  @override
  String get addNoteAutoFillTooltipTranscribe => 'Auto-fill (video transcript)';

  @override
  String get addNoteAutoFillTooltipUrl => 'Auto-fill from URL';

  @override
  String get addNoteReplaceDialogTitle => 'Replace current notes?';

  @override
  String get addNoteReplaceDialogTranscribe =>
      'Auto-fill will clear your draft, transcribe the video\'s audio, and write fresh notes.';

  @override
  String get addNoteReplaceDialogScrape =>
      'Auto-fill will clear your draft and replace it with new notes from the URL.';

  @override
  String get addNoteReplaceDialogCancel => 'Cancel';

  @override
  String get addNoteReplaceDialogConfirm => 'Replace';

  @override
  String get addNotePreviewEmpty => '_Nothing to preview yet…_';

  @override
  String get addNoteSavedSnack => 'Note saved.';

  @override
  String get addNoteUpdatedSnack => 'Changes saved';

  @override
  String get addNoteSaveButton => 'Save to Library';

  @override
  String get addNoteUpdateButton => 'Save changes';

  @override
  String get personalNotesEyebrow => 'NOTES';

  @override
  String get personalNotesTitle => 'Your thoughts.';

  @override
  String get personalNotesCountEmpty => 'No notes yet';

  @override
  String personalNotesCount(int count) {
    return '$count notes';
  }

  @override
  String get personalNotesSearchHint => 'Search note, content, or #tag…';

  @override
  String get personalNotesPinnedEyebrow => 'PINNED';

  @override
  String get personalNotesOthersEyebrow => 'OTHERS';

  @override
  String get personalNotesFabNew => 'New note';

  @override
  String get personalNotesEmptyEyebrow => 'EMPTY';

  @override
  String get personalNotesEmptyTitle => 'Write\nyour thoughts';

  @override
  String get personalNotesEmptyMessage =>
      'Tap \"New note\" to start. Free text, images, and links.';

  @override
  String get personalNotesNotFoundEyebrow => 'NOT FOUND';

  @override
  String personalNotesNotFoundTitle(String query) {
    return '\"$query\"\nisn\'t here';
  }

  @override
  String get personalNotesNotFoundMessage =>
      'Try another keyword, or clear the search.';

  @override
  String get noteEditorTitleHint => 'Title';

  @override
  String get noteEditorBodyHint => 'Write something…';

  @override
  String get noteEditorSectionLinks => 'LINKS';

  @override
  String get noteEditorSectionTags => 'TAGS';

  @override
  String get noteEditorPinTooltip => 'Pin';

  @override
  String get noteEditorUnpinTooltip => 'Unpin';

  @override
  String get noteEditorColorTooltip => 'Color';

  @override
  String get noteEditorDeleteTooltip => 'Delete';

  @override
  String get noteEditorAddImageTooltip => 'Add image';

  @override
  String get noteEditorAddLinkTooltip => 'Add link';

  @override
  String get noteEditorRemoveLinkTooltip => 'Remove link';

  @override
  String get noteEditorImageSourceGallery => 'From gallery';

  @override
  String get noteEditorImageSourceCamera => 'Take photo';

  @override
  String noteEditorImageAddFailed(String error) {
    return 'Couldn\'t add image: $error';
  }

  @override
  String noteEditorSaveFailed(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String get noteEditorDiscardEditTitle => 'Delete this note?';

  @override
  String get noteEditorDiscardNewTitle => 'Discard this note?';

  @override
  String get noteEditorDiscardEditMessage =>
      'The note and all its images will be deleted permanently.';

  @override
  String get noteEditorDiscardNewMessage =>
      'The draft will be tossed and any attached images go with it.';

  @override
  String get noteEditorDiscardCancel => 'Cancel';

  @override
  String get noteEditorDiscardEditConfirm => 'Delete';

  @override
  String get noteEditorDiscardNewConfirm => 'Discard';

  @override
  String get noteEditorLinkDialogAddTitle => 'Add link';

  @override
  String get noteEditorLinkDialogEditTitle => 'Edit link';

  @override
  String get noteEditorLinkUrlHint => 'https://…';

  @override
  String get noteEditorLinkLabelHint => 'Label (optional)';

  @override
  String get noteEditorLinkCancel => 'Cancel';

  @override
  String get noteEditorLinkSave => 'Save';

  @override
  String get noteEditorColorPickerEyebrow => 'NOTE COLOR';

  @override
  String get noteColorDefault => 'Default';

  @override
  String get noteColorRed => 'Red';

  @override
  String get noteColorOrange => 'Orange';

  @override
  String get noteColorYellow => 'Yellow';

  @override
  String get noteColorGreen => 'Green';

  @override
  String get noteColorTeal => 'Teal';

  @override
  String get noteColorBlue => 'Blue';

  @override
  String get noteColorPurple => 'Purple';

  @override
  String get noteColorPink => 'Pink';

  @override
  String get noteColorBrown => 'Brown';

  @override
  String get noteColorGray => 'Gray';

  @override
  String get loginEyebrow => 'INGATANKU';

  @override
  String get loginTitle => 'Welcome\nback.';

  @override
  String get loginSubtitle => 'Sign in to keep collecting notes.';

  @override
  String get loginEmailLabel => 'EMAIL';

  @override
  String get loginEmailHint => 'you@example.com';

  @override
  String get loginEmailInvalid => 'Invalid email';

  @override
  String get loginPasswordLabel => 'PASSWORD';

  @override
  String get loginPasswordForgot => 'FORGOT?';

  @override
  String get loginPasswordHint => 'At least 6 characters';

  @override
  String get loginPasswordTooShort => 'At least 6 characters';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginDivider => 'OR';

  @override
  String get loginNoAccount => 'No account yet?  ';

  @override
  String get loginSignUpAction => 'Sign up';

  @override
  String get signupAppBarTitle => 'SIGN UP';

  @override
  String get signupTitle => 'Create\nyour account.';

  @override
  String get signupSubtitle =>
      'Your pet is waiting to hatch. Feed it what you learn.';

  @override
  String get signupUsernameLabel => 'USERNAME';

  @override
  String get signupUsernameHint => 'e.g. sari.dewi';

  @override
  String get signupUsernameTooShort => 'At least 3 characters';

  @override
  String get signupEmailLabel => 'EMAIL';

  @override
  String get signupEmailHint => 'you@example.com';

  @override
  String get signupEmailInvalid => 'Invalid email';

  @override
  String get signupPasswordLabel => 'PASSWORD';

  @override
  String get signupPasswordHint => 'At least 6 characters';

  @override
  String get signupPasswordTooShort => 'At least 6 characters';

  @override
  String get signupSubmit => 'Sign up';

  @override
  String get forgotPasswordAppBarTitle => 'FORGOT PASSWORD';

  @override
  String get forgotPasswordEmailTitle => 'Reset your\npassword.';

  @override
  String get forgotPasswordEmailSubtitle =>
      'Enter your account email, we\'ll send a 6-digit code to verify.';

  @override
  String get forgotPasswordEmailLabel => 'EMAIL';

  @override
  String get forgotPasswordEmailHint => 'you@example.com';

  @override
  String get forgotPasswordEmailInvalid => 'Invalid email';

  @override
  String get forgotPasswordSendCode => 'Send reset code';

  @override
  String get forgotPasswordOtpTitle => 'Check\nyour email.';

  @override
  String get forgotPasswordOtpSubtitleLead => 'A 6-digit code was sent to\n';

  @override
  String get forgotPasswordOtpLabel => 'OTP CODE';

  @override
  String get forgotPasswordOtpVerify => 'Verify';

  @override
  String forgotPasswordOtpResendCooldown(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get forgotPasswordOtpResend => 'Resend code';

  @override
  String get forgotPasswordNewTitle => 'Set a new\npassword.';

  @override
  String get forgotPasswordNewSubtitle =>
      'Pick a password with at least 6 characters. Once saved you\'ll sign right in.';

  @override
  String get forgotPasswordNewLabel => 'NEW PASSWORD';

  @override
  String get forgotPasswordNewHint => 'At least 6 characters';

  @override
  String get forgotPasswordNewTooShort => 'At least 6 characters';

  @override
  String get forgotPasswordConfirmLabel => 'CONFIRMATION';

  @override
  String get forgotPasswordConfirmHint => 'Retype the password';

  @override
  String get forgotPasswordConfirmRequired => 'Confirm the password';

  @override
  String get forgotPasswordConfirmMismatch => 'Passwords don\'t match';

  @override
  String get forgotPasswordSaveAction => 'Save & sign in';

  @override
  String get verifyOtpAppBarTitle => 'VERIFY';

  @override
  String get verifyOtpTitle => 'Check\nyour email.';

  @override
  String get verifyOtpSubtitleLead => 'We sent a 6-digit code to\n';

  @override
  String get verifyOtpLabel => 'OTP CODE';

  @override
  String get verifyOtpVerify => 'Verify';

  @override
  String verifyOtpResendCooldown(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get verifyOtpResend => 'Resend code';

  @override
  String get verifyOtpResentSnack => 'A new code is on its way to your inbox';

  @override
  String get storageAppBarTitle => 'STORAGE';

  @override
  String get storageTitle => 'Offline storage.';

  @override
  String get storageEmptySubtitle => 'No videos or photos saved offline yet.';

  @override
  String storageUsage(int count, String size) {
    return '$count files · $size used';
  }

  @override
  String get storageDeleteOneTitle => 'Delete this file?';

  @override
  String get storageDeleteOnePhotoBody =>
      'The photo will be removed from your device. You can re-download from the note anytime.';

  @override
  String get storageDeleteOneVideoBody =>
      'The video will be removed from your device. You can re-download from the note anytime.';

  @override
  String get storageDeleteAllTitle => 'Delete all media?';

  @override
  String get storageDeleteAllBody =>
      'All offline videos and photos will be removed from your device. The notes stay safe and can be re-downloaded anytime.';

  @override
  String get storageConfirmCancel => 'Cancel';

  @override
  String get storageConfirmDelete => 'Delete';

  @override
  String get storageDeleteAllAction => 'Delete all';

  @override
  String get storageFileDeleted => 'File deleted';

  @override
  String storageFilesDeleted(int count) {
    return '$count files deleted';
  }

  @override
  String get storageRowUntitled => '(Untitled)';

  @override
  String get storageRowOrphan => 'Note deleted';

  @override
  String storageRowOrphanLabel(String ext) {
    return 'Orphan · $ext';
  }

  @override
  String get storageRowDeleteTooltip => 'Remove from device';

  @override
  String get storageDeleteAllButton => 'Delete all offline media';

  @override
  String get reindexAppBarTitle => 'AI & SEARCH';

  @override
  String get reindexTitle => 'AI index.';

  @override
  String get reindexSubtitle =>
      'Use this when the Assistant can\'t find old notes after you change the embedding model on the backend.';

  @override
  String get reindexStatusEyebrow => 'STATUS';

  @override
  String get reindexStatusLoading => 'Loading…';

  @override
  String reindexStatusReady(int total) {
    return '$total notes indexed, all set';
  }

  @override
  String reindexStatusMissing(int missing, int total) {
    return '$missing of $total notes need re-embed';
  }

  @override
  String get reindexRefreshTooltip => 'Refresh';

  @override
  String get reindexStep1Eyebrow => 'STEP 1';

  @override
  String get reindexStep1Title => 'Reset old embeddings';

  @override
  String get reindexStep1Description =>
      'Empties the embedding column on all your notes. Safe, doesn\'t delete the notes.';

  @override
  String get reindexStep1Action => 'Reset embeddings';

  @override
  String get reindexStep1Busy => 'Resetting…';

  @override
  String get reindexStep2Eyebrow => 'STEP 2';

  @override
  String get reindexStep2Title => 'Run re-embed';

  @override
  String get reindexStep2Description =>
      'Refills the embedding column on every empty note using the AI model that\'s currently active. Can take several minutes for large libraries.';

  @override
  String get reindexStep2Action => 'Run re-embed';

  @override
  String get reindexStep2Busy => 'Processing…';

  @override
  String get reindexResetDialogTitle => 'Reset all embeddings?';

  @override
  String get reindexResetDialogBody =>
      'All your notes will have their embedding column cleared. The AI assistant won\'t be able to find notes until the re-embed step completes.';

  @override
  String get reindexResetDialogConfirm => 'Reset';

  @override
  String get reindexConfirmCancel => 'Cancel';

  @override
  String get reindexNotLoggedIn => 'Not signed in';

  @override
  String get reindexResetDoneNudge =>
      'Embeddings reset. Tap \"Run re-embed\" now.';

  @override
  String reindexResetFailed(String error) {
    return 'Reset failed: $error';
  }

  @override
  String reindexRunFailed(String error) {
    return 'Re-embed failed: $error';
  }

  @override
  String get reindexRunDone => 'Re-embed completed.';

  @override
  String reindexRunDoneCount(Object count) {
    return '$count notes processed.';
  }

  @override
  String reindexRunSkipped(int count) {
    return '$count skipped: no title or text yet.';
  }

  @override
  String reindexRunErrors(int count) {
    return '$count failed, try running it again.';
  }

  @override
  String reindexStatusEmpty(int count) {
    return '$count notes with no title or text can\'t be indexed.';
  }

  @override
  String get privacyAppBarTitle => 'PRIVACY';

  @override
  String get privacyTitle => 'Privacy\n& data.';

  @override
  String get privacyIntro =>
      'Your notes belong to you. We store as little as possible and don\'t sell your data to third parties.';

  @override
  String get privacySectionGiven => 'WHAT YOU GIVE';

  @override
  String get privacyGiven1 =>
      'Email for sign-in and important emails (verification, password reset).';

  @override
  String get privacyGiven2 => 'Username shown on your dashboard.';

  @override
  String get privacyGiven3 =>
      'Notes: links, titles, manual content, and tags. All yours, accessible and deletable any time.';

  @override
  String get privacyGiven4 =>
      'Note embeddings, the numeric vectors the \"Assistant\" uses to find related notes.';

  @override
  String get privacySectionWhere => 'WHERE IT LIVES';

  @override
  String get privacyWhereBody =>
      'Postgres + pgvector on Supabase (Southeast Asia region). All connections over HTTPS. Every row is tagged with your user ID and protected by Row Level Security, so you only see your own notes. A copy of your notes is also kept on this phone (inside the app, shown only to your account) so they work offline; it goes when the app is uninstalled.';

  @override
  String get privacySectionDont => 'WHAT WE DON\'T DO';

  @override
  String get privacyDont1 => 'No ad tracking or third-party analytics.';

  @override
  String get privacyDont2 => 'No data selling.';

  @override
  String get privacyDont3 =>
      'No sending your notes to external services beyond AI features you trigger yourself (e.g. \"Ask the assistant\").';

  @override
  String get privacySectionRights => 'YOUR RIGHTS';

  @override
  String get privacyRights1 =>
      'Edit or delete notes any time from the Library.';

  @override
  String get privacyRights2 =>
      'Delete your account and all associated notes. The button is coming soon, for now reach out via the contact below.';

  @override
  String get privacyRights3 => 'Request a copy of your data by contacting us.';

  @override
  String get privacySectionContact => 'CONTACT';

  @override
  String get privacyContactBody =>
      'Questions, export requests, or data deletion: reach out to TemanLabs via the About IngatanKu page.';

  @override
  String get aboutAppBarTitle => 'ABOUT';

  @override
  String get aboutTitle => 'About\nIngatanKu.';

  @override
  String get aboutTagline => 'A little pet that grows with what you learn';

  @override
  String get aboutDescription =>
      'Save links and videos once. Your pet writes them up, eats them and grows, and the assistant already knows your whole collection.';

  @override
  String get aboutSectionMaker => 'MADE BY';

  @override
  String get aboutMakerName => 'TemanLabs';

  @override
  String get aboutMakerRole => 'Makers of IngatanKu';

  @override
  String get aboutMakerBody =>
      'Built wholeheartedly for curious people who want to turn daily scrolling into long-term memory.';

  @override
  String get aboutSectionVersion => 'VERSION';

  @override
  String get aboutVersionLabel => 'early release';

  @override
  String get aboutSectionThanks => 'THANKS';

  @override
  String get aboutThanksBody =>
      'To the open-source community and everyone who\'s been trying IngatanKu since day one.';

  @override
  String aboutCopyright(int year) {
    return '© $year TemanLabs';
  }

  @override
  String get weeklyQuizAppBarTitle => 'WEEKLY QUIZ';

  @override
  String get weeklyQuizPageTitle => 'Quiz this week.';

  @override
  String get weeklyQuizSubtitle =>
      'Five questions from notes you saved this week. Tap an option to answer.';

  @override
  String get weeklyQuizGenerateCta => 'Generate quiz';

  @override
  String get weeklyQuizRetryCta => 'Try again';

  @override
  String get weeklyQuizScoreLabel => 'Score';

  @override
  String get weeklyQuizCorrectLabel => 'Correct';

  @override
  String get weeklyQuizExplanationLabel => 'Why';

  @override
  String get weeklyQuizSourceLabel => 'Source note';

  @override
  String get weeklyQuizDoneTitle => 'Quiz complete.';

  @override
  String get weeklyQuizDoneSubtitle => 'Come back next week for a fresh set.';

  @override
  String get weeklyQuizNotEnoughNotes =>
      'Save at least 3 notes this week to unlock the quiz.';

  @override
  String get weeklyQuizGenerating =>
      'Building your quiz, this takes a few seconds.';

  @override
  String get weeklyQuizGenericError =>
      'Couldn\'t generate the quiz. Try again in a bit.';

  @override
  String weeklyQuizQuestionProgress(int current, int total) {
    return 'QUESTION $current / $total';
  }

  @override
  String get weeklyQuizReviewBadge => 'REVIEW';

  @override
  String get weeklyQuizCheckCta => 'CHECK';

  @override
  String get weeklyQuizNextCta => 'NEXT';

  @override
  String get weeklyQuizFinishCta => 'FINISH';

  @override
  String get weeklyQuizSubmitCta => 'SUBMIT QUIZ';

  @override
  String get weeklyQuizSubmittingCta => 'SUBMITTING…';

  @override
  String get weeklyQuizPrevCta => 'BACK';

  @override
  String get weeklyQuizCorrectBadge => 'CORRECT';

  @override
  String get weeklyQuizWrongBadge => 'WRONG';

  @override
  String get weeklyQuizScoreEyebrow => 'THIS WEEK\'S SCORE';

  @override
  String get weeklyQuizResultPerfect => 'Perfect! Your notes really stuck.';

  @override
  String get weeklyQuizResultGood => 'Nice, you absorbed most of it.';

  @override
  String get weeklyQuizResultRetry => 'Time to revisit the weaker notes.';

  @override
  String get weeklyQuizSummaryEyebrow => 'BREAKDOWN';

  @override
  String get weeklyQuizCloseCta => 'CLOSE';

  @override
  String get weeklyQuizReviewCta => 'REVIEW ANSWERS';

  @override
  String get weeklyQuizLoadingMessage =>
      'Generating a quiz from this week\'s notes…';

  @override
  String get weeklyQuizErrorRetryCta => 'TRY AGAIN';

  @override
  String get chatAppBarTitle => 'ASK YOUR ASSISTANT';

  @override
  String get chatPageTitle => 'Ask your\nassistant.';

  @override
  String get chatSubtitle =>
      'The AI searches across every note you\'ve saved and answers with direct references.';

  @override
  String get chatTrySection => 'TRY ASKING';

  @override
  String chatInputHint(String name) {
    return 'Ask $name about your notes…';
  }

  @override
  String chatTitle(String name) {
    return 'Ask $name';
  }

  @override
  String get chatResetTooltip => 'Start a new session';

  @override
  String get tagChipHint => 'Add a tag, press enter';

  @override
  String get tagChipSuggestionsLabel => 'SUGGESTED';

  @override
  String get timeAgoJustNow => 'just now';

  @override
  String timeAgoMinutes(int count) {
    return '${count}m';
  }

  @override
  String timeAgoHours(int count) {
    return '${count}h';
  }

  @override
  String timeAgoDays(int count) {
    return '${count}d';
  }

  @override
  String timeAgoWeeks(int count) {
    return '${count}w';
  }

  @override
  String get monthShortJan => 'Jan';

  @override
  String get monthShortFeb => 'Feb';

  @override
  String get monthShortMar => 'Mar';

  @override
  String get monthShortApr => 'Apr';

  @override
  String get monthShortMay => 'May';

  @override
  String get monthShortJun => 'Jun';

  @override
  String get monthShortJul => 'Jul';

  @override
  String get monthShortAug => 'Aug';

  @override
  String get monthShortSep => 'Sep';

  @override
  String get monthShortOct => 'Oct';

  @override
  String get monthShortNov => 'Nov';

  @override
  String get monthShortDec => 'Dec';

  @override
  String get dayShortSun => 'SUN';

  @override
  String get dayShortMon => 'MON';

  @override
  String get dayShortTue => 'TUE';

  @override
  String get dayShortWed => 'WED';

  @override
  String get dayShortThu => 'THU';

  @override
  String get dayShortFri => 'FRI';

  @override
  String get dayShortSat => 'SAT';

  @override
  String get monthShortUpperJan => 'JAN';

  @override
  String get monthShortUpperFeb => 'FEB';

  @override
  String get monthShortUpperMar => 'MAR';

  @override
  String get monthShortUpperApr => 'APR';

  @override
  String get monthShortUpperMay => 'MAY';

  @override
  String get monthShortUpperJun => 'JUN';

  @override
  String get monthShortUpperJul => 'JUL';

  @override
  String get monthShortUpperAug => 'AUG';

  @override
  String get monthShortUpperSep => 'SEP';

  @override
  String get monthShortUpperOct => 'OCT';

  @override
  String get monthShortUpperNov => 'NOV';

  @override
  String get monthShortUpperDec => 'DEC';

  @override
  String get tagsPageEyebrow => 'MANAGE TAGS';

  @override
  String get tagsPageTitle => 'Tags.';

  @override
  String tagsPageSummary(int tagCount, int noteCount) {
    return '$tagCount tags · $noteCount notes';
  }

  @override
  String tagsRowNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String get tagsEditTooltip => 'Rename tag';

  @override
  String get tagsDeleteTooltip => 'Delete tag';

  @override
  String get tagsRenameDialogTitle => 'Rename tag';

  @override
  String get tagsRenameDialogHint => 'New tag name';

  @override
  String get tagsRenameDialogCancel => 'Cancel';

  @override
  String get tagsRenameDialogConfirm => 'Save';

  @override
  String get tagsDeleteDialogTitle => 'Delete tag?';

  @override
  String get tagsDeleteDialogBody => 'The tag will be removed from every note.';

  @override
  String get tagsDeleteDialogCancel => 'Cancel';

  @override
  String get tagsDeleteDialogConfirm => 'Delete';

  @override
  String get tagDetailEyebrow => 'TAG';

  @override
  String tagDetailNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count related notes',
      one: '1 related note',
    );
    return '$_temp0';
  }

  @override
  String get tagDetailEmpty => 'No notes with this tag yet.';

  @override
  String get sourceLabelArticle => 'Article';

  @override
  String get quizSelfRatingPrompt => 'How well do you know this?';

  @override
  String get quizSelfRatingEasy => 'Easy';

  @override
  String get quizSelfRatingMedium => 'Just right';

  @override
  String get quizSelfRatingHard => 'Hard';

  @override
  String get quizResultHardCarryNone =>
      'Nice. No items to carry over next week.';

  @override
  String quizResultHardCarry(int count) {
    return '$count hard item(s) will return next week as a refresher.';
  }

  @override
  String get homeActionWardrobe => 'Wardrobe';

  @override
  String get petDefaultName => 'Bolubi';

  @override
  String petSemantics(String name) {
    return '$name, your pet. Stroke to pet; a tap is a smack.';
  }

  @override
  String get petMeterFullness => 'Full';

  @override
  String get petMeterHappiness => 'Happy';

  @override
  String get petMeterGrowth => 'Growth';

  @override
  String get petStageEgg => 'Egg';

  @override
  String get petStageBaby => 'Baby';

  @override
  String get petStageKid => 'Kid';

  @override
  String get petStageTeen => 'Teen';

  @override
  String get petStageAdult => 'Adult';

  @override
  String get petStageSage => 'Sage';

  @override
  String petGrowthNext(String stage) {
    return 'Growing into $stage';
  }

  @override
  String get petGrowthMax => 'Fully grown';

  @override
  String get petFoodBento => 'Bento';

  @override
  String get petFoodSandwich => 'Sandwich';

  @override
  String get petFoodOnigiri => 'Onigiri';

  @override
  String get petFoodDonut => 'Donut';

  @override
  String get petFoodCookie => 'Cookie';

  @override
  String get petFoodChips => 'Chips';

  @override
  String petWardrobeTitle(String name) {
    return '$name\'s wardrobe';
  }

  @override
  String get petNameLabel => 'NAME';

  @override
  String get petNamingTitle => 'Give it a name';

  @override
  String get petNamingBody =>
      'It\'s what its room is called and how it answers you. You can change it any time from its profile.';

  @override
  String get petNamingSave => 'Save name';

  @override
  String get petColorLabel => 'COLOR';

  @override
  String get petAccessoryLabel => 'ACCESSORY';

  @override
  String petLocked(String name, String stage) {
    return 'Unlocks when $name becomes a $stage.';
  }

  @override
  String get petStatAge => 'AGE';

  @override
  String get petStatCare => 'CARED FOR';

  @override
  String get petStatDigested => 'DIGESTED';

  @override
  String get petStatPets => 'PETS';

  @override
  String petStatDays(int days) {
    return '${days}d';
  }

  @override
  String petStatCareSemantics(int days) {
    return 'Fed $days days in a row';
  }

  @override
  String get petColorMatcha => 'Matcha';

  @override
  String get petColorPeach => 'Peach';

  @override
  String get petColorSky => 'Sky';

  @override
  String get petColorTaro => 'Taro';

  @override
  String get petColorHoney => 'Honey';

  @override
  String get petColorMocha => 'Mocha';

  @override
  String get petColorMochi => 'Mochi';

  @override
  String get petAccessoryNone => 'Plain';

  @override
  String get petAccessorySprout => 'Sprout';

  @override
  String get petAccessoryBow => 'Bow';

  @override
  String get petAccessoryGlasses => 'Glasses';

  @override
  String get petAccessoryScarf => 'Scarf';

  @override
  String get petAccessoryBeanie => 'Beanie';

  @override
  String get petAccessoryHeadphones => 'Headphones';

  @override
  String get petAccessoryCrown => 'Crown';

  @override
  String get petAccessoryChefHat => 'Chef hat';

  @override
  String get petAccessoryPartyHat => 'Party hat';

  @override
  String get petAccessoryCatEars => 'Cat ears';

  @override
  String get petAccessoryFlower => 'Flower';

  @override
  String get petAccessoryPeci => 'Peci';

  @override
  String get petAccessoryWitchHat => 'Witch hat';

  @override
  String get petAccessorySantaHat => 'Santa hat';

  @override
  String get petOutfitLabel => 'OUTFIT';

  @override
  String get petOutfitNone => 'No outfit';

  @override
  String get petOutfitHoodie => 'Hoodie';

  @override
  String get petOutfitStripedTee => 'Striped tee';

  @override
  String get petOutfitOveralls => 'Overalls';

  @override
  String get petOutfitSweater => 'Knit sweater';

  @override
  String get petOutfitBatik => 'Batik';

  @override
  String get petOutfitDino => 'Dino costume';

  @override
  String get petOutfitFrog => 'Frog costume';

  @override
  String get petOutfitBee => 'Bee costume';

  @override
  String get petOutfitAstronaut => 'Astronaut';

  @override
  String get petOutfitRaincoat => 'Raincoat';

  @override
  String get petOutfitKoko => 'Koko shirt';

  @override
  String get petOutfitPumpkin => 'Pumpkin costume';

  @override
  String get petOutfitGroupEveryday => 'Everyday';

  @override
  String get petOutfitGroupCostume => 'Costumes';

  @override
  String get petOutfitGroupSeasonal => 'Seasonal';

  @override
  String get petPremiumBadge => 'Premium';

  @override
  String get shopTitle => 'Boutique';

  @override
  String get shopTooltip => 'Boutique: accessories & outfits';

  @override
  String get shopTakeOff => 'Take it off';

  @override
  String get shopShelfAll => 'All';

  @override
  String get shopShelfHats => 'Accessories';

  @override
  String get shopPetLine1 => 'Which one shall I try?';

  @override
  String get shopPetLine2 => 'Tap something below and I\'ll try it on.';

  @override
  String get shopPetPetted => 'Hey, don\'t crease it!';

  @override
  String get shopPetReact1 => 'Does it suit me?';

  @override
  String get shopPetReact2 => 'Cute, right?';

  @override
  String get shopPetReact3 => 'I like this one!';

  @override
  String get shopPetMirror => 'Hmm, not bad…';

  @override
  String get shopBarSoon => 'For sale soon';

  @override
  String get shopOwned => 'Yours';

  @override
  String get shopWear => 'Wear it';

  @override
  String get shopWearing => 'Wearing it';

  @override
  String get wardrobeShopCta => 'Fancy something new? Visit the boutique';

  @override
  String get vaultRowDigested => 'Digested';

  @override
  String profileRoomTitle(String name) {
    return '$name\'s room';
  }

  @override
  String get homeTodayTitle => 'Saved today';

  @override
  String homeTodayRange(int from, int to, int total) {
    return '$from–$to of $total';
  }

  @override
  String get homeTodayOpenLibrary => 'Open Library';

  @override
  String get homeRest => 'Put to bed';

  @override
  String get homeWake => 'Wake up';

  @override
  String get homeQuickSaveHint => 'Paste a link here…';

  @override
  String get homeQuickSaveSend => 'Write it up';

  @override
  String get homeQuickSavePaste => 'Paste from clipboard';

  @override
  String get petStatusEgg =>
      'The egg feels warm… save your first link to hatch it.';

  @override
  String get petStatusReady => 'Keeping your notes safe';

  @override
  String get petStatusHappy => 'Full and happy';

  @override
  String get petStatusHungry => 'Hungry for something new to learn…';

  @override
  String get petStatusLonely => 'A little lonely — a pat, maybe?';

  @override
  String get petStatusResting => 'Napping on its cushion…';

  @override
  String get petStatusWoke => 'Oh — awake!';

  @override
  String get petStatusPetted => 'Loves the pats';

  @override
  String get petStatusPlayed => 'Wheee, again!';

  @override
  String get petStatusNewLink => 'Ooh, something new!';

  @override
  String get petStatusAte => 'Nom! A tasty little snack.';

  @override
  String petStatusAteMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nom! $count tasty snacks.',
      one: 'Nom! 1 tasty snack.',
    );
    return '$_temp0';
  }

  @override
  String get petStatusFull => 'Too full — saving it for later.';

  @override
  String petStatusHatched(String name) {
    return 'Hi! I\'m $name. Thanks for my first bite!';
  }

  @override
  String petStatusEvolved(String stage) {
    return 'I grew into a $stage!';
  }

  @override
  String get petStatusNotLink => 'Hmm, that\'s not a link.';

  @override
  String get petStatusClipboardEmpty => 'Your clipboard is empty.';

  @override
  String get petStatusSaveFailed => 'Couldn\'t save that. Try again?';

  @override
  String get petStatusNothingToday => 'Nothing saved today yet.';

  @override
  String get vaultAll => 'All';

  @override
  String get vaultGroupToday => 'Today';

  @override
  String get vaultGroupYesterday => 'Yesterday';

  @override
  String get vaultGroupWeek => 'This week';

  @override
  String get vaultGroupOlder => 'Older';

  @override
  String get vaultUntitled => '(Untitled)';

  @override
  String get vaultRowNotDigested => 'Not digested yet';

  @override
  String get homeTvCaption => 'saved today';

  @override
  String get notesPetEmpty =>
      'My notebook\'s empty. Let\'s write the first note!';

  @override
  String notesPetWriting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Writing away… $count notes so far.',
      one: 'Writing away… 1 note so far.',
    );
    return '$_temp0';
  }

  @override
  String get notesPetCopying => 'Psst, I\'m copying down your ideas.';

  @override
  String get notesPetPetted => 'Hehe, careful — I\'m writing!';

  @override
  String get libraryPetEmpty => 'My shelves are empty. Save your first link!';

  @override
  String libraryPetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count finds on my shelves.',
      one: '1 find on my shelves.',
    );
    return '$_temp0';
  }

  @override
  String libraryPetReading(String title) {
    return 'Reading “$title”…';
  }

  @override
  String get chatPetIdle =>
      'Ask me anything — I answer from the notes I\'ve eaten.';

  @override
  String get chatPetAnswering => 'Here\'s what I remember…';

  @override
  String get chatPetDone => 'Hope that helps! Anything else?';

  @override
  String get chatPetError => 'Oops, I lost my train of thought. Try again?';

  @override
  String get chatPetPetted => 'Hehe, I\'m listening.';

  @override
  String get petStatusLifted => 'Whoa! Put me down!';

  @override
  String get petStatusDizzy => 'Everything\'s spinning…';

  @override
  String get petStatusGrumpy => 'Hmph! Don\'t drop me like that!';

  @override
  String get petStatusPutDown => 'Hmph… gently next time.';

  @override
  String get libraryPetShush => 'Shh! It\'s a library — keep it down.';

  @override
  String get libraryPetAngry => 'Hey! I\'m trying to read here!';

  @override
  String get petStatusSharedLink =>
      'A link came in! Tap the check and I\'ll write it up.';

  @override
  String get petScribeStart => 'One sec, let me take notes…';

  @override
  String petScribeFound(String label) {
    return 'Found the $label — writing it up…';
  }

  @override
  String get petScribeDone => 'Ta-da! Here\'s my note.';

  @override
  String get petScribePartial =>
      'Couldn\'t read all of it, but here\'s my note.';

  @override
  String get petScribeOutOfQuota =>
      'I\'ve written all I can for today. Can you fill this one in?';

  @override
  String get petScribeCancelled => 'Okay, I\'ll leave the link here for now.';

  @override
  String scribeSheetEyebrow(String name) {
    return '$name\'s note';
  }

  @override
  String get scribeSheetTitle => 'Check it before I eat it';

  @override
  String get scribeSheetNoSummary =>
      'I couldn\'t summarise this one — add your own notes if you like.';

  @override
  String get scribeSheetOutOfQuota =>
      'That\'s all my write-ups for today — add your own notes, or share it again tomorrow.';

  @override
  String scribeSheetSave(String name) {
    return 'Save & feed $name';
  }

  @override
  String get petStatusQuizReady =>
      'I\'m hungry! Today\'s meal is waiting down here.';

  @override
  String get homeShelfSemantics => 'Bookshelf — open your collections';

  @override
  String get petIdleTv => 'Ooh, what\'s on TV?';

  @override
  String get petIdleShelf => 'Hmm, which book next…';

  @override
  String get petIdleYawn => 'Yaawn…';

  @override
  String get petIdleDance => 'A little dance!';

  @override
  String get petIdleSneeze => 'Achoo!';

  @override
  String get petIdleWave => 'Hi there!';

  @override
  String get petStatusHowTo =>
      'Stroke me for a pat, pick me up, or feed me a link!';

  @override
  String get petWardrobeHint => 'Colours and accessories to try on.';

  @override
  String get petVitalsLabel => 'HOW IT\'S DOING';

  @override
  String get petStatsLabel => 'ITS STORY';

  @override
  String get petStatusBonk => 'Ow! What was that for?';

  @override
  String get petStatusBonkAngry => 'Hey! Stop hitting me!';

  @override
  String get petStatusCry => 'Waaah… it hurts! Pet me better…';

  @override
  String get petStatusCrySoothe => 'Sniff… sniff…';

  @override
  String get petStatusComforted => 'Thank you… but please don\'t hit me again.';

  @override
  String get petIdleRoll => 'Wheee~ rolling!';

  @override
  String get petIdleRollBack => 'Hehe, I\'m back!';

  @override
  String get petStatusMosquito => 'Hey, a mosquito!';

  @override
  String get petStatusMosquitoChase => 'Come back here!';

  @override
  String get petStatusMosquitoCaught => 'Hap! Gotcha~';

  @override
  String get petStatusMosquitoAfter => 'Hmm… not very filling, though.';

  @override
  String homeBoardSemantics(int count) {
    return 'Pegboard: $count saved today. Tap to see them.';
  }

  @override
  String get homeTvChannel => 'TV — tap to change the channel';

  @override
  String homeHouseTitle(String name) {
    return '$name\'s place';
  }

  @override
  String get homeGreetNight => 'Good evening';

  @override
  String get homeGeckoChirp => 'tchk tchk tchk';

  @override
  String get petStatusGecko => 'Ooh, a gecko!';

  @override
  String homeClockSemantics(String time) {
    return 'Clock, $time';
  }

  @override
  String homePetInfo(String name) {
    return '$name — see its info';
  }

  @override
  String get homeInbox => 'News';

  @override
  String get homeInboxUnread => 'News — something new';

  @override
  String get petStatusFeedMe => 'Paste a link down here — I\'m hungry!';

  @override
  String inboxTitle(String name) {
    return 'News from $name';
  }

  @override
  String get inboxEmptyTitle => 'All quiet';

  @override
  String inboxEmptyBody(String name) {
    return '$name will let you know here.';
  }

  @override
  String get inboxNow => 'Now';

  @override
  String inboxMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String inboxHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String get inboxYesterday => 'Yesterday';

  @override
  String inboxDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String noticeHungryTitle(String name) {
    return '$name is hungry';
  }

  @override
  String get noticeHungryBody =>
      'Today\'s quiz is its meal — three quick questions.';

  @override
  String noticeLonelyTitle(String name) {
    return '$name feels a bit lonely';
  }

  @override
  String get noticeLonelyBody => 'Give it a little stroke.';

  @override
  String get noticeUnfedTitle => 'No meal yet today';

  @override
  String noticeUnfedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Keep your $count-day care streak going — finish today\'s quiz.',
      one: 'Keep your 1-day care streak going — finish today\'s quiz.',
    );
    return '$_temp0';
  }

  @override
  String get noticeQuizTitle => 'Today\'s meal is ready';

  @override
  String get noticeQuizBody => 'Three quick questions from your notes.';

  @override
  String noticeHatchedTitle(String name) {
    return '$name hatched!';
  }

  @override
  String get noticeHatchedBody => 'Say hi — then feed it your first finds.';

  @override
  String noticeEvolvedTitle(String name, String stage) {
    return '$name grew into $stage';
  }

  @override
  String get noticeEvolvedBody =>
      'New accessories may have opened up in the wardrobe.';

  @override
  String noticeStreakTitle(int count) {
    return '$count days of care!';
  }

  @override
  String noticeStreakBody(String name) {
    return '$name loves having you around.';
  }

  @override
  String get profileSoundEffects => 'Sound effects';

  @override
  String get profileRoomAmbience => 'Room ambience';

  @override
  String get profileBackgroundMusic => 'Background music';

  @override
  String get profileGroupSound => 'Sound';

  @override
  String get profileGroupYou => 'You';

  @override
  String get profileGroupNotes => 'Notes & library';

  @override
  String get profileGroupMore => 'More';

  @override
  String get profileSoundOn => 'On';

  @override
  String get profileSoundOff => 'Off';

  @override
  String get profileLanguageInUse => 'In use';

  @override
  String get profileLanguagePick => 'Choose';

  @override
  String get noteEditorNewTitle => 'New note';

  @override
  String get noteEditorEditTitle => 'Edit note';

  @override
  String get noteEditorAutoSave => 'Saved as you go';

  @override
  String get noteEditorSaving => 'Saving…';

  @override
  String get onboardSkip => 'Skip';

  @override
  String get onboardNext => 'Next';

  @override
  String get onboardStart => 'Let\'s go';

  @override
  String get onboardMeetTitle => 'Meet your\nlittle pet.';

  @override
  String get onboardMeetBody =>
      'It\'s still in its egg, and it only eats one thing: what you learn.';

  @override
  String get onboardFeedTitle => 'Feed it what\nyou find.';

  @override
  String get onboardFeedBody =>
      'Share a video or paste a link. Your pet writes down the title, summary and tags, then nibbles it as a snack.';

  @override
  String get onboardGrowTitle => 'Watch it\ngrow up.';

  @override
  String get onboardGrowBody =>
      'Every note helps it grow, from a tiny egg to a wise old sage. Keep it fed and happy!';

  @override
  String get onboardAskTitle => 'Ask, then\ntest yourself.';

  @override
  String get onboardAskBody =>
      'Its real meal is a 3-question quiz from your notes every day, so what you save actually sticks. You can ask the assistant anything, too.';

  @override
  String get onboardAskBubble => 'Ask me anything!';

  @override
  String get chatSourcesLabel => 'FROM YOUR NOTES';

  @override
  String get tagsEmptyEyebrow => 'NO TAGS YET';

  @override
  String get tagsEmptyTitle => 'No tags\nyet.';

  @override
  String get tagsEmptyBody =>
      'Tags show up here once you add them to your notes. Add them when you save or edit a note.';

  @override
  String get notesIdleSip => 'Tea break.';

  @override
  String get notesIdleThink => 'Hmm… how do I put this?';

  @override
  String get notesIdleIdea => 'Oh! Got it.';

  @override
  String get notesIdleBoard => 'Let me check the pinboard.';

  @override
  String get notesIdleDoze => 'Huh? I\'m awake, I\'m awake!';

  @override
  String get libraryIdleDoze => 'Zz… just resting my eyes.';

  @override
  String get libraryIdleGiggle => 'Hehe, this part\'s funny.';

  @override
  String get libraryIdleSneeze => 'Achoo! Dusty pages.';

  @override
  String get chatIdleSip => 'Mm, the tea\'s still warm.';

  @override
  String visitHello(String name) {
    return 'Hi, $name!';
  }

  @override
  String visitHelloBack(String name) {
    return 'Oh, $name! Hi there!';
  }

  @override
  String get visitAskFood => 'What did you eat today?';

  @override
  String get visitAskLearn => 'Learned anything new today?';

  @override
  String get visitAskRoom => 'Your room\'s so cozy!';

  @override
  String visitReplyAte(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasty notes!',
      one: 'One tasty note!',
    );
    return '$_temp0';
  }

  @override
  String get visitReplyHungry => 'Nothing yet… I\'m starving.';

  @override
  String get visitReplyRoom => 'Thanks! Come by anytime.';

  @override
  String get visitWow => 'Wow, I\'m jealous!';

  @override
  String get visitAww => 'Aww, hope you get fed soon.';

  @override
  String get visitBye => 'Gotta go. See you!';

  @override
  String get visitByeBack => 'Bye-bye!';

  @override
  String visitSemantics(String name) {
    return '$name, a friend dropping by';
  }

  @override
  String homeCalendarToday(String date) {
    return 'Today is $date.';
  }

  @override
  String get petStatusSnackEnough =>
      'That\'s enough snacks today — I\'m saving room for my quiz meal!';

  @override
  String petStatusMealLocked(int count) {
    return 'Save $count notes and I can have real meals — quizzes!';
  }

  @override
  String get homeMealReady => 'Today\'s meal';

  @override
  String get homeMealReadySub => '3 quick questions';

  @override
  String get homeFeastReady => 'Weekly feast';

  @override
  String get homeFeastReadySub => 'A longer quiz, big growth';

  @override
  String get homeMealDone => 'Fed for today';

  @override
  String get homeMealLocked => 'Meals open soon';

  @override
  String homeMealLockedSub(int count, int need) {
    return '$count/$need notes saved';
  }

  @override
  String get quizMealTitle => 'TODAY\'S MEAL';

  @override
  String get quizFeastTitle => 'WEEKLY FEAST';

  @override
  String get quizMealLoading => 'Preparing today\'s meal…';

  @override
  String quizGainFull(int count) {
    return '+$count full';
  }

  @override
  String quizGainGrowth(int count) {
    return '+$count growth';
  }

  @override
  String quizResultHardCarryDaily(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tricky questions will come back tomorrow.',
      one: '1 tricky question will come back tomorrow.',
    );
    return '$_temp0';
  }

  @override
  String get quizResultHardCarryNoneDaily =>
      'All clear — nothing tricky to bring back.';

  @override
  String get petStatusFullRefuse =>
      'Nope, I\'m full! A snack would be nice, though — save a new note.';

  @override
  String get petStatusFeastNudge =>
      'Want me to grow up fast? Do this week\'s feast quiz!';

  @override
  String petStatusFeastLocked(int count) {
    return 'Save $count notes this week, then we\'ll have a feast!';
  }

  @override
  String get quizPetStart => 'Mealtime! Let\'s go.';

  @override
  String get quizPetFeastStart => 'Feast time! I\'m starving.';

  @override
  String get quizPetLast => 'Last bite!';

  @override
  String get quizPetPicked => 'Ooh, that one?';

  @override
  String get quizPetHurry => 'Hurry up, I\'m hungry!';

  @override
  String get quizPetHurryAgain => 'My tummy\'s rumbling…';

  @override
  String get quizPetYum => 'Mmm, tasty!';

  @override
  String get quizPetYuck => 'Hmm… that tasted a bit off.';

  @override
  String get quizPetBurp => '*Burp!* Oops, excuse me.';

  @override
  String get quizPetFull => 'So full… thank you!';

  @override
  String get quizPetDoneGood => 'That was a good meal!';

  @override
  String get quizPetDoneMeh => 'Still a little hungry… let\'s study more!';

  @override
  String get libraryPetTease => 'Sure you can make me full today?';

  @override
  String get libraryPetTeaseFed => 'That\'s all? I want more tomorrow.';

  @override
  String offlineNeedInternet(String what) {
    return 'I need the internet to $what. Turn on Wi-Fi or mobile data first!';
  }

  @override
  String get offlineWhatAssistant => 'think up an answer';

  @override
  String get offlineWhatMealQuiz => 'cook up today\'s quiz';

  @override
  String get offlineWhatFeastQuiz => 'set up the weekly feast';

  @override
  String get offlineWhatSummary => 'read and summarize the link';

  @override
  String get offlineWhatPreview => 'peek at the link';

  @override
  String get offlineWhatVideo => 'play the video';

  @override
  String get offlineWhatDownload => 'download the video';

  @override
  String get offlineWhatReindex => 're-index your notes';

  @override
  String get offlineWhatAccount => 'update your account';

  @override
  String get offlineWhatSignUp => 'create your account';

  @override
  String get offlineWhatSignIn => 'sign you in';

  @override
  String get offlineSafeNote =>
      'Your notes are safe on this phone, and they sync by themselves once you\'re back online.';

  @override
  String get offlineBackOnline => 'Yay, we\'re back online!';

  @override
  String get offlineStill => 'Still offline… try again in a bit?';

  @override
  String get offlineOk => 'Okay';

  @override
  String get offlineRetry => 'Try again';

  @override
  String get offlineContinue => 'Continue';

  @override
  String get offlineTag => 'Offline';

  @override
  String get petStatusOfflineSaved =>
      'We\'re offline, so I can\'t summarize it yet. I saved the link for now!';

  @override
  String get petStatusWentOffline =>
      'We\'re offline. You can still save notes, I\'ll keep them safe!';

  @override
  String get petStatusBackOnline => 'Back online! Sending your notes up now.';

  @override
  String get petStatusCoinsFalling =>
      'Hey, my coins are falling out! Stop shaking me!';

  @override
  String get petStatusCoinsGather => 'My coins! My coins!';

  @override
  String petStatusCoinsCounted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coins, all here!',
      one: 'My one coin, safe and sound!',
    );
    return '$_temp0 Don\'t you steal my money!';
  }

  @override
  String get petStatusCoinsMine => 'Don\'t steal my money!';

  @override
  String get petStatusCoinsSavings => 'That\'s my savings! Hands off!';

  @override
  String noteDetailPageOf(int position, int count) {
    return 'Page $position of $count';
  }

  @override
  String get noteDetailPrevPage => 'Previous page';

  @override
  String get noteDetailNextPage => 'Next page';

  @override
  String get avatarPickerTitle => 'Pick your avatar';

  @override
  String get avatarPickerBody => 'A little animal to stand in for you.';

  @override
  String get avatarPickerUse => 'Use this avatar';

  @override
  String get accountCardEyebrow => 'Member card';

  @override
  String get accountChangeAvatar => 'Change avatar';

  @override
  String get avatarCat => 'Cat';

  @override
  String get avatarDog => 'Dog';

  @override
  String get avatarBear => 'Bear';

  @override
  String get avatarBunny => 'Bunny';

  @override
  String get avatarPanda => 'Panda';

  @override
  String get avatarFox => 'Fox';

  @override
  String get avatarFrog => 'Frog';

  @override
  String get avatarOwl => 'Owl';

  @override
  String get avatarKoala => 'Koala';

  @override
  String get avatarPig => 'Pig';

  @override
  String get avatarPenguin => 'Penguin';

  @override
  String get avatarLion => 'Lion';

  @override
  String get petIdleTour => 'A little tour of the room~';

  @override
  String get petIdleTourLook => 'Hmm, what\'s over here…';

  @override
  String get petIdleTourDone => 'Tour done! My place looks nice.';

  @override
  String get petIdleShelfAfter =>
      'Maybe later… I\'ll wait for you to read them, hehe~';

  @override
  String get petIdleTvAfter => 'Meh, nothing good on. TV\'s no fun anymore.';

  @override
  String get petIdleFull => 'Hehe, so full and happy~';

  @override
  String get petIdleHum => 'La la la~ ♪';

  @override
  String get coachNext => 'Next';

  @override
  String get coachSkip => 'Skip';

  @override
  String get coachDone => 'Got it';

  @override
  String quizCoachFeed(String name) {
    return 'From now on you can feed $name every day! Its meal is a 3-question quiz on your notes.';
  }

  @override
  String get quizCoachAnswer =>
      'Pick an answer, then tap Check. A right one is a tasty bite; a wrong one still gets eaten, but it tastes funny.';

  @override
  String quizCoachSteps(String name) {
    return 'Finish all three to fill $name up. There\'ll be new questions tomorrow.';
  }

  @override
  String get homeCoachEgg => 'Paste your first link here to hatch the egg.';

  @override
  String homeCoachSave(String name) {
    return 'Every link you save is a snack for $name. Paste one here any time.';
  }

  @override
  String homeCoachMeal(String name) {
    return 'This is $name\'s daily meal. Once you have 3 notes, tap it for the day\'s quiz.';
  }

  @override
  String homeCoachFeast(String name) {
    return 'The weekly feast: a longer quiz on the past week\'s notes. It makes $name grow fast.';
  }

  @override
  String homeCoachVitals(String name) {
    return 'How full, happy and grown $name is shows here. Tap its name for its profile.';
  }

  @override
  String get homeCoachShare =>
      'Even easier: in YouTube, TikTok or Instagram, tap Share and pick IngatanKu. No need to copy the link.';

  @override
  String get coachShareTap => 'Share';

  @override
  String get widgetEggTitle => 'The egg is waiting';

  @override
  String widgetEggBody(String name) {
    return 'Save your first link to hatch $name.';
  }

  @override
  String widgetLockedTitle(String name) {
    return '$name is snacking';
  }

  @override
  String get widgetLockedBody => 'Save 3 notes to open its daily quiz.';

  @override
  String widgetReadyTitle(String name) {
    return '$name is hungry!';
  }

  @override
  String get widgetReadyBody => 'Today\'s quiz is ready. Just 3 questions.';

  @override
  String widgetLateTitle(String name) {
    return '$name is still waiting…';
  }

  @override
  String get widgetLateBody => 'Nothing to eat all day. There\'s still time!';

  @override
  String widgetFullTitle(String name) {
    return '$name is full';
  }

  @override
  String get widgetFullBody => 'Today\'s meal is done. See you tomorrow!';

  @override
  String get widgetFeed => 'Feed it';

  @override
  String get widgetSave => 'Save a link';

  @override
  String widgetStreak(int days) {
    return '$days-day streak';
  }

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get authGoogleFailed => 'Couldn\'t sign in with Google. Try again?';

  @override
  String get accountFieldSignIn => 'Signs in with';

  @override
  String get accountFieldSignInGoogleCaption =>
      'Your Google account keeps this account safe.';

  @override
  String get quizMealScoreEyebrow => 'TODAY\'S SCORE';
}
