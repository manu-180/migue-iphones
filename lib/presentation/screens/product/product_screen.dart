// lib/presentation/screens/product/product_screen.dart (ACTUALIZADO)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/providers/products/products_provider.dart';
import 'package:migue_iphones/presentation/widgets/shared/custom_app_bar.dart'; 
import 'package:migue_iphones/presentation/widgets/shared/added_to_cart_dialog.dart';
// 1. IMPORTAR EL FOOTER COMPARTIDO
import 'package:migue_iphones/presentation/widgets/shared/app_footer.dart'; 

class ProductScreen extends ConsumerWidget {
  static const String name = 'product_screen';
  final String productId;

  const ProductScreen({super.key, required this.productId});

  // Formato para moneda local
  static final currencyFormatter = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsNotifierProvider);

    return Scaffold(
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (products) {
          final product = products.firstWhere(
            (p) => p.id.toString() == productId,
            orElse: () => products.first, 
          );

          // Usamos CustomScrollView para el App Bar y el contenido
          return CustomScrollView(
            slivers: [
              // 3. CORRECCIÓN: Usar TopNavigationBar (solo logo y carrito)
              const SliverToBoxAdapter(child: TopNavigationBar()),
              SliverToBoxAdapter(
                child: _ProductDetailView(product: product),
              ),
              // 2. AÑADIR EL FOOTER COMPARTIDO AL FINAL
              const SliverToBoxAdapter(child: AppFooter()),
            ],
          );
        },
      ),
    );
  }
}

class _ProductDetailView extends ConsumerWidget {
  final Product product;

  const _ProductDetailView({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200), // Límite de ancho
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 30,
            vertical: isDesktop ? 50 : 20,
          ),
          child: isDesktop
              ? _DesktopLayout(product: product)
              : _MobileLayout(product: product),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Layouts (Desktop y Móvil)
// -------------------------------------------------------------

class _DesktopLayout extends ConsumerWidget {
  final Product product;
  const _DesktopLayout({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna Izquierda: Imagen
        Expanded(
          flex: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(product.imageUrl, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 40),
        
        // Columna Derecha: Detalles y Compra
        Expanded(
          flex: 2,
          child: _ProductDetailsColumn(product: product),
        ),
      ],
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  final Product product;
  const _MobileLayout({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(product.imageUrl, fit: BoxFit.contain),
        ),
        const SizedBox(height: 30),
        _ProductDetailsColumn(product: product),
      ],
    );
  }
}

// -------------------------------------------------------------
// Columna de Detalles (Compartida)
// -------------------------------------------------------------

class _ProductDetailsColumn extends ConsumerWidget {
  final Product product;

  const _ProductDetailsColumn({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.category.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        
        Text(
          product.name,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 48,
          ),
        ),
        const SizedBox(height: 20),
        
        Text(
          ProductScreen.currencyFormatter.format(product.price),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w300,
            fontSize: 40,
          ),
        ),
        const SizedBox(height: 30),
        
        Text(
          product.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        const Divider(),
        const SizedBox(height: 30),

        // Botón de Añadir al Carrito
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              ref.read(cartNotifierProvider.notifier).addProductToCart(product);
              AddedToCartDialog.show(context, product);
            },
            icon: const Icon(Icons.shopping_bag_outlined, size: 20),
            label: const Text(
              'Añadir al Carrito',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}