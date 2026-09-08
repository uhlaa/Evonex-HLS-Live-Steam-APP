import 'package:evonex/screens/credits_copyrights_screen.dart';
import 'package:evonex/screens/league_screen.dart';
import 'package:evonex/screens/match_home_screen.dart';
import 'package:evonex/theme/theme_provider.dart';
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

  Future<void> _selectScreen(int index) async {
    _drawerController.hideDrawer();

    await Future.delayed(
      const Duration(milliseconds: 180),
    );

    if (!mounted) return;

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    return AdvancedDrawer(
      controller: _drawerController,

      backdrop: Container(
        color: Theme.of(context)
            .colorScheme
            .secondary
            .withOpacity(0.92),
      ),

      openRatio: 0.55,
      openScale: 0.80,

      animationDuration:
          const Duration(milliseconds: 300),

      animationCurve: Curves.easeOutCubic,

      childDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
      ),

      // ================= MAIN CONTENT =================

      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),

        child: IndexedStack(
          key: ValueKey(_currentIndex),
          index: _currentIndex,

          children: [

            // 0 - HOME
            MatchHomeScreen(
              advancedDrawerController:
                  _drawerController,
            ),

            // 1 - LEAGUES
            LeagueScreen(
              advancedDrawerController:
                  _drawerController,
            ),

            // 2 - ABOUT
            CreditsCopyrightScreen(
              advancedDrawerController:
                  _drawerController,
            ),
          ],
        ),
      ),

      // ================= DRAWER =================

      drawer: Drawer(
        backgroundColor:
            Theme.of(context).colorScheme.secondary,

        child: SafeArea(
          child: Column(
            children: [

              const SizedBox(height: 50),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),

                  children: [

                    // HOME
                    _item(
                      icon: IconsaxPlusLinear.home_1,
                      title: "Home",
                      onTap: () => _selectScreen(0),
                    ),

                    _divider(),

                    // LEAGUES
                    _item(
                      icon: IconsaxPlusLinear.cup,
                      title: "Leagues",
                      onTap: () => _selectScreen(1),
                    ),

                    _divider(),

                    // ABOUT
                    _item(
                      icon: IconsaxPlusLinear.info_circle,
                      title: "About",
                      onTap: () => _selectScreen(2),
                    ),
                  ],
                ),
              ),

              // ================= FOOTER =================

              Padding(
                padding: const EdgeInsets.only(
                  bottom: 16,
                ),

                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .inversePrimary
                          .withOpacity(0.7),
                    ),

                    children: [

                      // const TextSpan(
                      //   text: "Developed by  ",
                      //   style: TextStyle(
                      //     fontWeight: FontWeight.w500,
                      //   ),
                      // ),

                      // const TextSpan(
                      //   text: "UHLAA",
                      //   style: TextStyle(
                      //     color: Color.fromARGB(
                      //       255,
                      //       155,
                      //       238,
                      //       2,
                      //     ),
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Divider(
        thickness: 0.4,
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 20,
      ),
      title: Text(title),
      onTap: onTap,
    );
  }
}