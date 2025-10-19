import 'package:game_tools_lib/imports.dart';
import 'package:poe1_tools/core/config/poe1_fixed_config.dart';
import 'package:poe1_tools/core/config/poe1_mutable_config.dart';
import 'package:poe1_tools/core/config/poe1_tools_config.dart';
import 'package:poe1_tools/core/poe1_app.dart';
import 'package:poe1_tools/core/poe1_config_loader.dart';
import 'package:poe1_tools/core/poe1_game_manager.dart';
import 'package:poe1_tools/core/poe1_log_watcher.dart';
import 'package:poe1_tools/core/poe1_logger.dart';
import 'package:poe1_tools/core/poe1_web_manager.dart';
import 'package:poe_shared/core/poe_overlay_manager.dart';

Future<void> main() async {
  try {
    final String cfg = await FileUtils.getDocumentsPath(<String>["My Games", "Path of Exile", "production_Config.ini"]);

    final bool init = await GameToolsLib.initGameToolsLib(
      config: Poe1ToolsConfigT(fixed: const Poe1FixedConfig(), mutable: Poe1MutableConfig()),
      gameManager: Poe1GameManagerT(),
      overlayManager: PoeOverlayManager(),
      logger: Poe1Logger(),
      gameWindows: <GameWindow>[GameWindow(name: "Path of Exile")],
      gameLogWatcher: Poe1LogWatcher(),
      gameConfigLoader: Poe1ConfigLoader(filePath: cfg),
      webManager: Poe1WebManager(),
    );
    if (init == false) {
      Logger.error("Could not initialize PoeTools");
    } else {
      await GameToolsLib.runLoop(app: const Poe1App());
    }
  } catch (e, s) {
    Logger.error("Main Error: ", e, s);
  }
}
