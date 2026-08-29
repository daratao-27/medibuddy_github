import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

// shown when payment goes through
class NETSSuccessWidget extends StatefulWidget {
  final VoidCallback onFinished;

  const NETSSuccessWidget({required this.onFinished});

  @override
  State<NETSSuccessWidget> createState() => _NETSSuccessWidgetState();
}

class _NETSSuccessWidgetState extends State<NETSSuccessWidget> {
  Timer? _timer;
  int _countdown = 10;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        if (mounted) {
          widget.onFinished();
        }
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
      children: [
        Image.asset('images/green_tick.png',
            width: MediaQuery.of(context).size.width * 0.5),
        const SizedBox(height: 10),
        const Text(
          'Payment Successful',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Returning to main screen in $_countdown seconds',
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
