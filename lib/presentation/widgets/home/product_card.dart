// lib/presentation/widgets/home/product_card.dart (ACTUALIZADO CON HOVER)

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Importar para el cursor
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:intl/intl.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/screens/product/product_screen.dart';
import 'package:migue_iphones/presentation/widgets/shared/added_to_cart_dialog.dart';

class ProductCard extends ConsumerStatefulWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _isHovering = false;
  
  final formatter = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      
      child: GestureDetector(
        onTap: () {
          context.pushNamed(
            ProductScreen.name,
            pathParameters: {'id': widget.product.id.toString()},
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(15),
            
            // --- CORRECCIÓN DE SOMBRA ---
            boxShadow: [
              BoxShadow(
                // 1. Opacidad más oscura al hacer hover
                color: Colors.black.withOpacity(_isHovering ? 0.3 : 0.08), 
                // 2. Desenfoque (blur) más grande
                blurRadius: _isHovering ? 25 : 5, 
                // 3. Desplazamiento (offset) más notorio
                offset: Offset(0, _isHovering ? 12 : 2), 
              ),
            ],
          ),
          
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Imagen del Producto
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(
                    widget.product.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator.adaptive(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
                    },
                  ),
                ),
              ),
              
              // 2. Detalles del Producto
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del Producto
                    Text(
                      widget.product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Precio
                    Text(
                      formatter.format(widget.product.price),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Botón de Añadir al Carrito
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(double.infinity, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () {
                          ref.read(cartNotifierProvider.notifier).addProductToCart(widget.product);
                          AddedToCartDialog.show(context, widget.product);
                        },
                        icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                        label: const Text('Añadir al Carrito', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}