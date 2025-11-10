// lib/presentation/providers/cart/cart_provider.dart (CORREGIDO)

import 'dart:convert';
import 'package:migue_iphones/domain/models/cart_item.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/presentation/providers/products/products_provider.dart'; // Importar products_provider
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'cart_provider.g.dart';

const String _cartStorageKey = 'migue_iphones_cart';

// -------------------------------------------------------------
// 1. Notifier Principal del Carrito (Ahora Asíncrono)
// -------------------------------------------------------------

@Riverpod(keepAlive: true)
// CORRECCIÓN: Extiende el alias generado _$CartNotifier
class CartNotifier extends _$CartNotifier {
  
  // El método build AHORA es donde se realiza la limpieza.
  @override
  Future<List<CartItem>> build() async {
    // Escuchar la lista de productos actual para usarla en la limpieza
    // El .future nos da el valor real cuando ProductsNotifier termina de cargar.
    final currentProducts = await ref.watch(productsNotifierProvider.future);
    
    // Cargar el carrito guardado
    final savedCart = await _loadCartFromPrefs();

    // 1. LIMPIEZA: Obtener los IDs de los productos actualmente cargados en la DB
    final existingProductIds = currentProducts.map((p) => p.id).toSet();

    // 2. Filtrar los items del carrito que NO existen en la DB
    final cleanedCart = savedCart.where((item) {
      // Si el ID del producto guardado está en los IDs existentes, se mantiene.
      return existingProductIds.contains(item.product.id);
    }).toList();

    // 3. Si hubo cambios, guardar la lista limpia inmediatamente
    if (cleanedCart.length != savedCart.length) {
      await _saveCartToPrefs(cleanedCart);
    }
    
    return cleanedCart;
  }

  // --- Métodos de Persistencia ---

  Future<List<CartItem>> _loadCartFromPrefs() async {
    // Usamos esta función solo para leer el JSON guardado
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getStringList(_cartStorageKey);

      if (cartData == null) {
        return [];
      }

      // Convertir la lista de Strings JSON a List<CartItem>
      return cartData
          .map((itemString) => CartItem.fromJson(jsonDecode(itemString) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error al cargar el carrito: $e');
      return [];
    }
  }

  Future<void> _saveCartToPrefs(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();

    final cartData = items
        .map((item) => jsonEncode(item.toJson()))
        .toList();

    await prefs.setStringList(_cartStorageKey, cartData);
  }

  // --- Métodos de Mutación ---

  Future<void> addProductToCart(Product product) async {
    final currentState = state.value ?? [];
    List<CartItem> updatedList = List.from(currentState);

    final existingItemIndex = updatedList.indexWhere(
      (item) => item.product.id == product.id
    );

    if (existingItemIndex != -1) {
      final existingItem = updatedList[existingItemIndex];
      if (existingItem.quantity < product.stock) {
        updatedList[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + 1,
        );
      }
    } else {
      if (product.stock > 0) {
        updatedList.add(CartItem(product: product, quantity: 1));
      }
    }

    state = AsyncData(updatedList);
    await _saveCartToPrefs(updatedList);
  }

  Future<void> removeProductFromCart(int productId) async {
    final currentState = state.value ?? [];
    final updatedList = currentState.where((item) => item.product.id != productId).toList();
    
    state = AsyncData(updatedList);
    await _saveCartToPrefs(updatedList);
  }
  
  Future<void> decrementProductQuantity(int productId) async {
    final currentState = state.value ?? [];
    List<CartItem> updatedList = List.from(currentState);

    final existingItemIndex = updatedList.indexWhere(
      (item) => item.product.id == productId
    );

    if (existingItemIndex != -1) {
      final existingItem = updatedList[existingItemIndex];
      
      if (existingItem.quantity > 1) {
        updatedList[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity - 1,
        );
      } else {
        updatedList.removeAt(existingItemIndex);
      }

      state = AsyncData(updatedList);
      await _saveCartToPrefs(updatedList);
    }
  }
  
  Future<void> clearCart() async {
    state = const AsyncData([]);
    await _saveCartToPrefs([]);
  }
}

// -------------------------------------------------------------
// 2. Selectores (ACTUALIZADOS)
// -------------------------------------------------------------

@riverpod
int cartTotalItems(CartTotalItemsRef ref) {
  final cartAsync = ref.watch(cartNotifierProvider);

  if (cartAsync.isLoading || cartAsync.hasError || !cartAsync.hasValue) {
    return 0;
  }
  
  final cartItems = cartAsync.value!;
  
  return cartItems.fold(0, (total, item) => total + item.quantity);
}

@riverpod
double cartTotalPrice(CartTotalPriceRef ref) {
  final cartAsync = ref.watch(cartNotifierProvider);

  if (cartAsync.isLoading || cartAsync.hasError || !cartAsync.hasValue) {
    return 0.0;
  }
  
  final cartItems = cartAsync.value!;
  
  return cartItems.fold(0, (total, item) => total + item.subtotal);
}