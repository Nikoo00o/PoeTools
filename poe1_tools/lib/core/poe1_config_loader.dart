import 'dart:ui' show Locale;

import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:poe_shared/core/shared_config_loader.dart';

base class Poe1ConfigLoader extends GameConfigLoader with SharedConfigLoader {
  Poe1ConfigLoader({required super.filePath});

  // todo: for now always return the first "en" locale
  @override
  Locale? get gameLanguage => FixedConfig.fixedConfig.supportedLocales.first;

  // todo: implement getters that reference hotkey or value methods with name (maybe in mixin)
}
