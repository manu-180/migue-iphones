// lib/presentation/providers/cart/cart_provider.dart (CORREGIDO)

import 'dart:convert'; // Para JSON
import 'package:migue_iphones/domain/models/cart_item.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importar

part 'cart_provider.g.dart';

// Clave para guardar en SharedPreferences
const String _cartStorageKey = 'migue_iphones_cart';

// -------------------------------------------------------------
// 1. Notifier Principal del Carrito (Ahora Asíncrono)
// -------------------------------------------------------------

@Riverpod(keepAlive: true)
// CORRECCIÓN: Se extiende _$CartNotifier (generado), no _$AsyncNotifier
class CartNotifier extends _$CartNotifier {
  
  // El método build AHORA ES ASÍNCRONO para cargar desde el disco
  @override
  Future<List<CartItem>> build() async {
    return _loadCartFromPrefs();
  }

  // --- Métodos de Persistencia ---

  Future<List<CartItem>> _loadCartFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getStringList(_cartStorageKey);

      if (cartData == null) {
        return []; // Carrito vacío si no hay datos guardados
      }

      // Convertir la lista de Strings JSON de nuevo a List<CartItem>
      return cartData
          .map((itemString) => CartItem.fromJson(jsonDecode(itemString) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error al cargar el carrito: $e');
      return []; // Devolver vacío en caso de error de parseo
    }
  }

  Future<void> _saveCartToPrefs(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();

    // Convertir List<CartItem> a List<String> (JSON)
    final cartData = items
        .map((item) => jsonEncode(item.toJson()))
        .toList();

    await prefs.setStringList(_cartStorageKey, cartData);
  }

  // --- Métodos de Mutación (ahora actualizan el estado y guardan) ---

  // Método para AÑADIR un producto al carrito
  Future<void> addProductToCart(Product product) async {
    // Obtenemos el estado actual (usando .value)
    final currentState = state.value ?? [];
    List<CartItem> updatedList = List.from(currentState);

    final existingItemIndex = updatedList.indexWhere(
      (item) => item.product.id == product.id
    );

    if (existingItemIndex != -1) {
      // 2. Si existe: Incrementar la cantidad (respetando el stock)
      final existingItem = updatedList[existingItemIndex];
      if (existingItem.quantity < product.stock) {
        updatedList[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + 1,
        );
      }
    } else {
      // 3. Si no existe: Añadir el nuevo item (si hay stock)
      if (product.stock > 0) {
        updatedList.add(CartItem(product: product, quantity: 1));
      }
    }

    // Actualizar el estado y guardar
    state = AsyncData(updatedList);
    await _saveCartToPrefs(updatedList);
  }

  // Método para QUITAR un producto completamente del carrito
  Future<void> removeProductFromCart(int productId) async {
    final currentState = state.value ?? [];
    final updatedList = currentState.where((item) => item.product.id != productId).toList();
    
    state = AsyncData(updatedList);
    await _saveCartToPrefs(updatedList);
  }
  
  // Método para DECREMENTAR la cantidad
  Future<void> decrementProductQuantity(int productId) async {
    final currentState = state.value ?? [];
    List<CartItem> updatedList = List.from(currentState);

    final existingItemIndex = updatedList.indexWhere(
      (item) => item.product.id == productId
    );

    if (existingItemIndex != -1) {
      final existingItem = updatedList[existingItemIndex];
      
      if (existingItem.quantity > 1) {
        // Reducir cantidad
        updatedList[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity - 1,
        );
      } else {
        // Si la cantidad es 1, eliminar el item
        updatedList.removeAt(existingItemIndex);
      }

      state = AsyncData(updatedList);
      await _saveCartToPrefs(updatedList);
    }
  }
  
  // Método para VACIAR el carrito
  Future<void> clearCart() async {
    state = const AsyncData([]);
    await _saveCartToPrefs([]);
  }
}

// -------------------------------------------------------------
// 2. Selectores (ACTUALIZADOS para manejar AsyncValue)
// -------------------------------------------------------------

// Selector para el CONTEO TOTAL de artículos (el "globo")
@riverpod
int cartTotalItems(CartTotalItemsRef ref) {
  // Escucha al notifier principal (que ahora es AsyncValue)
  final cartAsync = ref.watch(cartNotifierProvider);

  // Si está cargando o hay error, el total es 0
  if (cartAsync.isLoading || cartAsync.hasError || !cartAsync.hasValue) {
    return 0;
  }
  
  final cartItems = cartAsync.value!;
  
  // Suma la cantidad de cada item
  return cartItems.fold(0, (total, item) => total + item.quantity);
}

// Selector para el PRECIO TOTAL del carrito
@riverpod
double cartTotalPrice(CartTotalPriceRef ref) {
  // Escucha al notifier principal (que ahora es AsyncValue)
  final cartAsync = ref.watch(cartNotifierProvider);

  // Si está cargando o hay error, el total es 0
  if (cartAsync.isLoading || cartAsync.hasError || !cartAsync.hasValue) {
    return 0.0;
  }
  
  final cartItems = cartAsync.value!;
  
  // Suma el subtotal de cada item
  return cartItems.fold(0, (total, item) => total + item.subtotal);
}