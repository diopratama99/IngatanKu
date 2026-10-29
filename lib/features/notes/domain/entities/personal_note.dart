import 'package:equatable/equatable.dart';

/// A single inline link attached to a personal note. Distinct from the
/// `content_vault.url` field because here links are secondary
/// references the user picks to enrich the note, not the main subject.
class NoteLink extends Equatable {
  final String url;

  /// Display label. Falls back to the bare URL when empty.
  final String label;

  const NoteLink({required this.url, required this.label});

  factory NoteLink.fromJson(Map<String, dynamic> json) => NoteLink(
        url: json['url'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'url': url, 'label': label};

  String get effectiveLabel => label.isEmpty ? url : label;

  @override
  List<Object?> get props => [url, label];
}

/// Background tint for a note card. Mirrors Google Keep's palette so
/// the colour picker reads naturally to anyone who's used Keep.
enum NoteColor {
  defaultColor('default'),
  red('red'),
  orange('orange'),
  yellow('yellow'),
  green('green'),
  teal('teal'),
  blue('blue'),
  purple('purple'),
  pink('pink'),
  brown('brown'),
  gray('gray');

  final String wireValue;
  const NoteColor(this.wireValue);

  static NoteColor parse(String? raw) {
    for (final c in NoteColor.values) {
      if (c.wireValue == raw) return c;
    }
    return NoteColor.defaultColor;
  }
}

/// Free-form personal note. Body is plain text (multiline); we don't
/// render markdown here — Google Keep deliberately doesn't support
/// markdown and that keeps the experience friction-free.
class PersonalNote extends Equatable {
  final String id;
  final String userId;
  final String? title;
  final String body;

  /// Image filenames stored under
  /// `<docs>/personal_note_images/<noteId>/<filename>`. The DB only
  /// records basenames so filesystem layout can change without a
  /// migration.
  final List<String> imageFiles;

  final List<NoteLink> links;
  final List<String> tags;
  final bool pinned;
  final NoteColor color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PersonalNote({
    required this.id,
    required this.userId,
    this.title,
    required this.body,
    this.imageFiles = const [],
    this.links = const [],
    this.tags = const [],
    this.pinned = false,
    this.color = NoteColor.defaultColor,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEmpty =>
      (title == null || title!.trim().isEmpty) &&
      body.trim().isEmpty &&
      imageFiles.isEmpty &&
      links.isEmpty;

  PersonalNote copyWith({
    String? title,
    String? body,
    List<String>? imageFiles,
    List<NoteLink>? links,
    List<String>? tags,
    bool? pinned,
    NoteColor? color,
    DateTime? updatedAt,
  }) {
    return PersonalNote(
      id: id,
      userId: userId,
      title: title ?? this.title,
      body: body ?? this.body,
      imageFiles: imageFiles ?? this.imageFiles,
      links: links ?? this.links,
      tags: tags ?? this.tags,
      pinned: pinned ?? this.pinned,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        imageFiles,
        links,
        tags,
        pinned,
        color,
        createdAt,
        updatedAt,
      ];
}
