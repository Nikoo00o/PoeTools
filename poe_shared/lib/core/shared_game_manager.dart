import 'package:flutter/foundation.dart' show mustCallSuper, protected;
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

base mixin SharedGameManager<CType extends GameToolsConfigBaseType> on GameManager<CType> {

  static List<BaseInputListener<dynamic>> get createInputListener => <BaseInputListener<dynamic>>[];

  @override
  @protected
  @mustCallSuper
  List<ModuleBaseType> moduleConfiguration() => <ModuleBaseType>[];

  @override
  @mustCallSuper
  Future<void> onStart() async {}

  @override
  @mustCallSuper
  Future<void> onStop() async {}

  @override
  @mustCallSuper
  Future<void> onUpdate() async {}

  @override
  @mustCallSuper
  Future<void> onOpenChange(GameWindow window) async {}

  @override
  @mustCallSuper
  Future<void> onFocusChange(GameWindow window) async {}

  @override
  @mustCallSuper
  Future<void> onStateChange(GameState oldState, GameState newState) async {}
}
