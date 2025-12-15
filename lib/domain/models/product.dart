// lib/domain/models/product.dart

class Product {
  final int id;
  final String name;
  final String description; // Asegúrate de tener este campo en DB o que acepte nulos
  final double price;
  
  // Getter de compatibilidad (toma la primera imagen para las cards viejas)
  String get imageUrl => images.isNotEmpty ? images.first : ''; 
  
  final List<String> images; // Lista de imágenes para el carrusel
  final String category;
  final int stock;
  final int discount;
  
  // NUEVO CAMPO CRÍTICO PARA ENVÍOS
  final double weight; 

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    required this.category,
    required this.stock,
    this.discount = 0,
    required this.weight,
  });

  // Cálculo de precio final con descuento
  double get finalPrice {
    if (discount <= 0) return price;
    return price * (1 - (discount / 100));
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // 1. Lógica robusta para recuperar imágenes (Array o String único)
    List<String> parsedImages = [];
    
    if (json['images'] != null && json['images'] is List) {
      parsedImages = List<String>.from(json['images']);
    } 
    
    // Fallback: Si el array está vacío, intentamos usar el campo viejo 'image_url'
    if (parsedImages.isEmpty && json['image_url'] != null) {
      parsedImages.add(json['image_url'] as String);
    }

    // Fallback de seguridad final (Placeholder)
    if (parsedImages.isEmpty) {
      parsedImages.add('https://via.placeholder.com/400');
    }

    return Product(
      id: json['id'],
      name: json['name'] as String? ?? 'Sin Nombre',
      description: json['description'] as String? ?? '',
      // Manejo seguro de números (int o double)
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      images: parsedImages, 
      category: json['category'] as String? ?? 'General',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      // LEER EL PESO (Si es null o 0, usamos 0.5kg por defecto para no romper cotización)
      weight: (json['weight'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'images': images, // Enviamos lista completa
      'image_url': imageUrl, // Compatibilidad hacia atrás
      'category': category,
      'stock': stock,
      'discount': discount,
      'weight': weight, // Guardamos el peso
    };
  }
  
  // Método copyWith por si necesitas actualizar estado localmente
  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    List<String>? images,
    String? category,
    int? stock,
    int? discount,
    double? weight,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      images: images ?? this.images,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      discount: discount ?? this.discount,
      weight: weight ?? this.weight,
    );
  }
}