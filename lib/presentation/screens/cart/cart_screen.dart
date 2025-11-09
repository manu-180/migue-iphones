// lib/presentation/screens/cart/cart_screen.dart (Resumen Limpio v2)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:migue_iphones/domain/models/cart_item.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/widgets/shared/app_footer.dart';

class CartScreen extends ConsumerWidget {
  static const String name = 'cart_screen';

  const CartScreen({super.key});
  
  static final currencyFormatter = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartNotifierProvider);
    final double totalPrice = ref.watch(cartTotalPriceProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),

          cartAsync.when(
            data: (cartItems) {
              if (cartItems.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyCartView(),
                );
              }
              
              return _buildCartSlivers(context, cartItems, totalPrice, currencyFormatter);
            },
            error: (err, stack) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Error al cargar el carrito: $err'),
              ),
            ),
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
          ),
          
          if (cartAsync.hasValue && cartAsync.value!.isNotEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: false,
              child: Container(color: Colors.white), 
            ),

          const SliverToBoxAdapter(
            child: AppFooter(),
          ),
        ],
      ),
    );
  }

  // WIDGET HELPER PARA EL SLIVERAPPBAR
  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0, 
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      scrolledUnderElevation: 2.0,

      leading: IconButton(
        icon: const Icon(Icons.store_outlined, size: 24),
        tooltip: 'Volver al catálogo',
        onPressed: () => context.pop(),
      ),
      
      title: Text(
        'Mi Carrito',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
    );
  }

  // Helper para construir los slivers cuando HAY items
  Widget _buildCartSlivers(BuildContext context, List<CartItem> cartItems, double totalPrice, NumberFormat formatter) {
    return SliverPadding(
      padding: const EdgeInsets.all(20.0),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          // Vista Escritorio (2 columnas)
          if (constraints.crossAxisExtent > 800) {
            return SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _CartItemsList(cartItems: cartItems),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: _OrderSummaryCard(
                      totalPrice: totalPrice,
                      formatter: formatter,
                    ),
                  ),
                ],
              ),
            );
          } 
          // Vista Móvil (1 columna)
          else {
            return SliverList(
              delegate: SliverChildListDelegate([
                _CartItemsList(cartItems: cartItems),
                const SizedBox(height: 20),
                _OrderSummaryCard(
                  totalPrice: totalPrice,
                  formatter: formatter,
                ),
              ]),
            );
          }
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// VISTA: Lista de Items
// -------------------------------------------------------------
class _CartItemsList extends ConsumerWidget {
  final List<CartItem> cartItems;
  const _CartItemsList({required this.cartItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    
    return ListView.builder(
      itemCount: cartItems.length,
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(), 
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return _CartItemCard(
          item: item,
          onIncrement: () => cartNotifier.addProductToCart(item.product),
          onDecrement: () => cartNotifier.decrementProductQuantity(item.product.id!),
          onRemove: () => cartNotifier.removeProductFromCart(item.product.id!),
        );
      },
    );
  }
}


// -------------------------------------------------------------
// VISTA: Resumen de Orden (SIMPLIFICADO V2)
// -------------------------------------------------------------
class _OrderSummaryCard extends StatelessWidget {
  final double totalPrice;
  final NumberFormat formatter;

  const _OrderSummaryCard({required this.totalPrice, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Resumen del Pedido',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 30),
            
            // --- LÓGICA CORREGIDA ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  formatter.format(totalPrice),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            // 2. Eliminado el texto de impuestos y el SizedBox
            
            const SizedBox(height: 20), // Espacio antes del botón
            ElevatedButton.icon(
              onPressed: () {
                print('Proceder al pago (Mercado Pago)');
              },
              icon: const FaIcon(FontAwesomeIcons.creditCard), 
              label: const Text('Pagar con Mercado Pago'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009EE3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// -------------------------------------------------------------
// VISTA: Tarjeta de Item Individual
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
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.product.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 15),
            
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
            
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: onDecrement,
                    ),
                    Text(
                      '${item.quantity}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
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
// VISTA: Carrito Vacío (Con Card)
// -------------------------------------------------------------
class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Card(
          elevation: 4, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
                const SizedBox(height: 20),
                Text(
                  'Tu carrito está vacío',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () => context.go('/'), // Vuelve al catálogo
                  child: const Text('Seguir comprando'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}