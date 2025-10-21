import 'package:flutter/material.dart';

/// เนื้อหาใน SnackBar (ทำให้หน้าตา error สวยและสม่ำเสมอ)
class ErrorSnackContent extends StatelessWidget {
  final String message;
  const ErrorSnackContent({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// ตัวช่วยแสดง error (SnackBar / Dialog)
class ErrorNotifier {
  /// แสดง SnackBar สำหรับ error
  static void showSnack(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.error.withOpacity(0.90),
        content: ErrorSnackContent(message: message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// แสดง AlertDialog สำหรับ error (ถ้าบางหน้าต้องการแบบ modal)
  static Future<void> showDialogError(BuildContext context, String message) {
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            const Text('เกิดข้อผิดพลาด'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          )
        ],
      ),
    );
  }
}
