// lib/infrastructure/datasources/products_datasource.dart

import 'package:migue_iphones/domain/models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Este es el Datasource de Supabase
class SupabaseProductsDatasource {
  final SupabaseClient supabase;
  
  // Asume que la tabla de productos se llama 'products'
  static const String _tableName = 'products'; 

  // Inyectamos el cliente de Supabase (viene de la inicialización en main.dart)
  SupabaseProductsDatasource() : 
    // Inicialización del cliente de Supabase
    // ADVERTENCIA: Debes reemplazar estos placeholders con tus credenciales reales de Supabase.
    // En un entorno de producción, estos valores deben cargarse desde un archivo .env.
    supabase = SupabaseClient(
      'TU_URL_DE_SUPABASE', 
      'TU_ANON_KEY_DE_SUPABASE_PUBLICA',
    );

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