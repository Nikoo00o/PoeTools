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
        const Text(
          "IMPORTANT: your local chat must be enabled and on the first join into a different than town "
          "area, the tool will write smth in local chat to get your character name! You can disable this by "
          "overriding your character name in the settings!",
        ),
        const SizedBox(height: 5),
        buildPoeVersionSpecific(context),
      ],
    );
  }

  Widget buildPoeVersionSpecific(BuildContext context);
}
