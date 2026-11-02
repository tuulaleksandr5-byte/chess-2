import 'package:chess_2/game/chess.dart';
import 'package:flutter_test/flutter_test.dart';

Position position(
  Map<int, Piece> pieces, {
  Side turn = Side.white,
  int? enPassantTarget,
  int halfmoveClock = 0,
  Map<String, int>? repetitions,
}) {
  final board = List<Piece?>.filled(100, null);
  for (final entry in pieces.entries) {
    board[entry.key] = entry.value;
  }
  return Position(
    board: board,
    turn: turn,
    enPassantTarget: enPassantTarget,
    halfmoveClock: halfmoveClock,
    repetitions: repetitions,
  );
}

const wk = Piece(Side.white, PieceType.king);
const bk = Piece(Side.black, PieceType.king);
const wp = Piece(Side.white, PieceType.pawn);
const bp = Piece(Side.black, PieceType.pawn);

Set<int> destinations(Position p, int from) =>
    p.legalMoves(from: from).map((move) => move.to).toSet();

void main() {
  test('initial board has two straight ranks and all eighteen types', () {
    final p = Position.initial();
    expect(p.board.length, 100);
    expect(p.board.whereType<Piece>().length, 40);
    expect(p.board.take(20).every((piece) => piece?.side == Side.white), isTrue);
    expect(p.board.skip(80).every((piece) => piece?.side == Side.black), isTrue);
    expect(p.board.skip(20).take(60).every((piece) => piece == null), isTrue);
    expect(p.pieceAt(4)?.type, PieceType.king);
    expect(p.pieceAt(94)?.type, PieceType.king);
    expect(p.board.take(20).whereType<Piece>().map((p) => p.type).toSet(),
        PieceType.values.toSet());
    expect(p.turn, Side.white);
    expect(p.result, isNull);
    expect(p.isInCheck(Side.white), isFalse);
    expect(p.isInCheck(Side.black), isFalse);
  });

  test('metadata has distinct codes, Russian labels and movement descriptions', () {
    expect(PieceType.values.map((type) => type.code).toSet().length, 18);
    expect(PieceType.values.map((type) => type.code).join(),
        'KQRBNPACGWFEDMZLST');
    for (final type in PieceType.values) {
      expect(type.label, matches(RegExp('[А-Яа-яЁё]')));
      expect(type.description, isNotEmpty);
      expect(type.balance, isNotEmpty);
      expect(type.value, greaterThan(0));
    }
    expect(Side.white.opponent, Side.black);
    expect(Side.black.opponent, Side.white);
    expect(squareName(0), 'a1');
    expect(squareName(99), 'j10');
  });

  test('positions copy their board and history and expose immutable collections', () {
    final board = List<Piece?>.filled(100, null)..[0] = wk;
    final history = <String, int>{'earlier': 2};
    final p = Position(board: board, repetitions: history);
    board[0] = null;
    history['earlier'] = 9;
    expect(p.pieceAt(0), wk);
    expect(p.repetitions['earlier'], 2);
    expect(() => p.board[0] = null, throwsUnsupportedError);
    expect(() => p.repetitions['earlier'] = 3, throwsUnsupportedError);
    expect(() => p.legalMoves().clear(), throwsUnsupportedError);
    expect(() => Position(board: <Piece?>[]), throwsArgumentError);
  });

  group('movement on an open board', () {
    final expected = <PieceType, int>{
      PieceType.king: 8,
      PieceType.queen: 35,
      PieceType.rook: 18,
      PieceType.bishop: 17,
      PieceType.knight: 8,
      PieceType.archbishop: 25,
      PieceType.chancellor: 26,
      PieceType.guard: 8,
      PieceType.wazir: 4,
      PieceType.advisor: 4,
      PieceType.elephant: 4,
      PieceType.dabbaba: 4,
      PieceType.camel: 8,
      PieceType.zebra: 8,
      PieceType.lancer: 8,
      PieceType.scout: 8,
      PieceType.cannon: 18,
    };
    for (final entry in expected.entries) {
      test('${entry.key.name} reaches its exact set of open-board squares', () {
        // Distant kings do not interfere with the centered movement sample.
        final p = position({
          if (entry.key != PieceType.king) 1: wk,
          98: bk,
          44: Piece(Side.white, entry.key),
        });
        expect(destinations(p, 44).length, entry.value);
      });
    }
  });

  test('short sliders cannot pass blockers and leapers can', () {
    final p = position({
      0: wk,
      99: bk,
      44: const Piece(Side.white, PieceType.lancer),
      54: wp,
      43: bp,
    });
    expect(destinations(p, 44), contains(43));
    expect(destinations(p, 44), isNot(contains(42)));
    expect(destinations(p, 44), isNot(contains(54)));
    expect(destinations(p, 44), isNot(contains(64)));
    final leaper = position({
      0: wk,
      99: bk,
      44: const Piece(Side.white, PieceType.elephant),
      55: wp,
    });
    expect(destinations(leaper, 44), contains(66));
  });

  test('camel and zebra have their distinct 3 by 1 and 3 by 2 leaps', () {
    final camel = position({0: wk, 99: bk, 44: const Piece(Side.white, PieceType.camel)});
    final zebra = position({0: wk, 99: bk, 44: const Piece(Side.white, PieceType.zebra)});
    expect(destinations(camel, 44), {13, 15, 31, 37, 51, 57, 73, 75});
    expect(destinations(zebra, 44), {12, 16, 21, 27, 61, 67, 72, 76});
  });

  test('cannon needs exactly one screen to capture and cannot land beyond it', () {
    final p = position({
      0: wk,
      99: bk,
      44: const Piece(Side.white, PieceType.cannon),
      64: wp,
      84: const Piece(Side.black, PieceType.rook),
      94: const Piece(Side.black, PieceType.bishop),
      47: bp,
    });
    final moves = destinations(p, 44);
    expect(moves, containsAll([54, 84, 45, 46]));
    expect(moves, isNot(contains(64)));
    expect(moves, isNot(contains(74)));
    expect(moves, isNot(contains(94)));
    expect(moves, isNot(contains(47)));
  });

  test('cannon screens of either color give check; zero and two do not', () {
    for (final screen in [wp, bp]) {
      final p = position({
        4: wk,
        99: bk,
        94: const Piece(Side.black, PieceType.cannon),
        44: screen,
      });
      expect(p.isInCheck(Side.white), isTrue);
    }
    expect(position({4: wk, 99: bk, 94: const Piece(Side.black, PieceType.cannon)})
        .isInCheck(Side.white), isFalse);
    expect(position({
      4: wk,
      99: bk,
      94: const Piece(Side.black, PieceType.cannon),
      44: wp,
      64: bp,
    }).isInCheck(Side.white), isFalse);
  });

  test('moving a pinned piece cannot expose its king', () {
    final p = position({
      4: wk,
      99: bk,
      14: const Piece(Side.white, PieceType.rook),
      94: const Piece(Side.black, PieceType.rook),
    });
    expect(destinations(p, 14), isNot(contains(15)));
    expect(destinations(p, 14), containsAll([24, 94]));
    expect(() => p.play(const ChessMove(from: 14, to: 15)), throwsArgumentError);
  });

  test('a cannon screen cannot move away if the second blocker would become sole screen', () {
    final p = position({
      4: wk,
      99: bk,
      24: const Piece(Side.white, PieceType.rook),
      64: bp,
      94: const Piece(Side.black, PieceType.cannon),
    });
    expect(p.isInCheck(Side.white), isFalse);
    expect(destinations(p, 24), isNot(contains(25)));
  });

  test('kings cannot become adjacent or capture a protected piece', () {
    final p = position({44: wk, 66: bk, 45: const Piece(Side.black, PieceType.rook),
      67: const Piece(Side.black, PieceType.bishop)});
    expect(destinations(p, 44), isNot(contains(55)));
    expect(destinations(p, 44), isNot(contains(45)));
  });

  test('a checking king is never a capture target, even through unchecked play', () {
    final p = position({
      0: wk,
      99: bk,
      89: const Piece(Side.white, PieceType.rook),
    });
    expect(destinations(p, 89), isNot(contains(99)));
    expect(() => p.play(const ChessMove(from: 89, to: 99)), throwsArgumentError);
    expect(() => p.applyUnchecked(const ChessMove(from: 89, to: 99)), throwsArgumentError);
  });

  test('white and black pawns double only from their starting rank', () {
    final white = position({0: wk, 99: bk, 17: wp});
    expect(destinations(white, 17), {27, 37});
    final advanced = position({0: wk, 99: bk, 27: wp});
    expect(destinations(advanced, 27), {37});
    final blocked = position({0: wk, 99: bk, 17: wp, 27: bp});
    expect(destinations(blocked, 17), isEmpty);
    final black = position({0: wk, 99: bk, 87: bp}, turn: Side.black);
    expect(destinations(black, 87), {77, 67});
  });

  test('en passant is available for one reply and removes the passed pawn', () {
    final start = position({0: wk, 99: bk, 17: wp, 36: bp});
    final afterDouble = start.play(const ChessMove(from: 17, to: 37));
    expect(afterDouble.enPassantTarget, 27);
    const capture = ChessMove(from: 36, to: 27, enPassant: true);
    expect(afterDouble.legalMoves(from: 36), contains(capture));
    final afterCapture = afterDouble.play(capture);
    expect(afterCapture.pieceAt(37), isNull);
    expect(afterCapture.pieceAt(27)?.side, Side.black);
    expect(afterCapture.enPassantTarget, isNull);
    expect(afterCapture.halfmoveClock, 0);
    final declined = afterDouble.play(const ChessMove(from: 99, to: 98));
    expect(declined.enPassantTarget, isNull);
  });

  test('white can capture en passant after a black double', () {
    final p = position({0: wk, 99: bk, 66: wp, 87: bp}, turn: Side.black)
        .play(const ChessMove(from: 87, to: 67));
    const capture = ChessMove(from: 66, to: 77, enPassant: true);
    expect(p.legalMoves(from: 66), contains(capture));
    expect(p.play(capture).pieceAt(67), isNull);
  });

  test('en passant cannot reveal an attack on the moving side king', () {
    final p = position({
      60: wk,
      99: bk,
      65: wp,
      66: bp,
      69: const Piece(Side.black, PieceType.rook),
    }, enPassantTarget: 76);
    expect(p.legalMoves(from: 65), isNot(contains(
        const ChessMove(from: 65, to: 76, enPassant: true))));
  });

  test('both pawn colors promote to exactly sixteen types including capture', () {
    for (final side in Side.values) {
      final from = side == Side.white ? 85 : 15;
      final to = side == Side.white ? 95 : 5;
      final captureTo = to + 1;
      final p = position({
        0: wk,
        99: bk,
        from: Piece(side, PieceType.pawn),
        captureTo: Piece(side.opponent, PieceType.guard),
      }, turn: side);
      final moves = p.legalMoves(from: from);
      expect(moves.length, 32);
      expect(moves.where((m) => m.to == to).map((m) => m.promotion).toSet(),
          PieceType.values.where((t) => t != PieceType.king && t != PieceType.pawn).toSet());
      for (final move in moves) {
        expect(p.play(move).pieceAt(move.to)?.type, move.promotion);
      }
      expect(() => p.play(ChessMove(from: from, to: to)), throwsArgumentError);
      expect(() => p.play(ChessMove(from: from, to: to, promotion: PieceType.king)),
          throwsArgumentError);
    }
  });

  test('turn, move counters and immutable prior position survive moves', () {
    final p = position({0: wk, 99: bk, 22: const Piece(Side.white, PieceType.rook)},
        halfmoveClock: 7);
    final whiteMove = p.play(const ChessMove(from: 22, to: 23));
    expect(whiteMove.turn, Side.black);
    expect(whiteMove.halfmoveClock, 8);
    expect(whiteMove.fullmoveNumber, 1);
    final blackMove = whiteMove.play(const ChessMove(from: 99, to: 98));
    expect(blackMove.fullmoveNumber, 2);
    expect(p.pieceAt(22)?.type, PieceType.rook);
    expect(p.pieceAt(23), isNull);
    expect(p.repetitions[p.key], 1);
  });

  test('capturing resets the halfmove clock', () {
    final p = position({0: wk, 99: bk,
      22: const Piece(Side.white, PieceType.rook), 25: bp}, halfmoveClock: 99);
    expect(p.play(const ChessMove(from: 22, to: 25)).halfmoveClock, 0);
  });

  test('checkmate, stalemate and two bare kings end with the right winner', () {
    final mate = position({0: wk, 22: bk, 11: const Piece(Side.black, PieceType.queen)});
    expect(mate.isInCheck(Side.white), isTrue);
    expect(mate.result?.outcome, GameOutcome.checkmate);
    expect(mate.result?.winner, Side.black);
    final stale = position({0: wk, 22: bk, 12: const Piece(Side.black, PieceType.queen)});
    expect(stale.isInCheck(Side.white), isFalse);
    expect(stale.result?.outcome, GameOutcome.stalemate);
    expect(stale.result?.winner, isNull);
    expect(position({0: wk, 99: bk}).result?.outcome, GameOutcome.insufficientMaterial);
  });

  test('one hundred quiet halfmoves draw but mate has priority', () {
    final p = position({0: wk, 99: bk, 22: const Piece(Side.white, PieceType.rook)},
        halfmoveClock: 99).play(const ChessMove(from: 22, to: 23));
    expect(p.result?.outcome, GameOutcome.fiftyMoves);
    final mate = position({0: wk, 22: bk, 11: const Piece(Side.black, PieceType.queen)},
        halfmoveClock: 100);
    expect(mate.result?.outcome, GameOutcome.checkmate);
  });

  test('threefold repetition counts actual repeated board and side', () {
    var p = position({0: wk, 99: bk, 11: const Piece(Side.white, PieceType.knight)});
    const cycle = [
      ChessMove(from: 11, to: 32),
      ChessMove(from: 99, to: 98),
      ChessMove(from: 32, to: 11),
      ChessMove(from: 98, to: 99),
    ];
    for (var repetition = 0; repetition < 2; repetition++) {
      for (final move in cycle) {
        p = p.play(move);
      }
      expect(p.result?.outcome,
          repetition == 0 ? isNull : GameOutcome.repetition);
    }
    expect(p.repetitions[p.key], 3);
  });

  test('repetition key includes turn and only legally exercisable en passant', () {
    final pieces = {0: wk, 99: bk, 65: wp, 66: bp};
    expect(position(pieces, enPassantTarget: 76).key,
        isNot(position(pieces).key));
    expect(position(pieces).key, isNot(position(pieces, turn: Side.black).key));
    final unavailable = {0: wk, 99: bk, 66: bp};
    expect(position(unavailable, enPassantTarget: 76).key,
        position(unavailable).key);
    final pinned = {60: wk, 99: bk, 65: wp, 66: bp,
      69: const Piece(Side.black, PieceType.rook)};
    expect(position(pinned, enPassantTarget: 76).key, position(pinned).key);
  });

  test('moves have value equality and readable capture/promotion notation', () {
    const a = ChessMove(from: 12, to: 32);
    const b = ChessMove(from: 12, to: 32);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(Set<ChessMove>.of([a, b]).length, 1);
    expect(a, isNot(const ChessMove(from: 12, to: 32, enPassant: true)));
    final p = position({0: wk, 99: bk, 85: wp,
      96: const Piece(Side.black, PieceType.rook)});
    final text = describeMove(p,
        const ChessMove(from: 85, to: 96, promotion: PieceType.chancellor));
    expect(text, contains('f9'));
    expect(text, contains('g10'));
    expect(text, contains('C'));
  });
}
