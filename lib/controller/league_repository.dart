import 'package:supabase_flutter/supabase_flutter.dart';

class LeagueRepository {
  static final SupabaseClient _supabase =
      Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> fetchLeagues() async {
    final response = await _supabase
        .from('home_leagues')
        .select('id, lgname, lgimages, lgCategories')
        .order('id', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}