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
    required List<FeedItem> feed,
    required List<Track> tracks,
    required List<MerchItem> merch,
    required this._preferences,
  }) : _feed = List.unmodifiable(feed),
       _tracks = List.unmodifiable(tracks),
       _merch = List.unmodifiable(merch);

  static const _sessionKey = 'deathfish_session';
  static const _favoritesKey = 'deathfish_favorite_track_ids';
  static const _cartKey = 'deathfish_merch_cart';
  static const _contentKey = 'deathfish_content_overrides';
  static const _adminUsername = 'adminfish';
  static const _adminPassword = 'administrafish';

  final SharedPreferences _preferences;
  final BandInfo bandInfo;
  List<FeedItem> _feed;
  List<Track> _tracks;
  List<MerchItem> _merch;
  UserSession? _session;

  List<FeedItem> get feed => _feed;
  List<Track> get tracks => _tracks;
  List<MerchItem> get merch => _merch;
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

    List<T> parseList<T>(
      Object? value,
      String key,
      T Function(Map<String, dynamic>) parse,
    ) {
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
    final savedContent = preferences.getString(_contentKey);
    final overrides = savedContent == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(savedContent) as Map);
    final service = DataService._(
      bandInfo: BandInfo.fromJson(objectFor('band_info')),
      feed: parseList(
        overrides['feed'] ?? json['feed'],
        'feed',
        FeedItem.fromJson,
      ),
      tracks: parseList(
        overrides['tracks'] ?? json['tracks'],
        'tracks',
        Track.fromJson,
      ),
      merch: parseList(
        overrides['merch'] ?? json['merch'],
        'merch',
        MerchItem.fromJson,
      ),
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
    if (normalizedEmail.toLowerCase() == _adminUsername) {
      if (password != _adminPassword) {
        throw const FormatException(
          'Usuario o contraseña de administrador incorrectos.',
        );
      }
      final session = UserSession(
        email: _adminUsername,
        isGuest: false,
        isAdmin: true,
      );
      await _saveSession(session);
      return session;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
      throw const FormatException(
        'Ingresa un correo válido o el usuario admin.',
      );
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

  Future<void> saveFeedItem(FeedItem item) async {
    _requireAdmin();
    if (item.id.trim().isEmpty || item.title.trim().isEmpty) {
      throw const FormatException(
        'El comunicado necesita título e identificador.',
      );
    }
    final updated = _feed.toList();
    final index = updated.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      updated.add(item);
    } else {
      updated[index] = item;
    }
    await _saveContent(feed: updated);
  }

  Future<void> deleteFeedItem(String id) async {
    _requireAdmin();
    final updated = _feed.where((entry) => entry.id != id).toList();
    if (updated.length == _feed.length) {
      throw ArgumentError.value(id, 'id', 'Comunicado desconocido.');
    }
    await _saveContent(feed: updated);
  }

  Future<void> saveTrack(Track track) async {
    _requireAdmin();
    if (track.id.trim().isEmpty ||
        track.title.trim().isEmpty ||
        track.youtubeUrl.trim().isEmpty) {
      throw const FormatException(
        'La canción necesita título, identificador y URL de video.',
      );
    }
    final videoUri = Uri.tryParse(track.youtubeUrl);
    if (videoUri == null ||
        !videoUri.hasAuthority ||
        !{'http', 'https'}.contains(videoUri.scheme)) {
      throw const FormatException('Ingresa una URL de video válida.');
    }
    final updated = _tracks.toList();
    final index = updated.indexWhere((entry) => entry.id == track.id);
    if (index == -1) {
      updated.add(track);
    } else {
      updated[index] = track;
    }
    await _saveContent(tracks: updated);
  }

  Future<void> deleteTrack(String id) async {
    _requireAdmin();
    final updated = _tracks.where((entry) => entry.id != id).toList();
    if (updated.length == _tracks.length) {
      throw ArgumentError.value(id, 'id', 'Canción desconocida.');
    }
    await _saveContent(tracks: updated);
  }

  Future<void> saveMerchItem(MerchItem item) async {
    _requireAdmin();
    if (item.id.trim().isEmpty ||
        item.name.trim().isEmpty ||
        item.image.trim().isEmpty ||
        item.sizes.isEmpty ||
        item.price < 0 ||
        item.stock < 0) {
      throw const FormatException(
        'Revisa nombre, imagen, tallas, precio y stock del producto.',
      );
    }
    final itemsInCart = cartItems
        .where((entry) => entry.productId == item.id)
        .toList();
    final cartQuantity = itemsInCart.fold(
      0,
      (total, entry) => total + entry.quantity,
    );
    if (cartQuantity > item.stock ||
        itemsInCart.any((entry) => !item.sizes.contains(entry.size))) {
      throw StateError(
        'El stock o las tallas no pueden quedar por debajo de lo que ya está en el carrito.',
      );
    }
    final updated = _merch.toList();
    final index = updated.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      updated.add(item);
    } else {
      updated[index] = item;
    }
    await _saveContent(merch: updated);
  }

  Future<void> deleteMerchItem(String id) async {
    _requireAdmin();
    if (cartItems.any((entry) => entry.productId == id)) {
      throw StateError(
        'Quita primero este producto del carrito antes de eliminarlo.',
      );
    }
    final updated = _merch.where((entry) => entry.id != id).toList();
    if (updated.length == _merch.length) {
      throw ArgumentError.value(id, 'id', 'Producto desconocido.');
    }
    await _saveContent(merch: updated);
  }

  void _requireAdmin() {
    if (_session?.isAdmin != true) {
      throw StateError('Esta acción requiere una sesión de administrador.');
    }
  }

  Future<void> _saveContent({
    List<FeedItem>? feed,
    List<Track>? tracks,
    List<MerchItem>? merch,
  }) async {
    final updatedFeed = feed ?? _feed;
    final updatedTracks = tracks ?? _tracks;
    final updatedMerch = merch ?? _merch;
    final saved = await _preferences.setString(
      _contentKey,
      jsonEncode({
        'feed': updatedFeed.map((item) => item.toJson()).toList(),
        'tracks': updatedTracks.map((item) => item.toJson()).toList(),
        'merch': updatedMerch.map((item) => item.toJson()).toList(),
      }),
    );
    if (!saved) {
      throw StateError('No se pudieron guardar los cambios del administrador.');
    }
    _feed = List.unmodifiable(updatedFeed);
    _tracks = List.unmodifiable(updatedTracks);
    _merch = List.unmodifiable(updatedMerch);
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
