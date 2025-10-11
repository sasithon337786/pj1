import 'dart:io';
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
    // Initialize timezones
    tz.initializeTimeZones();
    
    // Set local timezone
    final String timeZoneName = 'Asia/Bangkok';
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification tapped: ${details.payload}');
      },
    );
  }

  // ขอ permission (Android 13+)
  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        final bool? exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
        
        print('Notification permission: ${granted ?? false}');
        print('Exact alarm permission: ${exactAlarmGranted ?? false}');
        
        return granted ?? false;
      }
    }
    return true;
  }

  // ยกเลิก notification ทั้งหมดก่อน schedule ใหม่
  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('🗑️ Cancelled all previous notifications');
  }

  static Future<void> scheduleReminders(String idToken) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('🔔 START SCHEDULING NOTIFICATIONS');
      print('═══════════════════════════════════════════════════════');
      print('📡 Fetching activities from API...');
      print('🔗 URL: ${ApiEndpoints.baseUrl}/activityDetail/getActData');
      
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/activityDetail/getActData'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      print('📊 Response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        print('❌ API Error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return;
      }

      final activities = json.decode(response.body);
      print('✅ Found ${activities.length} activities');
      print('📝 Raw API Response: ${response.body}');
      print('───────────────────────────────────────────────────────');

      // ยกเลิก notification เก่าทั้งหมด
      await cancelAllNotifications();

      int scheduledCount = 0;
      final now = tz.TZDateTime.now(tz.local);
      print('⏰ Current time: $now');
      print('───────────────────────────────────────────────────────');

      for (var act in activities) {
        print('\n📌 Processing Activity:');
        print('   Raw data: $act');
        
        final actId = act['act_detail_id'] as int;
        final actName = act['act_name'] ?? 'กิจกรรม';
        final message = act['message'] ?? '';
        final round = act['round']; // 'day' หรือ 'week'
        
        print('   📋 ID: $actId');
        print('   📝 Name: $actName');
        print('   💬 Message: $message');
        print('   🔄 Round: $round');
        
        // Parse time_remind
        final timeRemindStr = act['time_remind'];
        print('   ⏱️  time_remind (raw): $timeRemindStr');
        
        if (timeRemindStr == null || timeRemindStr.toString().isEmpty) {
          print('   ⚠️  SKIP: No reminder time');
          print('   ────────────────────────────────────────');
          continue;
        }

        List<dynamic> remindList;
        try {
          remindList = json.decode(timeRemindStr.toString());
          print('   ⏱️  Parsed remind list: $remindList');
        } catch (e) {
          print('   ❌ SKIP: Error parsing time_remind - $e');
          print('   ────────────────────────────────────────');
          continue;
        }

        if (remindList.isEmpty) {
          print('   ⚠️  SKIP: Empty reminder list');
          print('   ────────────────────────────────────────');
          continue;
        }

        // กำหนดจำนวนวันที่จะ schedule
        final daysToSchedule = round == 'week' ? 7 : 1;
        print('   📅 Will schedule for $daysToSchedule day(s)');
        print('   ────────────────────────────────────────');

        // วนลูปแต่ละเวลาใน remindList
        for (int timeIndex = 0; timeIndex < remindList.length; timeIndex++) {
          final timeStr = remindList[timeIndex].toString();
          print('\n   🕐 Time slot ${timeIndex + 1}/${remindList.length}: $timeStr');
          
          // Parse time (format: "HH:mm")
          final parts = timeStr.split(':');
          if (parts.length != 2) {
            print('      ❌ SKIP: Invalid time format');
            continue;
          }

          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          print('      🕐 Parsed: Hour=$hour, Minute=$minute');

          if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
            print('      ❌ SKIP: Invalid time values');
            continue;
          }

          // Schedule สำหรับแต่ละวัน
          for (int dayOffset = 0; dayOffset < daysToSchedule; dayOffset++) {
            var scheduledDate = tz.TZDateTime(
              tz.local,
              now.year,
              now.month,
              now.day,
              hour,
              minute,
            ).add(Duration(days: dayOffset));

            print('      📅 Day +$dayOffset: Initial date = $scheduledDate');

            // ถ้าเวลาที่กำหนดผ่านไปแล้ววันนี้ ให้เลื่อนไปพรุ่งนี้
            if (scheduledDate.isBefore(now)) {
              scheduledDate = scheduledDate.add(Duration(days: 1));
              print('      ⏭️  Time passed, moved to: $scheduledDate');
            }

            // สร้าง unique notification ID
            // Formula: actId * 1000 + dayOffset * 10 + timeIndex
            final notificationId = (actId * 1000) + (dayOffset * 10) + timeIndex;
            print('      🆔 Notification ID: $notificationId');

            await _flutterLocalNotificationsPlugin.zonedSchedule(
              notificationId,
              '⏰ กิจกรรม: $actName',
              message.isNotEmpty ? message : 'ถึงเวลาทำกิจกรรมแล้ว!',
              scheduledDate,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'reminder_channel',
                  'Activity Reminders',
                  channelDescription: 'แจ้งเตือนกิจกรรมประจำวัน',
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                  enableVibration: true,
                  enableLights: true,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            );

            scheduledCount++;
            print('      ✅ SCHEDULED! #$notificationId at $scheduledDate');
          }
        }
        print('   ════════════════════════════════════════');
      }

      print('\n═══════════════════════════════════════════════════════');
      print('🎉 COMPLETED: Successfully scheduled $scheduledCount notifications');
      print('═══════════════════════════════════════════════════════\n');
    } catch (e, stackTrace) {
      print('\n═══════════════════════════════════════════════════════');
      print('❌ FATAL ERROR in scheduleReminders');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════\n');
    }
  }
}
// import 'dart:io';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> init() async {
//     // Initialize timezones
//     tz.initializeTimeZones();
    
//     // Set local timezone
//     final String timeZoneName = 'Asia/Bangkok';
//     tz.setLocalLocation(tz.getLocation(timeZoneName));

//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings settings =
//         InitializationSettings(android: androidSettings);

//     await _flutterLocalNotificationsPlugin.initialize(
//       settings,
//       onDidReceiveNotificationResponse: (details) {
//         print('Notification tapped: ${details.payload}');
//       },
//     );
//   }

//   // ใช้ built-in permission request แทน
//   static Future<bool> requestPermission() async {
//     if (Platform.isAndroid) {
//       final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
//           _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
//               AndroidFlutterLocalNotificationsPlugin>();

//       if (androidImplementation != null) {
//         // Request notification permission (Android 13+)
//         final bool? granted = await androidImplementation.requestNotificationsPermission();
//         print('Notification permission: ${granted ?? false}');
        
//         // Request exact alarm permission (Android 12+)
//         final bool? exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
//         print('Exact alarm permission: ${exactAlarmGranted ?? false}');
        
//         return granted ?? false;
//       }
//     }
//     return true;
//   }

//   static Future<void> scheduleTestNotification() async {
//     try {
//       // Schedule notification 5 seconds from now
//       final now = tz.TZDateTime.now(tz.local);
//       final scheduledDate = now.add(const Duration(seconds: 5));
      
//       print('📅 Current time: $now');
//       print('⏰ Scheduled time: $scheduledDate');

//       await _flutterLocalNotificationsPlugin.zonedSchedule(
//         0,
//         'แจ้งเตือนทดสอบ',
//         'นี่คือการแจ้งเตือนหลังจาก 5 วินาที!',
//         scheduledDate,
//         const NotificationDetails(
//           android: AndroidNotificationDetails(
//             'test_channel',
//             'Test Notifications',
//             channelDescription: 'ทดสอบการแจ้งเตือน',
//             importance: Importance.max,
//             priority: Priority.high,
//             showWhen: true,
//             playSound: true,
//             enableVibration: true,
//             enableLights: true,
//           ),
//         ),
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       );

//       print('✅ Notification scheduled successfully!');
//     } catch (e) {
//       print('❌ Error scheduling notification: $e');
//     }
//   }

//   // Show immediate notification (for testing)
//   static Future<void> showImmediateNotification() async {
//     try {
//       await _flutterLocalNotificationsPlugin.show(
//         1,
//         'ทดสอบทันที',
//         'แจ้งเตือนแบบทันทีทำงาน!',
//         const NotificationDetails(
//           android: AndroidNotificationDetails(
//             'test_channel',
//             'Test Notifications',
//             channelDescription: 'ทดสอบการแจ้งเตือน',
//             importance: Importance.max,
//             priority: Priority.high,
//           ),
//         ),
//       );
//       print('✅ Immediate notification shown!');
//     } catch (e) {
//       print('❌ Error showing notification: $e');
//     }
//   }
// }