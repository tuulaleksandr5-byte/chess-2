# Шахматы 2.0

Локальная игра на Flutter для Android, iOS, Windows и web: квадратное поле **10×10**, **18 типов фигур** и по **20 фигур** у каждой стороны. Моря и недоступных клеток нет. Фигуры начинают в двух прямых рядах. Интерфейс, справочник и история ходов — на русском языке.

Можно играть белыми против чёрного бота или вдвоём на одном устройстве. Есть три уровня сложности, подсветка допустимых ходов и шаха, отмена, переворот доски, новая партия и выбор превращения пешки. Изображения фигур рисуются векторно, рядом показаны буквенные коды.

Полные правила, начальная расстановка и таблица всех фигур: [docs/RULES.md](docs/RULES.md). Интерфейс движка: [docs/API.md](docs/API.md). Фактически выполненные проверки и ограничения среды: [docs/VALIDATION.md](docs/VALIDATION.md).

Исходники опубликованы: **[tuulaleksandr5-byte/chess-2](https://github.com/tuulaleksandr5-byte/chess-2)**.

**[Скачать готовую игру для Windows x64](https://github.com/tuulaleksandr5-byte/chess-2/actions/runs/41523086668/artifacts/13178477187)** — артефакт **Chess-2-Windows-x64** из успешной сборки. Для скачивания нужен вход в GitHub; этот артефакт хранится до **16 ноября 2026**. Распакуйте скачанный архив, затем находящийся внутри `Chess-2-Windows-x64.zip` целиком и запустите `chess_2.exe`. Соседние DLL и каталог `data` должны оставаться рядом с EXE. Flutter и Visual Studio для запуска готовой игры не нужны. Новые сборки доступны в [Actions → Windows release ZIP](https://github.com/tuulaleksandr5-byte/chess-2/actions/workflows/windows-release.yml).

## Требования

- **Flutter stable** не ниже **3.29** (Dart **3.7+**); рекомендуется текущий stable. Dart SDK поставляется вместе с Flutter. Установите Flutter по [официальной инструкции](https://docs.flutter.dev/get-started/install), добавьте `flutter/bin` в `PATH`.
- Git; для команд публикации исходников ниже — также [GitHub CLI](https://cli.github.com/) и собственная учётная запись GitHub.
- Для Android: Android Studio, Android SDK, совместимый JDK и эмулятор либо устройство с USB debugging. `flutter doctor` подскажет недостающие компоненты.
- Для iOS: **macOS**, Xcode с выбранными command line tools и iOS Simulator. Для установки на физическое устройство и подписанного архива нужны настроенная подпись и учётная запись Apple Developer.
- Для Windows: **Windows** и Visual Studio с компонентом **Desktop development with C++**; Visual Studio Code не заменяет этот набор сборки.
- Для web: Chrome либо любой современный браузер для готовой сборки.

Android и web можно собирать на поддерживаемых Flutter ОС. iOS собирается на macOS, Windows — на Windows. Наличие исходников платформы само по себе не подтверждает успешную нативную сборку.

Проверенные CI-сборки выполнены с **Flutter 3.47.9 / Dart 3.13.7**.

## Первый запуск

Откройте терминал в каталоге проекта:

```sh
flutter --version
flutter doctor -v
dart tool/bootstrap_platforms.dart
flutter pub get
flutter devices
```

**Перед первым запуском из исходников выполните `dart tool/bootstrap_platforms.dart`.** Скрипт создаёт штатные runner-файлы текущего Flutter во временном проекте и копирует в игру только платформенные каталоги. Он сохраняет `lib/`, тесты и `pubspec.yaml`. Запускайте его непосредственно командой `dart`, как показано выше: это позволяет подготовить платформы, включая Gradle wrapper JAR, до разрешения зависимостей. Этот же bootstrap используется в прошедших CI-сборках.

Для ручного восстановления платформ из корня проекта доступен штатный генератор Flutter:

```sh
flutter create --platforms=android,ios,windows,web --org=com.chess20 --project-name=chess_2 .
flutter pub get
```

Предпочтителен скрипт bootstrap, который переносит только платформенные файлы. После ручной генерации или обновления Flutter проверьте изменения через `git diff`.

### Android

```sh
flutter doctor --android-licenses
flutter emulators
flutter devices
flutter run -d emulator-5554
flutter build apk --debug
```

В `flutter run` замените `emulator-5554` на идентификатор своего запущенного устройства из `flutter devices`. Debug APK находится в `build/app/outputs/flutter-apk/app-debug.apk`.

Для выпуска после настройки собственной подписи Android:

```sh
flutter build apk --release
flutter build appbundle --release
```

Настройка ключей и публикация в магазине выполняются владельцем приложения. Не добавляйте ключи, пароли и `android/key.properties` в Git.

### iOS — терминал macOS

```sh
open -a Simulator
flutter devices
flutter run -d DEVICE_ID
flutter build ios --simulator --debug
```

Замените `DEVICE_ID` на идентификатор iOS Simulator. Для подписанного архива откройте `ios/Runner.xcworkspace` в Xcode, выберите свою Team и уникальный Bundle Identifier, затем выполните:

```sh
flutter build ipa --release
```

### Windows — PowerShell на Windows

Сборка полного архива для ПК одной командой:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\build_windows.ps1
```

Результат после успешной сборки: `dist/Chess-2-Windows-x64.zip`. Распакуйте его полностью и запустите `chess_2.exe`. В GitHub Actions предусмотрен отдельный workflow **Windows release ZIP**. Подробности: [docs/WINDOWS.md](docs/WINDOWS.md).

Для запуска и сборки вручную:

```powershell
flutter config --enable-windows-desktop
flutter doctor -v
flutter run -d windows
flutter build windows --release
```

Готовая папка приложения находится в `build/windows/x64/runner/Release/`. Для переноса нужны все файлы этой папки.

### Web

```sh
flutter config --enable-web
flutter run -d chrome
flutter build web --release
```

Содержимое `build/web/` можно раздавать обычным HTTP-сервером. Для локальной проверки при установленном Python:

```sh
python3 -m http.server 8080 --directory build/web
```

Откройте `http://localhost:8080`. На Windows команда Python может называться `python`. Для размещения в подкаталоге укажите подходящий `--base-href` при сборке.

## Управление

Нажмите на фигуру своей стороны, затем на одну из подсвеченных клеток. Пешка на последней горизонтали открывает выбор из 16 типов. Король остаётся на доске: партия заканчивается матом, а не его взятием.

В режиме бота человек играет белыми. Отмена возвращает ход человека и ответ бота; ответ от предыдущей позиции игнорируется. Уже запущенный поиск самостоятельно завершится по своему лимиту. В режиме игры вдвоём отменяется один полуход. Переключение режима позволяет продолжить текущую партию с ботом или вторым игроком. Кнопка новой партии восстанавливает начальную расстановку. Переворот меняет только вид доски. Справочник объясняет движение всех 18 типов, история показывает сделанные ходы.

Бот использует материал, положение фигур, подвижность, сортировку взятий и alpha-beta с последовательным увеличением глубины. Лимиты уровней: примерно 160, 700 и 1900 мс и дополнительное ограничение числа узлов. Итерация может закончиться раньше лимита. На нативных платформах поиск запускается через `compute` в отдельном isolate; в web стандартный Flutter `compute` исполняется в основном потоке, поэтому во время поиска возможна короткая пауза интерфейса. Это локальный бот, сеть для партии не требуется.

## Проверки и CI

```sh
dart format lib test tool
flutter analyze
flutter test
flutter build web --release
```

Тесты проверяют правила движения, безопасность короля, особые ходы, окончания партии, допустимость ответов бота, приоритет мата и основные сценарии интерфейса. Для кода `90e07e53383c14a2db833481240e9d86f221a126` успешно завершились [полный CI](https://github.com/tuulaleksandr5-byte/chess-2/actions/runs/41523086949) — анализ, **65 тестов**, web release, Android debug APK, iOS Simulator и Windows release — и [отдельная сборка Windows ZIP](https://github.com/tuulaleksandr5-byte/chess-2/actions/runs/41523086668). В браузере проверены ход `h2–h4`, история и смена стороны, а также мобильная ширина 375 px без горизонтального переполнения. Ручной запуск Windows GUI не выполнялся в Linux; подписанный iOS-релиз не заявляется.

Workflow [.github/workflows/ci.yml](.github/workflows/ci.yml) сначала подготавливает платформы через bootstrap, затем запускает форматирование, анализ, тесты и web-сборку на Flutter stable. Отдельные jobs собирают Android debug APK, iOS Simulator и Windows release на соответствующих ОС и сохраняют результаты как artifacts. Workflow ничего не публикует в магазинах или на хостинге.

## Структура проекта

```text
lib/
  main.dart             # точка входа и ChessApp
  game/
    chess.dart          # неизменяемая позиция, правила и результаты
    bot.dart            # чистый Dart-поиск и computeBotMove
  ui/                   # доска, элементы управления и справочник
test/
  chess_test.dart        # проверки движка
  bot_test.dart          # проверки бота
  widget_test.dart       # сценарии интерфейса
tool/
  bootstrap_platforms.dart # канонические платформенные runner-файлы
  build_windows.ps1       # проверка, Windows release и полный ZIP
docs/
  RULES.md               # полные правила варианта
  API.md                 # контракт движка, бота и UI
  VALIDATION.md          # фактическая проверка и ограничения среды
  superpowers/           # спецификация и план реализации
android/                 # runner Android
ios/                     # runner iOS
windows/                 # runner Windows
web/                     # web runner
.github/workflows/ci.yml
pubspec.yaml
```

## Сохранение в Git и свой GitHub-репозиторий

Следующие команды приведены для ручного выполнения владельцем. Требуются установленный Git, настроенные `user.name`/`user.email`, а для GitHub — установленный `gh` с доступом к вашему аккаунту. Выполняйте `git init` только при первом создании репозитория:

```sh
git init -b main
git add .
git commit -m "Initial Chess 2.0 Flutter app"
```

При желании авторизуйте GitHub CLI и создайте собственный приватный репозиторий, заменив `YOUR_REPOSITORY_NAME` выбранным именем:

```sh
gh auth login
gh auth status
gh repo create YOUR_REPOSITORY_NAME --private --source=. --remote=origin --push
```

Для публичного репозитория используйте `--public` вместо `--private`. Если `origin` уже существует, проверьте его через `git remote -v` и отправляйте изменения в правильный репозиторий командой `git push -u origin main`.

Репозиторий [tuulaleksandr5-byte/chess-2](https://github.com/tuulaleksandr5-byte/chess-2) уже создан, исходники отправлены в `main`. Команды выше нужны для создания собственной копии в другом репозитории. CI сохраняет сборки как artifacts; публикация в магазинах и на web-хостинге не настроена.
