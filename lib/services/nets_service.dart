import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

// handles all the calls to the NETS QR sandbox API
class NETSService {
  // supplied at build/run time via --dart-define-from-file=env.json (see env.example.json)
  final String apiKey = const String.fromEnvironment('NETS_API_KEY');
  final String projectId = const String.fromEnvironment('NETS_PROJECT_ID');

  // this is the merchant id tied to our api-key/project-id, not a
  // per-transaction id - the server hands out a unique txn_retrieval_ref
  // each time so we don't need to change this between purchases
  final String _merchantTxnId = 'sandbox_nets|m|8ff8e5b6-d43e-4786-8ac5-7accf8c5bd9b';

  // asks the sandbox for a qr code for this amount
  Future<Map<String, dynamic>> requestQR(double amount) async {
    try {
      final url = Uri.parse(
        'https://sandbox.nets.openapipaas.com/api/v1/common/payments/nets-qr/request',
      );

      final response = await post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'api-key': apiKey,
          'project-id': projectId,
        },
        body: jsonEncode({
          'txn_id': _merchantTxnId,
          'amt_in_dollars': amount,
          'notify_mobile': 0,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (data['status'] != 'success') {
        // show the real error from the sandbox (e.g. rate limit) instead of hiding it
        final apiMessage = data['result']?['message'] ?? 'Unknown error';
        debugPrint('requestQR failed (${response.statusCode}): $apiMessage');
        return {'error': apiMessage};
      }

      return {
        'qrCode': data['result']['data']['qr_code'],
        'txnRef': data['result']['data']['txn_retrieval_ref'],
      };
    } catch (e) {
      debugPrint('requestQR error: $e');
      return {'error': e.toString()};
    }
  }

  // listens for real-time payment updates over SSE
  Stream<String> webhookStream(String txnRef) async* {
    final client = Client();

    final url = Uri.parse(
      'https://sandbox.nets.openapipaas.com/api/v1/common/payments/nets/webhook?txn_retrieval_ref=$txnRef',
    );

    final request = Request('GET', url)
      ..headers.addAll({
        'Accept': 'text/event-stream',
        'Connection': 'keep-alive',
        'api-key': apiKey,
        'project-id': projectId,
      });

    final response = await client.send(request);

    if (response.statusCode == 200) {
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        yield chunk;
      }
    }
  }

  // checks the final status of a transaction
  Future<Map<String, dynamic>> checkPayment(String txnRef) async {
    try {
      final url = Uri.parse(
        'https://sandbox.nets.openapipaas.com/api/v1/common/payments/nets-qr/query',
      );

      final response = await post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'api-key': apiKey,
          'project-id': projectId,
        },
        body: jsonEncode({
          'txn_retrieval_ref': txnRef,
          'frontend_timeout_status': 1,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      return {
        'response_code': data['result']['data']['response_code'],
        'message': data['result']['data']['message'],
      };
    } catch (e) {
      debugPrint('checkPayment error: $e');
      return {};
    }
  }
}
