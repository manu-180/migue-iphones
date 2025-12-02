// lib/presentation/widgets/home/product_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/screens/product/product_screen.dart';

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
    // ZOOM POTENCIADO: 1.2 (20% más grande)
    final matrix = Matrix4.identity()..scale(_isHovering ? 1.2 : 1.0);
    final hasDiscount = widget.product.discount > 0;

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
        // Animación de la tarjeta (sombra y elevación)
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), // La tarjeta sube rápido
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovering ? 0.2 : 0.05), 
                blurRadius: _isHovering ? 30 : 10, 
                offset: Offset(0, _isHovering ? 15 : 4),
              ),
            ],
          ),
          
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Imagen con Zoom SUAVE
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      // --- AQUÍ ESTÁ EL CAMBIO PARA LA SUAVIDAD ---
                      child: AnimatedContainer(
                        // Duración aumentada a 700ms para que sea lento y suave
                        duration: const Duration(milliseconds: 700), 
                        // Curva profesional suave (sin rebote)
                        curve: Curves.easeOutCubic, 
                        transform: matrix, 
                        transformAlignment: Alignment.center,
                        child: Image.network(
                          widget.product.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity, 
                          height: double.infinity,
                          errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ),
                      // -------------------------------------------
                    ),
                    if (hasDiscount)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          ),
                          child: Text(
                            '-${widget.product.discount}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // 2. Detalles
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // PRECIOS
                    if (hasDiscount) ...[
                      Text(
                        formatter.format(widget.product.price),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        formatter.format(widget.product.finalPrice),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          fontSize: 18,
                        ),
                      ),
                    ] else ...[
                      Text(
                        formatter.format(widget.product.price),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          fontSize: 18,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          ref.read(cartNotifierProvider.notifier).addProductToCart(widget.product);
                        },
                        child: const Text('Añadir al Carrito', style: TextStyle(fontWeight: FontWeight.bold)),
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