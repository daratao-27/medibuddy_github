import 'dart:typed_data';

// state for the NETS QR payment flow
class NetsState {
  final Uint8List? qrCode;
  final String status; // idle, loading, success, fail, complete
  final int timeLeft;
  final String? message;
  final String? txnRef;

  NetsState({
    this.qrCode,
    this.status = 'idle',
    this.timeLeft = 300,
    this.message,
    this.txnRef,
  });

  NetsState copyWith({
    Uint8List? qrCode,
    String? status,
    int? timeLeft,
    String? message,
    String? txnRef,
  }) {
    return NetsState(
      qrCode: qrCode ?? this.qrCode,
      status: status ?? this.status,
      timeLeft: timeLeft ?? this.timeLeft,
      message: message ?? this.message,
      txnRef: txnRef ?? this.txnRef,
    );
  }
}
