// lib/presentation/widgets/shared/added_to_cart_popup.dart

import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';

class AddedToCartPopup extends ConsumerStatefulWidget {
  final Product product;
  final int quantity;

  const AddedToCartPopup({
    super.key, 
    required this.product,
    this.quantity = 1,
  });

  @override
  ConsumerState<AddedToCartPopup> createState() => _AddedToCartPopupState();
}

class _AddedToCartPopupState extends ConsumerState<AddedToCartPopup> {
  bool _isExiting = false;

  void _handleClose({bool openCart = false}) async {
    if (!mounted) return;
    setState(() => _isExiting = true);
    
    // Sincronizado con la duración de FadeOutUp
    await Future.delayed(const Duration(milliseconds: 500)); 
    
    if (!mounted) return;
    ref.read(lastAddedItemProvider.notifier).state = null;
    if (openCart) ref.read(isCartDrawerOpenProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);
    
    final totalFinal = widget.product.finalPrice * widget.quantity;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1D1D1F);

    Widget body = SizedBox(
      width: 350,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28), 
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.15), 
              blurRadius: 40, 
              offset: const Offset(0, 15),
              spreadRadius: -8
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header estilizado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 45, 
                    height: 45,
                    child: Lottie.asset(
                      'assets/animations/carritoconfirmado.json',
                      repeat: false,
                      errorBuilder: (_, __, ___) => const Icon(Icons.check_circle, color: Colors.green, size: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '¡Agregado con éxito!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900, 
                      color: titleColor,
                      letterSpacing: -0.5
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 2. Info Producto (Card Interna)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.product.imageUrl, 
                      width: 55, 
                      height: 55, 
                      fit: BoxFit.cover
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name, 
                          style: TextStyle(
                            fontWeight: FontWeight.w800, 
                            color: titleColor, 
                            fontSize: 13,
                            letterSpacing: -0.2
                          ), 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.quantity} unidad${widget.quantity > 1 ? 'es' : ''} • ${formatter.format(totalFinal)}', 
                          style: TextStyle(
                            color: titleColor.withOpacity(0.5), 
                            fontSize: 12,
                            fontWeight: FontWeight.w600
                          )
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 3. Botón de Acción EPIC
            _EpicButton(
              onPressed: () => _handleClose(openCart: true), 
              color: theme.colorScheme.primary
            ),
          ],
        ),
      ),
    );

    return _isExiting 
      ? FadeOutUp(duration: const Duration(milliseconds: 500), from: 20, child: body)
      : FadeInDown(duration: const Duration(milliseconds: 500), from: 20, child: body);
  }
}

class _EpicButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;
  
  const _EpicButton({required this.onPressed, required this.color});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, 
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [color, color.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35), 
            blurRadius: 18, 
            offset: const Offset(0, 8),
            spreadRadius: -2
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'REVISAR CARRITO', 
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.w900, 
                    fontSize: 13,
                    letterSpacing: 1.1 // Más aire para un look premium
                  )
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.6), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}