import 'package:flutter/cupertino.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/input/log_input_listener.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

import 'package:poe_shared/domain/states/in_area.dart';
import 'package:poe_shared/modules/area_manager/areas.dart';
import 'package:poe_shared/modules/progress_story/timer_xp/timer_xp_overlay.dart';

base class ProgressStory<GM extends GameManagerBaseType> extends Module<GM> {
  @override
  TranslationString get moduleName => TS.raw("Story Progression");

  late TimerXpOverlay _timerXp;

  @override
  @mustCallSuper
  List<MutableConfigOption<dynamic>> getConfigurableOptions() => <MutableConfigOption<dynamic>>[];

  @override
  @mustCallSuper
  List<LogInputListener> getAdditionalLogInputListener() => <LogInputListener>[];

  @override
  @mustCallSuper
  List<BaseInputListener<dynamic>> getAdditionalInputListener() => <BaseInputListener<dynamic>>[];

  @override
  @mustCallSuper
  Future<void> onStart() async {
    _timerXp = TimerXpOverlay();
  }

  @override
  @mustCallSuper
  Future<void> onStop() async {}

  @override
  @mustCallSuper
  Future<void> onUpdate() async {

  }

  @override
  @mustCallSuper
  Future<void> onOpenChange(GameWindow window) async {}

  @override
  @mustCallSuper
  Future<void> onFocusChange(GameWindow window) async {}

  @override
  @mustCallSuper
  Future<void> onStateChange(GameState oldState, GameState newState) async {
    if (newState.isType<InArea>()) {
      final InArea area = newState.asType<InArea>();
      if (area.isTown || area.isStoryZone) {
        _timerXp.visible = true;
        _timerXp.areaLvl.value = area.areaLevel;
        if (area.areaName == Areas.actZones.first.first && !area.isSecondPart) {
          _timerXp.startTimer(); // twilight strand
        } else if(area.areaName == Areas.towns.last){
          _timerXp.stopTimer(); // karui shores
        }
      } else {
        _timerXp.visible = false;
      }
    } else {
      _timerXp.visible = false;
    }
  }

  /// Shortcut to use this
  static ProgressStory<GM> progressStory<GM extends GameManagerBaseType>() =>
      GameManager.gameManager().getModuleT<ProgressStory<GM>>();
}
