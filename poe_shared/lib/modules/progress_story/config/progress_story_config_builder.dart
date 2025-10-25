import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_types.dart';
import 'package:game_tools_lib/presentation/pages/settings/gt_list_editor.dart';
import 'package:poe_shared/modules/area_manager/areas.dart';
import 'package:poe_shared/modules/progress_story/config/act_config.dart';
import 'package:poe_shared/modules/progress_story/config/progress_story_config.dart';
import 'package:poe_shared/modules/progress_story/config/progression_info.dart';

final class ConfigOptionBuilderProgressStoryConfig extends ConfigOptionBuilderModel<ProgressStoryConfig> {
  const ConfigOptionBuilderProgressStoryConfig({
    required super.configOption,
  });

  Widget _buildFormField(String? initialValue, void Function(String) onChanged, {String? hint, int? maxLength}) {
    return TextFormField(
      decoration: InputDecoration(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        hintText: hint,
      ),
      minLines: 1,
      maxLines: 20,
      keyboardType: TextInputType.multiline,
      initialValue: initialValue ?? "",
      onChanged: onChanged,
      maxLength: maxLength,
    );
  }

  Widget buildProgressionElement(BuildContext context, ProgressionInfo info, ProgressStoryConfig model) {
    return Column(
      children: <Widget>[
        _buildFormField(info.infoText, (String newText) {
          info.infoText = newText;
          configOption.setValue(model);
        }, hint: "enter general info to be shown in overlay until next step..."),
      ],
    );
  }

  Widget _buildList(
    int offset,
    String act,
    List<String> zones,
    ProgressStoryConfig model,
    void Function(int index, String act, String zone) onSelect,
    int selectedIndex,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: zones.length,
      itemBuilder: (_, int index) {
        final int shiftedIndex = index + offset;
        final bool selected = selectedIndex == shiftedIndex;
        if (selected) {
          Logger.verbose("$act and ${zones[index]} selected! for $selectedIndex and $index + $offset");
        }
        return Card(
          child: ListTile(
            enabled:
                shiftedIndex == selectedIndex ||
                model.progressionInfo
                    .where((ProgressionInfo info) => info.parentAct == act && info.triggerArea == zones[index])
                    .isEmpty,
            title: Text(zones[index]),
            trailing: selected ? const Icon(Icons.check) : null,
            onTap: () => onSelect(shiftedIndex, act, zones[index]),
            selected: selected,
          ),
        );
      },
    );
  }

  Widget buildProgressionCreation(
    BuildContext context,
    ProgressionInfo? oldElement,
    GTListOnElementUpdate<ProgressionInfo> onElementUpdate,
    ProgressStoryConfig model,
  ) {
    final List<(String, String)> zones = Areas.actZonesList;
    final List<List<String>> listsPerAct = Areas.actZones;
    final List<String> actNames = Areas.actNames;
    int selectedIndex = -1;
    if (oldElement != null) {
      selectedIndex = zones.indexWhere(
        ((String, String) el) => oldElement.parentAct == el.$1 && oldElement.triggerArea == el.$2,
      );
    }
    return SingleChildScrollView(
      child: SizedBox(
        width: 600,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            onSelect(int index, String act, String zone) {
              setState(() => selectedIndex = selectedIndex == index ? -1 : index);
              final ProgressionInfo newEl = oldElement ?? ProgressionInfo.empty();
              newEl.parentAct = act;
              newEl.triggerArea = zone;
              onElementUpdate.call(newEl);
              Logger.spam("Selected $newEl");
            }

            final List<Widget> children = <Widget>[];
            int offset = 0;
            for (int i = 0; i < listsPerAct.length; ++i) {
              final List<String> subList = listsPerAct.elementAt(i);
              final String act = actNames.elementAt(i);
              final int myOffset = offset;
              children.add(
                buildSimpleExpansionTile<String>(
                  title: TS.raw(act),
                  element: "",
                  buildElement: (BuildContext context, _) =>
                      _buildList(myOffset, act, subList, model, onSelect, selectedIndex),
                ),
              );
              offset += subList.length;
            }
            return Column(children: children);
          },
        ),
      ),
    );
  }

  Widget buildProgressionInfo(BuildContext context, ProgressStoryConfig model) {
    return buildListOption<ProgressionInfo>(
      title: TS.raw("Story Progression Steps"),
      description: TS.raw(
        "Independent from Acts, you add info to be displayed after entering a specific area the "
        "first time until the next progression area is entered for the first time. DON'T EDIT THIS WHILE PROGRESSING "
        "THE STORY",
      ),
      elements: model.progressionInfo,
      buildEditButtons: true,
      onChange: () {
        model.progressionInfo.sort((ProgressionInfo i1, ProgressionInfo i2) => i1.posInStory.compareTo(i2.posInStory));
        configOption.setValue(model);
      },
      buildCreateOrEditDialog:
          (
            BuildContext context,
            ProgressionInfo? oldElement,
            int elementNumber,
            GTListOnElementUpdate<ProgressionInfo> onElementUpdate,
          ) => buildProgressionCreation(context, oldElement, onElementUpdate, model),
      buildElement: (BuildContext context, ProgressionInfo info, int elementNumber) {
        return buildSimpleExpansionTile(
          key: ValueKey<ProgressionInfo>(info),
          title: TS.raw("${info.parentAct}: ${info.triggerArea}"),
          element: info,
          buildElement: (BuildContext context, ProgressionInfo info) => buildProgressionElement(context, info, model),
        );
      },
      maxHeight: 800,
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

  Widget _buildTownRegex(ActConfig config, ProgressStoryConfig model) {
    return buildSimpleExpansionTile(
      title: TS.raw("Vendor Regex for Ctrl+V"),
      element: "Vendor Regex for Ctrl+V",
      buildElement: (BuildContext context, _) {
        return _buildFormField(config.vendorRegex, (String newText) {
          config.vendorRegex = newText;
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
        "or general special info for each act what to pick up. Or vendor regexes",
      ),
      elements: model.actNotes.keys.toList(),
      deleteButton: false,
      buildElement: (BuildContext context, String actName, int _) {
        // no correct error handling
        final ActConfig actConfig = model.actNotes[actName]!;
        final Map<String, String> areaInfoTexts = actConfig.areaInfo;
        final List<String> children = <String>["", "", ...Areas.getZonesForAct(actName)]; // first element is act info
        return buildListOptionSimple(
          title: TS.raw(actName),
          elements: children,
          deleteButton: false,
          buildElement: (BuildContext context, String areaName, int elementNumber) {
            if (elementNumber == 1) {
              return _buildGeneralInfoChild(actConfig, model);
            } else if (elementNumber == 2) {
              return _buildTownRegex(actConfig, model);
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
        buildSimpleExpansionTile(
          title: TS.raw("Story Progression Replacements"),
          description: TS.raw(
            "Used below in the Steps. Separate entries with \";\" and use \"KEY=VALUE\". For example to set names for "
            "group leveling with \"G_P1={R,Name1};G_P2={G,Name2}\"",
          ),
          element: "",
          buildElement: (BuildContext context, String _) {
            return _buildFormField(model.replacements, (String newData) {
              model.replacements = newData;
              configOption.setValue(model);
            }, hint: "For example \"G_P1={R,Name1};G_P2={G,Name2}\"", maxLength: 250);
          },
        ),
        buildProgressionInfo(context, model),
        buildGeneralAreaInfo(context, model),
        buildSimpleExpansionTile(
          title: TS.raw("Endgame Mapping Notes"),
          description: TS.raw(
            "General speedrun tactics for endgame can be input here to show during all non unique maps",
          ),
          element: "",
          buildElement: (BuildContext context, String _) {
            return _buildFormField(model.endgameNotes, (String newData) {
              model.endgameNotes = newData;
              configOption.setValue(model);
            }, hint: "Enter Endgame Mapping Notes");
          },
        ),
      ],
    );
  }
}
