import 'dart:async';
import 'package:flutter/foundation.dart' show mustCallSuper, protected;
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';

import 'package:game_tools_lib/domain/game/input/log_input_listener.dart';
import 'package:game_tools_lib/domain/game/states/game_closed_state.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:poe_shared/core/poe_log_watcher.dart';
import 'package:poe_shared/domain/states/in_area.dart';
import 'package:poe_shared/domain/states/login_screen.dart';
import 'package:poe_shared/modules/area_manager/areas.dart';
import 'package:poe_shared/modules/player_manager/player_data.dart';

// contains all open panels, etc and character name, etc
// should poe1 and poe2 inherit with sub classes from this, or add listener?
base class PlayerManager<GM extends GameManagerBaseType> extends Module<GM> {
  static const String _chatMsg = ",";

  final PlayerData playerData = PlayerData();

  SimpleLogInputListener? lvlListener;

  // preserved until tool is closed to not open chat after each reconnect in story
  bool _noResetPlayerNameAfterTwilight = false;

  // used to select updates
  String? _lastName;

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

    // todo: other chat listener should be between this and delete chat line afterwards so that the "," does not
    // parse the names of them!
    SimpleLogInputListener.instant(
      matchBeforeRegex: PoeLogWatcher.infoStart,
      matchAfterRegex: r": ,",
      quickAction: _parseFromChat,
      deleteLineAfterwards: false,
    ),
  ];

  @override
  @mustCallSuper
  List<BaseInputListener<dynamic>> getAdditionalInputListener() => <BaseInputListener<dynamic>>[
    KeyInputListener(
      configLabel: TS.raw("Relog Key"),
      configLabelDescription: TS.raw("Press this to relog for faster story progress"),
      createEventCallback: () {
        _noResetPlayerNameAfterTwilight = true;
        return performRelog();
      },
      alwaysCreateNewEvents: true,
      defaultKey: BoardKey.s.restrictive.copyWith(withAlt: true),
    ),
    KeyInputListener(
      configLabel: TS.raw("Hideout Key"),
      configLabelDescription: TS.raw("Use this to go to your hideout faster"),
      createEventCallback: goToHideout,
      alwaysCreateNewEvents: true,
      defaultKey: BoardKey.f.restrictive.copyWith(withAlt: true),
    ),
  ];

  // before the twilight strand reset player name is also disabled
  @protected
  GameEvent? performRelog() {
    Logger.info("Relogging");
    // TODO: no panel checks at all here at the moment :(  BETTER MAKE EVENT FOR IT. WINDOW FOCUS IS ALREADY CHECKED
    //  HERE. after this playername will no longer be reset
    InputManager.sendChatMessage("/exit");
    return null;
  }

  @protected
  GameEvent? goToHideout() {
    Logger.info("Going to hideout");
    // TODO: no panel checks at all here at the moment :( BETTER MAKE EVENT FOR IT
    InputManager.sendChatMessage("/hideout");
    return null;
  }

  @override
  @mustCallSuper
  Future<void> onStart() async {
    playerData.addListener(_onPlayerNameChange);
    Logger.debug("Storage had player name: ${playerData.characterName}");
  }

  @override
  @mustCallSuper
  Future<void> onStop() async {
    playerData.removeListener(_onPlayerNameChange);
  }

  void _onPlayerNameChange() {
    if (playerData.characterName.isNotEmpty && _lastName != playerData.characterName) {
      _lastName = playerData.characterName;
      if (lvlListener != null) {
        _resetPlayerNameListener();
      }
      Logger.verbose("Adding character level listener for ${playerData.characterName}");
      lvlListener = SimpleLogInputListener.instant(
        matchBeforeRegex: "${PoeLogWatcher.infoStart}: ${playerData.characterName} \\(.*\\) is now level ",
        matchAfterRegex: null,
        quickAction: _parseLvl,
        deleteLineAfterwards: false,
      );
      gameManager().addLogInputListener(lvlListener!);
    } else if (lvlListener != null) {
      _resetPlayerNameListener();
    }
  }

  void _resetPlayerNameListener() {
    Logger.verbose("Removing character level listener");
    gameManager().removeLogInputListener(lvlListener!);
    lvlListener = null;
  }

  // called from log input listener (which is always added with current player name)
  void _parseLvl(String lvl) {
    if (playerData.characterName.isNotEmpty) {
      playerData.characterLvl = int.tryParse(lvl) ?? 0;
      Logger.debug("${playerData.characterName} is now level $lvl");
    } else {
      Logger.warn("Got lvlup to $lvl without character name");
    }
  }

  // triggered on every lvlup log, so only take first when not set yet
  void _parseNameFromLvlUp(String newName) {
    if (playerData.characterName.isEmpty) {
      playerData.characterName = newName;
      Logger.info("Got player name $newName from first level up");
    }
  }

  // from zone enter self write
  void _parseFromChat(String newName) {
    if (playerData.characterName.isNotEmpty) {
      Logger.verbose("Did not set character name from chat from $newName ");
    } else {
      playerData.characterName = newName;
      Logger.info("Got player name $newName from chatting");
    }
  }

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
        playerData.resetCurrentCache();
      }
    } else if (newState.isType<InArea>()) {
      final InArea area = newState.asType<InArea>();
      if (playerData.characterName.isEmpty && !area.isTown && !area.isHideout) {
        if (area.areaName == Areas.actZones.first.first) {
          // twilight strand started char will be auto configured, otherwise on first not town enter (first reset)
          playerData.resetCurrentCache();
          _noResetPlayerNameAfterTwilight = true;
          Logger.debug("Twilight strand char name reset after muling a char ");
        } else {
          Logger.debug("Chatting to init player name..."); // dont await it here! received in chat above
          // dont try multiple times, because opening chat sucks and could leak ctr+v?
          Utils.executeDelayedNoAwaitMS(
            milliseconds: 150,
            callback: () async {
              if (GameToolsLib.mainGameWindow.hasFocus) {
                await InputManager.sendChatMessage(_chatMsg, clearFirst: true);
              }
            },
          );
        }
      }
    }
  }

  /// Shortcut to use this
  static PlayerManager<GM> playerManager<GM extends GameManagerBaseType>() =>
      GameManager.gameManager().getModuleT<PlayerManager<GM>>();
}
