// lib/presentation/widgets/shared/custom_app_bar.dart (REFACTORIZADO)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:migue_iphones/presentation/providers/products/products_provider.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/screens/cart/cart_screen.dart';

// -------------------------------------------------------------------
// WIDGET 1: La barra superior (Logo + Carrito) - REUTILIZABLE
// -------------------------------------------------------------------
class TopNavigationBar extends ConsumerWidget {
  const TopNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int cartItemCount = ref.watch(cartTotalItemsProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 20, 
        horizontal: isDesktop ? 50 : 20,
      ),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo Clickeable
          InkWell(
            onTap: () => context.go('/'), // Navega al Home
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
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
            ),
          ),

          // Carrito (Usando el widget Badge)
          Badge(
            label: Text('$cartItemCount'),
            isLabelVisible: cartItemCount > 0,
            backgroundColor: Theme.of(context).colorScheme.primary,
            textColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, size: 30), 
              onPressed: () {
                context.pushNamed(CartScreen.name);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// WIDGET 2: El App Bar completo (Barra Superior + Filtros)
// -------------------------------------------------------------------
class CustomAppBar extends ConsumerWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(productFilterNotifierProvider);
    final filterNotifier = ref.read(productFilterNotifierProvider.notifier);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 1. USA EL WIDGET REUTILIZABLE
          const TopNavigationBar(),
          
          const SizedBox(height: 20),
          
          // 2. AÑADE LOS FILTROS
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