import 'package:game_tools_lib/domain/game/input/log_input_listener.dart';
import 'package:poe_shared/core/poe_log_watcher.dart';

// todo: check if something could be moved to shared tool
base class Poe1LogWatcher extends PoeLogWatcher {
  @override
  Duration get delayForOldLines => const Duration(minutes: 1);

  Poe1LogWatcher() : super(listeners: null, gameLogFilePaths: _poe1LogPaths, onlyHandleLastLinesUntil: _logStartLine);

  static List<String>? get _poe1LogPaths {
    // todo: support other platforms and also maybe add config option
    return <String>[
      "C:\\Program Files (x86)\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt",
      "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Path of Exile\\logs\\Client.txt",
    ];
  }

  static LogInputListener? get _logStartLine => SimpleLogInputListener.instant(
    matchBeforeRegex: "",
    matchAfterRegex: r"\*\*\*\*\* LOG FILE OPENING \*\*\*\*\*",
    quickAction: (_) {},
  );

  @override
  List<LogInputListener> additionalListeners() => <LogInputListener>[];

  @override
  bool shouldLineBeSkipped(String line) {
    if (line.contains(" [DEBUG Client ")) {
      final String next = _nextPart(line);
      if (next.isNotEmpty && skipDebugLogs(next)) {
        return true;
      }
    } else if (line.contains(" [CRIT Client ") || line.contains(" [WARN Client ")) {
      return true; // for now no useful logs here
    } else if (line.contains(" [INFO Client ")) {
      final String next = _nextPart(line);
      if (next.isNotEmpty && skipInfoLogs(next)) {
        return true;
      }
    }
    return false;
  }

  String _nextPart(String line) {
    final int pos = line.indexOf("] ");
    return line.substring(pos + 2);
  }

  bool _start(String part, String search) => part.startsWith(search);

  bool skipDebugLogs(String p) {
    if (_start(p, "ALTERNATE TREE JEWEL: ")) return true;
    if (_start(p, "[SCENE]") || _start(p, "[DXC]") || _start(p, "[D3D") || _start(p, "[VULKAN]")) return true;
    if (_start(p, "[SHADER]") || _start(p, "[WINDOW]") || _start(p, "Rebuilding")) return true;
    if (_start(p, "Client-Safe") || _start(p, "Got ") || _start(p, "[InGameAudioManager]")) return true;

    return false;
  }

  bool skipInfoLogs(String p) {
    if (_start(p, "[SCENE] C") || _start(p, "[ENGINE]") || _start(p, "[STARTUP]") || _start(p, "Finished")) return true;
    if (_start(p, "[RENDER]") || _start(p, "[SHADER]") || _start(p, "[VULKAN]") || _start(p, "[STORAGE]")) return true;
    if (_start(p, "[GRAPH]") || _start(p, "[SOUND]") || _start(p, "[STREAMLINE]") || _start(p, "[JOB]")) return true;
    if (_start(p, "[PARTICLE]") || _start(p, "[TEXTURE]") || _start(p, "[PARTICLE]") || _start(p, "[MAT]")) return true;
    if (_start(p, "[VIDEO]") || _start(p, "[BUNDLE]") || _start(p, "[TRAILS]") || _start(p, "[MESH]")) return true;
    if (_start(p, "[ENTITY]") || _start(p, "[MESH]") || _start(p, "[HTTP") || _start(p, "[ANIMATION]")) return true;
    if (_start(p, "[TELEMETRY]") || _start(p, "[PHYSICS]") || _start(p, "[UI]") || _start(p, "[LUT]")) return true;
    if (_start(p, "[GPU") || _start(p, "[VOLUMETRIC") || _start(p, "[D3D") || _start(p, "[WINDOW]")) return true;

    if (_start(p, "Requesting") || _start(p, "Enumerated") || _start(p, "Got file list")) return true;
    if (_start(p, "Send") || _start(p, "Web") || _start(p, "Backup") || _start(p, "[RESOURCE]")) return true;
    if (_start(p, "Precalc") || _start(p, "[DXC]") || _start(p, "Tile hash") || _start(p, "Doodad hash")) return true;
    if (_start(p, "[DOWNLOAD]")|| _start(p, "Queue file")) return true;

    // for now only ignore those scene logs (because trying to find login screen and character selection
    if (_start(p, "[SCENE] H") || _start(p, "[SCENE] Set Source [(null)]")) return true;
    return false;
  }
}
