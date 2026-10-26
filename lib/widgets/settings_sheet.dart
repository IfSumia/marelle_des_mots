import 'package:flutter/material.dart';

import '../logic/deck_settings.dart';
import '../logic/game_controller.dart';
import '../logic/word_pool.dart';
import '../services/music.dart';
import '../theme.dart';

/// Parent settings: which lessons go into the deck.
Future<void> showSettingsSheet(BuildContext context, GameController game, Music music) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Candy.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _SettingsSheet(game: game, music: music),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({required this.game, required this.music});

  final GameController game;
  final Music music;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late DeckSettings _draft = widget.game.settings;
  late final TextEditingController _text = TextEditingController(text: _draft.customText);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  GameController get _game => widget.game;

  bool _isOn(int number) =>
      _draft.cumulative ? number <= _draft.upTo : _draft.picked.contains(number);

  void _tapLesson(int number) {
    setState(() {
      if (_draft.cumulative) {
        _draft = _draft.copyWith(upTo: number);
      } else {
        final next = {..._draft.picked};
        if (!next.add(number)) next.remove(number);
        _draft = _draft.copyWith(picked: next);
      }
    });
  }

  void _setCumulative(bool value) {
    setState(() {
      if (value) {
        // "up to" the highest lesson that was ticked
        final highest = _draft.picked.isEmpty
            ? _draft.upTo
            : _draft.picked.reduce((a, b) => a > b ? a : b);
        _draft = _draft.copyWith(cumulative: true, upTo: highest);
      } else {
        // keep exactly what was selected, now as individual ticks
        final ticked = {
          for (final l in _game.library.lessons)
            if ((l.number ?? 0) <= _draft.upTo) l.number!,
        };
        _draft = _draft.copyWith(cumulative: false, picked: ticked);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final library = _game.library;
    final draft = _draft.copyWith(customText: _text.text);
    final count = buildPool(library, draft).length;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Réglages', style: Candy.display(24)),
              const SizedBox(height: 14),
              _label('Leçons'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final lesson in library.lessons)
                    _Chip(
                      label: '${lesson.number}',
                      on: _isOn(lesson.number!),
                      strong: _draft.cumulative && lesson.number == _draft.upTo,
                      onTap: () => _tapLesson(lesson.number!),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Candy.yellow,
                title: Text('Cumulatif', style: Candy.body(16)),
                subtitle: Text(
                  _draft.cumulative
                      ? 'Touche une leçon : toutes les leçons jusque-là sont incluses.'
                      : 'Touche les leçons une par une pour les choisir.',
                  style: Candy.body(12, color: Candy.textA(0.6)),
                ),
                value: _draft.cumulative,
                onChanged: _setCumulative,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Candy.yellow,
                title: Text('Musique', style: Candy.body(16)),
                value: widget.music.enabled,
                onChanged: (v) async {
                  await widget.music.setEnabled(v);
                  if (mounted) setState(() {});
                },
              ),
              _label('En plus'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    label: 'Mots outils',
                    on: _draft.toolWords,
                    onTap: () => setState(() => _draft = _draft.copyWith(toolWords: !_draft.toolWords)),
                  ),
                  _Chip(
                    label: 'Mes mots à moi',
                    on: _draft.customWords,
                    onTap: () => setState(() => _draft = _draft.copyWith(customWords: !_draft.customWords)),
                  ),
                ],
              ),
              if (_draft.customWords) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _text,
                  minLines: 3,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                  style: Candy.body(14),
                  cursorColor: Candy.yellow,
                  decoration: InputDecoration(
                    hintText: 'Colle ici des mots séparés par des espaces ou des virgules…',
                    hintStyle: Candy.body(14, color: Candy.textA(0.35)),
                    filled: true,
                    fillColor: Candy.textA(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Candy.textA(0.2), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Candy.textA(0.2), width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Candy.yellow, width: 2),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                '$count mots dans le paquet',
                style: Candy.body(13, color: Candy.textA(0.6)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Button(
                    label: 'Appliquer',
                    primary: true,
                    onTap: () {
                      _game.applySettings(draft);
                      Navigator.of(context).pop();
                    },
                  ),
                  _Button(
                    label: 'Mélanger',
                    onTap: () {
                      _game.shuffle();
                      Navigator.of(context).pop();
                    },
                  ),
                  _Button(
                    label: 'Réinitialiser le score',
                    onTap: () {
                      _game.resetScore();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: Candy.body(12, color: Candy.berry, weight: FontWeight.w800),
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on, required this.onTap, this.strong = false});

  final String label;
  final bool on;
  final bool strong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = !on
        ? const Color(0x00000000)
        : strong
            ? Candy.yellow
            : Candy.textA(0.22);
    final textColor = on && strong ? Candy.ink : Candy.text;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? fill : Candy.textA(0.3), width: 2),
        ),
        child: Text(label, style: Candy.display(16, color: textColor, weight: FontWeight.w700)),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onTap, this.primary = false});

  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: primary ? Candy.yellow : Candy.textA(0.15),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x40000000), offset: Offset(0, 3))],
        ),
        child: Text(
          label,
          style: Candy.display(14, color: primary ? Candy.ink : Candy.text, weight: FontWeight.w700),
        ),
      ),
    );
  }
}
