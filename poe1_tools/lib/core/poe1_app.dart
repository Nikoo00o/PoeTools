import 'package:game_tools_lib/imports.dart';
import 'package:game_tools_lib/presentation/pages/hotkeys/gt_hotkeys_page.dart';
import 'package:game_tools_lib/presentation/pages/settings/gt_settings_page.dart';
import 'package:poe1_tools/presentation/pages/home/poe1_home_page.dart';

base class Poe1App extends GTApp {
  const Poe1App() : super(additionalNavigatorPages: const <GTNavigationPage>[]);

  @override
  List<GTNavigationPage> buildBasePages() => <GTNavigationPage>[
    const Poe1HomePage(),
    GTSettingsPage(),
    GTHotkeysPage(),
  ];
}
