import 'package:game_tools_lib/domain/entities/base/model.dart';

final class ActConfig implements Model {
  static const String JSON_ACT_INFO = "Show for whole Act";
  static const String JSON_VENDOR_REGEX = "Vendor Regex";
  static const String JSON_AREA_INFO = "Show for whole Areas";

  /// may be empty
  String actInfo;

  /// has max limit that is currently not enforced! mayb be empty!
  String vendorRegex;

  /// key is area name
  Map<String, String> areaInfo;

  ActConfig({required this.actInfo, required this.vendorRegex, required this.areaInfo});

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_ACT_INFO: actInfo,
      JSON_VENDOR_REGEX: vendorRegex,
      JSON_AREA_INFO: areaInfo,
    };
  }

  factory ActConfig.fromJson(Map<String, dynamic> json) {
    return ActConfig(
      actInfo: json[JSON_ACT_INFO] as String,
      vendorRegex: json[JSON_VENDOR_REGEX] as String? ?? "", // migration for old versions
      areaInfo: Map<String, String>.from(json[JSON_AREA_INFO] as Map<String, dynamic>),
    );
  }
}
