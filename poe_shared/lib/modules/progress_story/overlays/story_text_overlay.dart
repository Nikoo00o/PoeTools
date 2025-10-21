import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_tools_lib/imports.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/helper/editable_builder.dart';
import 'package:poe_shared/presentation/overlay/opacity_overlay_mixin.dart';
import 'package:poe_shared/presentation/overlay_colors.dart';

// only uses update to display text
final class StoryTextOverlay extends OverlayElement with GTBaseWidget, OpacityOverlayMixin {
  TextSpan? _title;
  List<TextSpan>? _content;

  bool get hasContent => (_title?.text?.isNotEmpty ?? false) && (_content?.isNotEmpty ?? false);

  @override
  double get defaultOpacity => 0.45;

  static const String colorStart = "{";
  static const String colorEnd = "}";
  static const String colorDelimiter = ",";

  @override
  Widget buildEdit(BuildContext context) {
    return EditableBuilder(borderColor: Colors.cyan, overlayElement: this, alsoColorizeMiddle: true, child: null);
  }

  void update(String title, String content) {
    if (title.isEmpty || content.isEmpty) {
      _title = null;
      _content = null;
      visible = false; // also notifies listeners
    } else {
      _title = TextSpan(
        text: "$title: ",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      );
      _content = _parseContent(content);
      visible = true;
    }
  }

  static List<Point<int>> _getColorPositions(String data) {
    int startPos = -1;
    final List<Point<int>> colorPositions = <Point<int>>[];
    for (int i = 0; i < data.length; i++) {
      if (startPos >= 0) {
        if (data[i] == colorEnd) {
          colorPositions.add(Point<int>(startPos, i));
          startPos = -1;
        }
      } else if (data[i] == colorStart) {
        startPos = i;
      }
    }
    return colorPositions;
  }

  static TextSpan _spanForArea(String part) {
    if (part.isEmpty || part[0] != colorStart || part[part.length - 1] != colorEnd) {
      return TextSpan(text: part);
    }
    final String inner = part.substring(1, part.length - 1).trim();
    final int delimiter = inner.indexOf(colorDelimiter);
    if (delimiter == -1) {
      return TextSpan(text: part);
    }
    final String color = inner.substring(0, delimiter).trim();
    final String content = inner.substring(delimiter + 1).trim();
    return TextSpan(
      text: content,
      style: TextStyle(color: OverlayColors.colorForChar(color)),
    );
  }

  List<TextSpan> _parseContent(String content) {
    final List<Point<int>> colorPositions = _getColorPositions(content);
    final List<TextSpan> output = <TextSpan>[];
    if (colorPositions.isEmpty) {
      output.add(TextSpan(text: content));
    } else {
      int prevEnd = -1;
      for (int i = 0; i < colorPositions.length; i++) {
        final Point<int> pos = colorPositions[i];
        final int start = pos.x;
        final int end = pos.y; // inclusive index of }

        final int betweenStart = prevEnd + 1; // plain text between previous end and this start
        if (betweenStart < start) {
          final String plainText = content.substring(betweenStart, start);
          if (plainText.isNotEmpty) {
            output.add(TextSpan(text: plainText));
          }
        }
        final String tag = content.substring(start, end + 1); // end+1 because substring end is exclusive
        output.add(_spanForArea(tag));
        prevEnd = end;
      }

      if (prevEnd < content.length - 1) {
        final String tail = content.substring(prevEnd + 1); // text after the last tag
        if (tail.isNotEmpty) {
          output.add(TextSpan(text: tail));
        }
      }
    }
    return output;
  }

  factory StoryTextOverlay(TranslationString identifier, ScaledBounds<int> bounds) {
    final OverlayElement overlayElement =
        OverlayElement.cachedInstance(identifier) ??
        OverlayElement.storeToCache(
          StoryTextOverlay.newInstance(
            identifier: identifier,
            bounds: bounds,
          ),
        );
    return overlayElement as StoryTextOverlay;
  }

  /// New instance constructor should only be called internally from sub classes to create a new object instance!
  /// From the outside, use the default factory constructor instead!
  @protected
  StoryTextOverlay.newInstance({
    required super.identifier,
    required super.bounds,
  }) : super.newInstance(clickable: false, editable: true, visible: false, contentBuilder: null);

  Widget buildInner(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: <TextSpan>[?_title, ...?_content],
      ),
    );
  }

  @override
  Widget buildContent(BuildContext context, Bounds<double> scaledBounds) {
    return buildTransparentBackground(
      scaledBounds,
      colorSurface(context),
      padding: 5,
      child: buildInner(context),
    );
  }
}
