import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/game_controller.dart';
import '../services/music.dart';
import '../mascot/mascot_controller.dart';
import '../theme.dart';
import '../widgets/gingham.dart';
import '../widgets/marelle_trail.dart';
import '../widgets/mascot_view.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/swipe_card.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.game, required this.mascot, required this.music});

  final GameController game;
  final MascotController mascot;
  final Music music;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final StreamSubscription<GameEvent> _sub;
  Timer? _celebrateTimer;
  bool _showCelebrate = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.game.events.listen(_onEvent);
  }

  void _onEvent(GameEvent event) {
    widget.mascot.onGameEvent(event);
    if (event.type == GameEventType.roundComplete) {
      _celebrateTimer?.cancel();
      _celebrateTimer = Timer(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _showCelebrate = true);
      });
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    _celebrateTimer?.cancel();
    super.dispose();
  }

  void _continue() {
    setState(() => _showCelebrate = false);
    widget.game.continueRound();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Candy.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: GinghamBackground()),
            ListenableBuilder(
              listenable: widget.game,
              builder: (context, _) => _buildGame(context),
            ),
            if (_showCelebrate) _buildCelebrate(),
          ],
        ),
      ),
    );
  }

  Widget _buildGame(BuildContext context) {
    final game = widget.game;
    return Column(
      children: [
        _Header(game: game, music: widget.music),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth > 560 ? 520.0 : constraints.maxWidth - 40;
              final mascotSize = (cardWidth * 0.34).clamp(110.0, 170.0).toDouble();
              // The mascot stands on the card's top edge, so the stack reserves
              // his height ([mascotSize]) above the card.
              final cardHeight = (constraints.maxHeight - mascotSize - 12).clamp(170.0, 360.0).toDouble();
              return Center(
                child: SizedBox(
                  width: cardWidth,
                  height: mascotSize + cardHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // drawn first = behind the card
                      MascotView(
                        controller: widget.mascot,
                        size: mascotSize,
                        cardTop: mascotSize,
                      ),
                      Positioned(
                        top: mascotSize,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SwipeCard(
                          word: game.word,
                          height: cardHeight,
                          enabled: !game.roundComplete,
                          onKnown: game.known,
                          onAgain: game.again,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Text(
            'Touche le mot, ou glisse :  → je le sais   ← encore',
            textAlign: TextAlign.center,
            style: Candy.body(13, color: Candy.textA(0.65)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: MarelleTrail(total: GameController.casesPerRound, done: game.roundProgress),
        ),
      ],
    );
  }

  Widget _buildCelebrate() {
    final game = widget.game;
    return Positioned.fill(
      child: Container(
        color: const Color(0xF2FFE1EA),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bravo ! 🎉', style: Candy.display(44, color: Candy.berry)),
            const SizedBox(height: 12),
            Text(
              '${GameController.casesPerRound} mots lus dans cette manche ! On continue ?',
              textAlign: TextAlign.center,
              style: Candy.body(16),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: Candy.sticker(radius: 14),
              child: Text(
                '🏆 Record de série : ${game.best} mots d\'affilée',
                style: Candy.display(15, color: Candy.berry, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: _continue,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: Candy.sticker(fill: Candy.yellow, radius: 14),
                child: Text('Continuer', style: Candy.display(18, color: Candy.ink, weight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.game, required this.music});

  final GameController game;
  final Music music;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: Candy.display(30),
                        children: [
                          const TextSpan(text: 'La Marelle des '),
                          TextSpan(text: 'Mots', style: Candy.display(30, color: Candy.berry)),
                        ],
                      ),
                    ),
                    Text(
                      'Lecture rapide',
                      style: Candy.body(13, color: Candy.textA(0.6)),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => showSettingsSheet(context, game, music),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: Candy.sticker(radius: 14, lift: 2),
                  child: const Text('⚙️', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(value: game.score, label: 'mots'),
              _Stat(value: game.streak, label: 'série'),
              _Stat(value: game.best, label: 'record'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: Candy.sticker(radius: 14, lift: 2),
      child: Column(
        children: [
          Text('$value', style: Candy.display(20, color: Candy.berry)),
          Text(
            label.toUpperCase(),
            style: Candy.body(10, color: Candy.textA(0.55), weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
