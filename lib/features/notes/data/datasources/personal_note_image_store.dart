import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Local filesystem manager for personal-note images.
///
/// Layout:
///   <getApplicationDocumentsDirectory>/personal_note_images/<noteId>/
///     <imageId>.<ext>
///
/// Why local-only: notes are personal scratch space; the user already
/// stated they're OK losing images on uninstall in exchange for a
/// simpler stack (no Supabase Storage, no upload UX, no cleanup
/// tombstones).
class PersonalNoteImageStore {
  PersonalNoteImageStore();

  static const _folderName = 'personal_note_images';
  static const _uuid = Uuid();

  Future<Directory> _noteDir(String noteId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_folderName/$noteId');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies [sourcePath] into the note's local folder under a fresh
  /// uuid name and returns the basename. The original is left in
  /// place (image_picker hands us a temp file we don't own).
  Future<String> attach({
    required String noteId,
    required String sourcePath,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Image attach not supported on web');
    }
    final src = File(sourcePath);
    if (!src.existsSync()) {
      throw FileSystemException('Source image missing', sourcePath);
    }
    final ext = _extensionOf(sourcePath);
    final basename = '${_uuid.v4()}.$ext';
    final dir = await _noteDir(noteId);
    final dest = File('${dir.path}/$basename');
    await src.copy(dest.path);
    return basename;
  }

  /// Removes one image from the note's folder. No-op if the file is
  /// already gone.
  Future<void> detach({
    required String noteId,
    required String filename,
  }) async {
    if (kIsWeb) return;
    try {
      final dir = await _noteDir(noteId);
      final f = File('${dir.path}/$filename');
      if (f.existsSync()) await f.delete();
    } catch (e) {
      debugPrint('[notes-images] detach failed: $e');
    }
  }

  /// Removes every image attached to a note + the note's folder. Used
  /// when the note itself is deleted.
  Future<void> deleteAll(String noteId) async {
    if (kIsWeb) return;
    try {
      final dir = await _noteDir(noteId);
      if (dir.existsSync()) await dir.delete(recursive: true);
    } catch (e) {
      debugPrint('[notes-images] deleteAll failed: $e');
    }
  }

  /// Absolute path for an image basename. Used by `Image.file`.
  Future<String> pathFor({
    required String noteId,
    required String filename,
  }) async {
    final dir = await _noteDir(noteId);
    return '${dir.path}/$filename';
  }

  /// Returns the file handle directly. Convenience for callers that
  /// need stat + read (e.g. resizing).
  Future<File> fileFor({
    required String noteId,
    required String filename,
  }) async {
    final p = await pathFor(noteId: noteId, filename: filename);
    return File(p);
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot <= 0 || dot == path.length - 1) return 'jpg';
    final ext = path.substring(dot + 1).toLowerCase();
    // Sanitize — keep only known image extensions, default to jpg
    // otherwise so filesystem behaves predictably.
    const allowed = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'};
    return allowed.contains(ext) ? ext : 'jpg';
  }
}
