// lib/presentation/widgets/cart/cart_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Importar GoRouter
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/widgets/cart/cart_components.dart';

class CartDrawerView extends ConsumerStatefulWidget {
  const CartDrawerView({super.key});

  @override
  ConsumerState<CartDrawerView> createState() => _CartDrawerViewState();
}

class _CartDrawerViewState extends ConsumerState<CartDrawerView> {
  // Nodo de foco para atrapar la navegación del teclado dentro del Drawer
  final FocusScopeNode _drawerFocusNode = FocusScopeNode();

  @override
  void dispose() {
    _drawerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartNotifierProvider);
    final totalPrice = ref.watch(cartTotalPriceProvider);

    return Material(
      color: Colors.white,
      elevation: 16,
      // FocusScope atrapa el foco aquí dentro
      child: FocusScope(
        node: _drawerFocusNode,
        autofocus: true, // Solicita el foco apenas se construye
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
              // Contenido
              Expanded(
                child: cartAsync.when(
                  data: (cartItems) {
                    if (cartItems.isEmpty) {
                      return EmptyCartView(
                        // CAMBIO: Cierra el drawer Y navega a la raíz explícitamente
                        onContinueShopping: () {
                           ref.read(isCartDrawerOpenProvider.notifier).state = false;
                           context.go('/'); 
                        },
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
                                // CAMBIO: showNotification: false para evitar popup al sumar
                                onIncrement: () => ref.read(cartNotifierProvider.notifier).addProductToCart(item.product, showNotification: false),
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
      ),
    );
  }
}