import 'dart:io';

/// Generates canonical platform runners with the installed Flutter SDK while
/// keeping lib/, test/, pubspec.yaml, README and all other game sources intact.
Future<void> main() async {
  final root = Directory.current;
  if (!File('${root.path}/pubspec.yaml').existsSync() ||
      !File('${root.path}/lib/game/chess.dart').existsSync()) {
    stderr.writeln('Запустите команду из корня проекта chess_2.');
    exitCode = 1;
    return;
  }
  final staging = Directory.systemTemp.createTempSync('chess_2_platforms_');
  try {
    final process = await Process.start(
      'flutter',
      [
        'create',
        '--no-pub',
        '--platforms=android,ios,windows,web',
        '--project-name=chess_2',
        '--org=com.chess20',
        staging.path,
      ],
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows,
    );
    final status = await process.exitCode;
    if (status != 0) {
      stderr.writeln('Flutter не создал платформенные файлы (код $status).');
      exitCode = status;
      return;
    }
    for (final platform in ['android', 'ios', 'windows', 'web']) {
      final source = Directory('${staging.path}/$platform');
      if (!source.existsSync()) {
        throw FileSystemException('Flutter не создал $platform', source.path);
      }
      _copyDirectory(source, Directory('${root.path}/$platform'));
    }
    final metadata = File('${staging.path}/.metadata');
    if (metadata.existsSync()) metadata.copySync('${root.path}/.metadata');
    if (!Platform.isWindows) {
      final chmod = await Process.run(
        'chmod',
        ['+x', '${root.path}/android/gradlew'],
      );
      if (chmod.exitCode != 0) {
        stderr.writeln('Не удалось установить права android/gradlew.');
        stderr.writeln('Выполните: chmod +x android/gradlew');
      }
    }
    final manifest = File('${root.path}/android/app/src/main/AndroidManifest.xml');
    if (manifest.existsSync()) {
      manifest.writeAsStringSync(manifest.readAsStringSync().replaceFirst(
            'android:label="chess_2"',
            'android:label="Шахматы 2.0"',
          ));
    }
    stdout.writeln('Платформы созданы. Исходники игры сохранены.');
    stdout.writeln('Далее: flutter pub get, flutter test, flutter run.');
  } on ProcessException catch (error) {
    stderr.writeln('Не удалось запустить Flutter: ${error.message}');
    stderr.writeln('Установите Flutter stable и добавьте flutter/bin в PATH.');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Ошибка платформенных файлов: ${error.message}');
    exitCode = 1;
  } finally {
    if (staging.existsSync()) staging.deleteSync(recursive: true);
  }
}

void _copyDirectory(Directory source, Directory destination) {
  destination.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final name = entity.uri.pathSegments.where((part) => part.isNotEmpty).last;
    final target = '${destination.path}/$name';
    if (entity is Directory) {
      _copyDirectory(entity, Directory(target));
    } else if (entity is File) {
      entity.copySync(target);
    }
  }
}
