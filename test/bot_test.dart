import 'package:chess_2/game/bot.dart';
import 'package:chess_2/game/chess.dart';
import 'package:flutter_test/flutter_test.dart';

Position positionWith(
  Map<int, Piece> pieces, {
  Side turn = Side.white,
  int halfmoveClock = 0,
}) {
  final board = List<Piece?>.filled(100, null);
  for (final entry in pieces.entries) {
    board[entry.key] = entry.value;
  }
  return Position(board: board, turn: turn, halfmoveClock: halfmoveClock);
}

void main() {
  group('bot move selection', () {
    for (final difficulty in [1, 2, 3]) {
      test('difficulty $difficulty returns a legal opening move', () {
        final position = Position.initial();
        final before = List<Piece?>.of(position.board);
        final beforeKey = position.key;

        final move = chooseBotMove(position, difficulty: difficulty);

        expect(move, isNotNull);
        expect(position.legalMoves(), contains(move));
        expect(position.board, orderedEquals(before));
        expect(position.key, beforeKey);
        expect(position.turn, Side.white);
      });
    }

    test('takes an undefended queen to escape check', () {
      final position = positionWith({
        0: const Piece(Side.white, PieceType.rook),
        4: const Piece(Side.white, PieceType.king),
        40: const Piece(Side.black, PieceType.queen),
        99: const Piece(Side.black, PieceType.king),
      });
      expect(position.isInCheck(Side.white), isTrue);

      expect(
        chooseBotMove(position, difficulty: 1),
        const ChessMove(from: 0, to: 40),
      );
    });

    for (final difficulty in [1, 2, 3]) {
      test('difficulty $difficulty chooses mate over a free rook', () {
        final position = positionWith({
          71: const Piece(Side.white, PieceType.queen),
          72: const Piece(Side.white, PieceType.king),
          44: const Piece(Side.black, PieceType.rook),
          90: const Piece(Side.black, PieceType.king),
        });

        final move = chooseBotMove(position, difficulty: difficulty);

        expect(move, const ChessMove(from: 71, to: 81));
        final result = position.play(move!).result;
        expect(result?.outcome, GameOutcome.checkmate);
        expect(result?.winner, Side.white);
      });
    }

    test('compute entry point returns a legal move for black', () {
      final position = positionWith({
        0: const Piece(Side.white, PieceType.king),
        51: const Piece(Side.white, PieceType.rook),
        55: const Piece(Side.black, PieceType.rook),
        99: const Piece(Side.black, PieceType.king),
      }, turn: Side.black);

      final move = computeBotMove(BotRequest(position, 1));

      expect(move, const ChessMove(from: 55, to: 51));
    });

    test('promotes a pawn using a legal promotion choice', () {
      final position = positionWith({
        4: const Piece(Side.white, PieceType.king),
        80: const Piece(Side.white, PieceType.pawn),
        99: const Piece(Side.black, PieceType.king),
      });

      final move = chooseBotMove(position, difficulty: 1);

      expect(move, isNotNull);
      expect(move!.from, 80);
      expect(move.to, 90);
      expect(move.promotion, isNotNull);
      expect(position.legalMoves(), contains(move));
    });

    test('normalizes unsupported difficulties to a legal response', () {
      final position = positionWith({
        4: const Piece(Side.white, PieceType.king),
        10: const Piece(Side.white, PieceType.rook),
        99: const Piece(Side.black, PieceType.king),
      });
      expect(
        position.legalMoves(),
        contains(chooseBotMove(position, difficulty: -5, seed: 41)),
      );
    });
  });

  group('terminal positions', () {
    test('returns null after checkmate', () {
      final position = positionWith({
        72: const Piece(Side.white, PieceType.king),
        81: const Piece(Side.white, PieceType.queen),
        90: const Piece(Side.black, PieceType.king),
      }, turn: Side.black);
      expect(position.result?.outcome, GameOutcome.checkmate);
      expect(chooseBotMove(position), isNull);
    });

    test('returns null after stalemate', () {
      final position = positionWith({
        72: const Piece(Side.white, PieceType.king),
        82: const Piece(Side.white, PieceType.queen),
        90: const Piece(Side.black, PieceType.king),
      }, turn: Side.black);
      expect(position.result?.outcome, GameOutcome.stalemate);
      expect(chooseBotMove(position), isNull);
    });

    test('returns null for two bare kings', () {
      final position = positionWith({
        0: const Piece(Side.white, PieceType.king),
        99: const Piece(Side.black, PieceType.king),
      });
      expect(position.legalMoves(), isNotEmpty);
      expect(chooseBotMove(position), isNull);
    });

    test('returns null after 100 halfmoves without capture or pawn move', () {
      final position = positionWith({
        0: const Piece(Side.white, PieceType.king),
        10: const Piece(Side.white, PieceType.rook),
        99: const Piece(Side.black, PieceType.king),
      }, halfmoveClock: 100);
      expect(position.legalMoves(), isNotEmpty);
      expect(chooseBotMove(position), isNull);
    });

    test('returns null on the third occurrence of a position', () {
      final initial = Position.initial();
      final position = Position(
        board: initial.board,
        repetitions: {initial.key: 3},
      );
      expect(chooseBotMove(position), isNull);
    });
  });
}
