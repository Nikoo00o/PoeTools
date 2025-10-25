// div cards could also be parsed from site

// maps json also contains acts as well

final class MapInfo {
  // if map is currently on atlas
  final bool atlas;
  final List<String> bossIds;
  final List<String> connected;
  final String? image;
  final Map<String, dynamic> info;
  final String name;
  final Rating rating;
  final Tags tags;
  final String type;

  MapInfo({
    required this.atlas,
    required this.bossIds,
    required this.connected,
    required this.image,
    required this.info,
    required this.name,
    required this.rating,
    required this.tags,
    required this.type,
  });

  factory MapInfo.fromJson(Map<String, dynamic> json) {
    String name = json['name'] as String? ?? "UNKNOWN_MAP";
    if (name.endsWith(" Map")) {
      name = name.substring(0, name.length - 4); // remove " Map" at the end
    }
    final List<String> connected = List<String>.from(json['connected'] as List<dynamic>? ?? <String>[]);
    return MapInfo(
      name: name,
      connected: connected.map((String name) {
        if (name.endsWith(" Map")) {
          return name.substring(0, name.length - 4); // remove " Map" at the end
        }
        return name;
      }).toList(),
      atlas: json['atlas'] as bool? ?? false,
      bossIds: List<String>.from(json['boss_ids'] as List<dynamic>? ?? <String>[]),
      image: json['image'] as String?,
      info: json['info'] as Map<String, dynamic>? ?? <String, dynamic>{},
      rating: Rating.fromJson(json['rating'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      tags: Tags.fromJson(json['tags'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      type: json['type'] as String? ?? "UNKNOWN_TYPE",
    );
  }

  bool get isUnique => type == "unique map";

  // for overlay
  String getTextToDisplay() {
    final StringBuffer text = StringBuffer();
    text.write("Conn: $connected, Boss Num: ${bossIds.length}, Ratings: ${rating.getTextToDisplay()}");
    text.write("\n${tags.getTextToDisplay()}");
    return text.toString();
  }
}

class Rating {
  final int boss;
  final int density;
  final int layout;

  Rating({
    required this.boss,
    required this.density,
    required this.layout,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      boss: json['boss'] as int? ?? 0,
      density: json['density'] as int? ?? 0,
      layout: json['layout'] as int? ?? 0,
    );
  }

  String getTextToDisplay() {
    final StringBuffer text = StringBuffer();
    text.write("Boss: $boss, Layout: $layout, Density: $density");
    return text.toString();
  }
}

class Tags {
  final bool bossNotSpawned;
  final bool bossPhases;
  final bool bossRushable;
  final bool bossSeparated;
  final bool deliriumMirror;
  final bool fewObstacles;
  final bool leagueMechanics;
  final bool linear;
  final bool outdoors;
  final bool bossNotTwinAble;
  final String t17Drop;

  Tags({
    required this.bossNotSpawned,
    required this.bossPhases,
    required this.bossRushable,
    required this.bossSeparated,
    required this.deliriumMirror,
    required this.fewObstacles,
    required this.leagueMechanics,
    required this.linear,
    required this.outdoors,
    required this.bossNotTwinAble,
    required this.t17Drop,
  });

  factory Tags.fromJson(Map<String, dynamic> json) {
    final bool sanc = json['sanctuary_map'] as bool? ?? false;
    final bool zig = json['ziggurat_map'] as bool? ?? false;
    final bool cit = json['citadel_map'] as bool? ?? false;
    final bool abo = json['abomination_map'] as bool? ?? false;

    return Tags(
      bossNotSpawned: json['boss_not_spawned'] as bool? ?? false,
      bossPhases: json['boss_phases'] as bool? ?? false,
      bossRushable: json['boss_rushable'] as bool? ?? false,
      bossSeparated: json['boss_separated'] as bool? ?? false,
      deliriumMirror: json['delirium_mirror'] as bool? ?? false,
      fewObstacles: json['few_obstacles'] as bool? ?? false,
      leagueMechanics: json['league_mechanics'] as bool? ?? false,
      linear: json['linear'] as bool? ?? false,
      outdoors: json['outdoors'] as bool? ?? false,
      bossNotTwinAble: json['boss_not_twinnable'] as bool? ?? false,
      t17Drop: sanc
          ? "Sanctuary"
          : zig
          ? "Ziggurat"
          : cit
          ? "Citadel"
          : abo
          ? "Abomination"
          : "none",
    );
  }

  String getTextToDisplay() {
    final StringBuffer text = StringBuffer();
    text.write("T17 drop: $t17Drop, Tags:");
    if (linear) text.write(" Linear,");
    if (fewObstacles) text.write(" No Obstacles,");
    if (outdoors) text.write(" Outdoor,");
    if (leagueMechanics) text.write(" League Mechs,");

    if (bossNotSpawned) text.write(" Late Boss,");
    if (bossRushable) text.write(" Rush Boss,");
    if (bossPhases) text.write(" Phased Boss,");
    if (bossSeparated) text.write(" Seperatable Boss,");
    return text.toString();
  }
}
