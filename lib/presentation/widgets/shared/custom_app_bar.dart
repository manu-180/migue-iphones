// lib/presentation/widgets/shared/custom_app_bar.dart (ACTUALIZADO)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart'; // IMPORTAR GO_ROUTER
import 'package:migue_iphones/presentation/providers/products/products_provider.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/screens/cart/cart_screen.dart'; // IMPORTAR PANTALLA

class CustomAppBar extends ConsumerWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Obtener el filtro actual y el notifier
    final currentFilter = ref.watch(productFilterNotifierProvider);
    final filterNotifier = ref.read(productFilterNotifierProvider.notifier);
    
    // 2. Obtener el conteo de artículos en el carrito
    final int cartItemCount = ref.watch(cartTotalItemsProvider);
    
    // 3. Obtener el ancho de la pantalla para manejo responsivo
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 20, 
        horizontal: isDesktop ? 50 : 20,
      ),
      color: Colors.white,
      child: Column(
        children: [
          // Sección superior: Logo y Carrito
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo/Título
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.apple, size: 30, color: Colors.black),
                  const SizedBox(width: 10),
                  Text(
                    'Migue IPhones',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),

              // Carrito
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, size: 30),
                    onPressed: () {
                      // NAVEGAR A LA PANTALLA DEL CARRITO
                      context.pushNamed(CartScreen.name);
                    },
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary, // Apple Blue
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$cartItemCount',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Sección de filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: isDesktop 
                  ? MainAxisAlignment.center 
                  : MainAxisAlignment.start,
              children: ProductFilter.values.map((filter) {
                final isSelected = currentFilter == filter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextButton(
                    onPressed: () => filterNotifier.setFilter(filter),
                    child: Text(
                      filter.displayValue,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                        color: isSelected ? Colors.black : Colors.black54,
                        decoration: isSelected ? TextDecoration.underline : TextDecoration.none,
                        decorationColor: Colors.black,
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}