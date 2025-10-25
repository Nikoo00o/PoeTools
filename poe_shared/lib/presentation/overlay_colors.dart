import 'dart:ui' show Color;

abstract final class OverlayColors {
  static const Color white = Color.fromARGB(255, 255, 255, 255);
  static const Color red = Color.fromARGB(255, 255, 0, 0);
  static const Color green = Color.fromARGB(255, 0, 255, 0);
  static const Color blue = Color.fromARGB(255, 40, 110, 230); // not fully dark because of bad visibility
  static const Color yellow = Color.fromARGB(255, 255, 255, 0);
  static const Color orange = Color.fromARGB(255, 255, 165, 0);
  static const Color purple = Color.fromARGB(255, 128, 0, 128);
  static const Color cyan = Color.fromARGB(255, 0, 255, 255);

  static Color colorForChar(String char) => switch (char) {
    "R" => red,
    "G" => green,
    "B" => blue,
    "Y" => yellow,
    "O" => orange,
    "P" => purple,
    "C" => cyan,
    _ => white,
  };
}
