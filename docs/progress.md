# Progress

- Implemented the Flutter game: square 10×10 board, 18 piece types, 20 pieces per side, two straight starting rows, Russian UI, local two-player mode and three bot levels. Full rules: [RULES.md](RULES.md).
- Published the source to `main` in [tuulaleksandr5-byte/chess-2](https://github.com/tuulaleksandr5-byte/chess-2).
- Verified code: `90e07e53383c14a2db833481240e9d86f221a126`; CI SDK: Flutter 3.47.9 / Dart 3.13.7.
- [CI run 41523086949](https://github.com/tuulaleksandr5-byte/chess-2/actions/runs/41523086949) passed all jobs: Linux analysis, 65 tests and web release; Android debug APK; iOS Simulator build; Windows x64 release.
- [Windows ZIP run 41523086668](https://github.com/tuulaleksandr5-byte/chess-2/actions/runs/41523086668) passed. [Chess-2-Windows-x64 artifact 13178477187](https://github.com/tuulaleksandr5-byte/chess-2/actions/runs/41523086668/artifacts/13178477187) is available until 2026-11-16; the outer download is 11,405,205 bytes. Both ZIP layers passed CRC checks; the inner ZIP contains the EXE, DLL and data, and the EXE's MZ/PE headers confirm Windows x64. Extract both ZIP layers, then keep the EXE, DLLs and `data` together.
- Browser QA on the same application code: desktop 1400×1000 showed a square board with all 100 cells accessible; local-mode h2–h4 updated the board, history and black's turn. Mobile 375×812 had no horizontal overflow. Screenshots: `/workspace/chess_2_desktop.png` and `/workspace/chess_2_mobile.png`.
- Windows GUI was not manually run in Linux. Android verification covers a debug build; iOS verification covers Simulator. Signed mobile releases and store publication are outside the verified delivery.
- SDK is available. The user created the empty GitHub repository manually; source upload and CI then succeeded. Source builds use `tool/bootstrap_platforms.dart` before dependency resolution; full evidence and limitations are in [VALIDATION.md](VALIDATION.md).
