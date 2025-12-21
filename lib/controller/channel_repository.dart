import 'package:supabase_flutter/supabase_flutter.dart';

class ChannelRepository {
  ChannelRepository._();

  static final _client = Supabase.instance.client;

  static Stream<List<Map<String, dynamic>>> streamChannels() {
  return _client
      .from('channel_list')
      .stream(primaryKey: ['id'])
      .map((rows) {
        final list = rows
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        // ✅ SORT BY ID (ASCENDING)
        list.sort((a, b) =>
            (a['id'] as int).compareTo(b['id'] as int));

        return list;
      });
}

}
