import 'package:supabase_flutter/supabase_flutter.dart';

class ChannelRepository {
  ChannelRepository._();

  static final _client = Supabase.instance.client;

 static Stream<List<Map<String, dynamic>>> streamChannels() {
  return _client
      .from('channel_list')
      .stream(primaryKey: ['id'])
      .eq('is_active', true) // ✅ ONLY ACTIVE CHANNELS
      .map((rows) {
        final list = rows
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        list.sort(
          (a, b) => (a['id'] as int).compareTo(b['id'] as int),
        );

        return list;
      });
}


}
