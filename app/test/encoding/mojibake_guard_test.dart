import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('source text does not contain known mojibake fragments', () {
    final findings = <String>[];

    for (final file in _sourceFiles()) {
      final text = file.readAsStringSync();
      for (final fragment in _mojibakeFragments) {
        if (!text.contains(fragment)) {
          continue;
        }

        final lineNumber = _lineNumberFor(text, fragment);
        findings.add('${file.path}:$lineNumber contains "$fragment"');
      }
    }

    expect(findings, isEmpty, reason: findings.join('\n'));
  });
}

const _mojibakeFragments = <String>[
  '宸插垹闄',
  '瀹跺涵',
  '鍔犺浇',
  '淇℃伅',
  '澶辫触',
  '绋嶅悗',
  '閲嶈瘯',
  '鎴愰暱',
  '娲诲姏',
  '绋冲畾',
  '杩涢樁',
  '闂',
  '婊＄骇',
  '浼欎即',
  '鐨?',
  '灏忕尗',
  '灏忕嫍',
  '浠撻紶',
  '涔岄緹',
  '灏忛笩',
  '灏忛奔',
  '鐔婄尗',
  '鐖哥埜',
  '灏忔槑',
  '鍥㈠洟',
  '馃',
];

Iterable<File> _sourceFiles() sync* {
  final roots = <Directory>[
    Directory('lib'),
    Directory('test'),
    Directory('../backend/app'),
  ];

  for (final root in roots) {
    if (!root.existsSync()) {
      continue;
    }

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      if (entity.path.endsWith('mojibake_guard_test.dart')) {
        continue;
      }
      if (!_isTextSourceFile(entity.path)) {
        continue;
      }

      yield entity;
    }
  }
}

bool _isTextSourceFile(String path) {
  const extensions = <String>{
    '.dart',
    '.py',
    '.md',
    '.yaml',
    '.yml',
    '.json',
    '.toml',
    '.txt',
  };

  return extensions.any(path.endsWith);
}

int _lineNumberFor(String text, String fragment) {
  final index = text.indexOf(fragment);
  if (index < 0) {
    return 0;
  }

  return '\n'.allMatches(text.substring(0, index)).length + 1;
}
