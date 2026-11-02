# Shared implementation contract

Latest user decision: square 10×10 board, NO sea, two straight starting ranks. Implement now. Package name `chess_2`.

## Engine — lib/game/chess.dart (engine agent owns)

- `enum Side { white, black }`, extension getter `Side get opponent`.
- `enum PieceType { king, queen, rook, bishop, knight, pawn, archbishop, chancellor, guard, wazir, advisor, elephant, dabbaba, camel, zebra, lancer, scout, cannon }`.
- PieceType extension getters `String get label`, `String get code`, `String get description`, `String get balance`, `double get value`. Russian labels/descriptions. Codes K Q R B N P A C G W F E D M Z L S T respectively.
- `class Piece { const Piece(this.side, this.type); final Side side; final PieceType type; }`.
- Squares are ints 0..99: a1=0, j1=9, a2=10, j10=99. White moves towards increasing rank/index.
- `class ChessMove { const ChessMove({required this.from, required this.to, this.promotion, this.enPassant = false}); final int from, to; final PieceType? promotion; final bool enPassant; }`. Value equality and hashCode.
- `enum GameOutcome { checkmate, stalemate, repetition, fiftyMoves, insufficientMaterial }`.
- `class GameResult { final GameOutcome outcome; final Side? winner; ... }`.
- Immutable `class Position`: public constructor `Position({required List<Piece?> board, Side turn = Side.white, int halfmoveClock = 0, int fullmoveNumber = 1, int? enPassantTarget, Map<String,int>? repetitions})`; `factory Position.initial()`.
- Public position getters: `List<Piece?> board`, `Side turn`, `int halfmoveClock`, `int fullmoveNumber`, `int? enPassantTarget`, `Map<String,int> repetitions`, `String key`, `GameResult? result`.
- Methods `Piece? pieceAt(int square)`, `List<ChessMove> legalMoves({int? from})`, `bool isInCheck(Side side)`, `Position play(ChessMove move)` (validates), `Position applyUnchecked(ChessMove move)` (search, callers use legal generated moves).
- `String squareName(int square)` maps to a1..j10. `String describeMove(Position before, ChessMove move)` readable move notation.

Initial back rank a1..j1: rook, knight, bishop, queen, king, archbishop, chancellor, cannon, camel, zebra.
Initial front rank a2..j2: guard, wazir, advisor, elephant, dabbaba, lancer, scout, pawn, pawn, pawn.
Black uses same file order on ranks10,9.

Royal safety: never capture kings. No castling. Pawn double from2/9 only; en passant immediately after double move; promotion at10/1 to any type except king/pawn (16 types). End by mate, stalemate, threefold same position+turn+legal-en-passant rights, 100 halfmoves, or two bare kings.

New movement: archbishop B/N, chancellor R/N, guard king without royal status, wazir orth1, advisor diag1, elephant leap diag2, dabbaba leap orth2, camel leap3/1, zebra leap3/2, lancer slide orth1..2, scout slide diag1..2, cannon quiet rook/capture across exactly one intervening piece of either side. Leapers jump pieces. All sides use same directions except pawns. No sea logic remains.

## Bot — lib/game/bot.dart (bot agent owns)

Pure Dart, imports chess.dart. `class BotRequest { const BotRequest(this.position, this.difficulty); final Position position; final int difficulty; }`.
Top-level `ChessMove? computeBotMove(BotRequest request)` for Flutter compute isolate.
`ChessMove? chooseBotMove(Position position, {int difficulty = 2, int seed = 0})`.
Difficulty1/2/3. Always return legal move or null at terminal position. Bounded alpha-beta/iterative deepening with material+mobility/position, capture ordering, mate priority. Time budget normal ≤~1s, hard ≤~2.5s. No Flutter imports. Do not evaluate position.result at every node if avoidable; obey repetition/50-move draws.

## UI — lib/ui/*, lib/main.dart (UI agent owns)

Public entry `class ChessApp extends StatelessWidget` in main.dart. Responsive dark navy/ivory/gold Russian UI, square10×10 board in two straight starting rows (40 units total), clear distinct vector/custom-painted glyphs and tiny codes for novel types. Avoid relying on unsupported emoji. Board tap/selected/legal moves, last move/check markers, human white vs black bot, same-device both colors, difficulty1/2/3, undo (human+bot pair in bot mode), reset/new game, flip, history, all18-type guide, promotion dialog and result display. compute(computeBotMove, BotRequest(position,difficulty)); generation token discards stale bot answers on reset/undo/mode changes. Constrain board responsively and allow scroll for small screens/landscape. Use metadata from engine. MaterialApp app title Шахматы 2.0.

## Ownership

Engine agent: only lib/game/chess.dart, test/chess_test.dart.
Bot agent: only lib/game/bot.dart, test/bot_test.dart, README.md, docs/RULES.md, .github/workflows/ci.yml.
UI agent: only lib/ui/, lib/main.dart, test/widget_test.dart.
Root: pubspec, config, native/web scaffold, docs/plans/spec/progress, integration/verification.
Do not edit others' files; communicate API adjustments first. Tests can be authored before SDK available. No commits or subagents needed.
