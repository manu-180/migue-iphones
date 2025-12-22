// lib/presentation/widgets/product/product_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/screens/product/product_screen.dart';

class ProductCard extends ConsumerStatefulWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _isHovering = false;
  final formatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final hasDiscount = widget.product.discount > 0;
    final theme = Theme.of(context);
    const borderRadiusValue = 20.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () => context.pushNamed(ProductScreen.name, pathParameters: {'id': widget.product.id.toString()}),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadiusValue),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(_isHovering ? 0.3 : 0.05),
                blurRadius: _isHovering ? 40 : 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(borderRadiusValue),
            child: Container(
              color: Colors.white,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadiusValue),
                  border: Border.all(
                    color: _isHovering ? theme.primaryColor.withOpacity(0.6) : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  // CORRECCIÓN: Usamos stretch para ocupar ancho completo
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- 1. IMAGEN FLEXIBLE ---
                    // Usamos Expanded en lugar de AspectRatio. 
                    // La imagen tomará el espacio que sobre, asegurando que el contenido de abajo siempre entre.
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand, // Asegura que la imagen llene el Expanded
                        children: [
                          PositionPoint(isHovering: _isHovering, imageUrl: widget.product.imageUrl),
                          if (hasDiscount)
                            Positioned(
                              top: 10, left: 10,
                              child: _DiscountBadge(discount: widget.product.discount),
                            ),
                        ],
                      ),
                    ),

                    // --- 2. INFO (Footer Fijo) ---
                    // Reduje el padding ligeramente para dar más aire en pantallas chicas
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Ocupa lo mínimo necesario
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black, letterSpacing: -0.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                formatter.format(hasDiscount ? widget.product.finalPrice : widget.product.price),
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 15),
                              ),
                              if (hasDiscount)
                                Text(
                                  formatter.format(widget.product.price),
                                  style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey.shade400,
                                      fontSize: 10),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _AddButton(
                            isHovered: _isHovering,
                            onPressed: () => ref.read(cartNotifierProvider.notifier).addProductToCart(widget.product),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PositionPoint extends StatelessWidget {
  const PositionPoint({super.key, required this.isHovering, required this.imageUrl});
  final bool isHovering;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
      transform: Matrix4.identity()..scale(isHovering ? 1.05 : 1.0), 
      transformAlignment: Alignment.center,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        // Eliminamos width/height infinitos aquí porque el padre (Stack->Expanded) ya restringe
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final int discount;
  const _DiscountBadge({required this.discount});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF3B30), Color(0xFFFF2D55)]),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text('$discount% OFF',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9)),
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool isHovered;
  final VoidCallback onPressed;
  const _AddButton({required this.isHovered, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      height: 38, // Reduje 2px más para asegurar fit
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: isHovered
            ? LinearGradient(
                colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)])
            : null,
        color: isHovered ? null : const Color(0xFFF5F5F7),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_shopping_cart_rounded, size: 14, color: isHovered ? Colors.white : Colors.black87),
                    const SizedBox(width: 6),
                    Text('Añadir al carrito',
                        style: TextStyle(
                            color: isHovered ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)), // Bajé 1pt la fuente
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}