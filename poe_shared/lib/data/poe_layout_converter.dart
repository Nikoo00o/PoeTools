import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/logger/custom_logger.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/data/assets/gt_asset.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:poe_shared/modules/area_manager/areas.dart';
import 'package:poe_shared/modules/area_manager/layout_asset.dart';

// needs to be started instead of the main game loop
final class _HotReload extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    PoeLayoutConverter._saveAssets();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text("Hot reload for _loadAssets"),
            FilledButton(onPressed: () => PoeLayoutConverter._loadAssets(), child: const Text("Click for _loadAssets")),
          ],
        ),
      ),
    );
  }
}

abstract final class PoeLayoutConverter {
  static List<(FileInfoAsset, NativeImage)> _assets = <(FileInfoAsset, NativeImage)>[];

  static bool runLayoutConverter() {
    Logger.initLoggerInstance(StartupLogger(LogLevel.DEBUG)); // only debug and info logs from below
    PoeLayoutConverter._loadAssets();
    runApp(MaterialApp(home: _HotReload()));
    return true;
  }

  static void _rename(Directory dir) {
    String path = dir.absolute.path;
    final List<String> parts = path.split(Platform.pathSeparator);
    final int index = parts.indexOf(LayoutAsset.layoutFolder);
    if (index != -1) {
      final List<String> beforeLayouts = parts.sublist(0, index + 1);
      final List<String> afterLayouts = parts.sublist(index + 1);
      for (int i = 0; i < afterLayouts.length; ++i) {
        afterLayouts[i] = afterLayouts[i].replaceAll(" ", "_");
      }
      final String newPath = FileUtils.combinePath(<String>[...beforeLayouts, ...afterLayouts]);
      if (path != newPath) {
        Logger.debug("Renamed asset dir: $newPath");
        dir.renameSync(newPath);
        path = newPath;
      }
    }
    final List<FileSystemEntity> files = Directory(path).listSync(recursive: false, followLinks: false).toList();
    for (final FileSystemEntity file in files) {
      if (file is Directory) {
        _rename(file);
      }
    }
  }

  static Future<void> _loadAssets() async {
    Logger.info("Layout Converter Starting and loading assets...");
    final Directory dir = Directory(GameToolsConfig.resourceFolderPath);
    final Directory parent = dir.parent;
    final Directory target = Directory(FileUtils.combinePath(<String>[parent.path, "assets", LayoutAsset.layoutFolder]));
    final List<FileSystemEntity> files = target.listSync(recursive: false, followLinks: false).toList();
    for (final FileSystemEntity file in files) {
      if (file is Directory) {
        _rename(file);
      }
    }

    _assets = <(FileInfoAsset, NativeImage)>[];
    for (final (String act, String zone) in Areas.actZonesList) {
      final List<(FileInfoAsset, NativeImage)> newAssets = LayoutAsset(actName: act, areaName: zone).overlayImages;
      if (newAssets.isNotEmpty) {
        Logger.debug("$act - $zone layouts: ${newAssets.length}");
        _assets.addAll(newAssets);
      }
    }
  }

  static late Map<String, List<String>> _mappedPaths;

  static Future<void> _saveAssets() async {
    // ignore: prefer_const_declarations
    final bool onlyTestFirst5 = false; // set for debugging
    final String parent = FileUtils.combinePath(<String>[
      GameToolsConfig.resourceFolderPath,
      "converted",
      LayoutAsset.layoutFolder,
    ]);
    Logger.info("Layout Converter Processing total ${_assets.length} images to save in $parent");
    _initPixBounds();
    _mappedPaths = <String, List<String>>{};
    int testCounter = 1;
    for (final (FileInfoAsset info, NativeImage image) in _assets) {
      final List<String> parts = info.absolutePath.split(Platform.pathSeparator);
      final int index = parts.indexOf(LayoutAsset.layoutFolder);
      if (index != -1) {
        final List<String> afterLayouts = parts.sublist(index + 1);
        if (afterLayouts.length != 3) {
          throw AssetException(message: "Invalid depth of paths under layout folder $afterLayouts");
        }
        afterLayouts[0] = afterLayouts[0].replaceAll(" ", "_");
        afterLayouts[1] = afterLayouts[1].replaceAll(" ", "_");
        if (_mappedPaths.containsKey(afterLayouts[0]) == false) {
          _mappedPaths[afterLayouts[0]] = <String>[afterLayouts[1]];
        } else if (_mappedPaths[afterLayouts[0]]!.contains(afterLayouts[1]) == false) {
          _mappedPaths[afterLayouts[0]]!.add(afterLayouts[1]);
        }

        final String newPath = FileUtils.combinePath(<String>[parent, ...afterLayouts]);
        Logger.debug("Converting ${info.absolutePath} to $newPath with $testCounter");
        await _processAsset(image, newPath);
        //ignore: dead_code
        if (onlyTestFirst5 && testCounter++ > 4) {
          return;
        }
      } else {
        throw AssetException(message: "Could not get layout path for ${info.absolutePath}");
      }
    }
    Logger.info("Layout Converter done!");
    const String basePath = "    - assets/${LayoutAsset.layoutFolder}/";
    final StringBuffer text = StringBuffer();
    for (final String actFolder in _mappedPaths.keys) {
      text.write("$basePath$actFolder/\n");
      for (final String zoneFolder in _mappedPaths[actFolder]!) {
        text.write("$basePath$actFolder/$zoneFolder/\n");
      }
    }

    Logger.info("Put into assets of pubspec.yaml:\n$text");
  }

  static void _initPixBounds() {
    _pixelBounds = <_PB>[
      _PB.diff(r: 241, g: 118, b: 166, diff: 3), // pink drawing
      _PB.diff(r: 247, g: 236, b: 47, diff: 3), // yellow drawing
      _PB.diff(r: 250, g: 162, b: 27, diff: 3), // orange drawing
      _PB.diff(r: 93, g: 187, b: 77, diff: 3), // green drawing
      _PB.diff(r: 237, g: 27, b: 81, diff: 3), // red drawing
      _PB.diff(r: 81, g: 166, b: 220, diff: 3), // blue drawing
      _PB(minR: 190, maxR: 209, minG: 78, maxG: 95, minB: 38, maxB: 42), // orange area exit darker
      _PB(minR: 212, maxR: 219, minG: 110, maxG: 127, minB: 41, maxB: 42), // orange area exit brighter
      _PB(minR: 208, maxR: 218, minG: 95, maxG: 111, minB: 41, maxB: 42), // orange area exit middle

      _PB.diff(r: 251, g: 233, b: 150, diff: 12), // questbook 1
      _PB.diff(r: 251, g: 251, b: 235, diff: 12), // questbook 1.5
      _PB.diff(r: 233, g: 25, b: 10, diff: 21), // questbook 2
      _PB.diff(r: 238, g: 230, b: 188, diff: 21), // questbook 3
      _PB.diff(r: 199, g: 181, b: 103, diff: 5), // questbook 4
      _PB.diff(r: 97, g: 85, b: 44, diff: 5), // questbook 4

      _PB.diff(r: 255, g: 255, b: 44, diff: 12), // questmark
      _PB.diff(r: 255, g: 255, b: 12, diff: 12),
      _PB.diff(r: 245, g: 192, b: 22, diff: 7),
      _PB.diff(r: 149, g: 104, b: 5, diff: 7),
      _PB.diff(r: 250, g: 202, b: 34, diff: 7),
      _PB.diff(r: 254, g: 249, b: 19, diff: 7),
      _PB.diff(r: 247, g: 205, b: 44, diff: 7),
      _PB.diff(r: 227, g: 228, b: 6, diff: 7),
      _PB.diff(r: 142, g: 142, b: 19, diff: 7),
      _PB.diff(r: 253, g: 189, b: 6, diff: 7),
      _PB.diff(r: 153, g: 153, b: 17, diff: 7),
      _PB.diff(r: 232, g: 189, b: 42, diff: 7),
      _PB.diff(r: 171, g: 171, b: 15, diff: 7),

      _PB.diff(r: 56, g: 244, b: 66, diff: 12), // green question mark
      _PB.diff(r: 47, g: 184, b: 55, diff: 12),
      _PB.diff(r: 40, g: 202, b: 31, diff: 12),
      _PB.diff(r: 35, g: 220, b: 19, diff: 12),
      _PB.diff(r: 36, g: 244, b: 19, diff: 12),

      _PB.diff(r: 254, g: 30, b: 4, diff: 12), // gate
      _PB.diff(r: 209, g: 41, b: 3, diff: 7),
      _PB.diff(r: 174, g: 40, b: 23, diff: 7),
      _PB.diff(r: 254, g: 67, b: 5, diff: 7),
      _PB.diff(r: 249, g: 141, b: 37, diff: 7),
      _PB.diff(r: 247, g: 222, b: 65, diff: 7),
      _PB.diff(r: 227, g: 189, b: 2, diff: 7),
      _PB.diff(r: 254, g: 129, b: 55, diff: 7),
      _PB.diff(r: 254, g: 101, b: 71, diff: 7),
      _PB.diff(r: 252, g: 231, b: 220, diff: 7),
      _PB.diff(r: 232, g: 179, b: 4, diff: 7),
      _PB.diff(r: 241, g: 113, b: 2, diff: 7),
      _PB.diff(r: 240, g: 185, b: 3, diff: 7),

      _PB.diff(r: 230, g: 230, b: 260, diff: 21), // waypoint white 1
      _PB.diff(r: 180, g: 200, b: 253, diff: 21), // waypoint white 2
      _PB.diff(r: 161, g: 186, b: 252, diff: 11), // waypoint white 3
      _PB.diff(r: 31, g: 92, b: 197, diff: 6), // waypoint medium blue
      _PB.diff(r: 119, g: 166, b: 234, diff: 6), // waypoint light blue
      _PB.diff(r: 49, g: 122, b: 126, diff: 6), // waypoint cyan

      _PB.diff(r: 35, g: 87, b: 177, diff: 4), // waypoint exact pix
      _PB.diff(r: 79, g: 124, b: 205, diff: 4),
      _PB.diff(r: 161, g: 186, b: 254, diff: 4),
      _PB.diff(r: 30, g: 76, b: 159, diff: 4),
      _PB.diff(r: 46, g: 120, b: 173, diff: 4),
      _PB.diff(r: 50, g: 124, b: 193, diff: 4),
      _PB.diff(r: 47, g: 122, b: 163, diff: 4),
      _PB.diff(r: 102, g: 103, b: 108, diff: 4),
      _PB.diff(r: 55, g: 82, b: 90, diff: 4),
      _PB.diff(r: 69, g: 70, b: 80, diff: 4),
      _PB.diff(r: 35, g: 100, b: 213, diff: 4),
      _PB.diff(r: 33, g: 81, b: 167, diff: 4),
      _PB.diff(r: 23, g: 69, b: 146, diff: 4),
      _PB.diff(r: 31, g: 87, b: 183, diff: 4),
      _PB.diff(r: 26, g: 58, b: 122, diff: 4),
      _PB.diff(r: 78, g: 139, b: 221, diff: 4),
      _PB.diff(r: 98, g: 139, b: 244, diff: 4),
      _PB.diff(r: 140, g: 166, b: 217, diff: 4),
      _PB.diff(r: 101, g: 148, b: 202, diff: 4),
      _PB.diff(r: 49, g: 125, b: 245, diff: 4),
      _PB.diff(r: 58, g: 126, b: 213, diff: 4),
      _PB.diff(r: 46, g: 109, b: 120, diff: 4),
      _PB.diff(r: 26, g: 58, b: 122, diff: 4),
      _PB.diff(r: 28, g: 71, b: 150, diff: 4),
      _PB.diff(r: 31, g: 81, b: 171, diff: 4),
      _PB.diff(r: 62, g: 127, b: 254, diff: 4),
      _PB.diff(r: 20, g: 48, b: 103, diff: 4),
      _PB.diff(r: 44, g: 92, b: 181, diff: 4),

      _PB.diff(r: 138, g: 139, b: 190, diff: 10), // area border middle bright
      _PB.diff(r: 118, g: 119, b: 162, diff: 10), // area border top 1.
      _PB.diff(r: 71, g: 73, b: 102, diff: 10), // area border top 2.
      _PB.diff(r: 130, g: 130, b: 153, diff: 10), // area border bot 1.
      _PB.diff(r: 120, g: 120, b: 137, diff: 10), // area border bot 2.

      _PB.diff(r: 115, g: 115, b: 155, diff: 10), // area borders extra
      _PB.diff(r: 155, g: 149, b: 193, diff: 10),
      _PB.diff(r: 161, g: 153, b: 194, diff: 10),
      _PB.diff(r: 135, g: 131, b: 172, diff: 10),
      _PB.diff(r: 146, g: 142, b: 188, diff: 10),
    ];
  }

  static late List<_PB> _pixelBounds;

  static int _pixKeep = 0;
  static int _pixRemove = 0;

  static Future<void> _processAsset(NativeImage image, String newPath) async {
    final NativeImage clone = await image.clone();
    _pixKeep = 0;
    _pixRemove = 0;
    clone.modifyPixel(_changePixel);
    final bool saved = await clone.saveAsync(newPath);
    if (saved == false) {
      throw AssetException(message: "Could not save to $newPath");
    } else {
      Logger.debug("Removed $_pixRemove pixels and kept $_pixKeep for $newPath");
    }
  }

  // B, G, R, A pixel! row = height, col = width
  static void _changePixel(int row, int col, List<num> pixel) {
    for (final _PB bounds in _pixelBounds) {
      if (bounds.keep(pixel)) {
        _pixKeep++;
        return;
      }
    }
    pixel[0] = 0;
    pixel[1] = 0;
    pixel[2] = 0;
    pixel[3] = 0;
    _pixRemove++;
  }
}

// pixel bounds are inclusive
final class _PB {
  final int minR;
  final int maxR;
  final int minG;
  final int maxG;
  final int minB;
  final int maxB;

  _PB({
    required this.minR,
    required this.maxR,
    required this.minG,
    required this.maxG,
    required this.minB,
    required this.maxB,
  });

  _PB.diff({required int r, required int g, required int b, required int diff})
    : minR = r - diff,
      maxR = r + diff,
      minG = g - diff,
      maxG = g + diff,
      minB = b - diff,
      maxB = b + diff;

  // B, G, R, A pixel!
  bool keep(List<num> pixel) {
    if (pixel.length != 4) return false;
    if (pixel[0] < minB || pixel[0] > maxB) return false;
    if (pixel[1] < minG || pixel[1] > maxG) return false;
    if (pixel[2] < minR || pixel[2] > maxR) return false;
    return true;
  }
}
