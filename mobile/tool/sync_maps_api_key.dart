// ignore_for_file: avoid_print

import 'dart:io';

/// Writes ios/Flutter/Maps.local.xcconfig from the same sources as Android
/// (android/local.properties MAPS_API_KEY or masterfabric-go/.env).
void main() {
  final mobileDir = _mobileDir();
  final key = _readKey(mobileDir);
  if (key.isEmpty) {
    stderr.writeln(
      'No Maps API key found. Set MAPS_API_KEY in android/local.properties '
      'or GOOGLE_MAPS_API_KEY in masterfabric-go/.env',
    );
    exit(1);
  }

  final out = File('${mobileDir.path}/ios/Flutter/Maps.local.xcconfig');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync('MAPS_API_KEY=$key\n');
  print('Wrote ${out.path}');
}

Directory _mobileDir() {
  var dir = Directory.current;
  if (dir.path.endsWith('tool')) {
    dir = dir.parent;
  }
  if (!File('${dir.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Run from mobile/ or mobile/tool/');
    exit(1);
  }
  return dir;
}

String _readKey(Directory mobileDir) {
  final localProps = File('${mobileDir.path}/android/local.properties');
  if (localProps.existsSync()) {
    for (final line in localProps.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.startsWith('MAPS_API_KEY=')) {
        final v = trimmed.substring('MAPS_API_KEY='.length).trim();
        if (v.isNotEmpty) return v;
      }
    }
  }

  final envFile = File('${mobileDir.path}/../masterfabric-go/.env');
  if (envFile.existsSync()) {
    for (final line in envFile.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.startsWith('GOOGLE_MAPS_API_KEY=')) {
        final v = trimmed.substring('GOOGLE_MAPS_API_KEY='.length).trim();
        if (v.isNotEmpty) return v;
      }
    }
  }
  return '';
}
