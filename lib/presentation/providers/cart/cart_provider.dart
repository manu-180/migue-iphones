// lib/presentation/providers/cart/cart_provider.dart

import 'package:migue_iphones/domain/models/cart_item.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cart_provider.g.dart';

// -------------------------------------------------------------
// 1. Notifier Principal del Carrito
// -------------------------------------------------------------

@Riverpod(keepAlive: true)
class CartNotifier extends _$CartNotifier {
  // Estado inicial: una lista vacía de items del carrito
  @override
  List<CartItem> build() => [];

  // Método para AÑADIR un producto al carrito
  void addProductToCart(Product product) {
    // 1. Revisar si el producto ya existe en el carrito
    final existingItemIndex = state.indexWhere(
      (item) => item.product.id == product.id
    );

    if (existingItemIndex != -1) {
      // 2. Si existe: Incrementar la cantidad (respetando el stock)
      final existingItem = state[existingItemIndex];
      if (existingItem.quantity < product.stock) {
        
        final updatedList = List<CartItem>.from(state); // Copia de la lista
        updatedList[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + 1,
        );
        state = updatedList; // Actualizar estado
      }
      // Opcional: Mostrar snackbar de "Stock máximo alcanzado"
      
    } else {
      // 3. Si no existe: Añadir el nuevo item (si hay stock)
      if (product.stock > 0) {
        state = [...state, CartItem(product: product, quantity: 1)];
      }
      // Opcional: Mostrar snackbar de "Sin stock"
    }
  }

  // Método para QUITAR un producto completamente del carrito
  void removeProductFromCart(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }
  
  // Método para DECREMENTAR la cantidad (ej: en la pantalla del carrito)
  void decrementProductQuantity(int productId) {
    final existingItemIndex = state.indexWhere(
      (item) => item.product.id == productId
    );

    if (existingItemIndex != -1) {
      final existingItem = state[existingItemIndex];
      
      if (existingItem.quantity > 1) {
        // Reducir cantidad
        final updatedList = List<CartItem>.from(state);
        updatedList[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity - 1,
        );
        state = updatedList;
      } else {
        // Si la cantidad es 1, eliminar el item
        removeProductFromCart(productId);
      }
    }
  }
  
  // Método para VACIAR el carrito (ej: después de la compra)
  void clearCart() {
    state = [];
  }
}

// -------------------------------------------------------------
// 2. Selectores (Providers derivados para la UI)
// -------------------------------------------------------------

// Selector para el CONTEO TOTAL de artículos (el "globo")
@riverpod
int cartTotalItems(CartTotalItemsRef ref) {
  // Escucha al notifier principal
  final cartItems = ref.watch(cartNotifierProvider);
  
  // Suma la cantidad de cada item
  return cartItems.fold(0, (total, item) => total + item.quantity);
}

// Selector para el PRECIO TOTAL del carrito
@riverpod
double cartTotalPrice(CartTotalPriceRef ref) {
  // Escucha al notifier principal
  final cartItems = ref.watch(cartNotifierProvider);
  
  // Suma el subtotal de cada item
  return cartItems.fold(0, (total, item) => total + item.subtotal);
}