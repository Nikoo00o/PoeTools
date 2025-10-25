import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:poe_shared/modules/area_manager/areas.dart';

// only compares parent act and trigger area for equals!
final class ProgressionInfo implements Model {
  static const String JSON_TRIGGER_AREA = "Area to show after";
  static const String JSON_PARENT_ACT = "Act this area is in";
  static const String JSON_INFO_TEXT = "Info Text to show";

  String triggerArea;

  // for maps would be empty
  String parentAct;

  // remember when accessing to convert by parents list of replacements
  String infoText;

  // todo: gem info

  ProgressionInfo({required this.triggerArea, required this.parentAct, required this.infoText});

  ProgressionInfo.empty() : triggerArea = "", parentAct = "", infoText = "";

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_TRIGGER_AREA: triggerArea,
      JSON_PARENT_ACT: parentAct,
      JSON_INFO_TEXT: infoText,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressionInfo &&
          runtimeType == other.runtimeType &&
          parentAct == other.parentAct &&
          triggerArea == other.triggerArea;

  @override
  int get hashCode => parentAct.hashCode ^ triggerArea.hashCode;

  factory ProgressionInfo.fromJson(Map<String, dynamic> json) {
    return ProgressionInfo(
      triggerArea: json[JSON_TRIGGER_AREA] as String,
      parentAct: json[JSON_PARENT_ACT] as String,
      infoText: json[JSON_INFO_TEXT] as String,
    );
  }

  @override
  String toString() => "ProgressionInfo(parentAct: $parentAct, triggerArea: $triggerArea)";

  int get posInStory {
    if (triggerArea.isEmpty || parentAct.isEmpty) {
      return -1;
    }
    final List<String> actNames = Areas.actNames;
    final List<List<String>> acts = Areas.actZones;
    int counter = 0;
    for (int i = 0; i < acts.length; ++i) {
      final List<String> zones = acts[i];
      for (final String zone in zones) {
        if (parentAct == actNames.elementAt(i) && triggerArea == zone) {
          return counter;
        }
        counter++;
      }
    }
    throw AssetException(message: "Unknown progression info element $this");
  }
}
