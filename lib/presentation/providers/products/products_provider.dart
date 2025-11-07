// lib/presentation/providers/products/products_provider.dart (CORREGIDO)

import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/infrastructure/repositories/products_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'products_provider.g.dart';

// Definición de las opciones de filtro
enum ProductFilter { 
  all('Todos'), 
  iphone('iPhones'), 
  accessory('Accesorios'), 
  caseType('Fundas');

  final String displayValue;
  const ProductFilter(this.displayValue);
}

// -------------------------------------------------------------
// 1. Proveedor del Estado del Filtro (UI controlará este estado)
// -------------------------------------------------------------

@Riverpod(keepAlive: true)
class ProductFilterNotifier extends _$ProductFilterNotifier {
  @override
  ProductFilter build() => ProductFilter.all;

  void setFilter(ProductFilter filter) {
    state = filter;
  }
}

// -------------------------------------------------------------
// 2. Proveedor del Repositorio
// -------------------------------------------------------------

@Riverpod(keepAlive: true)
ProductsRepositoryImpl productsRepository(ProductsRepositoryRef ref) {
  return ProductsRepositoryImpl();
}


// 3. Notifier para manejar la lista de productos (sin cambios)
@riverpod
class ProductsNotifier extends _$ProductsNotifier {
  @override
  FutureOr<List<Product>> build() {
    return loadProducts();
  }

  Future<List<Product>> loadProducts() async {
    final repository = ref.read(productsRepositoryProvider);
    return repository.getProducts();
  }
}

// -------------------------------------------------------------
// 4. Proveedor que Aplica el Filtro (Selector) - CORREGIDO
// -------------------------------------------------------------

@riverpod
// DEVUELVE UN ASYNCVALUE, NO UN LIST
AsyncValue<List<Product>> filteredProducts(FilteredProductsRef ref) {
  
  // Observa el estado completo de los productos (AsyncValue<List<Product>>)
  final productsAsync = ref.watch(productsNotifierProvider);
  
  // Observa el filtro seleccionado (ProductFilter)
  final filter = ref.watch(productFilterNotifierProvider); 

  // Usamos .when() para transformar el AsyncValue
  return productsAsync.when(
    data: (products) {
      // Si tenemos datos, los filtramos
      final filteredList = products.where((product) {
        switch (filter) {
          case ProductFilter.all:
            return true; // Muestra todos
          case ProductFilter.iphone:
            return product.category.toLowerCase() == 'iphone'; 
          case ProductFilter.accessory:
            return product.category.toLowerCase() == 'accessory';
          case ProductFilter.caseType:
            return product.category.toLowerCase() == 'case';
          default:
            return true;
        }
      }).toList();
      
      // Devolvemos los datos filtrados, envueltos en un AsyncValue
      return AsyncValue.data(filteredList);
    },
    // Pasamos el estado de carga y error a la UI
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
}