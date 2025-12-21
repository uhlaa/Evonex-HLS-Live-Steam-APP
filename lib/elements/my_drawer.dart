import 'package:evonex/screens/credits_copyrights_screen.dart';
import 'package:evonex/screens/match_home_screen.dart';
import 'package:evonex/theme/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

class NewDrawer extends StatefulWidget {
  const NewDrawer({super.key});

  @override
  State<NewDrawer> createState() => _NewDrawerState();
}

class _NewDrawerState extends State<NewDrawer> {
  final AdvancedDrawerController _drawerController =
      AdvancedDrawerController();

  int _currentIndex = 0;
  bool notificationsEnabled = true;

  Future<void> _selectScreen(int index) async {
    _drawerController.hideDrawer();
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return AdvancedDrawer(
      controller: _drawerController,
      backdrop: Container(
        color: Theme.of(context)
            .colorScheme
            .secondary
            .withOpacity(0.92),
      ),
      openRatio: 0.65,
      openScale: 0.78,
      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeOutCubic,
      childDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
      ),

      /// 🔥 MAIN CONTENT (ALL SCREENS HERE)
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: IndexedStack(
          key: ValueKey(_currentIndex),
          index: _currentIndex,
          children: [
            MatchHomeScreen(
              advancedDrawerController: _drawerController,
            ),
            CreditsCopyrightScreen(
              advancedDrawerController: _drawerController,
            ),
            // AboutUsScreen(
            //   advancedDrawerController: _drawerController,
            // ),
          ],
        ),
      ),

      /// DRAWER UI
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 50),

              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    _item(
                      icon: IconsaxPlusLinear.home_1,
                      title: "Home",
                      onTap: () => _selectScreen(0),
                    ),
                    _divider(),

                    _item(
                      icon: IconsaxPlusLinear.info_circle,
                      title: "Credits",
                      onTap: () => _selectScreen(1),
                    ),
                    _divider(),

                    /// THEME
                    ListTile(
                      dense: true,
                      leading: const Icon(
                        IconsaxPlusLinear.moon,
                        size: 20,
                      ),
                      title: const Text("Theme"),
                      trailing: Transform.scale(
                         alignment: Alignment.centerRight,
                        scale: 0.8,
                        child: CupertinoSwitch(
                         activeColor: const Color(0xFFFF4C5B),
                          value: themeProvider.isDarkMode,
                          onChanged: (_) =>
                              themeProvider.toggleTheme(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  "App Version: 1.2.3",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .inversePrimary
                        .withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: const Divider(thickness: 0.4),
  );

  Widget _item({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(title),
      onTap: onTap,
    );
  }
}
