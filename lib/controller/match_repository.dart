import 'package:supabase_flutter/supabase_flutter.dart';

class MatchRepository {
  MatchRepository._();

  static final _client = Supabase.instance.client;

  /// live_match realtime stream
  static Stream<List<Map<String, dynamic>>> streamMatches() {
    return _client
        .from('live_match')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
            .map((e) => Map<String, dynamic>.from(e))
            .toList());
  }

  /// load all teams once
  static Future<List<Map<String, dynamic>>> fetchTeams() async {
    final data = await _client.from('team').select();
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// get channel by id
  static Future<Map<String, dynamic>?> getChannelById(int id) async {
    return await _client
        .from('channel_list')
        .select()
        .eq('id', id)
        .maybeSingle();
  }
}
