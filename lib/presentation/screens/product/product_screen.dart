// lib/presentation/screens/product/product_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/providers/products/products_provider.dart';
import 'package:migue_iphones/presentation/widgets/shared/app_footer.dart'; 
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (products) {
          final product = products.firstWhere(
            (p) => p.id.toString() == productId,
            orElse: () => products.first, 
          );

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _ProductDetailView(product: product),
              ),
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
        constraints: const BoxConstraints(maxWidth: 1300), 
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 50 : 20,
            vertical: isDesktop ? 60 : 20,
          ),
          child: isDesktop
              ? _DesktopLayout(product: product)
              : _MobileLayout(product: product),
        ),
      ),
    );
  }
}

class _DesktopLayout extends ConsumerWidget {
  final Product product;
  const _DesktopLayout({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // SOLUCIÓN: Agregado WidgetRef
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: SizedBox(
            height: 600, // Altura fija necesaria para la galería en slivers
            child: ProductGallery(
              images: product.images,
              isDesktop: true,
            ),
          ),
        ),
        const SizedBox(width: 80),
        Expanded(
          flex: 4,
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: screenWidth * 1.1,
          child: ProductGallery(
            images: product.images,
            isDesktop: false,
          ),
        ),
        const SizedBox(height: 40),
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                product.category.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text("En Stock", style: theme.textTheme.labelSmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        
        Text(
          product.name,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 48,
            color: const Color(0xFF1D1D1F),
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 24),
        
        if (hasDiscount) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatter.format(product.finalPrice),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 42, color: Colors.black, letterSpacing: -1),
              ),
              const SizedBox(width: 12),
              Text(
                formatter.format(product.price),
                style: TextStyle(fontSize: 22, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFFF3B30), borderRadius: BorderRadius.circular(100)),
            child: Text('AHORRÁ ${product.discount}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ] else ...[
          Text(
            formatter.format(product.price),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 42, color: Colors.black, letterSpacing: -1),
          ),
        ],

        const SizedBox(height: 32),
        Text(
          product.description,
          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 19, color: Colors.grey.shade700, height: 1.6),
        ),
        
        const SizedBox(height: 48),
        _AddToCartButton(onPressed: () {
          ref.read(cartNotifierProvider.notifier).addProductToCart(product);
        }),
        
        const SizedBox(height: 24),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text("Compra 100% segura", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

class _AddToCartButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _AddToCartButton({required this.onPressed});

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isPressed = true),
      onExit: (_) => setState(() => isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100), // Acelerado para respuesta instantánea
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(isPressed ? 1.02 : 1.0),
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0071E3),
              foregroundColor: Colors.white,
              elevation: isPressed ? 20 : 0,
              shadowColor: const Color(0xFF0071E3).withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: widget.onPressed,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_shopping_cart_rounded, size: 24),
                const SizedBox(width: 12),
                Text('Añadir al Carrito', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}