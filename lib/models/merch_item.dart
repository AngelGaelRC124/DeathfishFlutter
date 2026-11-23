class MerchItem {
  const MerchItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.sizes,
    required this.stock,
    required this.image,
    required this.description,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final List<String> sizes;
  final int stock;
  final String image;
  final String description;

  factory MerchItem.fromJson(Map<String, dynamic> json) {
    return MerchItem(
      id: json['id'] as String,
      name: json['nombre'] as String,
      category: json['categoria'] as String,
      price: (json['precio'] as num).toDouble(),
      sizes: List<String>.unmodifiable(
        (json['tallas'] as List<dynamic>).cast<String>(),
      ),
      stock: json['stock'] as int,
      image: json['imagen'] as String,
      description: json['descripcion'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': name,
    'categoria': category,
    'precio': price,
    'tallas': sizes,
    'stock': stock,
    'imagen': image,
    'descripcion': description,
  };
}
