import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deathfishflutter/models/merch_item.dart';
import 'package:deathfishflutter/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the shopping cart remains local and persists independently', () async {
    SharedPreferences.setMockInitialValues({});
    final service = await DataService.load();
    const product = MerchItem(
      id: 'mrc_test',
      name: 'PLAYERA DE PRUEBA',
      category: 'ROPA',
      price: 300,
      sizes: ['S', 'M'],
      stock: 2,
      image: 'assets/fondo1.JPG',
      description: 'Producto de prueba',
    );

    await service.addToCart(product, 'M');
    final reloaded = await DataService.load();

    expect(reloaded.cartCount, 1);
    expect(reloaded.cartTotalFor([product]), 300);
    expect(reloaded.cartItems.single.size, 'M');
  });
}
