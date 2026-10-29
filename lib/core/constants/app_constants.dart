class AppConstants {
  AppConstants._();

  static const String appName = 'IngatanKu';

  // Tables
  static const String tContentVault = 'content_vault';
  static const String tPersonalNotes = 'personal_notes';
  static const String tPets = 'pets';
  static const String tPetItems = 'pet_items';

  // Edge Functions
  static const String fnAskBrain = 'ask-brain';
  static const String fnEmbedNote = 'embed-note';
  static const String fnAutoSummarize = 'auto-summarize';
  static const String fnResolveMedia = 'resolve-media';
  static const String fnGenerateWeeklyQuiz = 'generate-weekly-quiz';
  static const String fnDailyQuiz = 'daily-quiz';
  static const String fnReembedMissing = 'reembed-missing';
  static const String fnRecordQuizAnswer = 'record-quiz-answer';

  /// Everyday topics to suggest as tags for a new note — offered only
  /// when the word actually turns up in what was saved, so both the
  /// Indonesian and the English words are here.
  static const List<String> suggestedTags = [
    // Food & home
    'resep', 'recipe', 'masak', 'cooking', 'kuliner', 'food',
    'tanaman', 'plants', 'diy',
    // Health & body
    'kesehatan', 'health', 'olahraga', 'fitness', 'diet', 'skincare',
    'mental', 'tidur', 'sleep',
    // Money & work
    'keuangan', 'finance', 'investasi', 'investing', 'bisnis', 'business',
    'karier', 'career', 'produktivitas', 'productivity',
    // Learning
    'belajar', 'learning', 'bahasa', 'language', 'sejarah', 'history',
    'sains', 'science', 'teknologi', 'tech',
    // Leisure
    'travel', 'liburan', 'buku', 'books', 'film', 'movies', 'musik',
    'music', 'fotografi', 'photography', 'desain', 'design', 'fashion',
    // Family
    'parenting', 'anak', 'kids', 'hewan', 'pets',
  ];
}
