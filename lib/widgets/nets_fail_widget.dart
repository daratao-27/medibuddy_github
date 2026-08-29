import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

// shown when payment fails or the QR expires
class NETSFailWidget extends StatefulWidget {
  final VoidCallback onFinished;
  final String? message;

  const NETSFailWidget({required this.onFinished, this.message});

  @override
  State<NETSFailWidget> createState() => _NETSFailWidgetState();
}

class _NETSFailWidgetState extends State<NETSFailWidget> {
  Timer? _timer;
  int _countdown = 10;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('images/red_cross.png',
            width: MediaQuery.of(context).size.width * 0.5),
        const SizedBox(height: 10),
        const Text(
          'Payment Failed',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.message != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.message!,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Returning to shop in $_countdown seconds',
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
