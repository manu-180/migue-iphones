// lib/domain/models/cart_item.dart

import 'package:migue_iphones/domain/models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  // Calcula el subtotal para este item
  double get subtotal => product.price * quantity;
  
  // Métodos para clonar o modificar la cantidad
  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}