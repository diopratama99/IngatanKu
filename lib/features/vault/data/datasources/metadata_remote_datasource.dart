import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/supabase_client.dart';
import '../models/url_metadata.dart';

abstract class MetadataRemoteDataSource {
  Future<UrlMetadata> fetch(String url);
}

class MetadataRemoteDataSourceImpl implements MetadataRemoteDataSource {
  final SupabaseService service;
  MetadataRemoteDataSourceImpl(this.service);

  @override
  Future<UrlMetadata> fetch(String url) async {
    final session = service.auth.currentSession;
    if (session == null) throw ServerException('Not authenticated');

    final uri = Uri.parse('${Env.supabaseUrl}/functions/v1/fetch-meta');
    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'apikey': Env.supabaseAnonKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'url': url}),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw ServerException('fetch-meta failed: ${res.statusCode}');
    }
    return UrlMetadata.fromJson(jsonDecode(res.body));
  }
}
