import 'package:flutter_test/flutter_test.dart';
import 'package:medibuddy/models/cart_item.dart';

void main() {
  group('CartItem', () {
    test('calculates total units using pack size', () {
      const item = CartItem(
        name: 'Panadol',
        quantity: 2,
        pricePerUnit: 15.99,
        image: '',
        packSize: 20,
      );

      expect(item.totalUnits, 40);
      expect(item.subtotal, 31.98);
    });
  });
}
