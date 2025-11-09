// lib/presentation/widgets/shared/added_to_cart_dialog.dart (CORREGIDO)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/presentation/screens/cart/cart_screen.dart';

class AddedToCartDialog extends StatelessWidget {
  final Product product;

  const AddedToCartDialog({
    super.key,
    required this.product,
  });

  // Función estática para mostrar el diálogo
  static void show(BuildContext context, Product product) {
    showDialog(
      context: context,
      barrierDismissible: false, // El usuario debe presionar un botón
      builder: (context) => AddedToCartDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final formatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 2,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Animación Lottie
            SizedBox(
              height: 120,
              child: Lottie.asset(
                'assets/animations/carritoconfirmado.json',
                // CORRECCIÓN: 'repeat' se establece en 'true' para que se repita.
                repeat: true, 
              ),
            ),
            const SizedBox(height: 16),

            // 2. Título
            Text(
              '¡Añadido al carrito!',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 3. Detalle del producto
            _ProductDetailCard(product: product, formatter: formatter),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // 4. Botones de Acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón "Seguir comprando" (cierra el modal)
                TextButton(
                  onPressed: () {
                    context.pop(); // Cierra el diálogo
                  },
                  child: Text(
                    'Seguir comprando',
                    style: TextStyle(color: textTheme.bodySmall?.color),
                  ),
                ),

                // Botón "Ir al carrito" (cierra y navega)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    context.pop(); // Cierra el diálogo
                    context.pushNamed(CartScreen.name); // Navega al carrito
                  },
                  child: const Text('Ir al carrito'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget interno para mostrar la tarjeta del producto añadido
class _ProductDetailCard extends StatelessWidget {
  const _ProductDetailCard({
    required this.product,
    required this.formatter,
  });

  final Product product;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // Gris claro
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Imagen
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          // Detalles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(product.price),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}