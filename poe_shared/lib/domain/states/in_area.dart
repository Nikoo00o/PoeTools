import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

final class InGameState extends GameState {
  @override
  Future<void> onStart(GameState oldState) async {
    super.onStart(oldState);
    // test
  }

  @override
  Future<void> onStop(GameState newState) async {}

  @override
  Future<void> onOpenChange(GameWindow window) async {}

  @override
  Future<void> onFocusChange(GameWindow window) async {}

  @override
  Future<void> onUpdate() async {}

  @override
  String get welcomeMessage => "Switched to $runtimeType";
}
