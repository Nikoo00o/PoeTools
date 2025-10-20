import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_types.dart';
import 'package:poe_shared/modules/area_manager/areas.dart';
import 'package:poe_shared/modules/progress_story/config/act_config.dart';
import 'package:poe_shared/modules/progress_story/config/progress_story_config.dart';
import 'package:poe_shared/modules/progress_story/config/progression_info.dart';

final class ConfigOptionBuilderProgressStoryConfig extends ConfigOptionBuilderModel<ProgressStoryConfig> {
  const ConfigOptionBuilderProgressStoryConfig({
    required super.configOption,
  });

  Widget _buildFormField(String? initialValue, void Function(String) onChanged) {
    return TextFormField(
      decoration: const InputDecoration(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
      ),
      minLines: 1,
      maxLines: 20,
      keyboardType: TextInputType.multiline,
      initialValue: initialValue ?? "",
      onChanged: onChanged,
    );
  }

  Widget buildProgressionInfo(BuildContext context, ProgressStoryConfig model) {
    return buildListOptionSimple(
      title: TS.raw("Story Progression Steps"),
      description: TS.raw(
        "Independent from Acts, you add info to be displayed after entering a specific area the "
        "first time until the next progression area is entered for the first time",
      ),

      elements: model.progressionInfo,
      addNewElementCallback: (int length) async {
        return ProgressionInfo(infoText: "", triggerArea: "");
      },
      deleteButton: true,
      buildElement: (BuildContext context, ProgressionInfo info, int elementNumber) {
        return Text("test test test ");
      },
    );
  }

  Widget _buildGeneralInfoChild(ActConfig config, ProgressStoryConfig model) {
    return buildSimpleExpansionTile(
      title: TS.raw("Always Show during whole Act"),
      element: "Always Show during whole Act",
      buildElement: (BuildContext context, _) {
        return _buildFormField(config.actInfo, (String newText) {
          config.actInfo = newText;
          configOption.setValue(model);
        });
      },
    );
  }

  Widget _buildGeneralAreaChild(String areaName, Map<String, String> areaInfoTexts, ProgressStoryConfig model) {
    return buildSimpleExpansionTile(
      title: TS.raw(areaName),
      element: areaName,
      buildElement: (BuildContext context, String areaName) {
        return _buildFormField(areaInfoTexts[areaName], (String newText) {
          areaInfoTexts[areaName] = newText;
          configOption.setValue(model);
        });
      },
    );
  }

  Widget buildGeneralAreaInfo(BuildContext context, ProgressStoryConfig model) {
    return buildListOptionSimple(
      title: TS.raw("General Info for Each Area"),
      description: TS.raw(
        "This can contain specific zone layout info in the separate entries, "
        "or general special info for each act what to pick up",
      ),
      elements: model.actNotes.keys.toList(),
      deleteButton: false,
      buildElement: (BuildContext context, String actName, int elementNumber) {
        // no correct error handling
        final ActConfig actConfig = model.actNotes[actName]!;
        final Map<String, String> areaInfoTexts = actConfig.areaInfo;
        final List<String> children = <String>["", ...Areas.getZonesForAct(actName)]; // first element is act info
        return buildListOptionSimple(
          title: TS.raw(actName),
          elements: children,
          deleteButton: false,
          buildElement: (BuildContext context, String areaName, int elementNumber) {
            if (elementNumber == 1) {
              return _buildGeneralInfoChild(actConfig, model);
            } else {
              return _buildGeneralAreaChild(areaName, areaInfoTexts, model);
            }
          },
        );
      },
    );
  }

  @override
  Widget buildContent(BuildContext context, ProgressStoryConfig model, {required bool calledFromInnerGroup}) {
    return buildMultiOptionsWithTitle(
      context: context,
      children: <Widget>[
        buildProgressionInfo(context, model),
        buildGeneralAreaInfo(context, model),
      ],
    );
  }
}
