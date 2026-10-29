import 'package:dartz/dartz.dart';

import '../../../../core/database/local_first.dart';
import '../../../../core/error/failures.dart';
import '../entities/personal_note.dart';

/// CRUD contract for the Catatan feature, for the signed-in user. Kept on
/// the device: reads and writes are instant and work offline, and [sync]
/// exchanges them with the account.
abstract class PersonalNoteRepository implements Syncable {
  /// Pinned first, then the most recently changed.
  Future<Either<Failure, List<PersonalNote>>> list({int? limit});

  Future<Either<Failure, PersonalNote>> getById(String id);

  /// Creates the note row and returns the persisted entity. The image
  /// files referenced in `imageFiles` must already exist on disk —
  /// callers move/copy them via [PersonalNoteRepository.attachImage]
  /// before calling create / update.
  Future<Either<Failure, PersonalNote>> create(PersonalNote draft);

  Future<Either<Failure, PersonalNote>> update(PersonalNote note);

  Future<Either<Failure, void>> delete(String id);

  /// Copies a picked image file into the note's local directory and
  /// returns the basename to store in `imageFiles`. The original is
  /// left untouched (image_picker returns a temp file we don't own).
  Future<Either<Failure, String>> attachImage({
    required String noteId,
    required String sourcePath,
  });

  /// Removes the image file from disk. Caller is responsible for also
  /// updating the note's `imageFiles` array.
  Future<Either<Failure, void>> detachImage({
    required String noteId,
    required String filename,
  });

  /// Resolves an image filename to its absolute on-disk path, creating
  /// the parent dir if needed. Used by detail/list views to render
  /// `Image.file(...)`.
  Future<String> imagePath({
    required String noteId,
    required String filename,
  });
}
