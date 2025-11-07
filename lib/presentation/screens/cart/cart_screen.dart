// lib/presentation/screens/cart/cart_screen.dart (CORREGIDO)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:migue_iphones/domain/models/cart_item.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  static const String name = 'cart_screen';

  const CartScreen({super.key});
  
  // Formato para moneda local
  static final currencyFormatter = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observar el estado del carrito
    final cartItems = ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final double totalPrice = ref.watch(cartTotalPriceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito de Compras'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(), // Vuelve a la pantalla anterior
        ),
      ),
      body: cartItems.isEmpty
          ? const _EmptyCartView()
          : Column(
              children: [
                // 1. Lista de Items en el carrito
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _CartItemCard(
                        item: item,
                        onIncrement: () => cartNotifier.addProductToCart(item.product), // Reutiliza la lógica de "añadir" (que incrementa)
                        onDecrement: () => cartNotifier.decrementProductQuantity(item.product.id!),
                        onRemove: () => cartNotifier.removeProductFromCart(item.product.id!),
                      );
                    },
                  ),
                ),
                
                // 2. Resumen y Botón de Pago
                _CheckoutSummary(
                  totalPrice: totalPrice,
                  formatter: currencyFormatter,
                ),
              ],
            ),
    );
  }
}

// -------------------------------------------------------------
// Vista de Carrito Vacío
// -------------------------------------------------------------
class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'Tu carrito está vacío',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => context.go('/'), // Vuelve al catálogo
            child: const Text('Seguir comprando'),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Tarjeta de Item Individual
// -------------------------------------------------------------
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            // Imagen
            Image.network(
              item.product.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 15),
            
            // Nombre y Precio
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(CartScreen.currencyFormatter.format(item.product.price)),
                  Text(
                    'Subtotal: ${CartScreen.currencyFormatter.format(item.subtotal)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Controles de Cantidad
            Column(
              children: [
                Row(
                  children: [
                    // Decrementar
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: onDecrement,
                    ),
                    Text(
                      '${item.quantity}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    // Incrementar (con chequeo de stock)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      // Deshabilitar si la cantidad iguala el stock
                      onPressed: item.quantity < item.product.stock ? onIncrement : null,
                      color: item.quantity < item.product.stock ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                  label: const Text('Quitar', style: TextStyle(color: Colors.red, fontSize: 12)),
                  onPressed: onRemove,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Resumen de Checkout
// -------------------------------------------------------------
class _CheckoutSummary extends StatelessWidget {
  final double totalPrice;
  final NumberFormat formatter;

  const _CheckoutSummary({required this.totalPrice, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Total
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total:', style: Theme.of(context).textTheme.titleMedium),
              Text(
                formatter.format(totalPrice),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // Botón de Pago
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implementar lógica de Mercado Pago
              print('Proceder al pago (Mercado Pago)');
            },
            // CORRECCIÓN: Usamos un ícono válido
            icon: const FaIcon(FontAwesomeIcons.creditCard), 
            label: const Text('Pagar con Mercado Pago'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009EE3), // Color de Mercado Pago
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}