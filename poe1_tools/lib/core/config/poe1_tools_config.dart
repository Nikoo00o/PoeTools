import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:poe1_tools/core/config/poe1_fixed_config.dart';
import 'package:poe1_tools/core/config/poe1_mutable_config.dart';
import 'package:poe_shared/core/config/shared_tools_config.dart';

typedef Poe1ToolsConfigT = Poe1ToolsConfig<Poe1FixedConfig, Poe1MutableConfig>;

base class Poe1ToolsConfig<FType extends Poe1FixedConfig, MType extends Poe1MutableConfig>
    extends GameToolsConfig<FType, MType>
    with SharedToolsConfig<FType, MType> {
  const Poe1ToolsConfig({required super.fixed, required super.mutable});

  @override
  String get appTitle => "Poe1Tools";
}
