import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:poe_shared/core/config/shared_fixed_config.dart';

base class Poe1FixedConfig extends FixedConfig with SharedFixedConfig {
  @override
  List<String> get versionPathToGitProject => <String>["https://github.com/Nikoo00o/GameToolsLib", ""];

  const Poe1FixedConfig();
}
