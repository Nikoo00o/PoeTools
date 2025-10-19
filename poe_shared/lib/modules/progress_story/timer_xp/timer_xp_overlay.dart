import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_tools_lib/imports.dart';
import 'package:poe_shared/modules/area_manager/areas.dart';
import 'package:poe_shared/modules/player_manager/player_manager.dart';

base class TimerXpOverlay extends OverlayElement with GTBaseWidget {
  final SimpleChangeNotifier<int> areaLvl = SimpleChangeNotifier<int>(0);
  Timer? _timer;

  final ValueNotifier<Duration> _duration = ValueNotifier<Duration>(const Duration(seconds: 0));

  void startTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), _addTime);
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _addTime(Timer t) {
    _duration.value = Duration(seconds: _duration.value.inSeconds + 1);
  }

  factory TimerXpOverlay() {
    final TranslationString identifier = TS.raw("Timer_XP_Bar");
    final ScaledBounds<int> bounds = ScaledBounds<int>.defaultBounds(x: 1150, y: 1290, width: 520, height: 110);
    final OverlayElement overlayElement =
        OverlayElement.cachedInstance(identifier) ??
        OverlayElement.storeToCache(
          TimerXpOverlay.newInstance(
            identifier: identifier,
            bounds: bounds,
          ),
        );
    return overlayElement as TimerXpOverlay;
  }

  /// New instance constructor should only be called internally from sub classes to create a new object instance!
  /// From the outside, use the default factory constructor instead!
  @protected
  TimerXpOverlay.newInstance({
    required super.identifier,
    required super.bounds,
  }) : super.newInstance(clickable: false, editable: true, visible: false, contentBuilder: null);

  String _digits(int n) => n.toString().padLeft(2, "0");

  Widget buildTop(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: _duration,
      builder: (BuildContext context, Duration time, Widget? child) {
        final String hours = _digits(time.inHours);
        final String minutes = _digits(time.inMinutes.remainder(60));
        final String seconds = _digits(time.inSeconds.remainder(50));
        return Text("$hours : $minutes : $seconds", style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold));
      },
    );
  }

  int _getXp(int areaLvl, int characterLevel) {
    final int safeZone = 3 + characterLevel ~/ 16;
    final int diff = max((characterLevel - areaLvl).abs() - safeZone, 0);
    final double bot = (characterLevel + 5 + pow(diff.toDouble(), 2.5)).toDouble();
    final double inner = pow((characterLevel + 5) / bot, 1.5).toDouble();
    return (max(inner, 0.01) * 100).toInt();
  }

  Widget buildInnerBot(BuildContext context, int areaLvl, int characterLevel) {
    final int xp = _getXp(areaLvl, characterLevel);
    final (int lvl1, String area1) = Areas.getPrevXpZone(characterLevel);
    final (int? lvl2, String? area2) = Areas.getNextXpZone(characterLevel);
    Areas.getNextXpZone(characterLevel);
    final String second = lvl2 != null ? "$area2($lvl2)" : "maps";
    late final String text;
    if (characterLevel != 0) {
      text = "Char LvL $characterLevel in Area LvL$areaLvl gets $xp %XP\nFarm $area1($lvl1), then $second";
    } else {
      text = "Waiting to get character level from next level up...";
    }
    return Align(
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget buildWithArea(BuildContext context, int areaLvl) {
    return UIHelper.simpleValueProvider(
      value: PlayerManager.playerManager().characterLvl,
      child: UIHelper.simpleConsumer<int>(
        builder: (BuildContext context, int characterLevel, Widget? child) {
          return buildInnerBot(context, areaLvl, characterLevel);
        },
      ),
    );
  }

  Widget buildBot(BuildContext context) {
    return UIHelper.simpleValueProvider(
      value: areaLvl,
      child: UIHelper.simpleConsumer<int>(
        builder: (BuildContext context, int areaLvl, Widget? child) {
          return buildWithArea(context, areaLvl);
        },
      ),
    );
  }

  @override
  Widget buildContent(BuildContext context, Bounds<double> scaledBounds) {
    return Container(
      width: scaledBounds.width,
      height: scaledBounds.height,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colorSurface(context).withValues(alpha: 0.65),
        border: Border.all(
          color: colorSurface(context),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: <Widget>[buildTop(context), const SizedBox(height: 8), buildBot(context)]),
    );
  }
}
