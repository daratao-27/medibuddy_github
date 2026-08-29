import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/cart_item.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function(List<CartItem>) onUpdate;
  final Function(List<CartItem>) onCheckout;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onUpdate,
    required this.onCheckout,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.cartItems
        .map(
          (item) => CartItem(
            name: item.name,
            quantity: item.quantity,
            pricePerUnit: item.pricePerUnit,
            image: item.image,
            packSize: item.packSize,
          ),
        )
        .toList();
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final current = _items[index];
      final nextQty = current.quantity + delta;

      if (nextQty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = CartItem(
          name: current.name,
          quantity: nextQty,
          pricePerUnit: current.pricePerUnit,
          image: current.image,
          packSize: current.packSize,
        );
      }
    });

    widget.onUpdate(_items);
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    widget.onUpdate(_items);
  }

  double _subtotal() {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('My Cart', style: TextStyle(color: AppColors.textDark)),
      ),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 56, color: AppColors.textLight),
                  const SizedBox(height: 12),
                  const Text('Your cart is empty', style: AppTextStyles.heading2),
                  const SizedBox(height: 8),
                  Text('Add some items from the shop to get started.', style: AppTextStyles.body),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5EDE0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: item.image.isNotEmpty
                                  ? Image.asset(item.image, fit: BoxFit.contain)
                                  : Icon(Icons.medication_outlined, color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: AppTextStyles.bodyBold),
                                  const SizedBox(height: 4),
                                  Text('\$${item.pricePerUnit.toStringAsFixed(2)} each', style: AppTextStyles.caption),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _updateQuantity(index, -1),
                                        icon: const Icon(Icons.remove_circle_outline),
                                      ),
                                      Text('${item.quantity}', style: AppTextStyles.bodyBold),
                                      IconButton(
                                        onPressed: () => _updateQuantity(index, 1),
                                        icon: const Icon(Icons.add_circle_outline),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('\$${item.subtotal.toStringAsFixed(2)}', style: AppTextStyles.bodyBold),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => _removeItem(index),
                                  child: Text('Remove', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  // extra bottom padding so the checkout button doesn't get
                  // covered by the "added to cart" snackbar from Shop
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom + 72),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: AppTextStyles.bodyBold),
                          Text('\$${_subtotal().toStringAsFixed(2)}', style: AppTextStyles.bodyBold),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _items.isEmpty ? null : () => widget.onCheckout(_items),
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                          child: const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
