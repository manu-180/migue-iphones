// lib/presentation/providers/cart/cart_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/domain/models/cart_item.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'cart_provider.g.dart';

const String _cartStorageKey = 'migue_iphones_cart_v1';

// Helper para notificaciones UI (Popup "Agregado al carrito")
class LastAddedItem {
  final Product product;
  final int quantity;

  LastAddedItem(this.product, this.quantity);
}

@Riverpod(keepAlive: true)
class CartNotifier extends _$CartNotifier {
  @override
  Future<List<CartItem>> build() async {
    return _loadCartFromPrefs();
  }

  Future<List<CartItem>> _loadCartFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getStringList(_cartStorageKey);
      if (cartData == null) return [];

      return cartData
          .map((itemString) => CartItem.fromJson(jsonDecode(itemString)))
          .toList();
    } catch (e) {
      print('Error cargando carrito: $e');
      return [];
    }
  }

  Future<void> _saveCartToPrefs(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_cartStorageKey, cartData);
  }

  // --- MÉTODO PRINCIPAL ---
  // ... dentro de CartNotifier ...
  Future<void> addProductToCart(Product product, {int quantity = 1}) async {
    final currentState = state.value ?? [];
    List<CartItem> updatedList = List.from(currentState);

    final existingItemIndex = updatedList.indexWhere((item) => item.product.id == product.id);

    if (existingItemIndex != -1) {
      final existingItem = updatedList[existingItemIndex];
      updatedList[existingItemIndex] = existingItem.copyWith(quantity: existingItem.quantity + quantity);
    } else {
      updatedList.add(CartItem(product: product, quantity: quantity));
    }

    state = AsyncData(updatedList);
    await _saveCartToPrefs(updatedList);
    
    // --- ESTA LÍNEA ES LA QUE HACE APARECER EL CARTEL ---
    ref.read(lastAddedItemProvider.notifier).state = LastAddedItem(product, quantity);
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

    final existingItemIndex = updatedList.indexWhere((item) => item.product.id == productId);

    if (existingItemIndex != -1) {
      final existingItem = updatedList[existingItemIndex];
      if (existingItem.quantity > 1) {
        updatedList[existingItemIndex] = existingItem.copyWith(quantity: existingItem.quantity - 1);
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

// --- PROVIDERS AUXILIARES ---

@riverpod
int cartTotalItems(CartTotalItemsRef ref) {
  final cartAsync = ref.watch(cartNotifierProvider);
  if (!cartAsync.hasValue) return 0;
  return cartAsync.value!.fold(0, (total, item) => total + item.quantity);
}

@riverpod
double cartTotalPrice(CartTotalPriceRef ref) {
  final cartAsync = ref.watch(cartNotifierProvider);
  if (!cartAsync.hasValue) return 0.0;
  return cartAsync.value!.fold(0, (total, item) => total + item.subtotal);
}

// Control del Popup flotante
final lastAddedItemProvider = StateProvider<LastAddedItem?>((ref) => null);

// Control de la posición del ícono del carrito (para que el popup sepa dónde salir)
final cartIconLayerLinkProvider = Provider((ref) => LayerLink());

// Control de apertura/cierre del Drawer Lateral
final isCartDrawerOpenProvider = StateProvider<bool>((ref) => false);