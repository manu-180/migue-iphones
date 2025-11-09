// lib/infrastructure/datasources/products_datasource.dart (CORREGIDO)

import 'package:migue_iphones/domain/models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Este es el Datasource de Supabase
class SupabaseProductsDatasource {
  final SupabaseClient supabase;
  
  // Asume que la tabla de productos se llama 'products'
  static const String _tableName = 'products'; 

  // CORRECCIÓN: Usamos la instancia global de Supabase inicializada en main.dart
  SupabaseProductsDatasource() : 
    supabase = Supabase.instance.client;

  // Método para obtener la lista de productos
  Future<List<Product>> getProducts() async {
    try {
      final response = await supabase
          .from(_tableName)
          .select()
          .order('name', ascending: true); // Ordenar por nombre

      // Mapear los resultados de la base de datos al modelo Product
      final List<Product> products = 
          (response as List).map((json) => Product.fromJson(json)).toList();

      return products;

    } on PostgrestException catch (e) {
      // Manejo específico de errores de Supabase
      throw Exception('Error al cargar productos desde Supabase: ${e.message}');
    } catch (e) {
      // Manejo general de errores
      throw Exception('Error desconocido al obtener productos: $e');
    }
  }
}