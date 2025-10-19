import 'package:flutter/foundation.dart' show mustCallSuper, protected;
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:poe1_tools/core/config/poe1_tools_config.dart';
import 'package:poe_shared/core/shared_game_manager.dart';
import 'package:poe_shared/modules/area_manager/area_manager.dart';
import 'package:poe_shared/modules/player_manager/player_manager.dart';
import 'package:poe_shared/modules/progress_story/progress_story.dart';

typedef Poe1GameManagerT = Poe1GameManager<Poe1ToolsConfigT>;

base class Poe1GameManager<CType extends Poe1ToolsConfigT> extends GameManager<CType> with SharedGameManager<CType> {
  Poe1GameManager([List<BaseInputListener<dynamic>>? additionalInputListener])
    : super(
        inputListeners: <BaseInputListener<dynamic>>[
          ...SharedGameManager.createInputListener,
          ...createInputListener,
          ...?additionalInputListener,
        ],
      );

  static List<BaseInputListener<dynamic>> get createInputListener => <BaseInputListener<dynamic>>[];

  @override
  @protected
  @mustCallSuper
  List<ModuleBaseType> moduleConfiguration() => <ModuleBaseType>[
    ...super.moduleConfiguration(),
    AreaManager<Poe1GameManagerT>(),
    PlayerManager<Poe1GameManagerT>(),
    ProgressStory<Poe1GameManagerT>(),
  ];

  @override
  @mustCallSuper
  Future<void> onStart() async {
    await super.onStart();
  }

  @override
  @mustCallSuper
  Future<void> onStop() async {
    await super.onStop();
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
  Future<void> onStateChange(GameState oldState, GameState newState) async {
    await super.onStateChange(oldState, newState);
  }
}
