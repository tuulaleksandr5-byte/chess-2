import 'package:flutter/material.dart';

import '../game/chess.dart';
import 'palette.dart';
import 'piece_glyph.dart';

class ChessBoard extends StatelessWidget {
  const ChessBoard({
    super.key,
    required this.position,
    required this.legalMoves,
    required this.onSquareTap,
    this.selected,
    this.lastMove,
    this.flipped = false,
    this.inCheck = false,
    this.enabled = true,
  });

  final Position position;
  final List<ChessMove> legalMoves;
  final ValueChanged<int> onSquareTap;
  final int? selected;
  final ChessMove? lastMove;
  final bool flipped;
  final bool inCheck;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final destinations = selected == null
        ? <int>{}
        : legalMoves.where((move) => move.from == selected).map((move) => move.to).toSet();
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.raised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.border),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 28, offset: Offset(0, 12))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LayoutBuilder(builder: (context, constraints) {
              final cellSize = constraints.maxWidth / 10;
              return GridView.builder(
                key: const Key('chess-board'),
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
                itemCount: 100,
                itemBuilder: (context, index) {
                  final row = index ~/ 10;
                  final column = index % 10;
                  final rank = flipped ? row : 9 - row;
                  final file = flipped ? 9 - column : column;
                  final square = rank * 10 + file;
                  final piece = position.pieceAt(square);
                  final isLight = (rank + file).isOdd;
                  final isSelected = selected == square;
                  final isLast = lastMove?.from == square || lastMove?.to == square;
                  final isChecked = inCheck && piece?.type == PieceType.king && piece?.side == position.turn;
                  final legal = destinations.contains(square);
                  final label = '${squareName(square)}, '
                      '${piece == null ? 'пусто' : '${piece.side == Side.white ? 'белые' : 'чёрные'}, ${piece.type.label}'}'
                      '${legal ? ', доступный ход' : ''}${isChecked ? ', шах' : ''}';
                  final base = isLight ? Palette.lightSquare : Palette.darkSquare;
                  final background = isChecked
                      ? Color.alphaBlend(Palette.danger.withValues(alpha: .62), base)
                      : isSelected
                          ? Color.alphaBlend(Palette.gold.withValues(alpha: .75), base)
                          : isLast
                              ? Color.alphaBlend(Palette.gold.withValues(alpha: .42), base)
                              : base;
                  final coordinateColor = isLight ? const Color(0xFF52645D) : const Color(0xFF1E332C);
                  return Semantics(
                    label: label,
                    button: true,
                    selected: isSelected,
                    enabled: enabled,
                    onTap: enabled ? () => onSquareTap(square) : null,
                    child: Material(
                      color: background,
                      child: InkWell(
                        key: Key('square-$square'),
                        onTap: enabled ? () => onSquareTap(square) : null,
                        excludeFromSemantics: true,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (piece != null)
                              Center(child: PieceGlyph(piece: piece, size: cellSize * .94)),
                            if (legal)
                              Center(
                                child: Container(
                                  width: piece == null ? cellSize * .23 : cellSize * .87,
                                  height: piece == null ? cellSize * .23 : cellSize * .87,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: piece == null ? Palette.background.withValues(alpha: .3) : null,
                                    border: piece == null
                                        ? null
                                        : Border.all(color: Palette.background.withValues(alpha: .48), width: 3),
                                  ),
                                ),
                              ),
                            if (isSelected)
                              DecoratedBox(decoration: BoxDecoration(border: Border.all(color: const Color(0xFF9D6F25), width: 2))),
                            if (column == 0)
                              Positioned(
                                left: 2,
                                top: 1,
                                child: ExcludeSemantics(
                                  child: Text('${rank + 1}', textScaler: TextScaler.noScaling,
                                    style: TextStyle(fontSize: cellSize < 35 ? 7 : 9, height: 1, color: coordinateColor, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            if (row == 9)
                              Positioned(
                                right: 2,
                                bottom: 1,
                                child: ExcludeSemantics(
                                  child: Text(String.fromCharCode(97 + file), textScaler: TextScaler.noScaling,
                                    style: TextStyle(fontSize: cellSize < 35 ? 7 : 9, height: 1, color: coordinateColor, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            if (isChecked)
                              Positioned(right: 2, top: 1,
                                child: Text('!', textScaler: TextScaler.noScaling,
                                  style: TextStyle(color: Palette.background, fontWeight: FontWeight.w900, fontSize: cellSize * .25))),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}
