// lib/domain/models/product.dart

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category; // 'iphone', 'accessory', 'case'
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.stock,
  });

  // Constructor factory para crear un Product desde un mapa (como el que viene de Supabase)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] as String,
      description: json['description'] as String,
      // Manejar la conversión de number (int/double) a double para el precio
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      category: json['category'] as String,
      stock: json['stock'] as int,
    );
  }

  // Método to json para cuando tengamos que enviar datos (ej: el programa de escritorio)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'stock': stock,
    };
  }
}