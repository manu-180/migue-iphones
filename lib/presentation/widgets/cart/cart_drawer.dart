// lib/presentation/widgets/cart/cart_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/widgets/cart/cart_components.dart';

class CartDrawerView extends ConsumerWidget {
  const CartDrawerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartNotifierProvider);
    final totalPrice = ref.watch(cartTotalPriceProvider);

    // CORRECCIÓN FINAL: Material provee el contexto necesario
    return Material(
      color: Colors.white,
      elevation: 16,
      child: Container(
        width: 450, 
        height: double.infinity,
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Carrito de Compras', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(isCartDrawerOpenProvider.notifier).state = false;
                    },
                  ),
                ],
              ),
            ),
            // Contenido (Lista y Resumen)...
            Expanded(
              child: cartAsync.when(
                data: (cartItems) {
                  if (cartItems.isEmpty) {
                    return EmptyCartView(
                      onContinueShopping: () => ref.read(isCartDrawerOpenProvider.notifier).state = false,
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        ListView.builder(
                          itemCount: cartItems.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return CartItemCard(
                              item: item,
                              onIncrement: () => ref.read(cartNotifierProvider.notifier).addProductToCart(item.product),
                              onDecrement: () => ref.read(cartNotifierProvider.notifier).decrementProductQuantity(item.product.id),
                              onRemove: () => ref.read(cartNotifierProvider.notifier).removeProductFromCart(item.product.id),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        OrderSummaryCard(totalPrice: totalPrice),
                        const SizedBox(height: 50),
                      ],
                    ),
                  );
                },
                error: (err, _) => Center(child: Text('Error: $err')),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}