import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:poe_shared/core/config/shared_mutable_config.dart';

base class Poe1MutableConfig extends MutableConfig with SharedMutableConfig {
  @override
  List<MutableConfigOption<dynamic>> getConfigurableOptions() {
    final defaultGroup = super.getConfigurableOptions().first;
    return <MutableConfigOption<dynamic>>[defaultGroup];
  }
}
