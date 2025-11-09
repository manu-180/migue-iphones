// lib/domain/models/cart_item.dart (ACTUALIZADO)

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

  // -------------------------------------------------------------
  // MÉTODOS DE SERIALIZACIÓN (para Shared Preferences)
  // -------------------------------------------------------------

  // Convertir un CartItem a un Mapa (JSON)
  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      // Guardamos el producto completo para poder reconstruirlo
      'product': product.toJson(), 
    };
  }

  // Crear un CartItem desde un Mapa (JSON)
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      quantity: json['quantity'] as int,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
    );
  }
}