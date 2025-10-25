import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:poe_shared/modules/area_manager/areas.dart';
import 'package:poe_shared/modules/progress_story/config/act_config.dart';
import 'package:poe_shared/modules/progress_story/config/progress_story_config_builder.dart';
import 'package:poe_shared/modules/progress_story/config/progression_info.dart';

typedef ProgressStoryConfigOption = ModelConfigOption<ProgressStoryConfig>;

final class ProgressStoryConfig implements Model {
  static const String JSON_ACT_NOTES = "Progression Notes";

  static const String JSON_PROGRESSION_INFO = "Progression Steps";

  static const String JSON_REPLACEMENTS = "Progression Replacement List";

  static const String JSON_ENDGAME_NOTES = "General Mapping Endgame Notes";

  /// one act after another named with correct names (only modify objects internally!)
  final Map<String, ActConfig> actNotes;

  /// one step after another independent from acts
  List<ProgressionInfo> progressionInfo;

  // for progression info names, etc
  String replacements;

  // for mapping some general info
  String endgameNotes;

  ProgressStoryConfig({
    required this.actNotes,
    required this.progressionInfo,
    required this.replacements,
    required this.endgameNotes,
  });

  static ModelConfigOption<ProgressStoryConfig> createOption() {
    return ModelConfigOption<ProgressStoryConfig>(
      title: TS.raw("Story Progression"),
      description: TS.raw(
        "You can edit the progression, or general info (and will instantly update, no restart "
        "needed). Your custom texts may contain parts with {COLOR,TEXT} which will be colorized like for example {G, "
        "green} but you may not use the braces otherwise and only the following colors are supported: R, G, B, Y, O, "
        "P, C, W ",
      ),
      defaultValue: ProgressStoryConfig.empty(),
      lazyLoaded: false,
      updateCallback: (ProgressStoryConfig? newModel) => Logger.spam("Updated progress story config $newModel"),
      createNewModelInstance: (Map<String, dynamic> json) => ProgressStoryConfig.fromJson(json),
      createModelBuilder: (ModelConfigOption<ProgressStoryConfig> option) =>
          ConfigOptionBuilderProgressStoryConfig(configOption: option),
      storeInExternalJsonFile: true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_ACT_NOTES: actNotes,
      JSON_PROGRESSION_INFO: progressionInfo,
      JSON_REPLACEMENTS: replacements,
      JSON_ENDGAME_NOTES: endgameNotes,
    };
  }

  factory ProgressStoryConfig.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> actsDyn = json[JSON_ACT_NOTES] as Map<String, dynamic>;
    final Map<String, ActConfig> acts = actsDyn.map(
      (String key, dynamic value) =>
          MapEntry<String, ActConfig>(key, ActConfig.fromJson(value as Map<String, dynamic>)),
    );
    final List<dynamic> progressionDyn = json[JSON_PROGRESSION_INFO] as List<dynamic>;
    final List<ProgressionInfo> progressionInfo = progressionDyn
        .map<ProgressionInfo>((dynamic map) => ProgressionInfo.fromJson(map as Map<String, dynamic>))
        .toList();
    return ProgressStoryConfig(
      actNotes: acts,
      progressionInfo: progressionInfo,
      replacements: json[JSON_REPLACEMENTS] as String? ?? "",
      endgameNotes: json[JSON_ENDGAME_NOTES] as String? ?? "",
    );
  }

  // can be used as default constructor
  factory ProgressStoryConfig.empty() {
    return ProgressStoryConfig(
      actNotes: <String, ActConfig>{
        for (int i = 1; i <= 10; ++i) "Act $i": ActConfig(actInfo: "", areaInfo: <String, String>{}),
      },
      progressionInfo: <ProgressionInfo>[],
      replacements: "",
      endgameNotes: "",
    );
  }

  // called only for default if areas is empty
  void fillEmptyAreas() {
    final List<List<String>> zones = Areas.actZones;
    for (int i = 0; i < 10; ++i) {
      final Map<String, String> areaInfo = actNotes.values.elementAt(i).areaInfo;
      final List<String> areas = zones.elementAt(i);
      for (int o = 0; o < areas.length; ++o) {
        areaInfo[areas.elementAt(o)] = "";
      }
    }
  }
}
