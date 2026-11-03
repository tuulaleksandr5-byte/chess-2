# Проверка реализации

Проверенный код: `90e07e53383c14a2db833481240e9d86f221a126`, репозиторий [tuulaleksandr5-byte/chess-2](https://github.com/tuulaleksandr5-byte/chess-2), ветка `main`. CI использовал Flutter **3.47.9** и Dart **3.13.7**.

## Сборки и автоматические проверки

[Полный CI №41523086949](https://github.com/tuulaleksandr5-byte/chess-2/actions/runs/41523086949) завершился успешно во всех заданиях:

| Задание | Подтверждённый результат |
| --- | --- |
| [Linux](https://github.com/tuulaleksandr5-byte/chess-2/actions/runs/41523086949/job/125544288211) | `flutter analyze`, 65 тестов и web release |
| [Android](https://github.com/tuulaleksandr5-byte/chess-2/actions/runs/41523086949/job/125544994631) | debug APK |
| [iOS](https://github.com/tuulaleksandr5-byte/chess-2/actions/runs/41523086949/job/125544994679) | сборка для iOS Simulator |
| [Windows](https://github.com/tuulaleksandr5-byte/chess-2/actions/runs/41523086949/job/125544994686) | Windows x64 release |

[Windows release ZIP №41523086668](https://github.com/tuulaleksandr5-byte/chess-2/actions/runs/41523086668/job/125543782283) также завершился успешно: анализ, тесты, Windows release и упаковка полного приложения. [Артефакт Chess-2-Windows-x64](https://github.com/tuulaleksandr5-byte/chess-2/actions/runs/41523086668/artifacts/13178477187), ID `13178477187`, размер внешнего архива **11 405 205 байт**, хранится до **16 ноября 2026**. Для скачивания нужен вход в GitHub.

Скачанные внешний и внутренний ZIP прошли проверку CRC. Внутренний `Chess-2-Windows-x64.zip` имеет размер **11 405 045 байт**, содержит 11 файлов, включая `chess_2.exe`, `flutter_windows.dll`, `data/icudtl.dat`, `data/app.so` и Flutter assets. Проверены сигнатуры MZ/PE и архитектура EXE **Windows x64** (`0x8664`). SHA-256 внутреннего ZIP: `22b73cbaabcdefb2b858a7271765b55f3e139d635b8fce940a8cc9cb41929bbe`.

Распакуйте оба ZIP целиком. Для запуска `chess_2.exe` нужны соседние DLL и каталог `data`.

## Проверка интерфейса в браузере

Web-сборка с тем же кодом приложения проверена в браузере:

- Desktop **1400×1000**: квадратная доска **10×10**, все **100 клеток** доступны; в режиме игры вдвоём ход **h2–h4** обновляет доску, историю и очередь хода на чёрных.
- Mobile **375×812**: горизонтального переполнения нет.

Снимки проверки сохранены в рабочей среде как `/workspace/chess_2_desktop.png` и `/workspace/chess_2_mobile.png`.

## Границы проверки

Успешная Windows-сборка подтверждена Windows runner в GitHub Actions; скачанный EXE проверен как PE x64. Ручной запуск нативного Windows GUI в Linux не выполнялся. Android подтверждён debug-сборкой, iOS — сборкой для Simulator; подписанные релизы, запуск на физических мобильных устройствах и публикация в магазинах не заявляются.

При сборке из исходников сначала выполните `dart tool/bootstrap_platforms.dart`, затем `flutter pub get`. CI использует этот bootstrap для штатных платформенных runner-файлов. SDK теперь доступен. Пустой GitHub-репозиторий пользователь создал вручную, после чего исходники были загружены и сборки успешно выполнены.
