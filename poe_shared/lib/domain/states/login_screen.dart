import 'package:game_tools_lib/game_tools_lib.dart';

final class LoginScreen extends GameState {
  // not always 100% accurate!
  final bool inCharacterSelection;

  LoginScreen({
    required this.inCharacterSelection,
  });

  @override
  Future<void> onStart(GameState oldState) async {
    await super.onStart(oldState);
  }

  @override
  Future<void> onStop(GameState newState) async {}

  @override
  Future<void> onUpdate() async {}

  @override
  String get welcomeMessage => "Switched to ${inCharacterSelection ? "Character Selection" : "Login Screen"}";
}
