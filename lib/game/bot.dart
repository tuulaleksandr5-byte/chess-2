import 'dart:math';

import 'chess.dart';

/// An isolate-safe request; the search and engine have no Flutter dependency.
class BotRequest {
  const BotRequest(this.position, this.difficulty);

  final Position position;
  final int difficulty;
}

/// Pass this top-level function to Flutter's `compute`.
ChessMove? computeBotMove(BotRequest request) => chooseBotMove(
      request.position,
      difficulty: request.difficulty,
    );

/// Finds a legal response with an interruptible, iterative alpha-beta search.
///
/// A fully searched iteration replaces the previous answer. If the first
/// iteration runs out of time, its best candidate (or the ordered legal
/// fallback) is still safe to play. [seed] only resolves equally ranked moves.
ChessMove? chooseBotMove(
  Position position, {
  int difficulty = 2,
  int seed = 0,
}) {
  final stopwatch = Stopwatch()..start();
  final legalMoves = position.legalMoves();
  if (legalMoves.isEmpty || _isDraw(position)) return null;
  final level = difficulty.clamp(1, 3);
  final limits = switch (level) {
    1 => const _Limits(160, 2, 2500),
    2 => const _Limits(700, 4, 14000),
    _ => const _Limits(1900, 6, 36000),
  };
  return _Search(position, legalMoves, limits, stopwatch, seed).findMove();
}

class _Limits {
  const _Limits(this.milliseconds, this.depth, this.nodes);

  final int milliseconds;
  final int depth;
  final int nodes;
}

class _Search {
  _Search(
    this.position,
    List<ChessMove> legalMoves,
    this.limits,
    this.stopwatch,
    int seed,
  ) : moves = List<ChessMove>.of(legalMoves) {
    moves.shuffle(Random(seed));
    final ties = <ChessMove, int>{
      for (var i = 0; i < moves.length; i++) moves[i]: i,
    };
    moves.sort((a, b) {
      final score = _movePriority(position, b)
          .compareTo(_movePriority(position, a));
      return score != 0 ? score : ties[a]!.compareTo(ties[b]!);
    });
    _fallback = moves.first;
  }

  static const double _mate = 1000000;
  static const double _infinity = 100000000;

  final Position position;
  final List<ChessMove> moves;
  final _Limits limits;
  final Stopwatch stopwatch;
  late ChessMove _fallback;
  int _nodes = 0;

  ChessMove findMove() {
    ChessMove? completed;
    for (var depth = 1; depth <= limits.depth; depth++) {
      try {
        final (move, score) = _searchRoot(depth, completed);
        completed = move;
        // An immediate mate is already the strongest possible move.
        if (score >= _mate - 1) break;
      } on _SearchExpired {
        break;
      }
    }
    return completed ?? _fallback;
  }

  (ChessMove, double) _searchRoot(int depth, ChessMove? previousBest) {
    final ordered = List<ChessMove>.of(moves);
    if (previousBest != null) {
      ordered.remove(previousBest);
      ordered.insert(0, previousBest);
    }
    var bestMove = ordered.first;
    var bestScore = -_infinity;
    var alpha = -_infinity;
    for (final move in ordered) {
      _checkBudget();
      final score = -_negamax(
        position.applyUnchecked(move),
        depth - 1,
        -_infinity,
        -alpha,
        1,
      );
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
        if (depth == 1) _fallback = move;
      }
      alpha = max(alpha, score);
      if (score >= _mate - 1) break;
    }
    return (bestMove, bestScore);
  }

  double _negamax(
    Position node,
    int depth,
    double alpha,
    double beta,
    int ply,
  ) {
    _nodes++;
    _checkBudget();
    final legalMoves = List<ChessMove>.of(node.legalMoves());
    // Mate takes precedence over a clock or repetition draw.
    if (legalMoves.isEmpty) {
      return node.isInCheck(node.turn) ? -_mate + ply : 0;
    }
    if (_isDraw(node)) return 0;
    if (depth <= 0) return _evaluate(node, legalMoves.length);
    legalMoves.sort((a, b) {
      final score = _movePriority(node, b).compareTo(_movePriority(node, a));
      if (score != 0) return score;
      final from = a.from.compareTo(b.from);
      if (from != 0) return from;
      final to = a.to.compareTo(b.to);
      return to != 0
          ? to
          : (a.promotion?.index ?? -1).compareTo(b.promotion?.index ?? -1);
    });
    var best = -_infinity;
    for (final move in legalMoves) {
      final score = -_negamax(
        node.applyUnchecked(move),
        depth - 1,
        -beta,
        -alpha,
        ply + 1,
      );
      best = max(best, score);
      alpha = max(alpha, score);
      if (alpha >= beta) break;
    }
    return best;
  }

  void _checkBudget() {
    if (_nodes >= limits.nodes ||
        stopwatch.elapsedMilliseconds >= limits.milliseconds) {
      throw const _SearchExpired();
    }
  }
}

class _SearchExpired implements Exception {
  const _SearchExpired();
}

bool _isDraw(Position position) {
  if (position.halfmoveClock >= 100 ||
      (position.repetitions[position.key] ?? 0) >= 3) {
    return true;
  }
  for (final piece in position.board) {
    if (piece != null && piece.type != PieceType.king) return false;
  }
  return true;
}

double _movePriority(Position position, ChessMove move) {
  final attacker = position.pieceAt(move.from);
  final victim = position.pieceAt(move.to);
  final captured = move.enPassant ? PieceType.pawn.value : victim?.type.value;
  return (captured ?? 0.0) * 1000 -
      (captured == null ? 0.0 : (attacker?.type.value ?? 0.0) * 10) +
      (move.promotion?.value ?? 0.0) * 900;
}

double _evaluate(Position position, int mobility) {
  var whiteScore = 0.0;
  final endgame = position.board.whereType<Piece>().length <= 8;
  for (var square = 0; square < position.board.length; square++) {
    final piece = position.board[square];
    if (piece == null) continue;
    final file = square % 10;
    final rank = square ~/ 10;
    final center = 9 - (file - 4.5).abs() - (rank - 4.5).abs();
    final advance = piece.side == Side.white ? rank : 9 - rank;
    final positional = switch (piece.type) {
      PieceType.pawn => advance * 5 + center * 2,
      PieceType.king => center * (endgame ? 3.5 : -2.5),
      PieceType.knight ||
      PieceType.camel ||
      PieceType.zebra ||
      PieceType.archbishop => center * 4,
      PieceType.guard ||
      PieceType.wazir ||
      PieceType.advisor ||
      PieceType.elephant ||
      PieceType.dabbaba => center * 3,
      _ => center * 1.5,
    };
    final material = piece.type == PieceType.king ? 0.0 : piece.type.value * 100;
    final score = material + positional;
    whiteScore += piece.side == Side.white ? score : -score;
  }
  // Mobility of the active side also discourages giving the opponent freedom.
  return (position.turn == Side.white ? whiteScore : -whiteScore) +
      mobility * 1.5;
}
