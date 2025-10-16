import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slider_captcha/slider_captcha.dart';

class CaptchaDialog extends StatefulWidget {
  const CaptchaDialog({super.key});

  @override
  State<CaptchaDialog> createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<CaptchaDialog> {
  String _errorText = "";
  final SliderController _sliderController = SliderController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFE6D2CD),
      title: Text("ยืนยันความเป็นมนุษย์",
          style: GoogleFonts.kanit(
              fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF564843))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderCaptcha(
            controller: _sliderController,
            image: Image.asset('assets/images/catty.jpg', fit: BoxFit.fitWidth),
            colorBar: const Color(0xFFC98993),
            colorCaptChar: const Color(0xFFE6D2CD),
            onConfirm: (value) async {
              if (value) {
                Navigator.pop(context, true);
              } else {
                setState(() => _errorText = "พบข้อผิดพลาด กรุณาลองใหม่อีกครั้ง");
                await Future.delayed(const Duration(seconds: 3));
                _sliderController.create.call();
                setState(() => _errorText = "");
              }
            },
          ),
          const SizedBox(height: 10),
          if (_errorText.isNotEmpty)
            Text(_errorText,
                style: GoogleFonts.kanit(color: Colors.red, fontSize: 16)),
        ],
      ),
    );
  }
}
