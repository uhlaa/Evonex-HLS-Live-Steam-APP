class BblTeam {
  final int id;             // maps to team_id (INT2) in DB
  final String name;        // team_name
  final String? logoUrl;    // team_logo_url

  BblTeam({
    required this.id,
    required this.name,
    this.logoUrl,
  });
}
