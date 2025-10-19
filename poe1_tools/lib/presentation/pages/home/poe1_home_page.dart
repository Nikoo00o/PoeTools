import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/pages/home/gt_home_page.dart';
import 'package:poe_shared/presentation/pages/home/shared_home_page.dart';

base class Poe1HomePage extends GTHomePage with SharedHomePage {
  const Poe1HomePage({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
  });

  @override
  Widget buildPoeVersionSpecific(BuildContext context) => const SizedBox();
}
