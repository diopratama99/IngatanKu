class AppConstants {
  AppConstants._();

  static const String appName = 'IngatanKu';
  static const String appTagline = 'Otak Kedua Tech-mu';

  // Tables
  static const String tProfiles = 'profiles';
  static const String tContentVault = 'content_vault';
  static const String tBadges = 'badges';
  static const String tUserBadges = 'user_badges';
  static const String tChatMessages = 'chat_messages';

  // RPC
  static const String rpcMatchNotes = 'match_notes';

  // Edge Functions
  static const String fnAskBrain = 'ask-brain';
  static const String fnEmbedNote = 'embed-note';

  // XP
  static const int xpPerNote = 10;
  static const int xpPerLevel = 100;

  // Suggested tech tags
  static const List<String> suggestedTags = [
    'flutter', 'dart', 'react', 'nextjs', 'typescript', 'python',
    'devops', 'docker', 'kubernetes', 'aws', 'supabase', 'postgres',
    'rust', 'golang', 'ai', 'ml', 'llm', 'rag', 'debugging', 'security',
  ];
}
