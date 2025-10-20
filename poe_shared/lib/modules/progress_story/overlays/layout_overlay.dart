import 'dart:ui' show Image;

import 'package:flutter/material.dart' hide Image;
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/core/utils/scaled_bounds.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/helper/editable_builder.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/overlay_element.dart';

// only uses update to display text
final class LayoutOverlay extends OverlayElement with GTBaseWidget {
  Image? _image;
  String _name = "";

  void update(Image? image, String name) {
    _image?.dispose(); // cleanup
    _image = image;
    _name = name;
    if (name.isEmpty || image == null) {
      visible = false; // also notifies listeners
    } else {
      visible = true;
    }
  }

  factory LayoutOverlay(TranslationString identifier, ScaledBounds<int> bounds) {
    final OverlayElement overlayElement =
        OverlayElement.cachedInstance(identifier) ??
        OverlayElement.storeToCache(
          LayoutOverlay.newInstance(
            identifier: identifier,
            bounds: bounds,
          ),
        );
    return overlayElement as LayoutOverlay;
  }

  /// New instance constructor should only be called internally from sub classes to create a new object instance!
  /// From the outside, use the default factory constructor instead!
  @protected
  LayoutOverlay.newInstance({
    required super.identifier,
    required super.bounds,
  }) : super.newInstance(clickable: false, editable: true, visible: false, contentBuilder: null);

  Widget buildInner(BuildContext context, Bounds<double> scaledBounds) {
    return Column(
      children: <Widget>[
        Text(_name),
        if (_image != null) Expanded(child: RawImage(image: _image!)),
      ],
    );
  }

  @override
  Widget buildContent(BuildContext context, Bounds<double> scaledBounds) {
    return Container(
      width: scaledBounds.width,
      height: scaledBounds.height,
      padding: const EdgeInsets.all(3),
      child: buildInner(context, scaledBounds),
    );
  }

  @override
  Widget buildEdit(BuildContext context) {
    return EditableBuilder(borderColor: Colors.orange, overlayElement: this, alsoColorizeMiddle: true, child: null);
  }
}
