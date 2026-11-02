import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/chess.dart';
import 'palette.dart';
import 'piece_glyph.dart';

Future<void> showPieceGuide(BuildContext context) => showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 760, maxHeight: MediaQuery.sizeOf(context).height * .88),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Row(children: [
                  const Expanded(child: Text('Справочник фигур', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
                  IconButton(tooltip: 'Закрыть справочник', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Знакомая игра. Больше возможностей.', style: TextStyle(color: Palette.gold, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Поле 10 × 10, по 20 фигур. Белые начинают. Цель — поставить мат королю. '
                      'Моря и рокировки нет. Пешка может сделать первый ход на две клетки с 2-го или 9-го ряда; '
                      'взятие на проходе доступно сразу после такого хода. На последнем ряду пешка превращается в одну из 16 фигур.'),
                    const SizedBox(height: 12),
                    const Text('Точка показывает ход, кольцо — взятие. Прыгающие фигуры могут проходить над другими. '
                      'Буква на фигурке совпадает с обозначением в этом справочнике.', style: TextStyle(color: Palette.muted)),
                    const SizedBox(height: 24),
                    for (final type in PieceType.values) _GuideEntry(type: type),
                    const SizedBox(height: 8),
                    const Text('Ничья: пат, трёхкратное повторение позиции, 50 ходов без взятия и движения пешек или два голых короля.',
                      style: TextStyle(color: Palette.muted)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );

class _GuideEntry extends StatelessWidget {
  const _GuideEntry({required this.type});
  final PieceType type;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 56, height: 60,
          decoration: BoxDecoration(color: Palette.raised, borderRadius: BorderRadius.circular(12)),
          child: Center(child: PieceGlyph(piece: Piece(Side.white, type), size: 48)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${type.label} · ${type.code}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 3),
          Text(type.description),
          const SizedBox(height: 3),
          Text(type == PieceType.king ? 'Ценность: короля необходимо сохранить' : 'Ценность: ≈ ${type.value.toStringAsFixed(type.value % 1 == 0 ? 0 : 1)} пешек',
            style: const TextStyle(color: Palette.gold, fontSize: 12)),
          const SizedBox(height: 3),
          Text(type.balance, style: const TextStyle(color: Palette.muted, fontSize: 12)),
        ])),
      ]),
    );
  }
}

Future<PieceType?> choosePromotion(BuildContext context, Side side) => showDialog<PieceType>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 640, maxHeight: MediaQuery.sizeOf(context).height * .86),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(children: [
                const Expanded(child: Text('Превращение пешки', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                IconButton(tooltip: 'Отменить выбор', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Выберите одну из 16 фигур.', style: TextStyle(color: Palette.muted))),
            const SizedBox(height: 12),
            Flexible(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: LayoutBuilder(builder: (context, constraints) {
                final columns = math.max(2, math.min(4, (constraints.maxWidth / 130).floor()));
                final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
                return Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final type in PieceType.values.where((type) => type != PieceType.king && type != PieceType.pawn))
                    SizedBox(width: width, child: Material(
                      color: Palette.raised,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        key: Key('promote-${type.code}'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.pop(context, type),
                        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                          child: Column(children: [
                            PieceGlyph(piece: Piece(side, type), size: 48),
                            const SizedBox(height: 4),
                            Text(type.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                          ])),
                      ),
                    )),
                ]);
              }),
            )),
          ]),
        ),
      ),
    );
