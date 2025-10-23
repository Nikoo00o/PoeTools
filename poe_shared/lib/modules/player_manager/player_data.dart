import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/data/cached_data.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:poe_shared/core/config/shared_mutable_config.dart';

// used in player manager module
base class PlayerData extends CachedData<List<Map<String, dynamic>>> {
  static const String JSON_NAME = "Name";
  static const String JSON_LVL = "Level";
  static const String JSON_TIMER = "Timer Milliseconds";

  PlayerData() : super(identifier: "player_data");

  @override
  String get defaultJsonIdentifier => "Characters";

  List<Map<String, dynamic>> get characters => defaultValue;

  Map<String, dynamic>? getDataFor(String? playerName) {
    if (playerName == null) {
      return null;
    }
    final Iterable<Map<String, dynamic>> it = characters.where(
      (Map<String, dynamic> data) => data[JSON_NAME] == playerName,
    );
    if (it.isNotEmpty) {
      return it.first;
    } else {
      return null;
    }
  }

  // may throw exception
  Map<String, dynamic> getCurrentDataNotNull() {
    final Map<String, dynamic>? data = getDataFor(characterName);
    if (data == null) {
      throw ConfigException(message: "PlayerData not found for $characterName in $data from chars $defaultValue");
    }
    return data;
  }

  void _addEntryIfNeeded(String name) {
    final Map<String, dynamic>? data = getDataFor(name);
    if (data == null || !data.containsKey(JSON_NAME)) {
      characters.add(<String, dynamic>{JSON_NAME: name});
    }
  }

  String _currentCharCache = "";

  //  new character will be loaded on first level up in twilight strand. Otherwise on joining the
  // first area that's not the town. others may listen to changes, but should not change value! may return the
  // overridden config as well.
  // NEVER NULL, BUT IS EMPTY FIRST
  String get characterName {
    String name = SharedMutableConfig.instance.characterNameOverride.cachedValue() ?? "";
    if (name.isEmpty) {
      name = _currentCharCache;
    }
    if (name.isNotEmpty) {
      _addEntryIfNeeded(name); // only add new entry if its not empty
    }
    return name;
  }

  // only use if not already set. it can not override player names!
  set characterName(String newName) {
    if (characterName.isEmpty) {
      _addEntryIfNeeded(newName);
      _currentCharCache = newName;
      save();
    } else {
      Logger.warn("Tried to set non empty character name $characterName to $newName");
    }
  }

  // currently not tracked until lvlup. could do whois but is another chat
  // but saved for old characters
  int? get characterLvl => getDataFor(characterName)?[JSON_LVL] as int?;

  // error if playername not found
  set characterLvl(int value) {
    final Map<String, dynamic>? data = getDataFor(characterName);
    if (data != null) {
      getCurrentDataNotNull()[JSON_LVL] = value;
      save();
    }
  }

  int? get timerMilliseconds => getDataFor(characterName)?[JSON_TIMER] as int?;

  set timerMilliseconds(int value) {
    final Map<String, dynamic>? data = getDataFor(characterName);
    if (data != null) {
      getCurrentDataNotNull()[JSON_TIMER] = value;
      save();
    }
  }

  // on logging out resetting current player name cache if not overridden. and also level will then return null
  void resetCurrentCache() {
    _currentCharCache = "";
    notifyListeners();
  }
}
