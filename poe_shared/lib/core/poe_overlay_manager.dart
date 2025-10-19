import 'package:flutter/foundation.dart' show mustCallSuper;
import 'package:flutter/material.dart' show BuildContext;
import 'package:game_tools_lib/core/enums/overlay_mode.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/overlay/gt_overlay.dart';

final class PoeOverlayManager extends OverlayManager<GTOverlayState> {
  PoeOverlayManager([super.initialOverlayMode = OverlayMode.APP_OPEN, super.windowToTrackOverride]);

  @override
  @mustCallSuper
  Future<bool> init() async {
    final bool init = await super.init();
    return init;
  }

  @override
  @mustCallSuper
  void onCreate(BuildContext context) {
    super.onCreate(context);
  }

  @override
  @mustCallSuper
  void onDispose(BuildContext context) {
    super.onDispose(context);
  }

  @override
  @mustCallSuper
  Future<void> onUpdate() async {
    await super.onUpdate();
  }

  @override
  @mustCallSuper
  Future<void> onOpenChange(GameWindow window) async {
    await super.onOpenChange(window);
  }

  @override
  @mustCallSuper
  Future<void> onFocusChange(GameWindow window) async {
    await super.onFocusChange(window);
  }

  @override
  @mustCallSuper
  Future<void> onWindowResize(GameWindow window) async {
    await super.onWindowResize(window);
  }

  @override
  @mustCallSuper
  void onOverlayModeChanged(OverlayMode? lastMode, {required bool changedBetweenHiddenAndVisible}) {
    super.onOverlayModeChanged(lastMode, changedBetweenHiddenAndVisible: changedBetweenHiddenAndVisible);
  }
}
