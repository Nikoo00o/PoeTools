import 'dart:async';
import 'package:flutter/foundation.dart' show mustCallSuper;
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';

import 'package:game_tools_lib/domain/game/input/log_input_listener.dart';
import 'package:game_tools_lib/domain/game/states/game_closed_state.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/widgets/helper/changes/simple_change_notifier.dart';
import 'package:poe_shared/core/config/shared_mutable_config.dart';
import 'package:poe_shared/core/poe_log_watcher.dart';
import 'package:poe_shared/domain/states/in_area.dart';
import 'package:poe_shared/domain/states/login_screen.dart';
import 'package:poe_shared/modules/area_manager/areas.dart';

// contains all open panels, etc and character name, etc
base class PlayerManager<GM extends GameManagerBaseType> extends Module<GM> {
  static const String _chatMsg = ",";

  // will be empty first, new character will be loaded on first level up. Otherwise on joining the first area that's
  // not the town. others may listen to changes, but should not change value!
  final SimpleChangeNotifier<String> characterName = SimpleChangeNotifier<String>("");

  // currently not tracked until lvlup. could do whois but is another chat
  final SimpleChangeNotifier<int> characterLvl = SimpleChangeNotifier<int>(0);

  SimpleLogInputListener? lvlListener;

  // preserved until tool is closed to not open chat after each reconnect in story
  bool _noResetPlayerNameAfterTwilight = false;

  @override
  TranslationString get moduleName => TS.raw("PlayerManager");

  @override
  @mustCallSuper
  List<MutableConfigOption<dynamic>> getConfigurableOptions() => <MutableConfigOption<dynamic>>[];

  @override
  @mustCallSuper
  List<LogInputListener> getAdditionalLogInputListener() => <LogInputListener>[
    // here no delete line afterwards because multi listeners to that line!
    SimpleLogInputListener.instant(
      matchBeforeRegex: "${PoeLogWatcher.infoStart}: ",
      matchAfterRegex: r" \(.*\) is now level .*",
      quickAction: _parseNameFromLvlUp,
      deleteLineAfterwards: false,
    ),
    SimpleLogInputListener.instant(
      matchBeforeRegex: PoeLogWatcher.infoStart,
      matchAfterRegex: r": ,",
      quickAction: _parseFromChat,
      deleteLineAfterwards: false,
    ),
  ];

  void _setName(String newName) {
    characterName.value = newName;
    if (newName.isNotEmpty) {
      lvlListener = SimpleLogInputListener.instant(
        matchBeforeRegex: "${PoeLogWatcher.infoStart}: $characterName \\(.*\\) is now level ",
        matchAfterRegex: null,
        quickAction: _parseLvl,
        deleteLineAfterwards: false,
      );
      gameManager().addLogInputListener(lvlListener!);
    } else if (lvlListener != null) {
      gameManager().removeLogInputListener(lvlListener!);
      lvlListener = null;
    }
  }

  void _parseLvl(String lvl) {
    if (characterName.value.isNotEmpty) {
      characterLvl.value = int.tryParse(lvl) ?? 0;
      Logger.debug("$characterName is now level $lvl");
    } else {
      Logger.warn("Got lvlup to $lvl without character name");
    }
  }

  void _parseNameFromLvlUp(String newName) {
    if (characterName.value.isEmpty) {
      _setName(newName);
      Logger.info("Got player name $newName from first level up");
    }
  }

  void _parseFromChat(String newName) {
    if (characterName.value.isNotEmpty) {
      Logger.warn("Wanted to set new player name $newName, but it already was $characterName");
    }
    _setName(newName);
    Logger.info("Got player name $newName from chatting");
  }

  @override
  @mustCallSuper
  List<BaseInputListener<dynamic>> getAdditionalInputListener() => <BaseInputListener<dynamic>>[];

  @override
  @mustCallSuper
  Future<void> onStart() async {
    final String name = SharedMutableConfig.instance.characterNameOverride.cachedValue() ?? "";
    if (name.isNotEmpty) {
      characterName.value = name;
    }
  }

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
  Future<void> onStateChange(GameState oldState, GameState newState) async {
    if (newState.isType<GameClosedState>() || newState.isType<LoginScreen>()) {
      if (_noResetPlayerNameAfterTwilight) {
        Logger.verbose("skip player name reset because leveling run");
      } else {
        Logger.verbose("resetting player name and lvl");
        _setName("");
        characterLvl.value = 0;
      }
    } else if (newState.isType<InArea>()) {
      final InArea area = newState.asType<InArea>();
      if (characterName.value.isEmpty && !area.isTown && area.isSecondPart == false) {
        if (area.areaName == Areas.actZones.first.first) {
          // twilight strand started char will be auto configured, otherwise on first not town enter (first reset)
          _setName(""); // set by listener above again!
          characterLvl.value = 0;
          _noResetPlayerNameAfterTwilight = true;
          Logger.debug("Twilight strand char name reset after muling");
        } else {
          Logger.debug("Chatting to init player name..."); // dont await it here! received in chat above
          Utils.executeDelayedNoAwaitMS(
            milliseconds: 1000,
            callback: () async => InputManager.sendChatMessage(_chatMsg, clearFirst: true),
          );
        }
      }
    }
  }

  /// Shortcut to use this
  static PlayerManager<GM> playerManager<GM extends GameManagerBaseType>() =>
      GameManager.gameManager().getModuleT<PlayerManager<GM>>();
}
