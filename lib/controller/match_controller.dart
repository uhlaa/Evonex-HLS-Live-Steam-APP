import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchController extends GetxController {
  var liveMatches = [].obs;

  @override
  void onInit() {
    super.onInit();
    checkAndUpdateMatchStatus(); // auto check here
  }

  Future<void> checkAndUpdateMatchStatus() async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('live_match')
        .select()
        .eq('is_live', true);

    final now = DateTime.now();

    for (var match in response) {
      final start = DateTime.parse(match['match_start_time']);
      final endTime = match['match_end_time'];

      final endParts = endTime.split(':');
      final endDateTime = DateTime(
        start.year,
        start.month,
        start.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
        int.parse(endParts[2]),
      );

      if (endDateTime.isBefore(start)) {
        final nextDay = start.add(Duration(days: 1));
        final endDateTime2 = DateTime(
          nextDay.year,
          nextDay.month,
          nextDay.day,
          int.parse(endParts[0]),
          int.parse(endParts[1]),
          int.parse(endParts[2]),
        );

        if (now.isAfter(endDateTime2)) {
          await supabase
              .from('live_match')
              .update({'is_live': false})
              .eq('id', match['id']);
        }
      } else {
        if (now.isAfter(endDateTime)) {
          await supabase
              .from('live_match')
              .update({'is_live': false})
              .eq('id', match['id']);
        }
      }
    }
  }
}
