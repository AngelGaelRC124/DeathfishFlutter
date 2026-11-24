import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/band_info.dart';
import '../models/cart_item.dart';
import '../models/merch_item.dart';
import 'firestore_service.dart';
import 'media_storage.dart';

class DataService {
  DataService._({required this.bandInfo, required this._preferences});

  static const _cartKey = 'deathfish_merch_cart';

  final SharedPreferences _preferences;
  final MediaStorage _mediaStorage = MediaStorage();
  final BandInfo bandInfo;

  List<CartItem> get cartItems {
    final stored = _preferences.getStringList(_cartKey) ?? [];
    return List<CartItem>.unmodifiable(
      stored.map(
        (entry) => CartItem.fromJson(
          Map<String, dynamic>.from(jsonDecode(entry) as Map),
        ),
      ),
    );
  }

  int get cartCount =>
      cartItems.fold(0, (total, item) => total + item.quantity);

  double cartTotalFor(List<MerchItem> products) =>
      cartItems.fold(0, (total, item) {
        for (final product in products) {
          if (product.id == item.productId) {
            return total + product.price * item.quantity;
          }
        }
        return total;
      });

  Future<void> saveMedia(String id, Uint8List bytes) =>
      _mediaStorage.save(id, bytes);

  Future<Uint8List?> readMedia(String id) => _mediaStorage.read(id);

  Future<void> deleteMedia(String id) => _mediaStorage.delete(id);

  static Future<DataService> load() async {
    final source = await rootBundle.loadString('assets/data.json');
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('La raíz de data.json debe ser un objeto.');
    }
    final root = Map<String, dynamic>.from(decoded);
    final rawBandInfo = root['band_info'];
    if (rawBandInfo is! Map) {
      throw const FormatException('La sección "band_info" no es válida.');
    }
    return DataService._(
      bandInfo: BandInfo.fromJson(Map<String, dynamic>.from(rawBandInfo)),
      preferences: await SharedPreferences.getInstance(),
    );
  }

  Future<void> addToCart(MerchItem product, String size) async {
    if (!product.sizes.contains(size)) {
      throw ArgumentError.value(size, 'size', 'Talla no disponible.');
    }
    final items = cartItems.toList();
    final index = items.indexWhere(
      (item) => item.productId == product.id && item.size == size,
    );
    final productQuantity = items
        .where((item) => item.productId == product.id)
        .fold(0, (total, item) => total + item.quantity);
    if (productQuantity >= product.stock) {
      throw StateError('No hay más unidades disponibles de este producto.');
    }
    if (index == -1) {
      items.add(CartItem(productId: product.id, size: size, quantity: 1));
    } else {
      items[index] = CartItem(
        productId: product.id,
        size: size,
        quantity: items[index].quantity + 1,
      );
    }
    await _saveCart(items);
  }

  Future<void> setCartQuantity(
    CartItem item,
    int quantity,
    List<MerchItem> products,
  ) async {
    final items = cartItems.toList();
    final index = items.indexWhere(
      (entry) => entry.productId == item.productId && entry.size == item.size,
    );
    if (index == -1) return;
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      final product = products.where((entry) => entry.id == item.productId);
      if (product.isEmpty) {
        throw StateError('El producto ya no está disponible en el catálogo.');
      }
      final otherSizesQuantity = items
          .where(
            (entry) =>
                entry.productId == item.productId && entry.size != item.size,
          )
          .fold(0, (total, entry) => total + entry.quantity);
      if (otherSizesQuantity + quantity > product.first.stock) {
        throw StateError('La cantidad supera el stock disponible.');
      }
      items[index] = CartItem(
        productId: item.productId,
        size: item.size,
        quantity: quantity,
      );
    }
    await _saveCart(items);
  }

  Future<void> _saveCart(List<CartItem> items) async {
    await _preferences.setStringList(
      _cartKey,
      items.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> sendContactMessage({
    required FirestoreGateway firestoreService,
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    await firestoreService.saveContactMessage(
      name: name,
      email: email,
      subject: subject,
      message: message,
    );
    final recipientEmail = bandInfo.emailJs.recipientEmail.trim();
    if (recipientEmail.isEmpty) {
      throw StateError(
        'El mensaje quedó guardado en Firestore, pero falta configurar el destinatario de EmailJS en assets/data.json (emailjs.recipient_email).',
      );
    }
    final response = await http
        .post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'service_id': bandInfo.emailJs.serviceId,
            'template_id': bandInfo.emailJs.templateId,
            'user_id': bandInfo.emailJs.publicKey,
            'template_params': {
              'to_email': recipientEmail,
              'from_name': name,
              'from_email': email,
              'reply_to': email,
              'subject': subject,
              'message': message,
              'user_name': name,
              'user_email': email,
            },
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'El respaldo quedó guardado en Firestore, pero EmailJS respondió con código ${response.statusCode}: ${response.body}',
      );
    }
  }
}
