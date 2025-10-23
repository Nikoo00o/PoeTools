part of '../progress_story.dart';

base mixin _ProgressStoryOverlays<GM extends GameManagerBaseType> on Module<GM> {
  late final TimerXpOverlay _timerXp;

  late final StoryTextOverlay _actInfo;
  late final StoryTextOverlay _areaInfo;

  late final StoryTextOverlay _progressCur;
  late final StoryTextOverlay _progressNext;

  final List<LayoutOverlay> _layoutOverlays = <LayoutOverlay>[];

  @override
  @mustCallSuper
  Future<void> onStart() async {
    await super.onStart();
    _timerXp = TimerXpOverlay();
    _actInfo = StoryTextOverlay(
      TS.raw("General Act Info"),
      ScaledBounds<int>.defaultBounds(x: 747, y: 1324, width: 530, height: 80),
    );
    _areaInfo = StoryTextOverlay(
      TS.raw("General Area Info"),
      ScaledBounds<int>.defaultBounds(x: 1113, y: 1149, width: 681, height: 158),
    );
    _progressCur = StoryTextOverlay(
      TS.raw("Current Story Progression"),
      ScaledBounds<int>.defaultBounds(x: 1147, y: 4, width: 681, height: 185),
    );
    _progressNext = StoryTextOverlay(
      TS.raw("Next Story Progression"),
      ScaledBounds<int>.defaultBounds(x: 1150, y: 203, width: 681, height: 185),
    );
    _addDefaultLayoutOverlays();
  }

  @override
  @mustCallSuper
  Future<void> onStop() async {
    await super.onStop();
    _disableOverlays();
  }

  void _addDefaultLayoutOverlays() {
    const int x = 10;
    const int y = 10;
    const int width = 360;
    const int height = 318;
    const int elementCount = 12;
    const int startRow = 1; // second row first
    for (int i = 0; i < elementCount; ++i) {
      _layoutOverlays.add(
        LayoutOverlay(
          TS.raw("Area Layout ${i + 1}"),
          ScaledBounds<int>.defaultBounds(
            x: (x + (i % 3) * width) % (width * 3),
            y: (y + (i ~/ 3 + startRow) * height) % (height * 4),
            width: width,
            height: height,
          ),
        ),
      );
    }
  }

  // does not reset progression variables
  void _disableOverlays() {
    _timerXp.visible = false;
    _actInfo.update("", "");
    _areaInfo.update("", "");
    _progressCur.visible = false;
    _progressNext.visible = false;
    _clearLayoutOverlays(); // also clear layouts
  }

  void _clearLayoutOverlays() {
    for (int i = 0; i < _layoutOverlays.length; ++i) {
      _layoutOverlays[i].update(null, "");
    }
  }

  Future<void> _updateLayoutOverlays(LayoutAsset? layouts) async {
    if (layouts != null) {
      final List<(FileInfoAsset, NativeImage)> elements = layouts.overlayImages;
      for (int i = 0; i < _layoutOverlays.length; ++i) {
        final LayoutOverlay layoutOverlay = _layoutOverlays[i];
        if (elements.length > i) {
          final (FileInfoAsset info, NativeImage image) = elements[i];
          layoutOverlay.update(await image.getDartImage(), info.fileName);
        } else {
          layoutOverlay.update(null, "");
        }
      }
      layouts.cleanup();
    } else {
      _clearLayoutOverlays();
    }
  }

  // called when progressing to new progression step
  void _updateNextProgressionOverlay(ProgressionInfo firstProgression, ProgressionInfo? secondProgression) {
    final bool secondAvailable = secondProgression != null; // change values
    _progressCur.update("1. ${firstProgression.triggerArea}", firstProgression.infoText);
    if (secondAvailable) {
      _progressNext.update("2. ${secondProgression.triggerArea}", secondProgression.infoText);
    } else {
      _progressNext.update("", "");
    }
  }

  void _makeNextProgressionOverlayVisible() {
    if (_progressCur.visible == false) _progressCur.visible = true; // only update visible again
    if (_progressNext.visible == false && _progressNext.hasContent) _progressNext.visible = true;
  }

  void _hideProgressionOverlay() {
    _progressCur.visible = false;
    _progressNext.visible = false;
  }
}
