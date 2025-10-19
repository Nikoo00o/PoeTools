import 'package:game_tools_lib/game_tools_lib.dart';

base class PoeLogWatcher extends GameLogWatcher {
  PoeLogWatcher({required super.gameLogFilePaths, required super.listeners, super.onlyHandleLastLinesUntil});

  static String infoStart = r".* \[INFO Client.*\] ";
  static String debugStart = r".* \[DEBUG Client.*\] ";
}
