import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:medibuddy/models/nets_state.dart';
import 'package:medibuddy/services/nets_service.dart';

final netsServiceProvider = Provider<NETSService>((ref) {
  return NETSService();
});

final netsProvider = StateNotifierProvider<NetsController, NetsState>((ref) {
  final service = ref.read(netsServiceProvider);
  return NetsController(service);
});

class NetsController extends StateNotifier<NetsState> {
  final NETSService service;

  // countdown timer for the QR expiry
  Timer? _timer;

  NetsController(this.service) : super(NetsState());

  // gets a QR code for the amount and kicks off the timer + webhook listener.
  // retries once if the sandbox says "too many requests" before giving up
  Future<void> generateQR(double amount, {int attempt = 0}) async {
    state = state.copyWith(status: 'loading');

    final decoded = await service.requestQR(amount);

    if (decoded['qrCode'] == null) {
      final error = decoded['error'] as String? ?? 'Could not generate QR code';
      if (attempt == 0 && error.toLowerCase().contains('too many requests')) {
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        return generateQR(amount, attempt: 1);
      }
      state = state.copyWith(status: 'fail', message: error);
      return;
    }

    final qr = base64Decode(decoded['qrCode']);
    final txnRef = decoded['txnRef'];

    state = state.copyWith(
      qrCode: qr,
      status: 'idle',
      timeLeft: 300,
      txnRef: txnRef,
      message: null,
    );

    startTimer(txnRef);
    startWebhookListener(txnRef);
  }

  // 5 minute countdown before the QR code expires
  void startTimer(String txnRef) {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      } else {
        timer.cancel();
        checkPayment(txnRef);
      }
    });
  }

  // listens for the QR scanned event over SSE. this connection drops on
  // its own sometimes (especially in debug mode), so just reconnect a
  // few times instead of assuming the payment failed
  void startWebhookListener(String txnRef, {int attempt = 0}) async {
    try {
      await for (final data in service.webhookStream(txnRef)) {
        if (!mounted) return;

        if (data.contains('QR code scanned')) {
          state = state.copyWith(message: 'QR code scanned');
          checkPayment(txnRef);
          return;
        }
      }
    } catch (_) {
      // connection dropped, try reconnecting below
    }

    if (!mounted || state.status != 'idle' || state.txnRef != txnRef) return;
    if (attempt < 5) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || state.status != 'idle' || state.txnRef != txnRef) return;
      startWebhookListener(txnRef, attempt: attempt + 1);
    }
  }

  // checks the actual payment result with the API
  Future<void> checkPayment(String txnRef) async {
    final decoded = await service.checkPayment(txnRef);

    final code = decoded['response_code'] ?? '99';
    final message = decoded['message'];

    state = state.copyWith(message: message);

    if (code == '00') {
      state = state.copyWith(status: 'success');

      await Future.delayed(const Duration(seconds: 10));

      state = state.copyWith(status: 'complete');
    } else {
      state = state.copyWith(status: 'fail');
    }
  }

  void cleanup() {
    _timer?.cancel();
    state = NetsState();
  }
}
