# Версия для ПК — Windows x64

Игра запускается локально на Windows x64. Интернет для партии не нужен. Готовый архив содержит `chess_2.exe`, DLL и каталог `data`: сохраняйте их вместе.

## Скачать из GitHub Actions

1. Откройте репозиторий на GitHub → **Actions** → **Windows release ZIP**.
2. Выберите успешный запуск после отправки в `main`. Для новой сборки нажмите **Run workflow** → **Run workflow**.
3. Внизу страницы запуска, в **Artifacts**, скачайте **Chess-2-Windows-x64**. Для скачивания артефактов требуется вход в GitHub; архив хранится 14 дней.
4. Распакуйте скачанный архив. Внутри находится `Chess-2-Windows-x64.zip` — распакуйте и его в отдельную папку.
5. Откройте папку с распакованной игрой и запустите `chess_2.exe`. Отдельно переносить только EXE нельзя: приложению нужны соседние DLL и `data`.

Если Windows сообщает об отсутствии `VCRUNTIME140.dll` или `MSVCP140.dll`, установите официальный [Microsoft Visual C++ Redistributable x64](https://aka.ms/vs/17/release/vc_redist.x64.exe).

Workflow собирает приложение на `windows-latest` с Flutter stable, форматирует код, запускает анализ и тесты, затем сохраняет полный комплект приложения в ZIP. Сборка становится доступна после успешного завершения workflow. Этот workflow не создаёт публичный GitHub Release и не публикует приложение в магазине.

## Собрать на своём компьютере

Нужны Windows x64, Git, [Flutter stable](https://docs.flutter.dev/get-started/install/windows/desktop) не ниже 3.29 и Visual Studio с компонентом **Desktop development with C++** и Windows SDK. Убедитесь, что `flutter` и `dart` доступны в `PATH` и `flutter doctor -v` видит Windows toolchain.

В PowerShell из каталога проекта выполните:

```powershell
flutter doctor -v
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\build_windows.ps1
```

`-ExecutionPolicy Bypass` действует только для этого процесса PowerShell. Сам скрипт можно запускать из любого каталога, указав полный путь к нему.

Скрипт подготавливает стандартные runner-файлы установленного Flutter через `tool/bootstrap_platforms.dart`, получает зависимости, форматирует код, запускает анализ и тесты, собирает Windows release для x64. При ошибке он завершается с ненулевым кодом. Подготовка runner-файлов обновляет платформенные каталоги — после сборки изменения можно проверить через `git diff`.

Результаты:

- `dist/Chess-2-Windows-x64.zip` — готовый архив для переноса;
- `build/windows/x64/runner/Release/` — полная папка приложения для непосредственного запуска.

Распакуйте ZIP полностью и запустите `chess_2.exe`. Для игры из готовой сборки Flutter и Visual Studio не нужны.

Нативная Windows-сборка выполняется только на Windows. Создание этих файлов в Linux не подтверждает получение рабочего EXE: результат проверяется Windows toolchain и успешным запуском workflow или локального скрипта на Windows.
