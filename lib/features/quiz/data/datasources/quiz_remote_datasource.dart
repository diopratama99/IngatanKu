import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../domain/entities/weekly_quiz.dart';

class QuizRemoteDataSource {
  final SupabaseService service;
  QuizRemoteDataSource(this.service);

  /// Calls `daily-quiz` or `generate-weekly-quiz`. Returns the existing
  /// quiz or a freshly-generated one — both come back with the same shape.
  Future<WeeklyQuiz> getOrGenerate(QuizKind kind) async {
    final token = await service.ensureFreshAccessToken();
    if (token == null) {
      throw ServerException('Belum login');
    }

    final fn = kind == QuizKind.daily
        ? AppConstants.fnDailyQuiz
        : AppConstants.fnGenerateWeeklyQuiz;
    final uri = Uri.parse('${Env.supabaseUrl}/functions/v1/$fn');
    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'apikey': Env.supabaseAnonKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'locale': _locale(),
            // "Today" is the user's day, not the server's.
            'date': localDay(DateTime.now()),
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (res.statusCode != 200) {
      String message = 'HTTP ${res.statusCode}';
      try {
        final json = jsonDecode(res.body);
        if (json is Map && json['error'] is String) {
          message = json['error'] as String;
        }
      } catch (_) {/* keep default */}
      throw ServerException(message);
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return WeeklyQuiz.fromJson({
      ...json,
      'kind': kind == QuizKind.daily ? 'daily' : 'weekly',
    });
  }

  /// The app's language, for the questions it writes.
  static String _locale() {
    try {
      return AppSettingsService.instance.resolvedLocale.languageCode;
    } catch (_) {
      return 'id';
    }
  }

  /// [d] as the user's local YYYY-MM-DD.
  static String localDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Persists answers + score (what the pet gets out of it is the app's).
  Future<void> submit({
    required WeeklyQuiz quiz,
    required List<QuizAnswer> answers,
    required int score,
  }) async {
    final db = service.db;
    final daily = quiz.kind == QuizKind.daily;

    // RLS allows the owner to update.
    await db
        .from(daily ? 'daily_quizzes' : 'weekly_quizzes')
        .update({
          'user_answers': answers.map((a) => a.toJson()).toList(),
          'score': score,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', quiz.id);
  }

  /// Fire-and-forget call ke `record-quiz-answer`. Throw kalau HTTP
  /// non-200; caller (repo) yang handle ke Failure.
  Future<void> recordAnswer({
    required String questionHash,
    required String questionText,
    String? sourceNoteId,
    required bool correct,
    int? timeToAnswerMs,
    QuizSelfRating? selfRating,
  }) async {
    final token = await service.ensureFreshAccessToken();
    if (token == null) {
      throw ServerException('Belum login');
    }

    final uri = Uri.parse(
      '${Env.supabaseUrl}/functions/v1/${AppConstants.fnRecordQuizAnswer}',
    );
    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'apikey': Env.supabaseAnonKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'date': localDay(DateTime.now()),
            'questionHash': questionHash,
            'questionText': questionText,
            if (sourceNoteId != null) 'sourceNoteId': sourceNoteId,
            'answeredCorrectly': correct,
            if (timeToAnswerMs != null) 'timeToAnswerMs': timeToAnswerMs,
            if (selfRating != null) 'selfRating': selfRating.value,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      String message = 'HTTP ${res.statusCode}';
      try {
        final json = jsonDecode(res.body);
        if (json is Map && json['error'] is String) {
          message = json['error'] as String;
        }
      } catch (_) {/* keep default */}
      throw ServerException(message);
    }
  }
}
