class CartItem {
  const CartItem({
    required this.productId,
    required this.size,
    required this.quantity,
  });

  final String productId;
  final String size;
  final int quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id'] as String,
      size: json['size'] as String,
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'size': size,
    'quantity': quantity,
  };
}
