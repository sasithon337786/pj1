import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
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
    final androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final iosImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

// ✅ ขอ permission สำหรับ iOS
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'reminder_channel', // ต้องตรงกับตอนใช้ zonedSchedule
      'Reminders',
      description: 'Activity reminders',
      importance: Importance.max,
    );
  }

  static Future<void> scheduleReminders(String idToken) async {
    final response = await http.get(
      Uri.parse('${ApiEndpoints.baseUrl}/api/activityDetail/getActData'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    debugPrint("📡 Response status: ${response.statusCode}");
    debugPrint("📡 Response body: ${response.body}");

    if (response.statusCode != 200) return;
    final activities = json.decode(response.body);

    for (var act in activities) {
      // ✅ parse list ของเวลาเตือน
      final List<dynamic> times = json.decode(act['time_remind']);
      final rounds = act['round'].toLowerCase(); // 'day' หรือ 'week'
      final daysToSchedule = rounds == 'week' ? 7 : 1;

      for (String t in times) {
        final parts = t.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        for (int i = 0; i < daysToSchedule; i++) {
          final now = DateTime.now();
          final scheduleTime = DateTime(
            now.year,
            now.month,
            now.day,
            hour,
            minute,
          ).add(Duration(days: i));

          // ✅ แปลงเป็น tz timezone ก่อนตั้งแจ้งเตือน
          final tzTime = tz.TZDateTime.from(scheduleTime, tz.local);

          await _flutterLocalNotificationsPlugin.zonedSchedule(
            act['act_detail_id'] + i * 100 + hour, // ให้ id ไม่ซ้ำ
            'Reminder',
            'กิจกรรม: ${act['message']}',
            tzTime,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'reminder_channel',
                'Reminders',
                channelDescription: 'Activity reminders',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );

          debugPrint(
              "🕒 ตั้งแจ้งเตือนเวลา ${tzTime.toLocal()} สำหรับ ${act['message']}");
        }
      }
    }
  }
}
