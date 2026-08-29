import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medibuddy/providers/nets_provider.dart';
import '../constants/app_theme.dart';
import '../screens/shop_screen.dart';
import 'nets_fail_widget.dart';
import 'nets_success_widget.dart';

// shows the NETS QR code and reacts to the payment status
class NETSWidget extends ConsumerStatefulWidget {
  final double amount;
  final VoidCallback onCancel;
  final Future<void> Function() onFinished;

  const NETSWidget({
    super.key,
    required this.amount,
    required this.onCancel,
    required this.onFinished,
  });

  @override
  ConsumerState<NETSWidget> createState() => _NETSWidgetState();
}

class _NETSWidgetState extends ConsumerState<NETSWidget> with WidgetsBindingObserver {
  bool _didFinish = false;
  @override
  void initState() {
    super.initState();

    // watch app lifecycle so we know when the user comes back
    WidgetsBinding.instance.addObserver(this);

    // ask for the qr code once the widget is actually built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(netsProvider.notifier).generateQR(widget.amount);
    });

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // back in the app, manually check payment status just in case
    if (state == AppLifecycleState.resumed) {
      final netsState = ref.read(netsProvider);
      final txnRef = netsState.txnRef;

      if (txnRef != null && netsState.status != 'complete') {
        ref.read(netsProvider.notifier).checkPayment(txnRef);
      }
    }
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  // pops back to ShopScreen if it's still in the stack, otherwise
  // just goes back to the first route
  void _returnToShop(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.settings.name == ShopScreen.routeName || route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(netsProvider);

    if (state.status == 'complete' && !_didFinish) {
      _didFinish = true;
      final localContext = context;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        debugPrint('NETSWidget: handling provider complete, calling parent onFinished');
        widget.onFinished().then((_) {
          if (!mounted) return;
          ref.read(netsProvider.notifier).cleanup();
          _returnToShop(localContext);
        });
      });
    }

    // not using a provider listener here, handling the completion nav
    // directly from the success widget's callback instead, avoids race
    // conditions between the timers and provider updates

    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (state.status == 'idle' && state.qrCode != null)
            Text(
              'Amount to pay: \$${widget.amount.toStringAsFixed(2)}\nScan the QR code below with TWallet',
              style: AppTextStyles.bodyBold
                  .copyWith(color: AppColors.primaryPurple),
              textAlign: TextAlign.center,
            ),

          if (state.status == 'idle' && state.qrCode != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Image.memory(
                state.qrCode!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),

          if (state.status == 'idle' && state.qrCode != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Image.asset('images/nets_qr_info.png',
                  width: MediaQuery.of(context).size.width * 0.7),
            ),

          if (state.status == 'loading')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            ),

          if (state.status == 'success')
            NETSSuccessWidget(
              onFinished: () async {
                if (_didFinish) return;
                _didFinish = true;

                debugPrint('NETSWidget: success callback triggered, calling parent onFinished');

                // let the parent do its firestore update first
                await widget.onFinished();

                // then clean up and navigate back, safe since we're still mounted
                ref.read(netsProvider.notifier).cleanup();

                if (!mounted) return;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _returnToShop(context);
                });
              },
            ),

          if (state.status == 'fail')
            NETSFailWidget(
              message: state.message,
              onFinished: () {
                ref.read(netsProvider.notifier).cleanup();
                if (mounted) _returnToShop(context);
              },
            ),

          if (state.status == 'idle' && state.qrCode != null)
            Text(
              'Time left: ${formatTime(state.timeLeft)}',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),

          if (state.status == 'idle' && state.qrCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton(
                onPressed: () {
                  ref.read(netsProvider.notifier).cleanup();
                  widget.onCancel();
                },
                child: const Text('Cancel Payment'),
              ),
            ),
        ],
      ),
    );
  }
}
