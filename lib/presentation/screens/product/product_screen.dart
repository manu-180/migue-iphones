// lib/presentation/screens/product/product_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/providers/products/products_provider.dart';
import 'package:migue_iphones/presentation/widgets/shared/app_footer.dart'; 
// IMPORTAR LA GALERÍA
import 'package:migue_iphones/presentation/widgets/product/product_gallery.dart';

class ProductScreen extends ConsumerWidget {
  static const String name = 'product_screen';
  final String productId;

  const ProductScreen({super.key, required this.productId});

  static final currencyFormatter = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsNotifierProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (products) {
        final product = products.firstWhere(
          (p) => p.id.toString() == productId,
          orElse: () => products.first, 
        );

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _ProductDetailView(product: product),
            ),
            const SliverToBoxAdapter(child: AppFooter()),
          ],
        );
      },
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
        constraints: const BoxConstraints(maxWidth: 1200), 
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
    return SizedBox(
      height: 600, // Altura fija para el layout desktop para que la galería luzca
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COLUMNA IZQUIERDA: GALERÍA
          Expanded(
            flex: 5,
            // AQUI USAMOS EL NUEVO WIDGET
            child: ProductGallery(
              images: product.images,
              isDesktop: true,
            ),
          ),
          const SizedBox(width: 60),
          
          // COLUMNA DERECHA: DATOS
          Expanded(
            flex: 4,
            child: _ProductDetailsColumn(product: product),
          ),
        ],
      ),
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  final Product product;
  const _MobileLayout({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        SizedBox(
          height: screenWidth * 0.9, // Cuadrado casi perfecto en móvil
          // AQUI USAMOS EL NUEVO WIDGET
          child: ProductGallery(
            images: product.images,
            isDesktop: false,
          ),
        ),
        const SizedBox(height: 30),
        _ProductDetailsColumn(product: product),
      ],
    );
  }
}

class _ProductDetailsColumn extends ConsumerWidget {
  final Product product;

  const _ProductDetailsColumn({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDiscount = product.discount > 0;
    final formatter = ProductScreen.currencyFormatter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center, // Centrado vertical en desktop
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
            fontSize: 42, // Ajuste leve de tamaño
          ),
        ),
        const SizedBox(height: 20),
        
        // --- SECCIÓN DE PRECIOS ---
        if (hasDiscount) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                formatter.format(product.finalPrice),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 36,
                  color: Colors.black87
                ),
              ),
              const SizedBox(width: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                child: Text('-${product.discount}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            "Antes: ${formatter.format(product.price)}",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough),
          ),
        ] else ...[
          Text(
            formatter.format(product.price),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w300, fontSize: 40, color: Colors.black87),
          ),
        ],

        const SizedBox(height: 30),
        
        Text(
          product.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.black87, height: 1.5),
        ),
        
        const SizedBox(height: 40),
        const Divider(),
        const SizedBox(height: 40),

        // Botón
        SizedBox(
          width: double.infinity,
          height: 55, // Botón un poco más alto
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ref.read(cartNotifierProvider.notifier).addProductToCart(product);
            },
            icon: const Icon(Icons.add_shopping_cart_outlined, size: 24),
            label: const Text('Añadir al Carrito', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
      ],
    );
  }
}