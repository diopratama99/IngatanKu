import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../config/env.dart';
import '../constants/app_constants.dart';
import '../network/supabase_client.dart';

/// Result of a `resolve-media` call — what Cobalt (or the OG-image fallback)
/// gave us back.
class MediaResolution {
  /// `video` or `photo` — used to pick the right icon/label in the UI.
  final String kind;

  /// Direct, downloadable URL. May expire — call [resolve] just before
  /// downloading.
  final String downloadUrl;

  /// Best-effort filename suggested by Cobalt; may be null.
  final String? filename;

  /// File extension without the leading dot: `mp4`, `jpg`, etc.
  final String ext;

  const MediaResolution({
    required this.kind,
    required this.downloadUrl,
    required this.filename,
    required this.ext,
  });

  factory MediaResolution.fromJson(Map<String, dynamic> json) {
    return MediaResolution(
      kind: json['kind'] as String? ?? 'video',
      downloadUrl: json['downloadUrl'] as String,
      filename: json['filename'] as String?,
      ext: (json['ext'] as String?) ?? 'mp4',
    );
  }

  bool get isPhoto => kind == 'photo';
  bool get isVideo => kind == 'video';
}

/// Single source of truth for media downloads. Handles resolving the source
/// URL via the `resolve-media` Edge Function, streaming the file via Dio,
/// and bookkeeping the on-device path.
///
/// File layout: `<getApplicationDocumentsDirectory>/ingatanku_media/<noteId>.<ext>`
///
/// The service is platform-agnostic: works on Android/iOS/macOS/Linux/Windows.
/// Web is unsupported (no filesystem) — callers should guard with
/// `kIsWeb` before using.
class MediaDownloadService {
  final SupabaseService service;
  final Dio _dio;

  MediaDownloadService(this.service, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              // Cobalt's tunnel URLs can take ~15s for large videos to start
              // streaming, so we bump the connect timeout but keep receive
              // timeout long enough for full downloads.
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 5),
              followRedirects: true,
              maxRedirects: 5,
            ));

  /// Folder name under the app's documents directory. Kept as a static
  /// const so we can `pumpEventQueue` it from tests without instantiating
  /// the service.
  static const String _folderName = 'ingatanku_media';

  /// Returns the on-disk media folder, creating it on first use.
  Future<Directory> _mediaDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_folderName');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Look for any previously-downloaded file for [noteId]. We match by
  /// basename so the extension can be anything (`.mp4`, `.jpg`, …).
  Future<File?> existingFile(String noteId) async {
    if (kIsWeb) return null;
    try {
      final dir = await _mediaDir();
      final entries = dir.listSync().whereType<File>();
      for (final f in entries) {
        final name = f.path.split('/').last;
        final dot = name.lastIndexOf('.');
        final base = dot > 0 ? name.substring(0, dot) : name;
        if (base == noteId) return f;
      }
      return null;
    } catch (e) {
      debugPrint('[media] existingFile error: $e');
      return null;
    }
  }

  /// Calls `resolve-media` and returns the parsed result. Throws if the
  /// server returns an error status — callers should wrap in try/catch.
  Future<MediaResolution> resolve(String sourceUrl) async {
    final token = await service.ensureFreshAccessToken();
    if (token == null) {
      throw const MediaDownloadException('Belum login');
    }

    final res = await _dio.post<Map<String, dynamic>>(
      '${Env.supabaseUrl}/functions/v1/${AppConstants.fnResolveMedia}',
      data: {'url': sourceUrl},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'apikey': Env.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        // Don't throw on 4xx — we want to surface the server's error
        // message verbatim instead of a generic DioException.
        validateStatus: (_) => true,
      ),
    );

    final body = res.data ?? const {};
    if (res.statusCode != 200) {
      final msg = body['error'] as String? ?? 'HTTP ${res.statusCode}';
      throw MediaDownloadException(msg);
    }
    return MediaResolution.fromJson(body);
  }

  /// Streams the resolved media to disk. Calls [onProgress] with a
  /// 0.0–1.0 value as bytes arrive (skipped when `Content-Length` is
  /// missing, which can happen with Cobalt tunnels).
  Future<File> download({
    required String noteId,
    required MediaResolution resolution,
    ValueChanged<double>? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (kIsWeb) {
      throw const MediaDownloadException('Download tidak didukung di web');
    }
    final dir = await _mediaDir();
    final target = File('${dir.path}/$noteId.${resolution.ext}');

    await _dio.download(
      resolution.downloadUrl,
      target.path,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
      options: Options(
        // Some Cobalt tunnels need a browser UA to avoid 403.
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/124 Safari/537.36',
        },
        responseType: ResponseType.stream,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
      ),
    );
    return target;
  }

  /// Removes a previously-downloaded file. No-op if it doesn't exist.
  Future<void> delete(String noteId) async {
    final f = await existingFile(noteId);
    if (f != null && f.existsSync()) {
      await f.delete();
    }
  }

  /// Returns every file currently in the media folder. Used by the
  /// Storage page to surface a per-file list. Files are returned with
  /// their fresh on-disk sizes; basename (minus extension) is the
  /// owning `noteId`.
  Future<List<DownloadedMedia>> listAll() async {
    if (kIsWeb) return const [];
    try {
      final dir = await _mediaDir();
      if (!dir.existsSync()) return const [];
      final entries = dir.listSync().whereType<File>();
      final out = <DownloadedMedia>[];
      for (final f in entries) {
        try {
          final stat = await f.stat();
          final name = f.path.split('/').last;
          final dot = name.lastIndexOf('.');
          final base = dot > 0 ? name.substring(0, dot) : name;
          final ext = dot > 0 ? name.substring(dot + 1) : '';
          out.add(DownloadedMedia(
            noteId: base,
            file: f,
            ext: ext,
            sizeBytes: stat.size,
            modified: stat.modified,
          ));
        } catch (_) {/* ignore individual file stat failures */}
      }
      // Newest first — matches the "recent downloads" mental model.
      out.sort((a, b) => b.modified.compareTo(a.modified));
      return out;
    } catch (e) {
      debugPrint('[media] listAll error: $e');
      return const [];
    }
  }

  /// Total bytes occupied by every downloaded artifact. Cheap enough
  /// to call on every page render — sums [File.lengthSync] over the
  /// dir, no recursion.
  Future<int> totalSize() async {
    final all = await listAll();
    return all.fold<int>(0, (sum, m) => sum + m.sizeBytes);
  }

  /// Wipe the entire media folder. Used by the "Hapus semua" CTA on
  /// the Storage page. Returns the number of files deleted so the UI
  /// can show a friendly confirmation.
  Future<int> deleteAll() async {
    if (kIsWeb) return 0;
    try {
      final dir = await _mediaDir();
      if (!dir.existsSync()) return 0;
      final files = dir.listSync().whereType<File>().toList();
      var n = 0;
      for (final f in files) {
        try {
          await f.delete();
          n++;
        } catch (_) {/* skip locked files */}
      }
      return n;
    } catch (e) {
      debugPrint('[media] deleteAll error: $e');
      return 0;
    }
  }
}

/// One downloaded artifact, surfaced on the Storage management page.
class DownloadedMedia {
  /// Owning note id — used to look up title/source for display.
  final String noteId;

  /// Full file handle.
  final File file;

  /// Extension without leading dot (`mp4`, `jpg`, …).
  final String ext;

  /// Size in bytes at probe time.
  final int sizeBytes;

  /// Last-modified timestamp (download time, give or take).
  final DateTime modified;

  const DownloadedMedia({
    required this.noteId,
    required this.file,
    required this.ext,
    required this.sizeBytes,
    required this.modified,
  });

  bool get isImage {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
      case 'heic':
        return true;
      default:
        return false;
    }
  }
}

/// Domain-level exception so the UI doesn't have to import dio.
class MediaDownloadException implements Exception {
  final String message;
  const MediaDownloadException(this.message);

  @override
  String toString() => message;
}
