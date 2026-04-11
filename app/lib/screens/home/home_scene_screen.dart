import 'package:flutter/widgets.dart';

import 'game/home_scene_game.dart';
import 'home_scene_flame_view.dart';

class HomeSceneScreen extends StatelessWidget {
  const HomeSceneScreen({
    super.key,
    this.openTasksPanelOnStart = false,
    this.openShopPanelOnStart = false,
  });

  final bool openTasksPanelOnStart;
  final bool openShopPanelOnStart;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final device = width >= 900
        ? HomeSceneDevice.tablet
        : HomeSceneDevice.mobile;

    return HomeSceneFlameView(
      device: device,
      openTasksPanelOnStart: openTasksPanelOnStart,
      openShopPanelOnStart: openShopPanelOnStart,
    );
  }
}
