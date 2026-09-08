import 'package:evonex/controller/league_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';

class LeagueScreen extends StatefulWidget {
  final AdvancedDrawerController advancedDrawerController;

  const LeagueScreen({
    super.key,
    required this.advancedDrawerController,
  });

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  late Future<List<Map<String, dynamic>>> _leagueFuture;

  @override
  void initState() {
    super.initState();

    _leagueFuture = LeagueRepository.fetchLeagues();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,

      appBar: AppBar(
        backgroundColor: theme.colorScheme.tertiary,
        centerTitle: true,

        title: Text(
          'Leagues',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: theme.colorScheme.inversePrimary,
          ),
        ),

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.onSurface,
            size: 18,
          ),
          onPressed: () {
            widget.advancedDrawerController.showDrawer();
          },
        ),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _leagueFuture,

        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            );
          }

          // Empty
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No leagues available',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            );
          }

          final leagues = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),

            child: GridView.builder(
              itemCount: leagues.length,

              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: .99,
              ),

              itemBuilder: (context, index) {
                final league = leagues[index];

                return _LeagueCard(
                  leagueMap: league,
                );
              },
            ),
          );
        },
      ),
    );
  }
}


// ============================================================
// LEAGUE CARD
// ============================================================

class _LeagueCard extends StatelessWidget {
  final Map<String, dynamic> leagueMap;

  const _LeagueCard({
    super.key,
    required this.leagueMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: theme.colorScheme.tertiary,
      ),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            // ================= IMAGE =================

            Expanded(
              child: Center(
                child: Image.network(
                  leagueMap['lgimages']?.toString() ?? '',
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // ================= NAME =================

            Text(
              leagueMap['lgname']?.toString() ?? '',

              maxLines: 1,
              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 3),

            // ================= CATEGORY =================

            Text(
              leagueMap['lgCategories']?.toString() ?? '',

              maxLines: 1,
              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}