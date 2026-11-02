/// The immutable, Flutter-independent rules of the 10 × 10 Chess 2 variant.
library;

enum Side { white, black }

extension SideRules on Side {
  Side get opponent => this == Side.white ? Side.black : Side.white;
}

enum PieceType {
  king,
  queen,
  rook,
  bishop,
  knight,
  pawn,
  archbishop,
  chancellor,
  guard,
  wazir,
  advisor,
  elephant,
  dabbaba,
  camel,
  zebra,
  lancer,
  scout,
  cannon,
}

extension PieceTypeInfo on PieceType {
  String get label => _labels[index];
  String get code => _codes[index];
  String get description => _descriptions[index];
  String get balance => _balances[index];

  /// Preliminary relative material values; a pawn is one point.
  double get value => _values[index];
}

const _labels = [
  'Король', 'Ферзь', 'Ладья', 'Слон', 'Конь', 'Пешка',
  'Архиепископ', 'Канцлер', 'Страж', 'Визирь', 'Советник',
  'Альфил', 'Даббаба', 'Верблюд', 'Зебра', 'Копейщик', 'Разведчик', 'Пушка',
];
const _codes = [
  'K', 'Q', 'R', 'B', 'N', 'P', 'A', 'C', 'G',
  'W', 'F', 'E', 'D', 'M', 'Z', 'L', 'S', 'T',
];
const _descriptions = [
  'На одну клетку в любом направлении. Нельзя оставлять под шахом. Рокировки нет.',
  'По вертикали, горизонтали или диагонали на любое число свободных клеток.',
  'По вертикали или горизонтали на любое число свободных клеток.',
  'По диагонали на любое число свободных клеток.',
  'Прыжок на две клетки в одном направлении и одну поперёк. Перепрыгивает фигуры.',
  'На одну клетку вперёд, с начальной линии 2/9 — на две. Бьёт по диагонали вперёд. '
      'Есть взятие на проходе; на линии 10/1 превращается в любую из 16 фигур, кроме короля и пешки.',
  'Объединяет ходы слона и коня. Прыжок коня не зависит от препятствий.',
  'Объединяет ходы ладьи и коня. Прыжок коня не зависит от препятствий.',
  'На одну клетку в любом направлении. Обычная фигура: может быть взята.',
  'На одну клетку по вертикали или горизонтали.',
  'На одну клетку по диагонали.',
  'Прыжок ровно на две клетки по диагонали. Перепрыгивает фигуры.',
  'Прыжок ровно на две клетки по вертикали или горизонтали. Перепрыгивает фигуры.',
  'Прыжок на три клетки в одном направлении и одну поперёк. Перепрыгивает фигуры.',
  'Прыжок на три клетки в одном направлении и две поперёк. Перепрыгивает фигуры.',
  'На одну или две клетки по вертикали или горизонтали. Не перепрыгивает фигуры.',
  'На одну или две клетки по диагонали. Не перепрыгивает фигуры.',
  'Без взятия ходит как ладья. Бьёт по вертикали или горизонтали через ровно одну '
      'промежуточную фигуру любого цвета. Перепрыгнуть её можно только при взятии.',
];
const _balances = [
  'Королевская фигура: мат завершает партию.',
  'Дальнобойная сила; берегитесь прыжковых вилок.',
  'Сильна на открытых вертикалях и горизонталях.',
  'Дальнобоен, но остаётся на клетках одного цвета.',
  'Полезен в тесной позиции и для вилок.',
  'Слабее остальных, но превращение даёт выбор из 16 фигур.',
  'Сильнее слона: прыжок добавляет угрозы обоим цветам клеток.',
  'Сильнее ладьи: прыжок помогает в закрытой позиции.',
  'Защищает соседние клетки без ограничений короля.',
  'Недальнобойный защитник; зависит от поддержки.',
  'Короткая диагональ; ограничен цветом клеток.',
  'Перепрыгивает заслон, но охватывает мало клеток.',
  'Перепрыгивает заслон, но привязан к чётности линий.',
  'Дальний прыжок удобен для неожиданных вилок.',
  'Дальний прыжок меняет цвет клетки и обходит заслоны.',
  'Контролирует ближние прямые линии; нуждается в свободном пути.',
  'Контролирует ближние диагонали; ограничен цветом клеток.',
  'Сила зависит от экранов: их появление и исчезновение меняет шах.',
];
const _values = <double>[
  1000, 9.5, 5, 3.2, 3.2, 1, 7.2, 8, 3, 1.4, 1.4,
  2, 2, 2.5, 3, 3, 2.5, 4.8,
];

class Piece {
  const Piece(this.side, this.type);

  final Side side;
  final PieceType type;
}

class ChessMove {
  const ChessMove({
    required this.from,
    required this.to,
    this.promotion,
    this.enPassant = false,
  });

  final int from;
  final int to;
  final PieceType? promotion;
  final bool enPassant;

  @override
  bool operator ==(Object other) =>
      other is ChessMove &&
      from == other.from &&
      to == other.to &&
      promotion == other.promotion &&
      enPassant == other.enPassant;

  @override
  int get hashCode => Object.hash(from, to, promotion, enPassant);

  @override
  String toString() => '${squareName(from)}-${squareName(to)}'
      '${promotion == null ? '' : '=${promotion!.code}'}'
      '${enPassant ? ' e.p.' : ''}';
}

enum GameOutcome {
  checkmate,
  stalemate,
  repetition,
  fiftyMoves,
  insufficientMaterial,
}

class GameResult {
  const GameResult(this.outcome, {this.winner});

  final GameOutcome outcome;
  final Side? winner;
}

class Position {
  factory Position({
    required List<Piece?> board,
    Side turn = Side.white,
    int halfmoveClock = 0,
    int fullmoveNumber = 1,
    int? enPassantTarget,
    Map<String, int>? repetitions,
  }) {
    if (board.length != 100) {
      throw ArgumentError.value(board.length, 'board.length', 'Must be 100');
    }
    if (halfmoveClock < 0 || fullmoveNumber < 1) {
      throw ArgumentError('Move counters must be non-negative; fullmove starts at 1.');
    }
    if (enPassantTarget != null) _checkSquare(enPassantTarget);
    return Position._(
      board: board,
      turn: turn,
      halfmoveClock: halfmoveClock,
      fullmoveNumber: fullmoveNumber,
      enPassantTarget: enPassantTarget,
      suppliedRepetitions:
          repetitions == null ? null : Map<String, int>.unmodifiable(repetitions),
    );
  }

  Position._({
    required List<Piece?> board,
    required this.turn,
    required this.halfmoveClock,
    required this.fullmoveNumber,
    required this.enPassantTarget,
    Map<String, int>? suppliedRepetitions,
    Map<String, int>? previousRepetitions,
  })  : board = List<Piece?>.unmodifiable(board),
        _suppliedRepetitions = suppliedRepetitions,
        _previousRepetitions = previousRepetitions;

  factory Position.initial() {
    const back = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.queen,
      PieceType.king,
      PieceType.archbishop,
      PieceType.chancellor,
      PieceType.cannon,
      PieceType.camel,
      PieceType.zebra,
    ];
    const front = [
      PieceType.guard,
      PieceType.wazir,
      PieceType.advisor,
      PieceType.elephant,
      PieceType.dabbaba,
      PieceType.lancer,
      PieceType.scout,
      PieceType.pawn,
      PieceType.pawn,
      PieceType.pawn,
    ];
    final board = List<Piece?>.filled(100, null);
    for (var file = 0; file < 10; file++) {
      board[file] = Piece(Side.white, back[file]);
      board[10 + file] = Piece(Side.white, front[file]);
      board[80 + file] = Piece(Side.black, front[file]);
      board[90 + file] = Piece(Side.black, back[file]);
    }
    return Position(board: board);
  }

  final List<Piece?> board;
  final Side turn;
  final int halfmoveClock;
  final int fullmoveNumber;
  final int? enPassantTarget;
  final Map<String, int>? _suppliedRepetitions;
  final Map<String, int>? _previousRepetitions;

  /// A history snapshot. Only an actually legal en passant changes the key.
  late final Map<String, int> repetitions = _suppliedRepetitions ??
      Map<String, int>.unmodifiable({
        ...?_previousRepetitions,
        key: (_previousRepetitions?[key] ?? 0) + 1,
      });

  late final String key = _positionKey();
  late final GameResult? result = _findResult();
  late final List<ChessMove> _moves = _generateLegalMoves();

  Piece? pieceAt(int square) {
    _checkSquare(square);
    return board[square];
  }

  List<ChessMove> legalMoves({int? from}) {
    if (from == null) return _moves;
    _checkSquare(from);
    return List<ChessMove>.unmodifiable(_moves.where((move) => move.from == from));
  }

  bool isInCheck(Side side) => _kingInCheck(board, side);

  Position play(ChessMove move) {
    if (!legalMoves(from: move.from).contains(move)) {
      throw ArgumentError.value(move, 'move', 'Move is not legal in this position');
    }
    if (result != null) throw StateError('The game has already ended.');
    return applyUnchecked(move);
  }

  /// Applies an already-generated legal move without generating moves again.
  Position applyUnchecked(ChessMove move) {
    _checkSquare(move.from);
    _checkSquare(move.to);
    final piece = board[move.from];
    if (piece == null || piece.side != turn) {
      throw ArgumentError.value(move, 'move', 'No moving piece for this side');
    }
    if (board[move.to]?.type == PieceType.king) {
      throw ArgumentError.value(move, 'move', 'Kings cannot be captured');
    }
    final capture = board[move.to] != null || move.enPassant;
    final doublePawn = piece.type == PieceType.pawn &&
        (move.to - move.from).abs() == 20;
    return Position._(
      board: _boardAfterMove(board, move),
      turn: turn.opponent,
      halfmoveClock:
          piece.type == PieceType.pawn || capture ? 0 : halfmoveClock + 1,
      fullmoveNumber: fullmoveNumber + (turn == Side.black ? 1 : 0),
      enPassantTarget: doublePawn ? (move.from + move.to) ~/ 2 : null,
      previousRepetitions: repetitions,
    );
  }

  List<ChessMove> _generateLegalMoves() {
    final moves = <ChessMove>[];
    for (var from = 0; from < 100; from++) {
      final piece = board[from];
      if (piece == null || piece.side != turn) continue;
      _pseudoMoves(from, piece, moves);
    }
    return List<ChessMove>.unmodifiable(moves.where((move) =>
        !_kingInCheck(_boardAfterMove(board, move), turn)));
  }

  void _pseudoMoves(int from, Piece piece, List<ChessMove> moves) {
    switch (piece.type) {
      case PieceType.king:
      case PieceType.guard:
        _leaps(from, piece, _adjacent, moves);
      case PieceType.queen:
        _rays(from, piece, _adjacent, 9, moves);
      case PieceType.rook:
        _rays(from, piece, _orthogonal, 9, moves);
      case PieceType.bishop:
        _rays(from, piece, _diagonal, 9, moves);
      case PieceType.knight:
        _leaps(from, piece, _knight, moves);
      case PieceType.pawn:
        _pawnMoves(from, piece, moves);
      case PieceType.archbishop:
        _rays(from, piece, _diagonal, 9, moves);
        _leaps(from, piece, _knight, moves);
      case PieceType.chancellor:
        _rays(from, piece, _orthogonal, 9, moves);
        _leaps(from, piece, _knight, moves);
      case PieceType.wazir:
        _leaps(from, piece, _orthogonal, moves);
      case PieceType.advisor:
        _leaps(from, piece, _diagonal, moves);
      case PieceType.elephant:
        _leaps(from, piece, _elephant, moves);
      case PieceType.dabbaba:
        _leaps(from, piece, _dabbaba, moves);
      case PieceType.camel:
        _leaps(from, piece, _camel, moves);
      case PieceType.zebra:
        _leaps(from, piece, _zebra, moves);
      case PieceType.lancer:
        _rays(from, piece, _orthogonal, 2, moves);
      case PieceType.scout:
        _rays(from, piece, _diagonal, 2, moves);
      case PieceType.cannon:
        _cannonMoves(from, piece, moves);
    }
  }

  void _leaps(
    int from,
    Piece piece,
    List<(int, int)> offsets,
    List<ChessMove> moves,
  ) {
    final file = from % 10;
    final rank = from ~/ 10;
    for (final (dx, dy) in offsets) {
      final x = file + dx;
      final y = rank + dy;
      if (!_onBoard(x, y)) continue;
      final to = y * 10 + x;
      final target = board[to];
      if (target == null ||
          (target.side != piece.side && target.type != PieceType.king)) {
        moves.add(ChessMove(from: from, to: to));
      }
    }
  }

  void _rays(
    int from,
    Piece piece,
    List<(int, int)> directions,
    int maxDistance,
    List<ChessMove> moves,
  ) {
    for (final (dx, dy) in directions) {
      for (var step = 1; step <= maxDistance; step++) {
        final x = from % 10 + dx * step;
        final y = from ~/ 10 + dy * step;
        if (!_onBoard(x, y)) break;
        final to = y * 10 + x;
        final target = board[to];
        if (target == null) {
          moves.add(ChessMove(from: from, to: to));
          continue;
        }
        if (target.side != piece.side && target.type != PieceType.king) {
          moves.add(ChessMove(from: from, to: to));
        }
        break;
      }
    }
  }

  void _cannonMoves(int from, Piece piece, List<ChessMove> moves) {
    for (final (dx, dy) in _orthogonal) {
      var screened = false;
      for (var step = 1; step < 10; step++) {
        final x = from % 10 + dx * step;
        final y = from ~/ 10 + dy * step;
        if (!_onBoard(x, y)) break;
        final to = y * 10 + x;
        final target = board[to];
        if (!screened) {
          if (target == null) {
            moves.add(ChessMove(from: from, to: to));
          } else {
            screened = true;
          }
        } else if (target != null) {
          if (target.side != piece.side && target.type != PieceType.king) {
            moves.add(ChessMove(from: from, to: to));
          }
          break;
        }
      }
    }
  }

  void _pawnMoves(int from, Piece piece, List<ChessMove> moves) {
    final direction = piece.side == Side.white ? 1 : -1;
    final file = from % 10;
    final rank = from ~/ 10;
    final nextRank = rank + direction;
    if (!_onBoard(file, nextRank)) return;
    final next = nextRank * 10 + file;
    if (board[next] == null) {
      _addPawnMove(from, next, piece.side, moves);
      final startingRank = piece.side == Side.white ? 1 : 8;
      final doubleTo = (rank + direction * 2) * 10 + file;
      if (rank == startingRank && board[doubleTo] == null) {
        moves.add(ChessMove(from: from, to: doubleTo));
      }
    }
    for (final dx in [-1, 1]) {
      if (!_onBoard(file + dx, nextRank)) continue;
      final to = nextRank * 10 + file + dx;
      final target = board[to];
      if (target != null &&
          target.side != piece.side &&
          target.type != PieceType.king) {
        _addPawnMove(from, to, piece.side, moves);
      } else if (_isEnPassant(from, to, piece.side)) {
        moves.add(ChessMove(from: from, to: to, enPassant: true));
      }
    }
  }

  void _addPawnMove(int from, int to, Side side, List<ChessMove> moves) {
    if (to ~/ 10 == (side == Side.white ? 9 : 0)) {
      for (final type in PieceType.values) {
        if (type == PieceType.king || type == PieceType.pawn) continue;
        moves.add(ChessMove(from: from, to: to, promotion: type));
      }
    } else {
      moves.add(ChessMove(from: from, to: to));
    }
  }

  bool _isEnPassant(int from, int to, Side side) {
    if (to != enPassantTarget || board[to] != null) return false;
    final direction = side == Side.white ? 1 : -1;
    if (to ~/ 10 != (side == Side.white ? 7 : 2) ||
        to ~/ 10 - from ~/ 10 != direction ||
        (to % 10 - from % 10).abs() != 1) {
      return false;
    }
    final captured = board[to - direction * 10];
    return captured?.type == PieceType.pawn && captured?.side == side.opponent;
  }

  bool _hasLegalEnPassant() {
    final target = enPassantTarget;
    if (target == null) return false;
    final direction = turn == Side.white ? 1 : -1;
    final sourceRank = target ~/ 10 - direction;
    for (final dx in [-1, 1]) {
      final file = target % 10 + dx;
      if (!_onBoard(file, sourceRank)) continue;
      final from = sourceRank * 10 + file;
      final piece = board[from];
      if (piece?.side != turn || piece?.type != PieceType.pawn) continue;
      if (_isEnPassant(from, target, turn) &&
          !_kingInCheck(_boardAfterMove(board,
              ChessMove(from: from, to: target, enPassant: true)), turn)) {
        return true;
      }
    }
    return false;
  }

  String _positionKey() {
    final buffer = StringBuffer();
    for (final piece in board) {
      buffer.write(piece == null
          ? '.'
          : piece.side == Side.white
              ? piece.type.code
              : piece.type.code.toLowerCase());
    }
    buffer.write(turn == Side.white ? ':w:' : ':b:');
    buffer.write(_hasLegalEnPassant() ? enPassantTarget : '-');
    return buffer.toString();
  }

  GameResult? _findResult() {
    if (_moves.isEmpty) {
      return isInCheck(turn)
          ? GameResult(GameOutcome.checkmate, winner: turn.opponent)
          : const GameResult(GameOutcome.stalemate);
    }
    if ((repetitions[key] ?? 0) >= 3) {
      return const GameResult(GameOutcome.repetition);
    }
    if (halfmoveClock >= 100) {
      return const GameResult(GameOutcome.fiftyMoves);
    }
    final pieces = board.whereType<Piece>().toList();
    if (pieces.length == 2 &&
        pieces.every((piece) => piece.type == PieceType.king) &&
        pieces.first.side != pieces.last.side) {
      return const GameResult(GameOutcome.insufficientMaterial);
    }
    return null;
  }
}

List<Piece?> _boardAfterMove(List<Piece?> board, ChessMove move) {
  final next = List<Piece?>.of(board);
  final piece = board[move.from]!;
  next[move.from] = null;
  if (move.enPassant) {
    next[move.to - (piece.side == Side.white ? 10 : -10)] = null;
  }
  next[move.to] = move.promotion == null
      ? piece
      : Piece(piece.side, move.promotion!);
  return next;
}

bool _kingInCheck(List<Piece?> board, Side side) {
  var king = -1;
  for (var square = 0; square < 100; square++) {
    final piece = board[square];
    if (piece?.side == side && piece?.type == PieceType.king) {
      king = square;
      break;
    }
  }
  if (king == -1) return false;
  for (var from = 0; from < 100; from++) {
    final piece = board[from];
    if (piece != null && piece.side == side.opponent &&
        _attacks(board, from, king, piece)) {
      return true;
    }
  }
  return false;
}

bool _attacks(List<Piece?> board, int from, int to, Piece piece) {
  final dx = to % 10 - from % 10;
  final dy = to ~/ 10 - from ~/ 10;
  final ax = dx.abs();
  final ay = dy.abs();
  final orthogonal = (dx == 0) != (dy == 0);
  final diagonal = ax == ay && ax != 0;
  final knight = (ax == 1 && ay == 2) || (ax == 2 && ay == 1);
  switch (piece.type) {
    case PieceType.king:
    case PieceType.guard:
      return ax <= 1 && ay <= 1 && ax + ay != 0;
    case PieceType.pawn:
      return ax == 1 && dy == (piece.side == Side.white ? 1 : -1);
    case PieceType.knight:
      return knight;
    case PieceType.wazir:
      return ax + ay == 1;
    case PieceType.advisor:
      return ax == 1 && ay == 1;
    case PieceType.elephant:
      return ax == 2 && ay == 2;
    case PieceType.dabbaba:
      return (ax == 2 && ay == 0) || (ax == 0 && ay == 2);
    case PieceType.camel:
      return (ax == 3 && ay == 1) || (ax == 1 && ay == 3);
    case PieceType.zebra:
      return (ax == 3 && ay == 2) || (ax == 2 && ay == 3);
    case PieceType.queen:
      if (!orthogonal && !diagonal) return false;
    case PieceType.rook:
      if (!orthogonal) return false;
    case PieceType.bishop:
      if (!diagonal) return false;
    case PieceType.archbishop:
      if (knight) return true;
      if (!diagonal) return false;
    case PieceType.chancellor:
      if (knight) return true;
      if (!orthogonal) return false;
    case PieceType.lancer:
      if (!orthogonal || ax > 2 || ay > 2) return false;
    case PieceType.scout:
      if (!diagonal || ax > 2) return false;
    case PieceType.cannon:
      if (!orthogonal) return false;
  }
  final stepX = dx.sign;
  final stepY = dy.sign;
  var screens = 0;
  var x = from % 10 + stepX;
  var y = from ~/ 10 + stepY;
  while (x != to % 10 || y != to ~/ 10) {
    if (board[y * 10 + x] != null) screens++;
    if (screens > (piece.type == PieceType.cannon ? 1 : 0)) return false;
    x += stepX;
    y += stepY;
  }
  return screens == (piece.type == PieceType.cannon ? 1 : 0);
}

bool _onBoard(int file, int rank) =>
    file >= 0 && file < 10 && rank >= 0 && rank < 10;

void _checkSquare(int square) {
  RangeError.checkValueInInterval(square, 0, 99, 'square');
}

String squareName(int square) {
  _checkSquare(square);
  return '${String.fromCharCode(97 + square % 10)}${square ~/ 10 + 1}';
}

String describeMove(Position before, ChessMove move) {
  final piece = before.pieceAt(move.from);
  if (piece == null) throw ArgumentError.value(move, 'move', 'Empty origin');
  final captures = before.pieceAt(move.to) != null || move.enPassant;
  return '${piece.type.code} ${squareName(move.from)}'
      '${captures ? '×' : '–'}${squareName(move.to)}'
      '${move.promotion == null ? '' : '=${move.promotion!.code}'}'
      '${move.enPassant ? ' e.p.' : ''}';
}

const _orthogonal = <(int, int)>[(1, 0), (-1, 0), (0, 1), (0, -1)];
const _diagonal = <(int, int)>[(1, 1), (1, -1), (-1, 1), (-1, -1)];
const _adjacent = <(int, int)>[..._orthogonal, ..._diagonal];
const _knight = <(int, int)>[
  (1, 2), (2, 1), (-1, 2), (-2, 1),
  (1, -2), (2, -1), (-1, -2), (-2, -1),
];
const _elephant = <(int, int)>[(2, 2), (2, -2), (-2, 2), (-2, -2)];
const _dabbaba = <(int, int)>[(2, 0), (-2, 0), (0, 2), (0, -2)];
const _camel = <(int, int)>[
  (3, 1), (1, 3), (-3, 1), (-1, 3),
  (3, -1), (1, -3), (-3, -1), (-1, -3),
];
const _zebra = <(int, int)>[
  (3, 2), (2, 3), (-3, 2), (-2, 3),
  (3, -2), (2, -3), (-3, -2), (-2, -3),
];
