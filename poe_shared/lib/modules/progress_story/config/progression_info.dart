import 'package:game_tools_lib/domain/entities/base/model.dart';

final class ProgressionInfo implements Model {
  static const String JSON_TRIGGER_AREA = "Area to show after";
  static const String JSON_INFO_TEXT = "Info Text to show";

  String triggerArea;

  String infoText;

  // todo: gem info

  ProgressionInfo({required this.triggerArea, required this.infoText});

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_TRIGGER_AREA: triggerArea,
      JSON_INFO_TEXT: infoText,
    };
  }

  factory ProgressionInfo.fromJson(Map<String, dynamic> json) {
    return ProgressionInfo(
      triggerArea: json[JSON_TRIGGER_AREA] as String,
      infoText: json[JSON_INFO_TEXT] as String,
    );
  }
}
