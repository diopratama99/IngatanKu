import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/weekly_quiz.dart';

class QuizRemoteDataSource {
  final SupabaseService service;
  QuizRemoteDataSource(this.service);

  /// Calls the `generate-weekly-quiz` Edge Function. Returns the existing
  /// quiz or a freshly-generated one — both come back with the same shape.
  Future<WeeklyQuiz> getOrGenerate() async {
    final session = service.auth.currentSession;
    if (session == null) {
      throw ServerException('Belum login');
    }

    final uri = Uri.parse(
      '${Env.supabaseUrl}/functions/v1/${AppConstants.fnGenerateWeeklyQuiz}',
    );
    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'apikey': Env.supabaseAnonKey,
            'Content-Type': 'application/json',
          },
          body: '{}',
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
    return WeeklyQuiz.fromJson(json);
  }

  /// Persists answers + score and triggers the XP/badge RPC. Returns the
  /// awarded XP value (5 per correct + 10 perfect-score bonus).
  Future<int> submit({
    required String quizId,
    required List<QuizAnswer> answers,
    required int score,
  }) async {
    final supabase = service.client;

    // 5 XP per correct + 10 perfect-score bonus, capped at 50.
    final earnedXp = score * 5 + (score == answers.length ? 10 : 0);

    // 1) Update the quiz row. RLS allows the owner to update.
    await supabase
        .from('weekly_quizzes')
        .update({
          'user_answers': answers.map((a) => a.toJson()).toList(),
          'score': score,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', quizId);

    // 2) Award XP + WEEKLY_REVIEWER badge atomically via RPC.
    await supabase.rpc(
      AppConstants.rpcAwardQuizCompletion,
      params: {'quiz_id': quizId, 'earned_xp': earnedXp},
    );

    return earnedXp;
  }
}
