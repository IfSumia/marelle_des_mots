import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/lessons.dart';
import 'logic/game_controller.dart';
import 'mascot/mascot_controller.dart';
import 'mascot/sprite_library.dart';
import 'screens/game_screen.dart';
import 'services/sfx.dart';
import 'services/store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final library = await LessonLibrary.load();
  final store = await Store.open();

  // Sound or sprites failing must never stop the game from starting.
  Sfx sfx = AudioSfx();
  try {
    await sfx.init();
  } catch (e) {
    debugPrint('Audio unavailable: $e');
    sfx = SilentSfx();
  }

  var sprites = SpriteLibrary.empty;
  try {
    sprites = await SpriteLibrary.load();
  } catch (e) {
    debugPrint('Sprites unavailable: $e');
  }

  final game = GameController(library: library, store: store, sfx: sfx)..init();
  final mascot = MascotController(sprites: sprites, sfx: sfx);

  runApp(MarelleApp(game: game, mascot: mascot));
}

class MarelleApp extends StatelessWidget {
  const MarelleApp({super.key, required this.game, required this.mascot});

  final GameController game;
  final MascotController mascot;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'La Marelle des Mots',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Chalk.green,
        useMaterial3: true,
      ),
      home: GameScreen(game: game, mascot: mascot),
    );
  }
}
