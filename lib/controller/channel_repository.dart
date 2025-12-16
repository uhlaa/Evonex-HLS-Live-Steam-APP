import 'package:supabase_flutter/supabase_flutter.dart';

class ChannelRepository {
  ChannelRepository._();

  static final _client = Supabase.instance.client;

  static Stream<List<Map<String, dynamic>>> streamChannels() {
    return _client
        .from('channel_list')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
            .map((e) => Map<String, dynamic>.from(e))
            .toList());
  }
}
