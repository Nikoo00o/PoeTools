import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/data/assets/gt_asset.dart';

// for now no multi language support :( . so also no language aware files
abstract final class Areas {
  // chatgpt: hideout names from https://www.poewiki.net/wiki/Hideout in simple json list with top level key "hideouts"
  /// then manually add "Kingsmarch" and "Aspirants' Plaza
  /// list of strings
  static final JsonAsset _hideouts = JsonAsset(subFolderPath: "areas", fileName: "hideouts");

  // one chatgpt command for towns and act areas: on https://www.poewiki.net/wiki/Town you first have a list of town names at the top including duplicates which should be put in a json list with key "towns:", but at the bottom you also have a world list with key "world" which you should put in a map with the act name as the key and then a list of area names in the correct order (dont include towns in the "world" list) as a complete version
  /// delete epilogue at bottom
  static final JsonAsset _story = JsonAsset(subFolderPath: "areas", fileName: "zones");

  // chatgpt: simple json map with key maps and value list of map names only and ignore the rest  from https://poedb.tw/us/Maps#MapsList i
  /// list of strings. NEEDS TO BE CRAWLED AGAIN EVERY SEASON FOR CURRENT AVAILABLE MAPS!
  static final JsonAsset _maps = JsonAsset(subFolderPath: "areas", fileName: "maps");

  // for example the temple, mastermind fight, syndicate safe house, other boss fights, etc
  // and "Azurite Mine", "The Forbidden Sanctum", "The Rogue Harbour", "The Menagerie"
  // todo: NOT COMPLETE YET!
  static final JsonAsset _special = JsonAsset(subFolderPath: "areas", fileName: "special");

  static List<String>? _towns;

  static final JsonAsset _goodXp = JsonAsset(subFolderPath: "areas", fileName: "good_xp");

  // correct order for acts from 0, but also epilogue
  static List<String> get towns {
    if (_towns != null) return _towns!;
    final Map<String, dynamic> json = _story.validContent;
    final List<dynamic>? element = json["towns"] as List<dynamic>?;
    if (element != null) {
      return _towns = List<String>.from(element);
    }
    throw AssetException(message: "${_story.fileName} did not contain towns");
  }

  static Map<String, dynamic>? get _world {
    final Map<String, dynamic> json = _story.validContent;
    return json["world"] as Map<String, dynamic>?;
  }

  static Map<String, List<String>> get _typedWorld {
    final Map<String, dynamic>? acts = _world;
    if (acts != null) {
      if (acts.keys.length != 10) {
        throw AssetException(message: "${_story.fileName} contained an invalid number of acts");
      }
      return acts.map(
        (String key, dynamic value) => MapEntry<String, List<String>>(key, List<String>.from(value as List<dynamic>)),
      );
    }
    throw AssetException(message: "${_story.fileName} did not contain acts");
  }

  // does not contain towns, should be correct order (0 is Act1)
  static List<String> get actNames {
    final Map<String, dynamic>? acts = _world;
    if (acts != null) {
      final List<String> actNames = acts.keys.toList();
      if (actNames.length != 10) {
        throw AssetException(message: "${_story.fileName} contained an invalid number of acts");
      }
      return actNames;
    }
    throw AssetException(message: "${_story.fileName} did not contain acts");
  }

  static List<List<String>>? _actZones;

  // does not contain towns, should be correct order (0 is Act1)
  static List<List<String>> get actZones {
    if (_actZones != null) return _actZones!;
    final Map<String, List<String>> acts = _typedWorld;
    _actZones = acts.values.toList();
    return _actZones!;
  }

  static List<(String, String)>? _actZonesList;

  // returns (Act, Zone) as list
  static List<(String, String)> get actZonesList {
    if (_actZonesList != null) return _actZonesList!;
    final List<(String, String)> results = <(String, String)>[];
    final Map<String, List<String>> acts = _typedWorld;
    for (final String act in acts.keys) {
      for (final String zone in acts[act]!) {
        results.add((act, zone));
      }
    }
    return _actZonesList = results;
  }

  static List<String> getZonesForAct(String actName) {
    final int? num = int.tryParse(actName.substring("Act ".length));
    if (num == null || num < 1 || num > 10) {
      throw AssetException(message: "could not get zones for act: $actName");
    }
    return actZones.elementAt(num - 1);
  }

  static List<String> get hideouts {
    final Map<String, dynamic> json = _hideouts.validContent;
    final List<dynamic>? element = json["hideouts"] as List<dynamic>?;
    if (element != null) {
      return List<String>.from(element);
    }
    throw AssetException(message: "${_hideouts.fileName} did not contain hideouts");
  }

  static List<String>? _mapNames;

  static List<String> get mapNames {
    if (_mapNames != null) return _mapNames!;
    final Map<String, dynamic> json = _maps.validContent;
    final List<dynamic>? element = json["maps"] as List<dynamic>?;
    if (element != null) {
      return _mapNames = List<String>.from(element);
    }
    throw AssetException(message: "${_maps.fileName} did not contain maps");
  }

  static List<String>? _specialNames;

  static List<String> get specialNames {
    if (_specialNames != null) return _specialNames!;
    final Map<String, dynamic> json = _special.validContent;
    final List<dynamic>? element = json["special"] as List<dynamic>?;
    if (element != null) {
      return _specialNames = List<String>.from(element);
    }
    throw AssetException(message: "${_special.fileName} did not contain entries");
  }

  static (int, String) getPrevXpZone(int lvl) {
    final Map<String, dynamic> json = _goodXp.validContent;
    late String key;
    late int targetLvl;
    for (int i = json.keys.length - 1; i >= 0; --i) {
      key = json.keys.elementAt(i);
      targetLvl = int.parse(key);
      if (targetLvl <= lvl) {
        return (targetLvl, json[key]);
      }
    }
    return (targetLvl, json[key]);
  }

  static (int?, String?) getNextXpZone(int lvl) {
    final Map<String, dynamic> json = _goodXp.validContent;
    for (int i = 1; i < json.keys.length; ++i) {
      final String key = json.keys.elementAt(i);
      final int targetLvl = int.parse(key);
      if (targetLvl > lvl) {
        return (targetLvl, json[key]);
      }
    }
    return (null, null);
  }
}
