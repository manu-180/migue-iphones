// lib/presentation/screens/home/home_screen.dart (ACTUALIZADO CON SKELETON)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/presentation/widgets/shared/app_footer.dart'; 
import 'package:migue_iphones/presentation/providers/products/products_provider.dart';
import 'package:migue_iphones/presentation/widgets/home/product_card.dart';
import 'package:migue_iphones/presentation/widgets/shared/custom_app_bar.dart'; 
// 1. IMPORTAR EL SKELETON
import 'package:migue_iphones/presentation/widgets/home/product_card_skeleton.dart';

class HomeScreen extends StatelessWidget {
  static const String name = 'home_screen';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: CustomAppBar()), 
          SliverToBoxAdapter(child: _HeaderSection()),
          
          _MainCatalogView(),
          
          SliverToBoxAdapter(child: AppFooter()),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// WIDGETS DE LA PANTALLA PRINCIPAL
// ----------------------------------------------------------------------

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      color: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          Text(
            'Catálogo de IPhones y Accesorios',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w200,
              fontSize: 48,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Los mejores productos Apple, garantizados.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.w400
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}


class _MainCatalogView extends ConsumerWidget {
  const _MainCatalogView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(filteredProductsProvider);
    
    // Definimos la cuadrícula aquí para reutilizarla en 'data' y 'loading'
    const gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 300.0, 
      mainAxisSpacing: 30.0,
      crossAxisSpacing: 30.0,
      childAspectRatio: 0.75, 
    );

    return productsState.when(
      data: (products) {
        if (products.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              heightFactor: 5,
              child: Text('No hay productos disponibles bajo el filtro actual.'),
            ),
          );
        }

        // --- Cuadrícula con DATOS ---
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          sliver: SliverGrid(
            gridDelegate: gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return ProductCard(product: product);
              },
              childCount: products.length,
            ),
          ),
        );
      },
      // --- CORRECCIÓN: Estado de Carga con SKELETON ---
      loading: () => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        sliver: SliverGrid(
          gridDelegate: gridDelegate,
          delegate: SliverChildBuilderDelegate(
            // Mostramos 6 tarjetas skeleton de carga
            (context, index) => const ProductCardSkeleton(),
            childCount: 6, 
          ),
        ),
      ),
      // Estado de Error
      error: (error, stack) {
        print('Error de carga: $error');
        return SliverToBoxAdapter(
          child: Center(
            heightFactor: 5,
            child: Text('Error al cargar el catálogo: $error'),
          ),
        );
      },
    );
  }
}