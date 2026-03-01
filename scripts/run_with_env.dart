// Run Flutter with --dart-define from a local .env file.
// Usage: dart run scripts/run_with_env.dart [flutter args...]
// Example: dart run scripts/run_with_env.dart run
//          dart run scripts/run_with_env.dart build apk
//
// .env is read from the project root and never bundled into the app.

import 'dart:io';

void main(List<String> args) async {
  final projectRoot = _findProjectRoot();
  final envFile = File(projectRoot.path + '/.env');
  final exampleFile = File(projectRoot.path + '/env.example');

  // If .env missing, copy from env.example so no manual step is needed
  if (!envFile.existsSync() && exampleFile.existsSync()) {
    await envFile.writeAsString(await exampleFile.readAsString());
    print('Created .env from env.example');
  }

  final dartDefines = <String>[];
  if (envFile.existsSync()) {
    for (final line in envFile.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final idx = trimmed.indexOf('=');
      if (idx <= 0) continue;
      final key = trimmed.substring(0, idx).trim();
      var value = trimmed.substring(idx + 1).trim();
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      } else if (value.startsWith("'") && value.endsWith("'")) {
        value = value.substring(1, value.length - 1);
      }
      if (key == 'USE_FIREBASE' ||
          key.startsWith('FIREBASE_') ||
          key.startsWith('USE_')) {
        dartDefines.add('--dart-define=$key=$value');
      }
    }
  }

  if (dartDefines.isEmpty) {
    print('No .env found and env.example missing or has no Firebase keys.');
    exit(1);
  }

  // Subcommand must come first (e.g. "run" or "build apk"), then --dart-define
  final subcommand = args.isEmpty ? ['run'] : args;
  final flutterArgs = [...subcommand, ...dartDefines];

  print('Running: flutter ${flutterArgs.join(' ')}');
  final process = await Process.start(
    'flutter',
    flutterArgs,
    mode: ProcessStartMode.inheritStdio,
    workingDirectory: projectRoot.path,
    runInShell: true, // so Windows finds flutter in PATH
  );
  exit(await process.exitCode);
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (dir.path != dir.parent.path) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  return Directory.current;
}
