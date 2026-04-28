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
  static const String knowledgeMap = '/tags/map';
  static const String notesStats = '/notes/stats';

  static const String chat = '/chat';
  static const String badges = '/badges';
  static const String badgesStats = '/badges/stats';
  static const String profile = '/profile';
  static const String privacy = '/profile/privacy';
  static const String about = '/profile/about';

  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';

  static const String shared = '/share/:token';
  static String sharedFor(String token) => '/share/$token';
}
