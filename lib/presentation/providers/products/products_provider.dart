// lib/presentation/providers/products/products_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/domain/repositories/products_repository.dart';
import 'package:migue_iphones/infrastructure/repositories/products_repository_impl.dart';
import 'package:migue_iphones/presentation/providers/search_provider.dart';
import 'package:migue_iphones/presentation/providers/sort_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'products_provider.g.dart';

@Riverpod(keepAlive: true)
ProductsRepository productsRepository(ProductsRepositoryRef ref) {
  return ProductsRepositoryImpl();
}

@Riverpod(keepAlive: true)
class ProductsNotifier extends _$ProductsNotifier {
  @override
  Future<List<Product>> build() async {
    final repository = ref.watch(productsRepositoryProvider);
    return repository.getProducts();
  }
}

final selectedCategoryProvider = StateProvider<String>((ref) => 'Todos');

// PROVIDER DE FILTRADO SIMPLIFICADO
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsNotifierProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final sortOption = ref.watch(sortOptionProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return productsAsync.whenData((products) {
    // 1. Filtro por Búsqueda
    var filtered = products.where((p) {
      return p.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    // 2. Filtro por Categoría (AHORA ES DIRECTO)
    if (selectedCategory != 'Todos') {
      filtered = filtered.where((p) {
        // Comparamos directamente porque en la DB ya dice "iPhones", "Accesorios", etc.
        return p.category == selectedCategory; 
      }).toList();
    }

    // 3. Ordenamiento
    switch (sortOption) {
      case SortOption.nombreAZ:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nombreZA:
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOption.precioMenorMayor:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.precioMayorMenor:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
    }

    return filtered;
  });
});