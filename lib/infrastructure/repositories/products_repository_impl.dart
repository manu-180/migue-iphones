// lib/infrastructure/repositories/products_repository_impl.dart

import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/domain/repositories/products_repository.dart';
import 'package:migue_iphones/infrastructure/datasources/products_datasource.dart';

// Implementación del Repositorio
class ProductsRepositoryImpl implements ProductsRepository {
  // Inyectamos el Datasource. Esto desacopla la lógica de negocio de la implementación de la DB.
  final SupabaseProductsDatasource datasource;

  ProductsRepositoryImpl({SupabaseProductsDatasource? datasource}) 
    : datasource = datasource ?? SupabaseProductsDatasource();

  @override
  Future<List<Product>> getProducts() {
    // Simplemente delegamos la llamada al Datasource
    return datasource.getProducts();
  }
}