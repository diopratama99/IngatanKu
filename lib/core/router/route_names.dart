class Routes {
  Routes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';

  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String vault = '/vault';
  static const String addNote = '/vault/new';
  static const String editNote = '/vault/edit';
  static const String noteDetail = '/vault/:id';
  static const String tags = '/tags';
  static const String tagDetail = '/tags/detail';

  static const String chat = '/chat';
  static const String weeklyQuiz = '/quiz/weekly';
  static const String dailyQuiz = '/quiz/daily';
  static const String shop = '/shop';
  static const String profile = '/profile';
  static const String accountSettings = '/profile/account';
  static const String privacy = '/profile/privacy';
  static const String about = '/profile/about';
  static const String storage = '/profile/storage';
  static const String reindex = '/profile/reindex';

  // Personal notes (Catatan)
  static const String notes = '/notes';
  static const String notesNew = '/notes/new';
  static const String notesEdit = '/notes/edit';

  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';

}
