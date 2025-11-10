// lib/presentation/providers/products/products_provider.dart (CORREGIDO CON SINTAXIS REALTIME V2)

import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/infrastructure/repositories/products_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

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
// 1. Proveedor del Estado del Filtro
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

// 3. Notifier para manejar la lista de productos (ACTUALIZADO)
@riverpod
class ProductsNotifier extends _$ProductsNotifier {
  
  @override
  FutureOr<List<Product>> build() {
    _setupRealtimeListener();
    return loadProducts();
  }

  Future<List<Product>> loadProducts() async {
    final repository = ref.read(productsRepositoryProvider);
    return repository.getProducts();
  }

  // Lógica de Supabase Realtime
  void _setupRealtimeListener() {
    final supabase = Supabase.instance.client;

    // 1. CORRECCIÓN: Usar el método 'onPostgresChanges'
    final channel = supabase
        .channel('public:products')
        .onPostgresChanges(
          // 2. CORRECCIÓN: Usar el enum 'PostgresChangeEvent'
          event: PostgresChangeEvent.all, // Escucha INSERT, UPDATE, DELETE
          schema: 'public',
          table: 'products',
          callback: (payload) { // El payload se recibe aquí
            print('¡Cambio detectado en Supabase! Recargando productos...');
            
            // 3. Invalidar el provider para forzar la recarga
            ref.invalidateSelf();
          },
        )
        .subscribe();

    // 4. Limpiar el canal cuando el provider muera
    ref.onDispose(() {
      supabase.removeChannel(channel);
    });
  }
}

// -------------------------------------------------------------
// 4. Proveedor que Aplica el Filtro (Selector)
// -------------------------------------------------------------

@riverpod
AsyncValue<List<Product>> filteredProducts(FilteredProductsRef ref) {
  
  final productsAsync = ref.watch(productsNotifierProvider);
  final filter = ref.watch(productFilterNotifierProvider); 

  return productsAsync.when(
    data: (products) {
      final filteredList = products.where((product) {
        switch (filter) {
          case ProductFilter.all:
            return true;
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
      
      return AsyncValue.data(filteredList);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
}