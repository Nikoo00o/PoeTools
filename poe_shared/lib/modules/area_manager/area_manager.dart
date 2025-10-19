import 'package:flutter/cupertino.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/input/log_input_listener.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:poe_shared/core/poe_log_watcher.dart';
import 'package:poe_shared/domain/states/in_area.dart';
import 'package:poe_shared/domain/states/login_screen.dart';

// main state management
base class AreaManager<GM extends GameManagerBaseType> extends Module<GM> {
  int _lastAreaLvl = 0;
  String? _connectDomain;

  @override
  TranslationString get moduleName => TS.raw("AreaManager");

  @override
  @mustCallSuper
  List<MutableConfigOption<dynamic>> getConfigurableOptions() => <MutableConfigOption<dynamic>>[];

  // todo: of course those logs have to be language aware at some point and should be loaded from json as well
  @override
  @mustCallSuper
  List<LogInputListener> getAdditionalLogInputListener() => <LogInputListener>[
    // this seems to also track "Abnormal disconnect: An unexpected disconnection occurred."
    // and also "Abnormal disconnect: The operation timed out."
    SimpleLogInputListener.instant(
      matchBeforeRegex: "",
      matchAfterRegex: r"\[SCENE\] Set Source \[\(unknown\)\]",
      quickAction: onEnterLoginScreen,
      shouldStopOldLineHandling: true,
    ),
    SimpleLogInputListener.instant(
      matchBeforeRegex: "${PoeLogWatcher.infoStart}Connected to ",
      matchAfterRegex: r" in .*ms\.",
      quickAction: onConnect,
    ),
    SimpleLogInputListener.instant(
      matchBeforeRegex: "${PoeLogWatcher.infoStart}: You have entered ",
      matchAfterRegex: r"\.",
      quickAction: onEnterArea,
    ),
    SimpleLogInputListener.instant(
      matchBeforeRegex: "${PoeLogWatcher.debugStart}Generating level ",
      matchAfterRegex: " area.*",
      quickAction: (String lvl) => _lastAreaLvl = int.tryParse(lvl) ?? 0,
      shouldStopOldLineHandling: true,
    ),
  ];

  @override
  @mustCallSuper
  List<BaseInputListener<dynamic>> getAdditionalInputListener() => <BaseInputListener<dynamic>>[];

  @protected
  void onConnect(String domain) {
    _connectDomain = domain;
    if (currentState.isType<LoginScreen>()) {
      // login to character select, sadly currently cant get the other way around
      gameManager().changeState(LoginScreen(inCharacterSelection: true));
    }
  }

  @protected
  void onEnterLoginScreen(String name) {
    if (_connectDomain != null) {
      gameManager().changeState(LoginScreen(inCharacterSelection: true));
    } else {
      gameManager().changeState(LoginScreen(inCharacterSelection: false));
    }
    _lastAreaLvl = 0;
    _connectDomain = null;
  }

  @protected
  void onEnterArea(String name) {
    gameManager().changeState(InArea(areaName: name, areaLevel: _lastAreaLvl));
    _lastAreaLvl = 0;
    _connectDomain = null;
  }

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

  /// Shortcut to use this
  static AreaManager<GM> areaManager<GM extends GameManagerBaseType>() =>
      GameManager.gameManager().getModuleT<AreaManager<GM>>();
}
