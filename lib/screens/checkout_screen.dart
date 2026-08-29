import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../widgets/nets_widget.dart';
import '../providers/firebase_provider.dart';
import '../models/cart_item.dart';
import '../models/medication.dart';

class CheckoutScreen extends ConsumerWidget {
  final String productName;
  final int quantity;
  final double pricePerUnit;
  final int packSize;
  final List<CartItem>? cartItems;

  const CheckoutScreen({
    required this.productName,
    required this.quantity,
    required this.pricePerUnit,
    this.packSize = 1,
    this.cartItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double total = cartItems == null
        ? quantity * pricePerUnit
        : cartItems!.fold(0.0, (sum, item) => sum + item.subtotal);
    final int totalQuantity = cartItems == null
        ? quantity
        : cartItems!.fold(0, (sum, item) => sum + item.quantity);
    final String summaryLabel = cartItems == null
        ? '$productName × $quantity tablets'
        : '${cartItems!.length} item${cartItems!.length == 1 ? '' : 's'} • $totalQuantity units';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Shop for ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        TextSpan(
                          text: 'Medications',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back,
                        size: 16, color: AppColors.textMedium),
                    label: const Text('Back',
                        style: TextStyle(color: AppColors.textMedium)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // order summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EDE0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📦 ', style: TextStyle(fontSize: 18)),
                        Text(
                          'Order summary',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          summaryLabel,
                          style: AppTextStyles.body,
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyBold,
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.divider),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: AppTextStyles.bodyBold),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // nets qr section header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEAF8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  children: [
                    Text(
                      'NETS QR payment',
                      style: TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Scan with your banking app to pay',
                      style: TextStyle(
                        color: AppColors.primaryPurple,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // the actual qr code widget for this order's total
              NETSWidget(
                amount: total,
                onCancel: () => Navigator.of(context).pop(),
                onFinished: () async {
                  debugPrint('CheckoutScreen: onFinished called — starting Firestore update');
                  final service = ref.read(firebaseServiceProvider);
                  final user = service.getCurrentUser();

                  try {
                    if (user == null || user.email == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Not signed in — cannot add medication')),
                      );
                      return;
                    }

                    final email = user.email!;
                    final itemsToProcess = cartItems ?? [
                      CartItem(
                        name: productName,
                        quantity: quantity,
                        pricePerUnit: pricePerUnit,
                        image: '',
                        packSize: packSize,
                      ),
                    ];

                    for (final item in itemsToProcess) {
                      final existing = await service.getMedicationByName(item.name, email);

                      if (existing != null && existing.data() != null) {
                        final data = existing.data()!;
                        final currentStock =
                            (data['stockCount'] as num?)?.toInt() ?? 0;
                        final currentTotal =
                            (data['totalCount'] as num?)?.toInt() ?? currentStock;

                        final unitsToAdd = item.quantity * item.packSize;
                        final updatedMed = Medication(
                          id: existing.id,
                          name: data['name'] ?? item.name,
                          dosage: (data['dosage'] as num?)?.toDouble() ?? 0.0,
                          unit: data['unit'] ?? 'pcs',
                          frequency: data['frequency'] ?? '',
                          scheduledTime: data['scheduledTime'] ?? '',
                          instructions: data['instructions'] ?? '',
                          stockCount: currentStock + unitsToAdd,
                          totalCount: currentTotal + unitsToAdd,
                          userEmail: email,
                        );

                        await service.updateMedication(existing.id, updatedMed);
                      } else {
                        final unitsToAdd = item.quantity * item.packSize;
                        final newMed = Medication(
                          id: '',
                          name: item.name,
                          dosage: 0.0,
                          unit: 'pcs',
                          frequency: '',
                          scheduledTime: '',
                          instructions: '',
                          stockCount: unitsToAdd,
                          totalCount: unitsToAdd,
                          userEmail: email,
                        );

                        await service.addMedication(newMed);
                      }
                    }

                    final service2 = ref.read(firebaseServiceProvider);
                    final user2 = service2.getCurrentUser();
                    if (user2 != null && user2.email != null) {
                      await service2.clearCart(user2.email!);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Medication stock updated')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding medication: $e')),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
