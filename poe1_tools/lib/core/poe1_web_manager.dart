import 'package:flutter/foundation.dart' show mustCallSuper;
import 'package:game_tools_lib/domain/game/web_manager.dart';

// todo: check if something could be moved to shared tool
base class Poe1WebManager extends WebManager {
  @override
  @mustCallSuper
  Future<void> init() async {
    await super.init();
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    await super.dispose();
  }
}
