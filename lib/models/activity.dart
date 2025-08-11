// lib/models/activity.dart
import 'package:flutter/material.dart';

class Activity {
  final int? id; // เพิ่ม id เข้ามาด้วยถ้าต้องการเก็บ activityId
  final String label;
  final String iconPath;
  final bool isNetworkImage; // เพิ่ม field นี้

  Activity({
    this.id,
    required this.label,
    required this.iconPath,
    this.isNetworkImage = false, // กำหนดค่าเริ่มต้น
  });

  // คุณอาจจะเพิ่ม factory constructor หรือ toMap/fromMap methods
  // เพื่อแปลงข้อมูลระหว่าง Activity object กับ JSON สำหรับ API ได้ถ้าจำเป็น
}
