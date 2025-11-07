// lib/presentation/widgets/home/product_card.dart (ACTUALIZADO)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importar
import 'package:migue_iphones/domain/models/product.dart';
import 'package:intl/intl.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart'; // Importar

class ProductCard extends ConsumerStatefulWidget { // 1. Cambiar a ConsumerStatefulWidget
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState(); // 2. Cambiar a ConsumerState
}

class _ProductCardState extends ConsumerState<ProductCard> { // 3. Cambiar a ConsumerState
  bool _isHovering = false;
  
  // Formato para mostrar el precio en moneda local (Argentina - ARS)
  final formatter = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    // Escucha el evento del mouse
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      
      // La tarjeta se envuelve en un GestureDetector para la acción de click
      child: GestureDetector(
        onTap: () {
          // TODO: Implementar navegación a la pantalla de detalle del producto
          print('Clic en ${widget.product.name}');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          // La elevación cambia al hacer hover
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface, // Gris claro Apple
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovering ? 0.2 : 0.08),
                blurRadius: _isHovering ? 15 : 5,
                offset: Offset(0, _isHovering ? 8 : 2),
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
                      // Placeholder o shimmer durante la carga de la imagen
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
                        color: Theme.of(context).colorScheme.primary, // Apple Blue
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Botón de Añadir al Carrito (temporal)
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, // Botón negro como Apple
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(double.infinity, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () {
                          // 4. USAR EL NOTIFIER PARA AÑADIR EL PRODUCTO
                          ref.read(cartNotifierProvider.notifier).addProductToCart(widget.product);
                          
                          // Feedback visual al usuario
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${widget.product.name} añadido al carrito.'),
                              duration: const Duration(seconds: 1),
                            )
                          );
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