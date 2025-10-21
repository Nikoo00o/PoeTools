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
import 'package:poe_shared/modules/progress_story/config/act_config.dart';
import 'package:poe_shared/modules/progress_story/config/progress_story_config.dart';
import 'package:poe_shared/modules/progress_story/config/progression_info.dart';
import 'package:poe_shared/modules/progress_story/overlays/layout_overlay.dart';
import 'package:poe_shared/modules/progress_story/overlays/story_text_overlay.dart';
import 'package:poe_shared/modules/progress_story/overlays/timer_xp_overlay.dart';

base class ProgressStory<GM extends GameManagerBaseType> extends Module<GM> {
  @override
  TranslationString get moduleName => TS.raw("Story Progression");

  late TimerXpOverlay _timerXp;

  late StoryTextOverlay _actInfo;
  late StoryTextOverlay _areaInfo;

  late StoryTextOverlay _progressCur;
  late StoryTextOverlay _progressNext;

  // zero based so 0 is act 1. never goes back
  int _currentAct = 0;

  // step from act (will stay after logging out until end of program!)
  int _currentProgressionStep = -1;

  // only one cached at a time
  LayoutAsset? _currentLayouts;

  final List<LayoutOverlay> _layoutOverlays = <LayoutOverlay>[];

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
    _timerXp = TimerXpOverlay();
    _actInfo = StoryTextOverlay(
      TS.raw("General Act Info"),
      ScaledBounds<int>.defaultBounds(x: 747, y: 1324, width: 530, height: 80),
    );
    _areaInfo = StoryTextOverlay(
      TS.raw("General Area Info"),
      ScaledBounds<int>.defaultBounds(x: 1113, y: 1149, width: 681, height: 158),
    );
    _progressCur = StoryTextOverlay(
      TS.raw("Current Story Progression"),
      ScaledBounds<int>.defaultBounds(x: 1147, y: 4, width: 681, height: 185),
    );
    _progressNext = StoryTextOverlay(
      TS.raw("Next Story Progression"),
      ScaledBounds<int>.defaultBounds(x: 1150, y: 203, width: 681, height: 185),
    );

    _addDefaultLayoutOverlays();
    await _fillEmptyDefaultConfigIfNeeded();
  }

  void _addDefaultLayoutOverlays() {
    const int x = 10;
    const int y = 10;
    const int width = 360;
    const int height = 318;
    const int elementCount = 12;
    const int startRow = 1; // second row first
    for (int i = 0; i < elementCount; ++i) {
      _layoutOverlays.add(
        LayoutOverlay(
          TS.raw("Area Layout ${i + 1}"),
          ScaledBounds<int>.defaultBounds(
            x: (x + (i % 3) * width) % (width * 3),
            y: (y + (i ~/ 3 + startRow) * height) % (height * 4),
            width: width,
            height: height,
          ),
        ),
      );
    }
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
    if (newState.isType<InArea>()) {
      final InArea area = newState.asType<InArea>();
      if (area.isTown || area.isStoryZone) {
        if (oldState.isType<InArea>()) {
          final InArea oldArea = oldState.asType<InArea>();
          if (area != oldArea) {
            await _onStoryArea(area, oldState, oldArea);
          } else {
            Logger.verbose("Skipped rejoining same area $area sub state"); // skip sub states!!!
          }
        } else {
          await _onStoryArea(area, oldState, null);
        }
      } else {
        _disableOnNoStoryArea();
      }
    } else {
      _disableOnNoStoryArea();
    }
  }

  // only if old state was not the same! area will always be story zone or town
  Future<void> _onStoryArea(InArea area, GameState oldState, InArea? oldArea) async {
    final int newAct = area.actForStoryZone;
    final String actName = progressStoryConfig.actNotes.keys.elementAtOrNull(newAct) ?? "";
    if (newAct > _currentAct) {
      Logger.info("Progressed from Act ${_currentAct + 1} to $actName!");
      _currentAct = newAct;
    }
    final (ProgressionInfo? first, ProgressionInfo? second) = _updateAndGetProgressionInfo(actName, area);

    _updateTimerWithArea(area);
    final ActConfig actConfig = progressStoryConfig.actNotes[actName]!;
    _updateGeneralInfoWithArea(area, actName, actConfig); // also updates progression info
    _updateProgressionOverlays(first, second, area);
    await _updateLayouts(area, actName);
  }

  (ProgressionInfo? first, ProgressionInfo? second) _updateAndGetProgressionInfo(String actName, InArea area) {
    ProgressionInfo? firstProgression;
    ProgressionInfo? secondProgression;
    final List<ProgressionInfo> progressions = progressStoryConfig.progressionInfo;
    for (int i = _currentProgressionStep + 1; i < progressions.length; i++) {
      final ProgressionInfo progression = progressions[i]; // initial -1 so 0, only check > cur
      if (progression.parentAct == actName && progression.triggerArea == area.areaName) {
        if (_currentProgressionStep > -1) {
          firstProgression = progressions[_currentProgressionStep];
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

  // does not reset progression variables
  void _disableOnNoStoryArea() {
    _timerXp.visible = false;
    _actInfo.update("", "");
    _areaInfo.update("", "");
    _progressCur.visible = false;
    _progressNext.visible = false;
    _clearLayouts(); // also clear layouts
  }

  void _updateTimerWithArea(InArea area) {
    _timerXp.visible = true;
    _timerXp.areaLvl.value = area.areaLevel;
    if (area.areaName == Areas.actZones.first.first && !area.isSecondPart) {
      _timerXp.startTimer(); // twilight strand
    } else if (area.areaName == Areas.towns.last) {
      final String time = _timerXp.getTimeString(_timerXp.stopTimer()); // karui shores
      Logger.present("Finished the campaign / story in $time");
    }
  }

  void _updateGeneralInfoWithArea(InArea area, String act, ActConfig actConfig) {
    if (area.isStoryZone) {
      _actInfo.update(act, actConfig.actInfo);
      _areaInfo.update(area.areaName, actConfig.areaInfo[area.areaName] ?? "");
    } else {
      _actInfo.update("", ""); // dont display in town
      _areaInfo.update("", "");
    }
  }

  // only called when it changes and needs updating
  void _updateProgressionOverlays(ProgressionInfo? firstProgression, ProgressionInfo? secondProgression, InArea area) {
    if (firstProgression != null) {
      final bool secondAvailable = secondProgression != null; // change values
      _progressCur.update("1. ${firstProgression.triggerArea}", firstProgression.infoText);
      if (secondAvailable) {
        _progressNext.update("2. ${secondProgression.triggerArea}", secondProgression.infoText);
      } else {
        _progressNext.update("", "");
      }
    } else if (_currentProgressionStep > -1) {
      if (_progressCur.visible == false) _progressCur.visible = true; // only update visible again
      if (_progressNext.visible == false && _progressNext.hasContent) _progressNext.visible = true;
    }
  }

  Future<void> _updateLayouts(InArea area, String actName) async {
    if (area.isStoryZone) {
      _currentLayouts?.cleanup();
      _currentLayouts = LayoutAsset(actName: actName, areaName: area.areaName);
      final List<(FileInfoAsset, NativeImage)> elements = _currentLayouts!.overlayImages;
      for (int i = 0; i < _layoutOverlays.length; ++i) {
        final LayoutOverlay layoutOverlay = _layoutOverlays[i];
        if (elements.length > i) {
          final (FileInfoAsset info, NativeImage image) = elements[i];
          layoutOverlay.update(await image.getDartImage(), info.fileName);
        } else {
          layoutOverlay.update(null, "");
        }
      }
    } else {
      _clearLayouts(); // dont show in town!
    }
  }

  void _clearLayouts() {
    for (int i = 0; i < _layoutOverlays.length; ++i) {
      _layoutOverlays[i].update(null, "");
    }
    _currentLayouts?.cleanup();
    _currentLayouts = null;
  }

  /// Shortcut to use this
  static ProgressStory<GM> progressStory<GM extends GameManagerBaseType>() =>
      GameManager.gameManager().getModuleT<ProgressStory<GM>>();
}
