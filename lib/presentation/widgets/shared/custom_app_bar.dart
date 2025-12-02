// lib/presentation/widgets/shared/custom_app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/providers/sort_provider.dart';
import 'package:migue_iphones/presentation/widgets/shared/product_search_bar.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool showFilters;

  const CustomAppBar({
    super.key, 
    this.showFilters = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final double height = isDesktop ? 100.0 : 80.0;
    
    final cartItemCount = ref.watch(cartTotalItemsProvider);
    final cartLayerLink = ref.watch(cartIconLayerLinkProvider);

    return Material(
      color: Colors.white, 
      elevation: 4, 
      shadowColor: Colors.black.withOpacity(0.1),
      child: SizedBox(
        height: height, 
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 20),
          child: Row(
            children: [
              // 1. LOGO (IMAGEN)
              InkWell(
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(8),
                hoverColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  // REEMPLAZO: Usamos tu imagen en lugar del Icono+Texto
                  child: Image.asset(
                    'assets/images/migueicon.png',
                    height: 50, // Ajusta este valor si quieres el logo más grande o chico
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // 2. BUSCADOR
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: const ProductSearchBar(),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // 3. ICONOS Y FILTROS
              if (isDesktop && showFilters) ...[
                _buildSortDropdown(ref, context),
                const SizedBox(width: 20),
              ],

              // 4. CARRITO
              CompositedTransformTarget(
                link: cartLayerLink,
                child: Badge(
                  label: Text('$cartItemCount'),
                  isLabelVisible: cartItemCount > 0,
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, size: 28, color: Colors.black),
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onPressed: () {
                      ref.read(isCartDrawerOpenProvider.notifier).state = true;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown(WidgetRef ref, BuildContext context) {
    final sortOption = ref.watch(sortOptionProvider);

    return DropdownButtonHideUnderline(
      child: DropdownButton<SortOption>(
        value: sortOption,
        icon: const Icon(Icons.sort, size: 20, color: Colors.black),
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        dropdownColor: Colors.white,
        focusColor: Colors.transparent,
        autofocus: false,
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        onChanged: (SortOption? newValue) {
          if (newValue != null) {
            ref.read(sortOptionProvider.notifier).state = newValue;
          }
        },
        items: const [
          DropdownMenuItem(value: SortOption.nombreAZ, child: Text('Nombre (A-Z)')),
          DropdownMenuItem(value: SortOption.nombreZA, child: Text('Nombre (Z-A)')),
          DropdownMenuItem(value: SortOption.precioMenorMayor, child: Text('Precio: Menor a Mayor')),
          DropdownMenuItem(value: SortOption.precioMayorMenor, child: Text('Precio: Mayor a Menor')),
        ],
      ),
    );
  }
}