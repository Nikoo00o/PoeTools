import 'package:flutter/foundation.dart' show mustCallSuper;
import 'package:flutter/material.dart';
import 'package:game_tools_lib/imports.dart';

base mixin OpacityOverlayMixin on OverlayElement {
  // sub classes must override
  double get defaultOpacity;

  late double _opacity = defaultOpacity;

  double get opacity => _opacity;

  set opacity(double value) {
    _opacity = value;
    notifyListeners();
  }

  static const String JSON_OPACITY = "Opacity";

  @override
  @mustCallSuper
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...super.toJson(),
      JSON_OPACITY: _opacity,
    };
  }

  @override
  @mustCallSuper
  void fromJson(Map<String, dynamic> json) {
    _opacity = json[JSON_OPACITY] as double;
    super.fromJson(json);
  }

  Widget buildTransparentBackground(
    Bounds<double> scaledBounds,
    Color color, {
    double padding = 2.0,
    double borderRadius = 20,
    double borderWidth = 1.0,
    required Widget child,
  }) {
    return Container(
      width: scaledBounds.width,
      height: scaledBounds.height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        border: Border.all(
          color: color,
          width: borderWidth,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}
