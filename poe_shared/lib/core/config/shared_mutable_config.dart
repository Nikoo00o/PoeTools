import 'package:flutter/widgets.dart';
import 'package:game_tools_lib/core/config/app_colors_config_option.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/config/locale_config_option.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme.dart';

base mixin SharedMutableConfig on MutableConfig {
  @override
  LogLevelConfigOption get logLevel => _logLevel;

  final LogLevelConfigOption _logLevel = LogLevelConfigOption(
    title: const TS("config.logLevel"),
    defaultValue: LogLevel.SPAM,
  );

  @override
  LocaleConfigOption get currentLocale => _currentLocale;

  final LocaleConfigOption _currentLocale = LocaleConfigOption(
    title: const TS("config.currentLocale"),
    defaultValue: FixedConfig().supportedLocales.first,
  );

  @override
  AppColorsConfigOption get appColors => _appColors;

  final AppColorsConfigOption _appColors = AppColorsConfigOption(
    defaultValue: const GTAppTheme.seed(
      seedColor: Color(0xff004A95),
      baseSuccessColor: Color.fromARGB(255, 0, 255, 0),
      baseAdditionalColors: <Color>[],
    ),
  );
}
