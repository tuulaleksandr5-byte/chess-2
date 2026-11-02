import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game/bot.dart';
import '../game/chess.dart';
import 'chess_board.dart';
import 'palette.dart';
import 'piece_glyph.dart';
import 'piece_guide.dart';

typedef BotMoveRunner = Future<ChessMove?> Function(BotRequest request);

Future<ChessMove?> _computeMove(BotRequest request) => compute(computeBotMove, request);

class ChessScreen extends StatefulWidget {
  const ChessScreen({super.key, this.botMoveRunner = _computeMove});

  final BotMoveRunner botMoveRunner;

  @override
  State<ChessScreen> createState() => _ChessScreenState();
}

class _ChessScreenState extends State<ChessScreen> {
  final List<Position> _positions = [Position.initial()];
  final List<ChessMove> _history = [];
  final TransformationController _boardTransform = TransformationController();
  List<ChessMove> _legalMoves = [];
  GameResult? _result;
  bool _inCheck = false;
  bool _versusBot = true;
  bool _flipped = false;
  bool _botThinking = false;
  bool _botError = false;
  int _difficulty = 2;
  int _generation = 0;
  int? _selected;

  Position get _position => _positions.last;
  bool get _canPlay => _result == null && !_botThinking && (!_versusBot || _position.turn == Side.white);

  @override
  void initState() {
    super.initState();
    _refreshPosition();
  }

  @override
  void dispose() {
    _generation++;
    _boardTransform.dispose();
    super.dispose();
  }

  void _refreshPosition() {
    _legalMoves = _position.legalMoves();
    _result = _position.result;
    _inCheck = _position.isInCheck(_position.turn);
  }

  void _invalidateBot() {
    _generation++;
    _botThinking = false;
    _botError = false;
  }

  void _newGame() {
    setState(() {
      _invalidateBot();
      _positions
        ..clear()
        ..add(Position.initial());
      _history.clear();
      _selected = null;
      _refreshPosition();
    });
    _boardTransform.value = Matrix4.identity();
  }

  void _changeMode(bool versusBot) {
    if (_versusBot == versusBot) return;
    setState(() {
      _invalidateBot();
      _versusBot = versusBot;
      _selected = null;
    });
    _scheduleBot();
  }

  void _changeDifficulty(int value) {
    if (value == _difficulty) return;
    setState(() {
      _invalidateBot();
      _difficulty = value;
    });
    _scheduleBot();
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _invalidateBot();
      var restoreIndex = _positions.length - 2;
      if (_versusBot) {
        while (restoreIndex > 0 && _positions[restoreIndex].turn != Side.white) {
          restoreIndex--;
        }
      }
      _positions.removeRange(restoreIndex + 1, _positions.length);
      _history.removeRange(restoreIndex, _history.length);
      _selected = null;
      _refreshPosition();
    });
    _scheduleBot();
  }

  Future<void> _tapSquare(int square) async {
    if (!_canPlay) return;
    final available = _legalMoves.where((move) => move.from == _selected && move.to == square).toList();
    if (available.isNotEmpty) {
      var move = available.first;
      if (move.promotion != null) {
        final generation = _generation;
        final position = _position;
        final promotion = await choosePromotion(context, _position.turn);
        if (!mounted || promotion == null || generation != _generation || !identical(position, _position)) return;
        move = available.firstWhere((candidate) => candidate.promotion == promotion);
      }
      _applyMove(move);
      return;
    }
    final piece = _position.pieceAt(square);
    setState(() => _selected = piece?.side == _position.turn && _selected != square ? square : null);
  }

  void _applyMove(ChessMove move) {
    setState(() {
      _generation++;
      _positions.add(_position.play(move));
      _history.add(move);
      _selected = null;
      _botThinking = false;
      _botError = false;
      _refreshPosition();
    });
    _scheduleBot();
  }

  Future<void> _scheduleBot() async {
    if (!mounted || !_versusBot || _position.turn != Side.black || _result != null || _botThinking) return;
    final generation = ++_generation;
    final position = _position;
    setState(() {
      _botThinking = true;
      _botError = false;
    });
    try {
      final move = await widget.botMoveRunner(BotRequest(position, _difficulty));
      if (!mounted || generation != _generation) return;
      if (move != null && _legalMoves.contains(move)) {
        _applyMove(move);
      } else {
        setState(() {
          _botThinking = false;
          _botError = _result == null && _legalMoves.isNotEmpty;
        });
      }
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _botThinking = false;
        _botError = true;
      });
    }
  }

  String get _status {
    if (_result case final result?) {
      return switch (result.outcome) {
        GameOutcome.checkmate => result.winner == Side.white ? 'Мат. Белые победили' : 'Мат. Чёрные победили',
        GameOutcome.stalemate => 'Ничья — пат',
        GameOutcome.repetition => 'Ничья — повторение позиции',
        GameOutcome.fiftyMoves => 'Ничья — правило 50 ходов',
        GameOutcome.insufficientMaterial => 'Ничья — два короля',
      };
    }
    if (_botThinking) return 'Бот обдумывает ход';
    if (_botError) return 'Не удалось получить ход бота';
    if (_inCheck) return _position.turn == Side.white ? 'Шах белому королю' : 'Шах чёрному королю';
    return _position.turn == Side.white ? 'Ход белых' : 'Ход чёрных';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(-.5, -.9), radius: 1.4,
            colors: [Color(0xFF192D43), Palette.background]),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final roomy = constraints.maxWidth >= 1120 && MediaQuery.textScalerOf(context).scale(1) < 1.5;
            final gutter = constraints.maxWidth < 600 ? 16.0 : 32.0;
            return SingleChildScrollView(
              key: const Key('game-scroll'),
              padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1480),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _header(constraints.maxWidth),
                    const SizedBox(height: 26),
                    if (roomy)
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(width: 244, child: Column(children: [_settingsCard(), const SizedBox(height: 16), _discoveryCard()])),
                        const SizedBox(width: 24),
                        Expanded(child: Center(child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: math.max(360, constraints.maxHeight - 280)),
                          child: _boardSection(),
                        ))),
                        const SizedBox(width: 24),
                        SizedBox(width: 244, child: Column(children: [_gameCard(), const SizedBox(height: 16), _historyCard()])),
                      ])
                    else ...[
                      _compactModeBar(),
                      const SizedBox(height: 16),
                      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: _boardSection())),
                      const SizedBox(height: 20),
                      if (constraints.maxWidth >= 760)
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: _settingsCard()),
                          const SizedBox(width: 16),
                          Expanded(child: Column(children: [_gameCard(), const SizedBox(height: 16), _historyCard()])),
                        ])
                      else ...[
                        _gameCard(),
                        const SizedBox(height: 16),
                        _settingsCard(showMode: false),
                        const SizedBox(height: 16),
                        _historyCard(),
                      ],
                      const SizedBox(height: 16),
                      _discoveryCard(),
                    ],
                    const SizedBox(height: 28),
                    const Text('10 × 10 КЛЕТОК    ·    18 ТИПОВ ФИГУР    ·    НОВАЯ ГЛУБИНА ИГРЫ',
                      textAlign: TextAlign.center, style: TextStyle(color: Palette.muted, fontSize: 10, letterSpacing: 1.2)),
                  ]),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _header(double width) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: width < 450 ? 48 : 58,
        height: width < 450 ? 48 : 58,
        decoration: BoxDecoration(color: Palette.gold.withValues(alpha: .1), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Palette.gold.withValues(alpha: .3))),
        child: const Center(child: PieceGlyph(piece: Piece(Side.white, PieceType.king), size: 43, showCode: false)),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Шахматы 2.0', style: TextStyle(fontSize: width < 450 ? 26 : 34, fontWeight: FontWeight.w700, letterSpacing: -.8, height: 1.15)),
        const SizedBox(height: 5),
        const Text('Классика с новым характером', style: TextStyle(color: Palette.muted, fontSize: 12)),
      ])),
      if (width > 620) ...[
        const SizedBox(width: 12),
        OutlinedButton.icon(key: const Key('guide-button-header'), onPressed: () => showPieceGuide(context),
          icon: const Icon(Icons.menu_book_outlined, size: 18), label: const Text('Как играть')),
      ],
    ]);
  }

  Widget _compactModeBar() => Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
    _modeButton(true), _modeButton(false),
    if (_versusBot) Text('Уровень $_difficulty из 3', style: const TextStyle(color: Palette.muted, fontSize: 12)),
  ]);

  Widget _modeButton(bool bot) {
    final selected = _versusBot == bot;
    return OutlinedButton.icon(
      key: Key(bot ? 'mode-bot' : 'mode-local'),
      onPressed: () => _changeMode(bot),
      icon: Icon(bot ? Icons.smart_toy_outlined : Icons.people_outline, size: 18),
      label: Text(bot ? 'Против бота' : 'Вдвоём'),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Palette.gold : Palette.muted,
        backgroundColor: selected ? Palette.gold.withValues(alpha: .1) : Colors.transparent,
        side: BorderSide(color: selected ? Palette.gold.withValues(alpha: .65) : Palette.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _boardSection() {
    final topSide = _flipped ? Side.white : Side.black;
    final bottomSide = topSide.opponent;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _playerRow(topSide),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          transformationController: _boardTransform,
          minScale: 1,
          maxScale: 3,
          child: ChessBoard(
            position: _position,
            legalMoves: _legalMoves,
            selected: _selected,
            lastMove: _history.isEmpty ? null : _history.last,
            flipped: _flipped,
            inCheck: _inCheck,
            enabled: _canPlay,
            onSquareTap: _tapSquare,
          ),
        ),
      ),
      const SizedBox(height: 12),
      _playerRow(bottomSide),
      const SizedBox(height: 12),
      Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (_botThinking)
            const Padding(padding: EdgeInsets.only(right: 9), child: SizedBox.square(dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Palette.gold)))
          else
            Padding(padding: const EdgeInsets.only(right: 7), child: Icon(_result != null ? Icons.flag_outlined : Icons.circle,
              size: _result != null ? 17 : 8, color: _inCheck ? Palette.danger : Palette.gold)),
          Flexible(child: Semantics(liveRegion: true, child: Text(_status,
            key: const Key('turn-status'), style: TextStyle(color: _inCheck ? Palette.danger : Palette.ivory, fontSize: 13)))),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(key: const Key('undo-move'), tooltip: _versusBot ? 'Отменить свой ход и ответ бота' : 'Отменить ход',
            onPressed: _history.isEmpty ? null : _undo, icon: const Icon(Icons.undo, size: 20)),
          IconButton(key: const Key('flip-board'), tooltip: 'Перевернуть доску',
            onPressed: () => setState(() => _flipped = !_flipped), icon: const Icon(Icons.flip_camera_android_outlined, size: 20)),
          IconButton(key: const Key('zoom-board'), tooltip: 'Увеличить / уменьшить доску · можно щипком',
            onPressed: () {
              final zoomed = _boardTransform.value.getMaxScaleOnAxis() > 1.01;
              _boardTransform.value = zoomed ? Matrix4.identity() : Matrix4.diagonal3Values(1.8, 1.8, 1);
            }, icon: const Icon(Icons.zoom_in, size: 21)),
        ]),
      ]),
      if (_botError)
        Padding(padding: const EdgeInsets.only(top: 8), child: OutlinedButton.icon(onPressed: _scheduleBot,
          icon: const Icon(Icons.refresh), label: const Text('Повторить ход бота'))),
      if (_result != null)
        Padding(padding: const EdgeInsets.only(top: 12), child: _panel(child: Column(children: [
          const Icon(Icons.emoji_events_outlined, color: Palette.gold, size: 32),
          const SizedBox(height: 8),
          Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FilledButton(onPressed: _newGame, child: const Text('Сыграть ещё')),
        ]))),
    ]);
  }

  Widget _playerRow(Side side) {
    final active = _position.turn == side && _result == null;
    final count = _position.board.where((piece) => piece?.side == side).length;
    final bot = _versusBot && side == Side.black;
    return Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: Palette.raised, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? Palette.gold.withValues(alpha: .65) : Palette.border)),
        child: Icon(bot ? Icons.smart_toy_outlined : Icons.person_outline, size: 20, color: active ? Palette.gold : Palette.muted)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(side == Side.white ? 'Белые' : 'Чёрные', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text(bot ? 'Бот · ${_difficultyName(_difficulty)}' : (_versusBot ? 'Вы' : 'Игрок ${side == Side.white ? '1' : '2'}'),
          style: const TextStyle(color: Palette.muted, fontSize: 11)),
      ])),
      if (active) Container(
        margin: const EdgeInsets.only(left: 6, right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Palette.gold.withValues(alpha: .12), borderRadius: BorderRadius.circular(6)),
        child: const Text('ХОД', style: TextStyle(color: Palette.gold, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1))),
      Text('$count / 20', style: const TextStyle(color: Palette.muted, fontSize: 11)),
    ]);
  }

  Widget _settingsCard({bool showMode = true}) => _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _eyebrow('ВАША ПАРТИЯ'),
    const SizedBox(height: 14),
    if (showMode) ...[
      const Text('Режим игры', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [_modeButton(true), _modeButton(false)]),
      const SizedBox(height: 22),
    ],
    Text(_versusBot ? 'Сложность бота' : 'Игра на одном устройстве', style: const TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 10),
    if (_versusBot) ...[
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var level = 1; level <= 3; level++)
          ChoiceChip(
            key: Key('difficulty-$level'),
            label: Text('$level · ${_difficultyName(level)}'),
            selected: _difficulty == level,
            onSelected: (_) => _changeDifficulty(level),
            selectedColor: Palette.gold.withValues(alpha: .18),
            labelStyle: TextStyle(fontSize: 12, color: _difficulty == level ? Palette.gold : Palette.muted),
            side: BorderSide(color: _difficulty == level ? Palette.gold.withValues(alpha: .5) : Palette.border),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
          ),
      ]),
      const SizedBox(height: 10),
      Text(switch (_difficulty) {
        1 => 'Для знакомства с новыми фигурами и спокойной практики.',
        2 => 'Продуманные ответы и поиск тактических возможностей.',
        _ => 'Более глубокий расчёт. Боту понадобится немного времени.',
      }, style: const TextStyle(color: Palette.muted, fontSize: 12)),
    ] else
      const Text('Передавайте ход сопернику. При желании переверните доску кнопкой под полем.', style: TextStyle(color: Palette.muted, fontSize: 12)),
    const SizedBox(height: 22),
    FilledButton.icon(key: const Key('reset-game'), onPressed: _newGame,
      icon: const Icon(Icons.add, size: 20), label: const Text('Новая партия')),
    const SizedBox(height: 8),
    const Text('Новая партия начинается с исходной позиции.', textAlign: TextAlign.center,
      style: TextStyle(color: Palette.muted, fontSize: 10)),
  ]));

  Widget _gameCard() {
    final selected = _selected == null ? null : _position.pieceAt(_selected!);
    return _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _eyebrow(selected == null ? 'СЕЙЧАС НА ДОСКЕ' : 'ВЫБРАННАЯ ФИГУРА'),
      const SizedBox(height: 14),
      if (selected != null) ...[
        Row(children: [
          PieceGlyph(piece: selected, size: 44),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(selected.type.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text('${squareName(_selected!)} · ${selected.type.code}', style: const TextStyle(color: Palette.gold, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 10),
        Text(selected.type.description, style: const TextStyle(color: Palette.muted, fontSize: 12)),
      ] else ...[
        Text('Ход ${_position.fullmoveNumber}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(_result != null ? 'Партия завершена' : 'Выберите свою фигуру, затем клетку для хода.', style: const TextStyle(color: Palette.muted, fontSize: 12)),
      ],
      const SizedBox(height: 16),
      const Divider(height: 1),
      const SizedBox(height: 14),
      Wrap(spacing: 16, runSpacing: 8, children: [
        _legend(const Icon(Icons.circle, size: 8, color: Palette.sage), 'Возможный ход'),
        _legend(const Icon(Icons.circle_outlined, size: 14, color: Palette.sage), 'Взятие'),
        _legend(Container(width: 11, height: 11, decoration: BoxDecoration(color: Palette.gold.withValues(alpha: .6), borderRadius: BorderRadius.circular(2))), 'Последний ход'),
      ]),
    ]));
  }

  Widget _historyCard() => _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: _eyebrow('ИСТОРИЯ ХОДОВ')),
      Text('${_history.length}', style: const TextStyle(color: Palette.muted, fontSize: 12)),
    ]),
    const SizedBox(height: 16),
    if (_history.isEmpty)
      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Первый ход — за вами.', style: TextStyle(color: Palette.muted, fontSize: 12)))
    else
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: ListView.builder(
          key: const Key('move-history'),
          shrinkWrap: true,
          itemCount: (_history.length + 1) ~/ 2,
          itemBuilder: (context, row) {
            final whiteIndex = row * 2;
            final blackIndex = whiteIndex + 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              decoration: BoxDecoration(color: row.isEven ? Palette.raised.withValues(alpha: .65) : Colors.transparent,
                borderRadius: BorderRadius.circular(6)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 27, child: Text('${row + 1}.', style: const TextStyle(color: Palette.muted, fontSize: 11))),
                Expanded(child: Text(describeMove(_positions[whiteIndex], _history[whiteIndex]), style: const TextStyle(fontSize: 11))),
                const SizedBox(width: 8),
                Expanded(child: Text(blackIndex < _history.length ? describeMove(_positions[blackIndex], _history[blackIndex]) : '—',
                  style: const TextStyle(fontSize: 11, color: Palette.muted))),
              ]),
            );
          },
        ),
      ),
  ]));

  Widget _discoveryCard() => _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _eyebrow('ОТКРОЙТЕ НОВЫЕ ФИГУРЫ'),
    const SizedBox(height: 12),
    Wrap(spacing: 3, runSpacing: 4, children: [
      for (final type in [PieceType.archbishop, PieceType.chancellor, PieceType.camel, PieceType.cannon])
        PieceGlyph(piece: Piece(Side.white, type), size: 40),
    ]),
    const SizedBox(height: 10),
    const Text('18 характеров на одной доске', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    const Text('Архиепископ, канцлер, пушка и другие фигуры открывают новые сочетания и тактику.',
      style: TextStyle(color: Palette.muted, fontSize: 12)),
    const SizedBox(height: 14),
    OutlinedButton.icon(key: const Key('guide-button'), onPressed: () => showPieceGuide(context),
      icon: const Icon(Icons.menu_book_outlined, size: 18), label: const Text('Все фигуры и правила')),
  ]));

  Widget _panel({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Palette.panel.withValues(alpha: .94), borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Palette.border.withValues(alpha: .85))),
    child: child,
  );

  Widget _eyebrow(String text) => Text(text, style: const TextStyle(color: Palette.gold, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700));

  Widget _legend(Widget marker, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
    SizedBox(width: 14, height: 16, child: Center(child: marker)),
    const SizedBox(width: 5),
    Text(text, style: const TextStyle(color: Palette.muted, fontSize: 10)),
  ]);

  String _difficultyName(int level) => switch (math.max(1, math.min(level, 3))) {
    1 => 'Лёгкий',
    2 => 'Средний',
    _ => 'Сильный',
  };
}
