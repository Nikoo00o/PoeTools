// contains the different layout images for the act and area name and transforms them on loading
import 'package:game_tools_lib/core/enums/native_image_type.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/data/assets/gt_asset.dart';
import 'package:game_tools_lib/data/native/native_image.dart';

// accessed directly in progress story. IMPORTANT: REMMEBER TO ADD ALL SUBFOLDERS TO PUBSPEC ASSETS!!!

// directly converts spaces to underscores in folders. so folder structure does not have spaces
// also converts %20 back to spaces in the file names
final class LayoutAsset {
  final String actName;

  final String areaName;

  static const String layoutFolder = "layouts";

  // the sub path after the assets dir
  late final String _pathAfterAsset;

  List<(FileInfoAsset, NativeImage)>? _cachedImages;

  LayoutAsset({required this.actName, required this.areaName}) {
    _pathAfterAsset = FileUtils.combinePath(<String>[
      layoutFolder,
      actName.replaceAll(" ", "_"),
      areaName.replaceAll(" ", "_"),
    ]);
  }

  // returns the cached and transformed overlay images with file name. may be empty if it does not exist
  List<(FileInfoAsset, NativeImage)> get overlayImages {
    if (_cachedImages != null) return _cachedImages!;
    return _cachedImages = _load();
  }

  List<(FileInfoAsset, NativeImage)> _load() {
    final List<FileInfoAsset> files = FolderAsset(subFolderPath: _pathAfterAsset).validContent;
    final List<(FileInfoAsset, NativeImage)> pairs = <(FileInfoAsset, NativeImage)>[];
    for (final FileInfoAsset file in files) {
      pairs.add((
        FileInfoAsset(fileName: file.fileName.replaceAll("%20", " "), absolutePath: file.absolutePath),
        NativeImage.readSync(path: file.absolutePath, type: NativeImageType.RGBA),
      ));
    }
    return pairs;
  }

  void cleanup() {
    if (_cachedImages != null) {
      if (_cachedImages!.isNotEmpty) {
        for (final (_, NativeImage img) in _cachedImages!) {
          img.cleanupMemory();
        }
      }
      _cachedImages = null;
    }
  }
}
