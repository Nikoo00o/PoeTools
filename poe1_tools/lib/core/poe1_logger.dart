import 'package:game_tools_lib/core/logger/custom_logger.dart';

base class Poe1Logger extends CustomLogger {
  static const List<String> _sensitiveDataToRemove = <String>[];

  /// [additionalSensitiveDataToRemove] may be used in addition to the own sensitive data
  Poe1Logger({List<String> additionalSensitiveDataToRemove = const <String>[]})
    : super(sensitiveDataToRemove: <String>[..._sensitiveDataToRemove, ...additionalSensitiveDataToRemove]);
}
