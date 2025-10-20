import 'package:flutter/widgets.dart';
import 'package:game_tools_lib/core/config/app_colors_config_option.dart';
import 'package:game_tools_lib/core/config/locale_config_option.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme.dart';
import 'package:poe_shared/modules/progress_story/config/progress_story_config.dart';

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
    defaultValue: const Locale("en"),
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

  final StringConfigOption characterNameOverride = StringConfigOption(
    title: TS.raw("Character Name Override"),
    defaultValue: "",
    description: TS.raw(
      "Empty per default, but can be used to disable the tool chatting on first hideout enter. "
      "RESTART TOOL AFTER CHANGE",
    ),
  );

  // managd in progress story 
  final ProgressStoryConfigOption progressStoryConfig = ProgressStoryConfig.createOption();

  @override
  List<MutableConfigOption<dynamic>> getConfigurableOptions() {
    final List<MutableConfigOption<dynamic>> previous = super.getConfigurableOptions();
    final MutableConfigOption<dynamic> defaultGroup = previous.first;
    return <MutableConfigOption<dynamic>>[
      ...previous,
      MutableConfigOptionGroup(
        title: TS.raw("Poe Settings"),
        configOptions: <MutableConfigOption<dynamic>>[
          characterNameOverride,
        ],
      ),
      progressStoryConfig,
    ];
  }

  /// Quick getter
  static SharedMutableConfig get instance => MutableConfig.mutableConfig as SharedMutableConfig;
}
