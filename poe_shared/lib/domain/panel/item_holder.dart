import 'dart:math' show Point;

import 'package:game_tools_lib/core/utils/scaled_bounds.dart';
import 'package:poe_shared/domain/panel/item_area.dart';

// single item filed of an item area
base class ItemHolder {

  final ItemArea parent;
  final ScaledBounds<int> bounds;
  final int index;


  bool contains(Point<int> point){

  }

  int get row => index ~/ parent.rows;

  int get column => index % parent.rows;

}