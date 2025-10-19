import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/pages/home/gt_home_page.dart';

base mixin SharedHomePage on GTHomePage {
  @override
  Widget buildMiddleEnd(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 5),
        const Text("For now only english is supported as the ingame language of poe!"),
        const SizedBox(height: 5),
        buildPoeVersionSpecific(context),
      ],
    );
  }

  Widget buildPoeVersionSpecific(BuildContext context);
}
