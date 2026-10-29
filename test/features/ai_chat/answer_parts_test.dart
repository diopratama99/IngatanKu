import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/features/ai_chat/domain/answer_parts.dart';
import 'package:ingatanku/features/ai_chat/domain/entities/message_entity.dart';

void main() {
  AnswerParts parts(String content, {bool streaming = false}) =>
      AnswerParts.of(MessageEntity(
        id: 'a',
        role: MessageRole.assistant,
        content: content,
        streaming: streaming,
        createdAt: DateTime(2026, 10, 21),
      ));

  test('the opening reaction is the pet\'s to say', () {
    final p = parts('Wah, yang ini aku ingat banget! 😋 Kamu pernah nyimpen '
        '**ayam bawang mentega** [1]:\n- Marinasi 15 menit');
    expect(p.opener, 'Wah, yang ini aku ingat banget! 😋');
    expect(p.rest, startsWith('Kamu pernah nyimpen **ayam'));
    expect(p.pending, isFalse);
  });

  test('a whole short answer is all said, nothing left for the card', () {
    final p = parts('Hmm, aku belum pernah makan catatan soal itu nih. '
        'Simpan dulu ya 🙂');
    expect(p.opener, 'Hmm, aku belum pernah makan catatan soal itu nih.');
    expect(p.rest, 'Simpan dulu ya 🙂');
  });

  test('a line that leads into a list is said, the list stays', () {
    final p = parts('Ini nih caranya:\n- Install di semua komputer');
    expect(p.opener, 'Ini nih caranya:');
    expect(p.rest, '- Install di semua komputer');
  });

  test('content first (a list, a cited fact, a long sentence): all in the card',
      () {
    expect(parts('- Install dulu\n- Lalu atur').opener, isNull);
    expect(parts('Poin utamanya pakai **MAS** [1]. Lalu…').opener, isNull);
    final long = 'Kata ' * 40;
    expect(parts('$long. Selesai.').opener, isNull);
    expect(parts('$long. Selesai.').rest, '$long. Selesai.');
  });

  test('while it comes in, the first sentence waits to be whole', () {
    final early = parts('Wah, yang ini aku', streaming: true);
    expect(early.pending, isTrue);
    expect(early.opener, isNull);
    final done = parts('Wah, yang ini aku ingat! Kamu', streaming: true);
    expect(done.pending, isFalse);
    expect(done.opener, 'Wah, yang ini aku ingat!');
    expect(parts('', streaming: true).pending, isTrue);
  });

  test('markdown in the opener is said as plain words', () {
    expect(parts('Nah, **ini dia**! Resepnya:').opener, 'Nah, ini dia!');
  });

  test('real replies from the assistant', () {
    final empty =
        parts('Hmm, perutku lagi kosong nih, belum pernah makan resep '
            'apa-apa dari kamu 😋\n\nCoba deh kamu simpan catatan resep baru!');
    expect(empty.opener,
        'Hmm, perutku lagi kosong nih, belum pernah makan resep apa-apa dari kamu 😋');
    expect(empty.rest, 'Coba deh kamu simpan catatan resep baru!');

    final found =
        parts('Wah, yang ini gampang banget buat aku! 🖥️ Intinya tuh '
            'gini [1]:\n- Pakai **Input Leap**');
    expect(found.opener, 'Wah, yang ini gampang banget buat aku! 🖥️');
    expect(found.rest, startsWith('Intinya tuh gini [1]:'));
  });
}
