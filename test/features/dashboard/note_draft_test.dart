import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/features/dashboard/domain/note_draft.dart';

void main() {
  group('splitMarkdownTitle', () {
    test('takes the leading H1 off the body', () {
      final (title, body) =
          splitMarkdownTitle('\n# Dasar Flutter AI\n\n- satu\n- dua\n');
      expect(title, 'Dasar Flutter AI');
      expect(body, '- satu\n- dua');
    });

    test('leaves text without an H1 alone', () {
      final (title, body) = splitMarkdownTitle('## Bukan judul\nisi');
      expect(title, isNull);
      expect(body, '## Bukan judul\nisi');
    });
  });

  group('suggestTags', () {
    test('hashtags from the source come first, then known and common', () {
      final tags = suggestTags(
        '5 AI tools I use with Flutter. Pakai supabase juga.',
        hashtagSource: '5 AI tools I use with Flutter #ai #FlutterDev',
        known: const ['supabase', 'laravel'],
        common: const ['flutter', 'react', 'ai'],
      );
      expect(tags, ['ai', 'flutterdev', 'supabase', 'flutter']);
    });

    test('the summary\'s own picks come after hashtags, even unmentioned', () {
      final tags = suggestTags(
        'Video viral Khaby Lame dengan jutaan likes.',
        hashtagSource: 'Khaby Lame #fyp',
        picked: const ['komedi', 'Viral', 'fyp'],
        known: const ['viral', 'lucu'],
        common: const ['film'],
      );
      expect(tags, ['fyp', 'komedi', 'viral']);
    });

    test('matches whole words only and stops at max', () {
      final tags = suggestTags(
        'reactive streams, not react; dart and rust and go',
        common: const ['react', 'dart', 'rust', 'ai'],
        max: 2,
      );
      expect(tags, ['react', 'dart']);
    });
  });
}
