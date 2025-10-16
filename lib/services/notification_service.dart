import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz; // init ทำใน main()
import 'package:permission_handler/permission_handler.dart';
import 'package:pj1/constant/api_endpoint.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'reminder_channel',
    'Reminders',
    description: 'Activity reminders with sound',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> init() async {
    // ❌ ไม่ต้องเรียก WidgetsFlutterBinding / tz.* ที่นี่ (ทำใน main() แล้ว)

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null && payload.isNotEmpty) {
          // TODO: เรียก navigatorKey/router ของคุณเพื่อนำทางไปหน้าเป้าหมาย
          debugPrint("🧭 openFromNotification: $payload");
        }
      },
    );

    // ✅ Android permissions + channel
    final androidImpl = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(_channel);
      final granted = await androidImpl.requestNotificationsPermission();
      debugPrint("🔔 Notification Permission: $granted");
      final exactAlarmGranted = await androidImpl.requestExactAlarmsPermission();
      debugPrint("⏰ Exact Alarm Permission: $exactAlarmGranted");
    }

    // ✅ iOS permissions (เผื่อใช้ cross-platform)
    final iosImpl = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    // ✅ สำหรับ Android เก่า
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      debugPrint("📱 Permission status: $status");
    }

    // ✅ ขอยกเว้นแบต
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      final status = await Permission.ignoreBatteryOptimizations.request();
      debugPrint("🔋 Battery Optimization exemption: $status");
    }
  }

  // ✅ ดู pending + payload (ช่วยดีบัก)
  static Future<void> checkPendingNotifications() async {
    final pending =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    final now = tz.TZDateTime.now(tz.local);

    debugPrint("📋 Pending notifications: ${pending.length}");
    debugPrint("⏰ เวลาปัจจุบัน: ${now.day}/${now.month} "
        "${now.hour}:${now.minute.toString().padLeft(2, '0')}");
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    for (var n in pending) {
      Map<String, dynamic>? p;
      try {
        if ((n.payload ?? '').isNotEmpty) p = jsonDecode(n.payload!);
      } catch (_) {}
      debugPrint("   🔔 ID: ${n.id}");
      debugPrint("      Title: ${n.title}");
      debugPrint("      Body: ${n.body}");
      if (p != null) debugPrint("      Payload: $p");
    }
  }

  // ✅ สร้าง/รีเฟรชแจ้งเตือนจาก API
  static Future<void> scheduleReminders(String idToken) async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint("🗑️ ลบการแจ้งเตือนเก่าทั้งหมดแล้ว");

    final response = await http.get(
      Uri.parse('${ApiEndpoints.baseUrl}/api/activityDetail/getActData'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    debugPrint("📡 Response status: ${response.statusCode}");
    debugPrint("📡 Response body: ${response.body}");

    if (response.statusCode != 200) {
      debugPrint("❌ ไม่สามารถดึงข้อมูลได้");
      return;
    }

    final activities = json.decode(response.body);
    final now = tz.TZDateTime.now(tz.local);
    debugPrint("⏰ เวลาปัจจุบัน: $now");

    int notificationCount = 0;

    for (final act in activities) {
      final List<dynamic> timeList = json.decode(act['time_remind']);
      final times = timeList.map((e) => e.toString()).toList();

      final String rounds = act['round']?.toString().toLowerCase() ?? 'day';
      final bool isWeekly = rounds == 'week';

      // ทำ actId ให้ปลอดภัย + มี fallback
      final rawActId = act['act_detail_id']?.toString();
      final parsed = int.tryParse(rawActId ?? '');
      final actId = parsed ?? DateTime.now().millisecondsSinceEpoch % 100000000;

      final String title = act['activity_name']?.toString() ?? 'กิจกรรม';
      final String message = act['message']?.toString() ?? '';

      for (final t in times) {
        final parts = t.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        // หา occurrence แรก (วันนี้ถ้าทัน ไม่งั้นวันถัดไป)
        var first = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
        if (first.isBefore(now)) {
          first = first.add(const Duration(days: 1));
        }

        // ทำให้ ID ไม่ชน
        final notificationId = Object.hash(actId, hour, minute, rounds);

        final payload = jsonEncode({
          "source": "activityDetail",
          "actId": actId,
          "hour": hour,
          "minute": minute,
          "round": rounds,
          "scheduledAt": first.toIso8601String(),
          "title": title,
          "message": message,
        });

        try {
          await _flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            title,
            message,
            first,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                icon: '@mipmap/ic_launcher',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          
            // 🔁 ยิงซ้ำอัตโนมัติ (เหลือ pending แค่ 1 รายการต่อเวลา)
            matchDateTimeComponents:
                isWeekly ? DateTimeComponents.dayOfWeekAndTime
                         : DateTimeComponents.time,
            payload: payload,
          );

          notificationCount++;
          debugPrint(
              "✅ [$notificationCount] ตั้งแจ้งเตือน: $title @ $first | id=$notificationId | round=$rounds");
        } catch (e) {
          debugPrint("❌ ตั้งแจ้งเตือนล้มเหลว: $e");
        }
      }
    }

    debugPrint("🎯 ตั้งแจ้งเตือนทั้งหมด $notificationCount รายการ");
    await checkPendingNotifications();
  }

  // ✅ ฟังก์ชันทดสอบแจ้งเตือนทันที
  static Future<void> showTestNotification() async {
    await _flutterLocalNotificationsPlugin.show(
      999,
      'ทดสอบแจ้งเตือน',
      'ถ้าเห็นข้อความนี้แสดงว่าระบบแจ้งเตือนทำงานได้',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: jsonEncode({"source": "instant"}),
    );
    debugPrint("🧪 ส่งการแจ้งเตือนทดสอบแล้ว");
  }

  // ✅ ฟังก์ชันทดสอบแจ้งเตือนแบบตั้งเวลา
  static Future<void> scheduleTestNotificationIn10Seconds() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduleTime = now.add(const Duration(seconds: 45)); // แนะนำ 45s

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      998,
      '⏰ ทดสอบตั้งเวลา',
      'ถ้าเห็นนี้หลัง 45 วินาที = ระบบตั้งเวลาทำงาน!',
      scheduleTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      
      payload: jsonEncode({
        "source": "test",
        "scheduledAt": scheduleTime.toIso8601String(),
      }),
    );

    debugPrint('⏱️ ตั้งแจ้งเตือนทดสอบไว้ที่: '
        '${scheduleTime.hour}:${scheduleTime.minute}:${scheduleTime.second}');
  }
}
