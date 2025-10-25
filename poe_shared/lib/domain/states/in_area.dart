import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:poe_shared/modules/area_manager/areas.dart';

final class InArea extends GameState {
  final String areaName;

  /// Default would be 0
  final int areaLevel;

  static const int maxAreaLevelForPart1 = 44;

  /// Only for areas which may have the same name, this can be true depending on the area level
  bool get isSecondPart => areaLevel > maxAreaLevelForPart1;

  InArea({
    required this.areaName,
    required this.areaLevel,
  });

  @override
  Future<void> onStart(GameState oldState) async {
    await super.onStart(oldState);
  }

  @override
  Future<void> onStop(GameState newState) async {}

  @override
  Future<void> onUpdate() async {}

  bool get isHideout => Areas.hideouts.contains(areaName);

  bool get isTown => Areas.towns.contains(areaName);

  bool get isMap => Areas.getMapInfo(areaName) != null;

  /// does not return true for towns
  bool get isStoryZone {
    for (final List<String> zones in Areas.actZones) {
      if (zones.contains(areaName)) {
        return true;
      }
    }
    return false;
  }

  /// special area like
  bool get isSpecial => Areas.specialNames.contains(areaName);

  String get areaType {
    if (isHideout) return "Hideout";
    if (isTown) return "Town";
    if (isMap) return "Map";
    if (isStoryZone) return "Zone";
    if (isSpecial) return "Special";
    return "Area";
  }

  // just returns -1 if not story zone (for towns 0!). exception if story zone not found
  /// ZERO BASED ACCESS!!!
  int get actForStoryZone {
    if (isStoryZone) {
      final List<List<String>> acts = Areas.actZones;
      late int start, end;
      if (isSecondPart) {
        start = 5;
        end = 10;
      } else {
        start = 0;
        end = 5;
      }
      for (int i = start; i < end; ++i) {
        if (isContainedInAct(acts.elementAt(i))) {
          return i;
        }
      }
      throw AssetException(message: "Could not find zone $areaName in acts $acts");
    } else if (isTown) {
      return 0;
    }
    return -1;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is InArea && areaName == other.areaName && areaLevel == other.areaLevel;

  @override
  int get hashCode => Object.hash(areaName.hashCode, areaLevel.hashCode);

  bool isContainedInAct(List<String> areas) {
    Logger.verbose("Comparing $areaName to ${areas.join(",")}");
    return areas.contains(areaName);
  }

  @override
  String get welcomeMessage => "Joined $areaType $areaName LvL $areaLevel";
}
