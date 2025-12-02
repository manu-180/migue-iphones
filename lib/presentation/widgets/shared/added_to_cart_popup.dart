// lib/presentation/widgets/shared/added_to_cart_popup.dart

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';

class AddedToCartPopup extends ConsumerWidget {
  final Product product;
  final int quantity;

  const AddedToCartPopup({
    super.key, 
    required this.product,
    this.quantity = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);

    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;

    // Precios
    final totalOriginal = product.price * quantity;
    final totalFinal = product.finalPrice * quantity;
    final hasDiscount = product.discount > 0;

    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: 350,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                    spreadRadius: -5,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Header (Lottie + Título)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Lottie.asset(
                          'assets/animations/carritoconfirmado.json',
                          repeat: true,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.check_circle, color: Colors.green, size: 40),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          '¡Agregado al carrito!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  // 2. Detalle del producto
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            product.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quantity > 1 ? '$quantity x ${product.name}' : product.name,
                                style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              
                              // PRECIOS
                              if (hasDiscount)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatter.format(totalOriginal),
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      formatter.format(totalFinal),
                                      style: const TextStyle( 
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Colors.black87, // DESCUENTO EN NEGRO
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  formatter.format(totalFinal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Colors.black87, // PRECIO NORMAL EN NEGRO
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                      
                  const SizedBox(height: 20),
                  
                  // 3. Botón "Ver Carrito"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        ref.read(lastAddedItemProvider.notifier).state = null;
                        ref.read(isCartDrawerOpenProvider.notifier).state = true;
                      },
                      child: const Text('Ver Carrito'),
                    ),
                  )
                ],
              ),
            ),

            // El "Piquito" (Triángulo) superior
            Positioned(
              top: -10,
              right: 25,
              child: CustomPaint(
                size: const Size(20, 10),
                painter: _TrianglePainter(color: backgroundColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}