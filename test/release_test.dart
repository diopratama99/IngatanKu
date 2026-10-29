// The release rule ("Versions and the changelog" in README.md): the version
// in pubspec.yaml always has its own dated section in both changelogs
// (English and Indonesian), under the one for what's not out yet.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final version = RegExp(r'^version:\s*(\S+)', multiLine: true)
      .firstMatch(pubspec)!
      .group(1)!;
  final name = version.split('+').first;
  final build = version.contains('+') ? version.split('+').last : '';

  test('the version is MAJOR.MINOR.PATCH[-pre]+BUILD', () {
    expect(name, matches(RegExp(r'^\d+\.\d+\.\d+(-[0-9A-Za-z.]+)?$')));
    expect(int.tryParse(build), isNotNull,
        reason: 'pubspec.yaml needs a build number: $name+1, +2, …');
    expect(int.parse(build), greaterThan(0));
  });

  for (final file in ['CHANGELOG.md', 'CHANGELOG.id.md']) {
    final changelog = File(file).readAsStringSync();

    test('the version has a dated section in $file', () {
      final heading = RegExp(
        '^## \\[${RegExp.escape(name)}\\] - \\d{4}-\\d{2}-\\d{2}\$',
        multiLine: true,
      );
      expect(changelog, matches(heading),
          reason: 'Add "## [$name] - YYYY-MM-DD" to $file');
    });

    test('changes not out yet have their place at the top of $file', () {
      final unreleased = changelog.indexOf('## [Unreleased]');
      expect(unreleased, isNot(-1));
      expect(unreleased, lessThan(changelog.indexOf('## [$name]')));
    });
  }
}
