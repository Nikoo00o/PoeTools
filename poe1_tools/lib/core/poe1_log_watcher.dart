import 'package:game_tools_lib/domain/game/input/log_input_listener.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

// todo: check if something could be moved to shared tool
base class Poe1LogWatcher extends GameLogWatcher {
  @override
  Duration get delayForOldLines => const Duration(minutes: 5);

  Poe1LogWatcher() : super(listeners: null, gameLogFilePaths: _poe1LogPaths, onlyHandleLastLinesUntil: _logStartLine);

  static List<String>? get _poe1LogPaths {
    // todo: support other platforms and also maybe add config option
    return <String>[
      "C:\\Program Files (x86)\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt",
      "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Path of Exile\\logs\\Client.txt",
    ];
  }

  static LogInputListener? get _logStartLine => null;

  @override
  List<LogInputListener> additionalListeners() => <LogInputListener>[];

  /// If a line should not be processed (for example overridden in a subclass to skip a pattern that would never
  /// contain logs). Per default only empty lines are skipped (which never arrive anyways, because empty lines are
  /// sorted out earlier)!
  @override
  bool shouldLineBeSkipped(String line) {
    return line.isEmpty;
  }

  /// If on startup the game already produces any logs since [delayForOldLines], then this will be called with the
  /// latest [lastListener] that would have been called before with its matching [line] (because the game has
  /// probably been running for a while longer). And it will be called multiple times with older listeners as long as
  /// this returns [false]. If this returns [true] then it signals that the current listener should be the last final
  /// one and this will no longer be called!
  ///
  /// You can override this to have different behaviour depending on the type of the [lastListener].
  /// Per default this just calls [LogInputListener.processLine] and returns true to only process the last listener!
  /// You can also override the [delayForOldLines] for a different timeframe.
  ///
  /// Important: this will not be called if a previous line matched the [onlyHandleLastLinesUntil] if its not null
  /// (to avoid false positives for too old events)!
  ///
  /// Important: this will be called during [GameToolsLib.runLoop] after [GameManager.onStart] and the current state
  /// will be [GameClosedState] at the current point only if it didn't change in the start of a custom game manager
  /// subclass!
  @override
  bool handleLastLine(LogInputListener lastListener, String line) {
    lastListener.processLine(line);
    return true;
  }
}
