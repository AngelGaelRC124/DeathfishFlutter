import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/band_info.dart';
import '../models/cart_item.dart';
import '../models/feed_item.dart';
import '../models/merch_item.dart';
import '../models/track.dart';
import '../models/user_session.dart';

class DataService {
  DataService._({
    required this.bandInfo,
    required this.feed,
    required this.tracks,
    required this.merch,
    required this._preferences,
  });

  static const _sessionKey = 'deathfish_session';
  static const _favoritesKey = 'deathfish_favorite_track_ids';
  static const _cartKey = 'deathfish_merch_cart';

  final SharedPreferences _preferences;
  final BandInfo bandInfo;
  final List<FeedItem> feed;
  final List<Track> tracks;
  final List<MerchItem> merch;
  UserSession? _session;

  UserSession? get session => _session;
  Set<String> get favoriteIds =>
      Set<String>.unmodifiable(_preferences.getStringList(_favoritesKey) ?? []);
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

  double get cartTotal => cartItems.fold(0, (total, item) {
    final product = merch.firstWhere((product) => product.id == item.productId);
    return total + product.price * item.quantity;
  });

  static Future<DataService> load() async {
    final source = await rootBundle.loadString('assets/data.json');
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('La raíz de data.json debe ser un objeto.');
    }
    final json = Map<String, dynamic>.from(decoded);

    Map<String, dynamic> objectFor(String key) {
      final value = json[key];
      if (value is! Map) {
        throw FormatException('La sección "$key" no es un objeto válido.');
      }
      return Map<String, dynamic>.from(value);
    }

    List<T> listFor<T>(String key, T Function(Map<String, dynamic>) parse) {
      final value = json[key];
      if (value is! List) {
        throw FormatException('La sección "$key" no es una lista válida.');
      }
      return List<T>.unmodifiable(
        value.map((item) {
          if (item is! Map) {
            throw FormatException('Hay un elemento inválido en "$key".');
          }
          return parse(Map<String, dynamic>.from(item));
        }),
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final service = DataService._(
      bandInfo: BandInfo.fromJson(objectFor('band_info')),
      feed: listFor('feed', FeedItem.fromJson),
      tracks: listFor('tracks', Track.fromJson),
      merch: listFor('merch', MerchItem.fromJson),
      preferences: preferences,
    );
    final savedSession = preferences.getString(_sessionKey);
    if (savedSession != null) {
      service._session = UserSession.fromJson(
        Map<String, dynamic>.from(jsonDecode(savedSession) as Map),
      );
    }
    return service;
  }

  Future<UserSession> login(String email, String password) async {
    final normalizedEmail = email.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
      throw const FormatException('Ingresa un correo electrónico válido.');
    }
    if (password.length < 6) {
      throw const FormatException(
        'La contraseña debe tener al menos 6 caracteres.',
      );
    }
    final session = UserSession(email: normalizedEmail, isGuest: false);
    await _saveSession(session);
    return session;
  }

  Future<UserSession> loginAsGuest() async {
    const session = UserSession(email: 'INVITADO', isGuest: true);
    await _saveSession(session);
    return session;
  }

  Future<void> _saveSession(UserSession session) async {
    await _preferences.setString(_sessionKey, jsonEncode(session.toJson()));
    _session = session;
  }

  Future<void> logout() async {
    await _preferences.remove(_sessionKey);
    _session = null;
  }

  Future<bool> toggleFavorite(String trackId) async {
    if (!tracks.any((track) => track.id == trackId)) {
      throw ArgumentError.value(trackId, 'trackId', 'Canción desconocida.');
    }
    final favorites = _preferences.getStringList(_favoritesKey) ?? [];
    final isFavorite = favorites.contains(trackId);
    if (isFavorite) {
      favorites.remove(trackId);
    } else {
      favorites.add(trackId);
    }
    await _preferences.setStringList(_favoritesKey, favorites);
    return !isFavorite;
  }

  Future<void> addToCart(String productId, String size) async {
    final product = merch.firstWhere(
      (item) => item.id == productId,
      orElse: () => throw ArgumentError.value(
        productId,
        'productId',
        'Producto desconocido.',
      ),
    );
    if (!product.sizes.contains(size)) {
      throw ArgumentError.value(size, 'size', 'Talla no disponible.');
    }
    final items = cartItems.toList();
    final index = items.indexWhere(
      (item) => item.productId == productId && item.size == size,
    );
    final quantity = index == -1 ? 1 : items[index].quantity + 1;
    final productQuantity = items
        .where((item) => item.productId == productId)
        .fold(0, (total, item) => total + item.quantity);
    if (productQuantity >= product.stock) {
      throw StateError('No hay más unidades disponibles de este producto.');
    }
    if (index == -1) {
      items.add(CartItem(productId: productId, size: size, quantity: quantity));
    } else {
      items[index] = CartItem(
        productId: productId,
        size: size,
        quantity: quantity,
      );
    }
    await _saveCart(items);
  }

  Future<void> setCartQuantity(CartItem item, int quantity) async {
    final items = cartItems.toList();
    final index = items.indexWhere(
      (entry) => entry.productId == item.productId && entry.size == item.size,
    );
    if (index == -1) return;
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      final product = merch.firstWhere((entry) => entry.id == item.productId);
      final otherSizesQuantity = items
          .where(
            (entry) =>
                entry.productId == item.productId && entry.size != item.size,
          )
          .fold(0, (total, entry) => total + entry.quantity);
      if (otherSizesQuantity + quantity > product.stock) {
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
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    final response = await http
        .post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'service_id': bandInfo.emailJs.serviceId,
            'template_id': bandInfo.emailJs.templateId,
            'user_id': bandInfo.emailJs.publicKey,
            'template_params': {
              'from_name': name,
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
        'EmailJS respondió con código ${response.statusCode}: ${response.body}',
      );
    }
  }
}
