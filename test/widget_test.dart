import 'dart:async';

import 'package:chess_2/game/chess.dart';
import 'package:chess_2/main.dart';
import 'package:chess_2/ui/chess_board.dart';
import 'package:chess_2/ui/chess_screen.dart';
import 'package:chess_2/ui/piece_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ChessBoard boardOf(WidgetTester tester) => tester.widget<ChessBoard>(find.byType(ChessBoard));

Future<void> launchGame(WidgetTester tester, {Size size = const Size(1280, 1100), Widget? app}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(app ?? const ChessApp());
  await tester.pumpAndSettle();
}

Future<void> tapSquare(WidgetTester tester, int square) async {
  final target = find.byKey(Key('square-$square'));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('initial board shows forty vector pieces in two straight ranks per side', (tester) async {
    await launchGame(tester);
    expect(find.text('Шахматы 2.0'), findsOneWidget);
    expect(find.descendant(of: find.byType(ChessBoard), matching: find.byType(PieceGlyph)), findsNWidgets(40));
    final board = boardOf(tester);
    expect(board.position.turn, Side.white);
    expect(board.position.board.where((piece) => piece != null).length, 40);
    for (var square = 20; square < 80; square++) {
      expect(board.position.pieceAt(square), isNull);
    }
    expect(find.text('Ход белых'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a piece exposes legal moves and a destination makes the move', (tester) async {
    await launchGame(tester);
    await tester.tap(find.byKey(const Key('mode-local')));
    await tester.pumpAndSettle();
    await tapSquare(tester, 17);
    expect(boardOf(tester).selected, 17);
    expect(boardOf(tester).legalMoves.where((move) => move.from == 17).map((move) => move.to), contains(37));
    await tapSquare(tester, 37);
    expect(boardOf(tester).position.pieceAt(17), isNull);
    expect(boardOf(tester).position.pieceAt(37)?.type, PieceType.pawn);
    expect(boardOf(tester).selected, isNull);
    expect(boardOf(tester).lastMove, const ChessMove(from: 17, to: 37));
  });

  testWidgets('same-device mode lets black move and undo restores the last turn', (tester) async {
    await launchGame(tester);
    await tester.tap(find.byKey(const Key('mode-local')));
    await tester.pumpAndSettle();
    await tapSquare(tester, 17);
    await tapSquare(tester, 37);
    expect(boardOf(tester).position.turn, Side.black);
    await tapSquare(tester, 87);
    await tapSquare(tester, 67);
    expect(boardOf(tester).position.turn, Side.white);
    expect(boardOf(tester).position.pieceAt(67)?.side, Side.black);
    await tester.ensureVisible(find.byKey(const Key('undo-move')));
    await tester.tap(find.byKey(const Key('undo-move')));
    await tester.pumpAndSettle();
    expect(boardOf(tester).position.turn, Side.black);
    expect(boardOf(tester).position.pieceAt(87)?.side, Side.black);
    expect(boardOf(tester).position.pieceAt(67), isNull);
  });

  testWidgets('new game clears the position, last move and history', (tester) async {
    await launchGame(tester);
    await tester.tap(find.byKey(const Key('mode-local')));
    await tester.pumpAndSettle();
    await tapSquare(tester, 17);
    await tapSquare(tester, 37);
    await tester.ensureVisible(find.byKey(const Key('reset-game')));
    await tester.tap(find.byKey(const Key('reset-game')));
    await tester.pumpAndSettle();
    expect(boardOf(tester).position.turn, Side.white);
    expect(boardOf(tester).position.pieceAt(17)?.type, PieceType.pawn);
    expect(boardOf(tester).position.pieceAt(37), isNull);
    expect(boardOf(tester).lastMove, isNull);
    expect(find.text('Первый ход — за вами.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset discards a bot answer that was already running', (tester) async {
    final answer = Completer<ChessMove?>();
    await launchGame(tester, app: MaterialApp(home: ChessScreen(botMoveRunner: (_) => answer.future)));
    await tapSquare(tester, 17);
    await tester.tap(find.byKey(const Key('square-37')));
    await tester.pump();
    expect(boardOf(tester).position.turn, Side.black);
    expect(boardOf(tester).enabled, isFalse);
    await tester.tap(find.byKey(const Key('reset-game')));
    await tester.pump();
    answer.complete(const ChessMove(from: 87, to: 67));
    await tester.pumpAndSettle();
    expect(boardOf(tester).position.turn, Side.white);
    expect(boardOf(tester).position.pieceAt(17)?.type, PieceType.pawn);
    expect(boardOf(tester).position.pieceAt(87)?.side, Side.black);
    expect(boardOf(tester).lastMove, isNull);
  });

  testWidgets('undo during a pending bot turn restores the human move', (tester) async {
    final answer = Completer<ChessMove?>();
    await launchGame(tester, app: MaterialApp(home: ChessScreen(botMoveRunner: (_) => answer.future)));
    await tapSquare(tester, 17);
    await tester.tap(find.byKey(const Key('square-37')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('undo-move')));
    await tester.pump();
    answer.complete(const ChessMove(from: 87, to: 67));
    await tester.pumpAndSettle();
    expect(boardOf(tester).position.turn, Side.white);
    expect(boardOf(tester).position.pieceAt(17)?.type, PieceType.pawn);
    expect(boardOf(tester).position.pieceAt(37), isNull);
    expect(boardOf(tester).lastMove, isNull);
  });

  testWidgets('undo after a bot answer removes both moves', (tester) async {
    await launchGame(tester, app: MaterialApp(home: ChessScreen(
      botMoveRunner: (request) async => request.position.legalMoves().first,
    )));
    await tapSquare(tester, 17);
    await tapSquare(tester, 37);
    expect(boardOf(tester).position.turn, Side.white);
    expect(boardOf(tester).position.fullmoveNumber, 2);
    expect(boardOf(tester).position.pieceAt(17), isNull);
    await tester.tap(find.byKey(const Key('undo-move')));
    await tester.pumpAndSettle();
    expect(boardOf(tester).position.key, Position.initial().key);
    expect(boardOf(tester).lastMove, isNull);
  });

  testWidgets('switching to same-device mode discards a pending bot answer', (tester) async {
    final answer = Completer<ChessMove?>();
    await launchGame(tester, app: MaterialApp(home: ChessScreen(botMoveRunner: (_) => answer.future)));
    await tapSquare(tester, 17);
    await tester.tap(find.byKey(const Key('square-37')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('mode-local')));
    await tester.pump();
    answer.complete(const ChessMove(from: 87, to: 67));
    await tester.pumpAndSettle();
    expect(boardOf(tester).position.turn, Side.black);
    expect(boardOf(tester).position.pieceAt(87)?.side, Side.black);
    expect(boardOf(tester).enabled, isTrue);
    await tapSquare(tester, 87);
    await tapSquare(tester, 67);
    expect(boardOf(tester).position.turn, Side.white);
  });

  testWidgets('compact phone and landscape layouts remain scrollable without overflow', (tester) async {
    await launchGame(tester, size: const Size(320, 568));
    expect(tester.getSize(find.byType(ChessBoard)).width, 288);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('guide-button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(const Size(667, 375));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('reset-game')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('guide opens with every piece type and scrolls to the cannon', (tester) async {
    await launchGame(tester);
    await tester.tap(find.byKey(const Key('guide-button-header')));
    await tester.pumpAndSettle();
    expect(find.text('Справочник фигур'), findsOneWidget);
    for (final type in PieceType.values) {
      expect(find.text('${type.label} · ${type.code}'), findsOneWidget);
    }
    final cannon = find.text('${PieceType.cannon.label} · ${PieceType.cannon.code}');
    await tester.ensureVisible(cannon);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
