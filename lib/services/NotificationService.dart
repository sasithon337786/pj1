import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:pj1/constant/api_endpoint.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _flutterLocalNotificationsPlugin.initialize(settings);
  }

  static Future<void> scheduleReminders(String idToken) async {
    final response = await http.get(
      Uri.parse('${ApiEndpoints.baseUrl}/activityDetail/getActData'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode != 200) return;
    final activities = json.decode(response.body);

    for (var act in activities) {
      final timeRemind = DateTime.parse(act['time_remind']);
      final rounds = act['round']; // 'day' หรือ 'week'
      final daysToSchedule = rounds == 'week' ? 7 : 1;

      for (int i = 0; i < daysToSchedule; i++) {
        final scheduleTime = timeRemind.add(Duration(days: i));

        await _flutterLocalNotificationsPlugin.zonedSchedule(
          act['act_detail_id'], // unique id
          'Reminder',
          'กิจกรรม: ${act['message']}',
          tz.TZDateTime.from(scheduleTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'reminder_channel',
              'Reminders',
              channelDescription: 'Activity reminders',
            ),
          ),
          androidScheduleMode:
              AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }
}
