import 'dart:io';
import 'package:html/dom.dart' show Element, Document;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:html/parser.dart' as parser;
import 'dart:convert';

// IMPORTANT: TWILIGHT STRAND IS HARDCODED FROM QUEST REWARDS

// always run from INNER POE1 directory per cmd, or use run configuration for relative paths to work!
Future<void> main() async {
  print("Running from ${Directory.current.absolute.path}");
  await downloadActiveGems();
  await downloadQuestRewards();
  await downloadVendorBuys();
  await downloadQuestsToTowns();
}

Future<void> downloadActiveGems() async {
  final gems = await crawlGemList();
  File("assets/items/gems.json").writeAsStringSync(const JsonEncoder.withIndent('  ').convert(gems));
  print("got new active gems: $gems");

  final List<Map<String, String>> gemList = gems!["gems"] as List<Map<String, String>>;
  Map<String, String>? _last;
  bool skip = true;

  for (final Map<String, String> gem in gemList) {
    if (skip) {
      if (gem["name"] == "Despair") {
        skip = false;
      }
      continue;
    }
    try {
      _last = gem;
      await downloadAndConvertWebpToPng(gem["name"]!, gem["icon"]!);
      await Future<void>.delayed(Duration(seconds: 1));
    } catch (e, s) {
      print("error, trying after long delay... $e in $s");
      await Future<void>.delayed(Duration(minutes: 2));
      await downloadAndConvertWebpToPng(_last!["name"]!, _last["icon"]!);
      await Future<void>.delayed(Duration(seconds: 1));
    }
  }
  print("saved all active gem icons!");
}

Future<Map<String, List<Map<String, String>>>?> crawlGemList() async {
  print("Trying to crawl gems...");
  final url = 'https://poedb.tw/us/Skill_Gems#SkillGemsGem';
  final resp = await http.get(Uri.parse(url));

  if (resp.statusCode != 200) {
    stderr.writeln('Failed to fetch page: ${resp.statusCode}');
    exit(2);
  }

  final Document doc = parser.parse(resp.body);

  // Find the top-level container
  final root = doc.querySelector('.clearfix.row.no-gutters');
  if (root == null) {
    stderr.writeln('Could not find top-level .clearfix.row.no-gutters container.');
    exit(3);
  }

  // Collect child column DIVs in order (tolerant to small class-name typos)
  final List<Element> cols = [];
  for (final child in root.children) {
    final cls = child.attributes['class'] ?? '';
    // Accept expected class or common typo 'rol-md-4' or any token containing 'col' and 'md-4'
    final normalized = cls.replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.contains('col-md-4') ||
        normalized.contains('rol-md-4') ||
        RegExp(r'col.*md-4').hasMatch(normalized)) {
      cols.add(child);
    }
  }

  if (cols.length < 3) {
    // As fallback, try to find any descendant divs with col-md-4 class
    final fallback = root.querySelectorAll('div').where((e) {
      final c = e.attributes['class'] ?? '';
      return c.contains('col-md-4') || c.contains('rol-md-4') || RegExp(r'col.*md-4').hasMatch(c);
    }).toList();
    if (fallback.length >= 3) {
      cols
        ..clear()
        ..addAll(fallback.take(3));
    }
  }

  if (cols.length < 3) {
    stderr.writeln('Could not find three gem columns (expected 3 col-md-4 divs). Found: ${cols.length}');
    exit(4);
  }

  final List<Map<String, String>> gems = [];
  final types = ['R', 'G', 'B'];

  for (var i = 0; i < 3; i++) {
    final col = cols[i];
    final type = types[i];

    // Find gem links inside tbody of the table in this column
    // Be permissive: search for 'tbody a' inside the column
    final links = col.querySelectorAll('tbody a');
    for (final a in links) {
      final name = a.text?.trim() ?? '';
      if (name.isEmpty) continue;
      // filter out unrelated links (if any)
      if (name.toLowerCase().contains('skill gems')) continue;
      Element? row = a.parent;
      while (row != null && row.localName != 'tr') {
        row = row.parent;
      }

      String icon = '';
      if (row != null) {
        final img = row.querySelector('img');
        if (img != null) {
          final src = img.attributes['src'] ?? '';
          if (src.isNotEmpty) {
            icon = src.startsWith('http') ? src : 'https://cdn.poedb.tw${src.startsWith('/') ? src : '/$src'}';
          }
        }
      }

      gems.add({
        'name': name,
        'type': type,
        'icon': icon,
      });
    }
  }

  // Deduplicate preserving first-seen order
  final seen = <String>{};
  final unique = <Map<String, String>>[];
  for (final g in gems) {
    final n = g['name']!;
    if (seen.add(n)) unique.add(g);
  }

  return {"gems": unique};
}

List<String> _contained = <String>[];

Future<void> downloadAndConvertWebpToPng(String gemName, String gemUrl) async {
  if (_contained.contains(gemUrl)) {
    print("$gemName was already contained");
    return;
  }
  _contained.add(gemUrl);
  final String outputPath = 'assets/images/gems/$gemName.png';

  print('Downloading gem image for $gemName...');

  final response = await http.get(
    Uri.parse(gemUrl),
    headers: {
      // Pretend to be a regular browser
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
      'Referer': 'https://poedb.tw/',
    },
  );

  if (response.statusCode != 200) {
    print('Failed to download image. Status code: ${response.statusCode} for $gemUrl');
    return;
  }

  img.Image? webpImage = img.decodeWebP(response.bodyBytes);

  if (webpImage == null) {
    print('Error: Failed to decode WEBP image.');
    return;
  }
  webpImage = img.copyResize(webpImage, width: 68, height: 68);

  final pngBytes = img.encodePng(webpImage);

  final file = File(outputPath);
  await file.writeAsBytes(pngBytes);

  print('Saved to $outputPath');
}

Future<void> downloadQuestRewards() async {
  final url = 'https://poedb.tw/us/QuestRewards#QuestReward';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode != 200) {
    stderr.writeln('Failed to fetch page: ${response.statusCode}');
    exit(1);
  }

  final document = parser.parse(response.body);
  final questRewards = <String, Map<String, List<String>>>{};

  // Find all tables under div.card-body
  final tables = document.querySelectorAll('div.card-body table.table.table-hover.table-striped.filters');

  for (final table in tables) {
    // Extract class names from the table header
    final classHeaders = table.querySelectorAll('thead th');
    final classNames = classHeaders.skip(1).map((th) => th.text.trim()).toList();

    // Track current quest for multi-row quests
    String? currentQuest;

    final tbodyRows = table.querySelectorAll('tbody tr');
    for (final row in tbodyRows) {
      final tds = row.querySelectorAll('td');
      if (tds.isEmpty) continue;

      // First td may contain quest name
      final firstTd = tds.first.text.trim();
      if (firstTd.isNotEmpty) {
        // Remove Act suffix if present
        currentQuest = firstTd.replaceAll(RegExp(r'\s*Act\d+$'), '');
        if (!questRewards.containsKey(currentQuest)) {
          questRewards[currentQuest] = {};
        }
      } else if (currentQuest == null) {
        // Skip rows before the first quest
        continue;
      }

      // Remaining tds correspond to classes
      for (var i = 0; i < classNames.length && i < tds.length - 1; i++) {
        final className = classNames[i];
        final gemLinks = tds[i + 1].querySelectorAll('a[href*="/us/"]');
        final gemNames = gemLinks.map((a) => a.text.trim()).where((n) => n.isNotEmpty).toList();

        if (questRewards[currentQuest!]!.containsKey(className)) {
          questRewards[currentQuest!]![className]!.addAll(gemNames);
        } else {
          questRewards[currentQuest!]![className] = gemNames;
        }
      }
    }
  }

  questRewards['The Twilight Strand'] = {
    'Marauder': ['Heavy Strike', 'Ruthless Support'],
    'Witch': ['Fireball', 'Arcane Surge', 'Support'],
    'Scion': ['Spectral Throw', 'Prismatic Burst', 'Support'],
    'Ranger': ['Burning Arrow', 'Momentum', 'Support'],
    'Duelist': ['Double Strike', 'Chance to Bleed', 'Support'],
    'Shadow': ['Viper Strike', 'Chance to Poison', 'Support'],
    'Templar': ['Glacial Hammer', 'Elemental Proliferation', 'Support'],
  };

  // remove entries with same reward for each class (so never gems)
  for (int i = 0; i < questRewards.keys.length; ++i) {
    if ((questRewards[questRewards.keys.elementAt(i)] as Map<String, dynamic>).length < 5) {
      questRewards.remove(questRewards.keys.elementAt(i--));
    }
  }

  // last quests give class specific items
  for (int i = 0; i < 5; ++i) {
    questRewards.remove(questRewards.keys.elementAt(questRewards.keys.length - 1));
  }

  final jsonOutput = const JsonEncoder.withIndent('  ').convert(questRewards);
  print(jsonOutput);

  File("assets/items/quest_rewards.json").writeAsStringSync(jsonOutput);
  print('Saved quest rewards');
}

Future<void> downloadVendorBuys() async {
  final url = 'https://poedb.tw/us/QuestRewards#QuestVendorRewards';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode != 200) {
    stderr.writeln('Failed to fetch page: ${response.statusCode}');
    exit(1);
  }

  final document = parser.parse(response.body);
  final questVendorRewards = <String, Map<String, List<String>>>{};

  // Select the div with id "QuestVendorRewards"
  final vendorDiv = document.querySelector('div#QuestVendorRewards');
  if (vendorDiv == null) {
    stderr.writeln('QuestVendorRewards div not found.');
    exit(1);
  }

  // Select the table inside this div
  final table = vendorDiv.querySelector('table');
  if (table == null) {
    stderr.writeln('Vendor Rewards table not found inside QuestVendorRewards.');
    exit(1);
  }

  // Extract class names from the header (skip first "Quest" column)
  final classHeaders = table.querySelectorAll('thead th');
  final classNames = classHeaders.skip(1).map((th) => th.text.trim()).toList();

  // Process each row in tbody
  for (final row in table.querySelectorAll('tbody tr')) {
    final tds = row.querySelectorAll('td');
    if (tds.isEmpty) continue;

    // Quest name (first td)
    var questName = tds.first.text.trim();
    if (questName.isEmpty) continue;

    // Remove Act suffix
    questName = questName.replaceAll(RegExp(r'\s*Act\d+$'), '');

    // Map rewards per class
    final questMap = <String, List<String>>{};
    for (var i = 0; i < classNames.length && i < tds.length - 1; i++) {
      final className = classNames[i];
      final itemLinks = tds[i + 1].querySelectorAll('a[href*="/us/"]');
      final itemNames = itemLinks.map((a) => a.text.trim()).where((n) => n.isNotEmpty).toList();
      if (itemNames.isNotEmpty) {
        questMap[className] = itemNames;
      }
    }

    // Only add quests with at least one reward
    if (questMap.isNotEmpty) {
      questVendorRewards[questName] = questMap;
    }
  }

  // Output JSON
  final jsonOutput = const JsonEncoder.withIndent('  ').convert(questVendorRewards);
  print(jsonOutput);

  File("assets/items/vendor_buys.json").writeAsStringSync(jsonOutput);
  print('Saved vendor buys');
}

Future<void> downloadQuestsToTowns() async {
  final url = 'https://www.poewiki.net/wiki/Quest';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode != 200) {
    stderr.writeln('Failed to fetch page: ${response.statusCode}');
    exit(1);
  }

  final document = parser.parse(response.body);
  final questData = <String, List<String>>{};

  final actTitles = [
    'Act 1',
    'Act 2',
    'Act 3',
    'Act 4',
    'Act 5',
    'Act 6',
    'Act 7',
    'Act 8',
    'Act 9',
    'Act 10',
    'Epilogue',
  ];

  final headers = document.querySelectorAll('h3');

  for (final actTitle in actTitles) {
    // Find the header manually without firstWhere
    Element? header;
    for (final h in headers) {
      if (h.text.trim() == actTitle) {
        header = h;
        break;
      }
    }

    if (header != null) {
      final questList = <String>[];
      Element? sibling = header.nextElementSibling;

      while (sibling != null && sibling.localName != 'h3') {
        if (sibling.localName == 'ul') {
          for (final li in sibling.querySelectorAll('li')) {
            final questName = li.text.trim();
            if (questName.isNotEmpty) {
              questList.add(questName);
            }
          }
        }
        sibling = sibling.nextElementSibling;
      }

      if (questList.isNotEmpty) {
        questData[actTitle] = questList;
      }
    }
  }

  final jsonOutput = const JsonEncoder.withIndent('  ').convert(questData);
  print(jsonOutput);

  File("assets/items/quest_to_act.json").writeAsStringSync(jsonOutput);
  print('Saved vendor buys');
}
