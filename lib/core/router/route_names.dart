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

  static const String chat = '/chat';
  static const String badges = '/badges';
  static const String profile = '/profile';

  static const String verifyOtp = '/verify-otp';

  static const String shared = '/share/:token';
  static String sharedFor(String token) => '/share/$token';
}
