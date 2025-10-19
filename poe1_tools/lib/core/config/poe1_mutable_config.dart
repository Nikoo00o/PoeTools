import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:poe_shared/core/config/shared_mutable_config.dart';

base class Poe1MutableConfig extends MutableConfig with SharedMutableConfig {
  @override
  List<MutableConfigOption<dynamic>> getConfigurableOptions() {
    final List<MutableConfigOption<dynamic>> previous = super.getConfigurableOptions();
    final MutableConfigOption<dynamic> defaultGroup = previous.first;
    return <MutableConfigOption<dynamic>>[...previous];
  }
}
