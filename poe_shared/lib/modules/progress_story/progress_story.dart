import 'package:flutter/cupertino.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/data/assets/gt_asset.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/input/log_input_listener.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:poe_shared/core/config/shared_mutable_config.dart';
import 'package:poe_shared/domain/states/in_area.dart';
import 'package:poe_shared/modules/area_manager/areas.dart';
import 'package:poe_shared/modules/area_manager/layout_asset.dart';
import 'package:poe_shared/modules/player_manager/player_data.dart';
import 'package:poe_shared/modules/player_manager/player_manager.dart';
import 'package:poe_shared/modules/progress_story/config/act_config.dart';
import 'package:poe_shared/modules/progress_story/config/progress_story_config.dart';
import 'package:poe_shared/modules/progress_story/config/progression_info.dart';
import 'package:poe_shared/modules/progress_story/overlays/layout_overlay.dart';
import 'package:poe_shared/modules/progress_story/overlays/story_text_overlay.dart';
import 'package:poe_shared/modules/progress_story/overlays/timer_xp_overlay.dart';

part 'parts/progress_story_overlays.dart';

base class ProgressStory<GM extends GameManagerBaseType> extends Module<GM> with _ProgressStoryOverlays<GM> {
  @override
  TranslationString get moduleName => TS.raw("Story Progression");

  // zero based so 0 is act 1. never goes back
  int _currentAct = 0;

  // step from act (will stay after logging out until end of program!)
  int _currentProgressionStep = -1;

  // used only to access read
  ProgressStoryConfig get progressStoryConfig => SharedMutableConfig.instance.progressStoryConfig.cachedValueNotNull();

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
    await super.onStart();
    await _fillEmptyDefaultConfigIfNeeded();
  }

  Future<void> _fillEmptyDefaultConfigIfNeeded() async {
    final ProgressStoryConfig config = progressStoryConfig;
    if (config.actNotes.values.firstOrNull?.areaInfo.isEmpty ?? true) {
      Logger.verbose("Filling progress story config empty general area infos...");
      config.fillEmptyAreas(); // first load when loading empty file but after config is done
      await SharedMutableConfig.instance.progressStoryConfig.setValue(config);
    }
  }

  @override
  @mustCallSuper
  Future<void> onStop() async {
    await super.onStop();
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
    if (newState.isType<InArea>()) {
      final InArea area = newState.asType<InArea>();
      if (oldState.isType<InArea>()) {
        final InArea oldArea = oldState.asType<InArea>();
        if (area != oldArea) {
          await _onNextArea(area, oldState, oldArea);
        } else {
          Logger.verbose("Skipped rejoining same area $area sub state"); // skip sub states!!!
        }
      } else {
        await _onNextArea(area, oldState, null);
      }
    } else {
      _disableOverlays();
    }
  }

  // only if old state was not the same! area can be of any!
  Future<void> _onNextArea(InArea area, GameState oldState, InArea? oldArea) async {
    final int newAct = area.actForStoryZone; // -1 / empty for maps
    final String actName = newAct < 0 ? "" : progressStoryConfig.actNotes.keys.elementAt(newAct);
    if (newAct > _currentAct) {
      Logger.info("Progressed from Act ${_currentAct + 1} to $actName!");
      _currentAct = newAct;
    }
    _updateProgressionWithArea(area, actName); // only visible in town and story zones
    _updateTimerWithArea(area); // visible in any zone
    _updateGeneralInfoWithArea(area, actName); // depends on story vs maps inside
    await _updateLayouts(area, actName); // depends on story vs maps inside
  }

  // uses _updateAndGetProgressionInfo to update progression step
  void _updateProgressionWithArea(InArea area, String actName) {
    if (area.isStoryZone || area.isTown) {
      final (ProgressionInfo? first, ProgressionInfo? second) = _updateAndGetProgressionInfo(actName, area.areaName);
      if (first != null) {
        Logger.spam("update prog overlay for ", first, " and ", second, " in ", area);
        _updateNextProgressionOverlay(first, second);
      } else if (_currentProgressionStep > -1) {
        Logger.spam("visible prog overlay for ", _currentProgressionStep, " in ", area);
        _makeNextProgressionOverlayVisible();
      }
    } else {
      Logger.spam("hide prog overlay in ", area);
      _hideProgressionOverlay();
    }
  }

  // for maps actName would be empty. only returns if new progression step was found, otherwise first is null!
  // second might still be null at the end (because there isnt one more). changes _currentProgressionSteps!
  (ProgressionInfo? first, ProgressionInfo? second) _updateAndGetProgressionInfo(String actName, String areaName) {
    ProgressionInfo? firstProgression;
    ProgressionInfo? secondProgression;
    final List<ProgressionInfo> progressionSteps = progressStoryConfig.progressionInfo;
    for (int i = _currentProgressionStep + 1; i < progressionSteps.length; i++) {
      final ProgressionInfo progression = progressionSteps[i]; // initial -1 so 0, only check > cur
      if (progression.parentAct == actName && progression.triggerArea == areaName) {
        if (_currentProgressionStep > -1) {
          firstProgression = progressionSteps[_currentProgressionStep];
        }
        Logger.info("Progressed from $firstProgression to $progression");
        _currentProgressionStep = i;
        firstProgression = progression;
        if (i < progressStoryConfig.progressionInfo.length - 1) {
          secondProgression = progressStoryConfig.progressionInfo[i + 1];
        } else {
          secondProgression = null;
        }
        break;
      }
    }
    return (firstProgression, secondProgression);
  }

  void _updateTimerWithArea(InArea area) {
    _timerXp.visible = true;
    _timerXp.areaLvl.value = area.areaLevel;
    final PlayerData playerData = PlayerManager.playerManager().playerData;
    if (area.areaName == Areas.actZones.first.first && !area.isSecondPart) {
      Logger.info("Starting timer from first zone");
      _timerXp.startTimer(); // twilight strand
    } else if (area.areaName == Areas.towns.last) {
      final Duration stopped = _timerXp.stopTimer(); // karui shores
      Logger.present("Finished the campaign / story in ${_timerXp.getTimeString(stopped)}");
      const Duration delay = Duration(minutes: 5);
      Utils.executeDelayedNoAwait(
        delay: delay,
        callback: () async {
          _timerXp.startTimer(stopped.inMilliseconds + delay.inMilliseconds); // after 5 min restart timer
        },
      );
    } else if (!_timerXp.isStarted && playerData.characterName.isNotEmpty) {
      Logger.info("Starting timer on entering with old value: ${playerData.timerMilliseconds}");
      _timerXp.startTimer(playerData.timerMilliseconds);
    }
  }

  void _updateGeneralInfoWithArea(InArea area, String act) {
    if (area.isStoryZone) {
      final ActConfig actConfig = progressStoryConfig.actNotes[act]!;
      _actInfo.update(act, actConfig.actInfo);
      _areaInfo.update(area.areaName, actConfig.areaInfo[area.areaName] ?? "");
    } else {
      // todo: map notes? with empty actname? different document?
      _actInfo.update("", ""); // dont display in town
      _areaInfo.update("", "");
    }
  }

  Future<void> _updateLayouts(InArea area, String actName) async {
    if (area.isStoryZone) {
      await _updateLayoutOverlays(LayoutAsset(actName: actName, areaName: area.areaName));
    } else {
      // todo: map layout overlays
      await _updateLayoutOverlays(null); // dont show in town!
    }
  }

  /// Shortcut to use this
  static ProgressStory<GM> progressStory<GM extends GameManagerBaseType>() =>
      GameManager.gameManager().getModuleT<ProgressStory<GM>>();
}
