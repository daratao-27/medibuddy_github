import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../models/cart_item.dart';
import '../providers/firebase_provider.dart';
import '../services/firebase_service.dart';
import '../main.dart' show routeObserver;
import 'checkout_screen.dart';
import 'cart_screen.dart';

// basic data class for a shop item
class _Product {
  final String name;
  final String qty;
  final double price;
  final double? originalPrice; // non-null = on sale
  final String image;

  const _Product({
    required this.name,
    required this.qty,
    required this.price,
    this.originalPrice,
    required this.image,
  });
}

class ShopScreen extends ConsumerStatefulWidget {
  static const routeName = '/shop';

  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> with RouteAware {
  final List<CartItem> _cartItems = [];
  // popular products, horizontal scroll
  static const _popular = [
    _Product(
        name: 'Panadol',
        qty: '20pcs',
        price: 15.99,
        image: 'images/pills.png'),
    _Product(
        name: 'Metformin',
        qty: '20 pcs',
        price: 25.30,
        image: 'images/capsule.png'),
    _Product(
        name: 'Lisinopril',
        qty: '100mg',
        price: 19.99,
        image: 'images/pill.png'),
    _Product(
        name: 'Vitamin D',
        qty: '30 tabs',
        price: 12.50,
        image: 'images/tablet.png'),
  ];

  // on sale products, 2 column grid
  static const _onSale = [
    _Product(
        name: 'OBH Combi',
        qty: '75ml',
        price: 9.99,
        originalPrice: 10.99,
        image: 'images/medicine.png'),
    _Product(
        name: 'Betadine',
        qty: '50ml',
        price: 6.99,
        originalPrice: 8.99,
        image: 'images/pill2.png'),
    _Product(
        name: 'Bodrexin',
        qty: '75ml',
        price: 7.99,
        originalPrice: 8.99,
        image: 'images/pills2.png'),
    _Product(
        name: 'Konidin',
        qty: '3pcs',
        price: 5.99,
        image: 'images/pill3.png'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCartFromFirestore();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // runs when we come back to this screen after cart/checkout was popped,
  // just refreshes the cart in case it changed (e.g. cleared after paying)
  @override
  void didPopNext() {
    _loadCartFromFirestore();
  }

  Future<void> _loadCartFromFirestore() async {
    final service = ref.read(firebaseServiceProvider);
    final user = service.getCurrentUser();
    if (user == null || user.email == null) return;

    final items = await service.loadCart(user.email!);
    if (!mounted) return;

    setState(() {
      _cartItems
        ..clear()
        ..addAll(items);
    });
  }

  Future<void> _saveCartToFirestore() async {
    final service = ref.read(firebaseServiceProvider);
    final user = service.getCurrentUser();
    if (user == null || user.email == null) return;

    await service.saveCart(user.email!, _cartItems);
  }

  int _packSizeForProduct(_Product product) {
    final lower = product.qty.toLowerCase();
    if (lower.contains('pcs') || lower.contains('pc') || lower.contains('tabs') || lower.contains('tab')) {
      final match = RegExp(r'(\d+)').firstMatch(product.qty);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    }
    return 1;
  }

  void _addToCart(BuildContext context, _Product product, int quantity) {
    final existingIndex = _cartItems.indexWhere((item) => item.name == product.name);

    if (existingIndex >= 0) {
      final existing = _cartItems[existingIndex];
      _cartItems[existingIndex] = CartItem(
        name: existing.name,
        quantity: existing.quantity + quantity,
        pricePerUnit: existing.pricePerUnit,
        image: existing.image,
        packSize: existing.packSize,
      );
    } else {
      _cartItems.add(CartItem(
        name: product.name,
        quantity: quantity,
        pricePerUnit: product.price,
        image: product.image,
        packSize: _packSizeForProduct(product),
      ));
    }

    setState(() {});
    _saveCartToFirestore();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$quantity x ${product.name} added to cart'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showProductActionSheet(BuildContext context, _Product product) {
    final TextEditingController qtyController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose quantity for ${product.name}', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              Text('${product.name} · ${product.qty}', style: AppTextStyles.subtitle),
              const SizedBox(height: 12),
              TextFormField(
                controller: qtyController,
                decoration: appInputDecoration('Quantity'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Quantity is required';
                  final qty = int.tryParse(v.trim());
                  if (qty == null) return 'Enter a whole number';
                  if (qty <= 0) return 'Quantity must be at least 1';
                  if (qty > 999) return 'Quantity is too large';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid quantity')),
                          );
                          return;
                        }
                        final int qty = int.parse(qtyController.text.trim());
                        Navigator.of(ctx).pop();
                        _addToCart(context, product, qty);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid quantity')),
                      );
                      return;
                    }
                    final int qty = int.parse(qtyController.text.trim());
                    Navigator.of(ctx).pop();
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(
                              productName: product.name,
                              quantity: qty,
                              pricePerUnit: product.price,
                              packSize: _packSizeForProduct(product),
                            ),
                          ),
                        )
                        .then((_) async {
                          await _loadCartFromFirestore();
                        });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                  child: const Text('Buy Now'),
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
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
                        size: 14, color: AppColors.textMedium),
                    label: const Text('Back',
                        style: TextStyle(color: AppColors.textMedium)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EDE0),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shopping_cart_outlined, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _cartItems.isEmpty
                                  ? 'Your cart is empty'
                                  : '${_cartItems.length} item${_cartItems.length == 1 ? '' : 's'} in cart',
                              style: AppTextStyles.bodyBold,
                            ),
                          ),
                          if (_cartItems.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CartScreen(
                                      cartItems: _cartItems,
                                      onUpdate: (updatedItems) {
                                        setState(() {
                                          _cartItems
                                            ..clear()
                                            ..addAll(updatedItems);
                                        });
                                        _saveCartToFirestore();
                                      },
                                      onCheckout: (items) {
                                        Navigator.of(context)
                                            .push(
                                              MaterialPageRoute(
                                                builder: (_) => CheckoutScreen(
                                                  productName: items.first.name,
                                                  quantity: items.fold<int>(0, (sum, item) => sum + item.quantity),
                                                  pricePerUnit: items.fold<double>(0.0, (sum, item) => sum + item.subtotal),
                                                  cartItems: items,
                                                ),
                                              ),
                                            )
                                            .then((_) async {
                                              await _loadCartFromFirestore();
                                            });
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: const Text('View Cart'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // popular products - horizontal list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Popular Product',
                      style: AppTextStyles.heading2),
                  TextButton(
                    onPressed: () {},
                    child: Text('See all',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 178,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _popular.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final p = _popular[i];
                    return _PopularCard(
                      product: p,
                      onAdd: () => _showProductActionSheet(context, p),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // on sale - 2 column grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Product on Sale',
                      style: AppTextStyles.heading2),
                  TextButton(
                    onPressed: () {},
                    child: Text('See all',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                // shrinkWrap so it fits inside the scroll view
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _onSale.length,
                itemBuilder: (context, i) {
                  final p = _onSale[i];
                  return _SaleCard(
                    product: p,
                    onAdd: () => _showProductActionSheet(context, p),
                  );
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
// product card for the horizontal list
class _PopularCard extends StatelessWidget {
  final _Product product;
  final VoidCallback onAdd;

  const _PopularCard({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // product image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              product.image,
              width: double.infinity,
              height: 35,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 26),
          Text(product.name, style: AppTextStyles.bodyBold),
          Text(product.qty, style: AppTextStyles.caption),
          const SizedBox(height: 26),
          // price + add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// product card for the sale grid
class _SaleCard extends StatelessWidget {
  final _Product product;
  final VoidCallback onAdd;

  const _SaleCard({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // product image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              product.image,
              width: double.infinity,
              height: 55,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 26),
          Text(product.name, style: AppTextStyles.bodyBold),
          Text(product.qty, style: AppTextStyles.caption),
          const SizedBox(height: 16),
          // sale price + crossed out original price + add button
          Row(
            children: [
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontSize: 14,
                ),
              ),
              if (product.originalPrice != null) ...[
                const SizedBox(width: 4),
                Text(
                  '\$${product.originalPrice!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
