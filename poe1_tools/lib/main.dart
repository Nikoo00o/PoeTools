import 'package:game_tools_lib/imports.dart';

Future<void> main() async {
  final bool init = await GameToolsLib.initGameToolsLib(gameWindows: <GameWindow>[GameWindow(name: "Path of Exile")]);

  await GameToolsLib.runLoop(app: GTApp(additionalNavigatorPages: <GTNavigationPage>[]));
}
