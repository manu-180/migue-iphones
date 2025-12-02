// lib/domain/models/product.dart

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  // Mantenemos imageUrl como getter para compatibilidad rápida (toma la primera)
  String get imageUrl => images.isNotEmpty ? images.first : ''; 
  final List<String> images; // NUEVO CAMPO
  final String category;
  final int stock;
  final int discount;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    required this.category,
    required this.stock,
    this.discount = 0,
  });

  double get finalPrice {
    if (discount <= 0) return price;
    return price * (1 - (discount / 100));
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Lógica robusta para recuperar imágenes
    List<String> parsedImages = [];
    
    if (json['images'] != null) {
      parsedImages = List<String>.from(json['images']);
    } 
    
    // Fallback: Si el array está vacío, intentamos usar el campo viejo 'image_url'
    if (parsedImages.isEmpty && json['image_url'] != null) {
      parsedImages.add(json['image_url'] as String);
    }

    // Fallback de seguridad final (placeholder)
    if (parsedImages.isEmpty) {
      parsedImages.add('https://via.placeholder.com/400');
    }

    return Product(
      id: json['id'],
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      images: parsedImages, // Asignamos la lista
      category: json['category'] as String,
      stock: json['stock'] as int,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'images': images, // Enviamos lista
      'image_url': imageUrl, // Compatibilidad
      'category': category,
      'stock': stock,
      'discount': discount,
    };
  }
}