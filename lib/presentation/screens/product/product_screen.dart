// lib/presentation/screens/product/product_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/providers/products/products_provider.dart';
import 'package:migue_iphones/presentation/widgets/shared/custom_app_bar.dart'; // Reutilizamos el App Bar

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
    // 1. Buscamos el producto en la lista de productos ya cargada
    // Esto es eficiente si el usuario viene del catálogo.
    final productsAsync = ref.watch(productsNotifierProvider);

    return Scaffold(
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (products) {
          // 2. Encontrar el producto específico usando el ID de la ruta
          final product = products.firstWhere(
            (p) => p.id.toString() == productId,
            // Fallback si no se encuentra (aunque no debería pasar si la navegación es correcta)
            orElse: () => products.first, 
          );

          // Usamos CustomScrollView para el App Bar y el contenido
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: CustomAppBar()),
              SliverToBoxAdapter(
                child: _ProductDetailView(product: product),
              ),
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
          flex: 2,
          child: Image.network(product.imageUrl, fit: BoxFit.contain),
        ),
        const SizedBox(width: 40),
        
        // Columna Derecha: Detalles y Compra
        Expanded(
          flex: 3,
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
        Image.network(product.imageUrl, fit: BoxFit.contain),
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
        // Categoría (con estilo Apple)
        Text(
          product.category.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        
        // Nombre del Producto
        Text(
          product.name,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 48,
          ),
        ),
        const SizedBox(height: 20),
        
        // Precio
        Text(
          ProductScreen.currencyFormatter.format(product.price),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w300,
            fontSize: 40,
          ),
        ),
        const SizedBox(height: 30),
        
        // Descripción
        Text(
          product.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            color: Colors.black87,
            height: 1.5, // Interlineado
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
              backgroundColor: Colors.black, // Botón negro
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              // USAR EL NOTIFIER PARA AÑADIR EL PRODUCTO
              ref.read(cartNotifierProvider.notifier).addProductToCart(product);
              
              // Feedback visual
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} añadido al carrito.'),
                  duration: const Duration(seconds: 1),
                )
              );
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