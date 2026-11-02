import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/chess.dart';
import 'palette.dart';

/// Font-independent chess silhouettes; the code also identifies fairy pieces.
class PieceGlyph extends StatelessWidget {
  const PieceGlyph({super.key, required this.piece, this.size = 44, this.showCode = true});

  final Piece piece;
  final double size;
  final bool showCode;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _PiecePainter(piece, showCode)),
    );
  }
}

class _PiecePainter extends CustomPainter {
  const _PiecePainter(this.piece, this.showCode);

  final Piece piece;
  final bool showCode;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final white = piece.side == Side.white;
    final fill = Paint()..color = white ? const Color(0xFFFFF5DF) : const Color(0xFF23364B);
    final line = Paint()
      ..color = white ? const Color(0xFF344559) : const Color(0xFFF4E4C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    void shape(Path path) {
      canvas.drawPath(path, fill);
      canvas.drawPath(path, line);
    }
    void ellipse(double x, double y, double rx, double ry) {
      final rect = Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2);
      canvas.drawOval(rect, fill);
      canvas.drawOval(rect, line);
    }
    void stroke(List<Offset> points, {bool closed = false}) {
      final path = Path()..addPolygon(points, closed);
      canvas.drawPath(path, line);
    }
    void body({double top = 43, double width = 12}) {
      shape(Path()
        ..moveTo(50 - width, top)
        ..lineTo(50 + width, top)
        ..quadraticBezierTo(58, 62, 69, 74)
        ..lineTo(31, 74)
        ..quadraticBezierTo(42, 62, 50 - width, top)
        ..close());
    }
    void base() {
      shape(Path()
        ..moveTo(30, 75)
        ..lineTo(70, 75)
        ..lineTo(76, 84)
        ..lineTo(24, 84)
        ..close());
    }
    void rookTop() {
      shape(Path()
        ..moveTo(30, 23)..lineTo(40, 23)..lineTo(40, 32)
        ..lineTo(46, 32)..lineTo(46, 23)..lineTo(55, 23)
        ..lineTo(55, 32)..lineTo(61, 32)..lineTo(61, 23)
        ..lineTo(71, 23)..lineTo(67, 48)..lineTo(34, 48)..close());
    }
    void bishopTop() {
      shape(Path()
        ..moveTo(50, 16)
        ..cubicTo(24, 35, 30, 49, 50, 51)
        ..cubicTo(70, 49, 76, 35, 50, 16)..close());
      stroke(const [Offset(52, 25), Offset(43, 39)]);
    }
    void horse({bool longNeck = false}) {
      shape(Path()
        ..moveTo(31, 73)..lineTo(66, 73)
        ..cubicTo(70, 55, 70, longNeck ? 22 : 35, 57, 25)
        ..lineTo(56, 15)..lineTo(46, 26)..lineTo(39, 27)
        ..lineTo(24, 48)..lineTo(32, 55)..lineTo(45, 47)
        ..quadraticBezierTo(43, 60, 31, 73)..close());
      canvas.drawCircle(const Offset(47, 35), 2.3, line..style = PaintingStyle.fill);
      line.style = PaintingStyle.stroke;
    }

    switch (piece.type) {
      case PieceType.king:
        body(top: 40);
        ellipse(50, 36, 15, 10);
        stroke(const [Offset(50, 12), Offset(50, 29)]);
        stroke(const [Offset(42, 19), Offset(58, 19)]);
      case PieceType.queen:
        body(top: 43, width: 15);
        shape(Path()..moveTo(35, 48)..lineTo(27, 23)..lineTo(43, 35)
          ..lineTo(50, 18)..lineTo(57, 35)..lineTo(73, 23)..lineTo(65, 48)..close());
        for (final x in [27.0, 50.0, 73.0]) {
          ellipse(x, x == 50 ? 17 : 22, 3.5, 3.5);
        }
      case PieceType.rook:
        body(top: 42, width: 14);
        rookTop();
      case PieceType.bishop:
        body(top: 44);
        bishopTop();
      case PieceType.knight:
        horse();
      case PieceType.pawn:
        body(top: 42, width: 10);
        ellipse(50, 31, 12, 12);
      case PieceType.archbishop:
        body(top: 46, width: 15);
        bishopTop();
        stroke(const [Offset(31, 47), Offset(22, 30), Offset(34, 36)]);
        stroke(const [Offset(69, 47), Offset(78, 30), Offset(66, 36)]);
      case PieceType.chancellor:
        body(top: 42, width: 17);
        rookTop();
        shape(Path()..moveTo(38, 67)..lineTo(57, 67)..lineTo(60, 48)
          ..lineTo(53, 39)..lineTo(44, 45)..lineTo(35, 56)..lineTo(42, 59)
          ..lineTo(48, 54)..close());
      case PieceType.guard:
        shape(Path()..moveTo(50, 20)..lineTo(74, 29)..lineTo(70, 53)
          ..quadraticBezierTo(66, 68, 50, 77)
          ..quadraticBezierTo(34, 68, 30, 53)..lineTo(26, 29)..close());
        stroke(const [Offset(50, 32), Offset(50, 62)]);
        stroke(const [Offset(39, 46), Offset(61, 46)]);
      case PieceType.wazir:
        body(top: 45);
        shape(Path()..moveTo(40, 18)..lineTo(60, 18)..lineTo(60, 32)
          ..lineTo(73, 32)..lineTo(73, 46)..lineTo(27, 46)
          ..lineTo(27, 32)..lineTo(40, 32)..close());
      case PieceType.advisor:
        body(top: 45);
        shape(Path()..moveTo(50, 17)..lineTo(72, 38)..lineTo(50, 57)
          ..lineTo(28, 38)..close());
        ellipse(50, 38, 5, 5);
      case PieceType.elephant:
        body(top: 47, width: 17);
        ellipse(33, 37, 12, 17);
        ellipse(67, 37, 12, 17);
        shape(Path()..moveTo(37, 24)..quadraticBezierTo(50, 15, 63, 24)
          ..lineTo(61, 47)..lineTo(56, 47)..lineTo(57, 64)
          ..quadraticBezierTo(50, 74, 42, 64)..lineTo(44, 59)
          ..quadraticBezierTo(50, 63, 49, 57)..lineTo(47, 47)..lineTo(39, 47)..close());
      case PieceType.dabbaba:
        shape(Path()..moveTo(27, 71)..lineTo(30, 36)..lineTo(41, 36)
          ..lineTo(41, 26)..lineTo(59, 26)..lineTo(59, 36)
          ..lineTo(70, 36)..lineTo(73, 71)..close());
        ellipse(39, 65, 7, 7);
        ellipse(61, 65, 7, 7);
        stroke(const [Offset(38, 45), Offset(62, 45)]);
      case PieceType.camel:
        horse(longNeck: true);
        shape(Path()..moveTo(43, 60)..quadraticBezierTo(34, 41, 26, 61)
          ..lineTo(24, 73)..lineTo(47, 73)..close());
      case PieceType.zebra:
        horse();
        stroke(const [Offset(60, 40), Offset(66, 47)]);
        stroke(const [Offset(56, 49), Offset(65, 58)]);
        stroke(const [Offset(51, 58), Offset(62, 68)]);
      case PieceType.lancer:
        body(top: 52, width: 9);
        shape(Path()..moveTo(50, 13)..lineTo(61, 34)..lineTo(54, 42)
          ..lineTo(54, 66)..lineTo(46, 66)..lineTo(46, 42)
          ..lineTo(39, 34)..close());
        stroke(const [Offset(36, 48), Offset(64, 48)]);
      case PieceType.scout:
        body(top: 52);
        shape(Path()..moveTo(28, 39)..lineTo(42, 24)..lineTo(50, 34)
          ..lineTo(58, 24)..lineTo(72, 39)..lineTo(59, 54)
          ..lineTo(50, 44)..lineTo(41, 54)..close());
        stroke(const [Offset(42, 24), Offset(42, 15)]);
        stroke(const [Offset(58, 24), Offset(58, 15)]);
      case PieceType.cannon:
        shape(Path()..moveTo(31, 59)..lineTo(27, 33)..lineTo(74, 20)
          ..lineTo(79, 38)..lineTo(42, 51)..lineTo(48, 65)..close());
        ellipse(48, 64, 15, 15);
        ellipse(48, 64, 5, 5);
        stroke(const [Offset(72, 23), Offset(76, 35)]);
    }
    base();
    canvas.restore();

    if (showCode) {
      final painter = TextPainter(
        text: TextSpan(
          text: piece.type.code,
          style: TextStyle(
            color: piece.side == Side.white ? Palette.background : Palette.ivory,
            fontSize: math.max(7.0, size.width * .16),
            fontWeight: FontWeight.w800,
            fontFamily: 'sans-serif',
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = size.width * .85 - painter.width / 2;
      final y = size.height * .79;
      final backing = Paint()
        ..color = piece.side == Side.white ? Palette.ivory : Palette.background;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 2, y - 1, painter.width + 4, painter.height + 2), const Radius.circular(2)),
        backing,
      );
      painter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _PiecePainter oldDelegate) =>
      oldDelegate.piece.side != piece.side || oldDelegate.piece.type != piece.type || oldDelegate.showCode != showCode;
}
