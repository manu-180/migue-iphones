// lib/domain/repositories/products_repository.dart

import 'package:migue_iphones/domain/models/product.dart';

// Definición del Contrato del Repositorio
abstract class ProductsRepository {
  Future<List<Product>> getProducts();
  // Future<Product> getProductById(int id); // Se agregará después
  // Future<void> createProduct(Product product); // Para el programa de escritorio
}