// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/presentation/providers/products/products_provider.dart';
import 'package:migue_iphones/presentation/providers/search_provider.dart';
import 'package:migue_iphones/presentation/widgets/home/category_filter_bar.dart'; // IMPORTAR NUEVO WIDGET
import 'package:migue_iphones/presentation/widgets/home/product_card.dart';
import 'package:migue_iphones/presentation/widgets/home/product_card_skeleton.dart';
import 'package:migue_iphones/presentation/widgets/shared/app_footer.dart'; 
import 'package:migue_iphones/presentation/widgets/shared/no_search_results.dart';

class HomeScreen extends StatelessWidget {
  static const String name = 'home_screen';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _HeaderSection()),
        
        // --- AQUÍ INSERTAMOS LA BARRA DE CATEGORÍAS ---
        const SliverToBoxAdapter(child: CategoryFilterBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)), 
        // ----------------------------------------------

        const _MainCatalogView(),
        const SliverToBoxAdapter(child: AppFooter()),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 10), // Reduje el padding inferior
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
    final searchQuery = ref.watch(searchQueryProvider);
    
    const gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 300.0, 
      mainAxisSpacing: 30.0,
      crossAxisSpacing: 30.0,
      childAspectRatio: 0.75, 
    );

    return productsState.when(
      data: (products) {
        if (products.isEmpty) {
          return SliverToBoxAdapter(
            child: NoSearchResults(query: searchQuery),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
      loading: () => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        sliver: SliverGrid(
          gridDelegate: gridDelegate,
          delegate: SliverChildBuilderDelegate(
            (context, index) => const ProductCardSkeleton(),
            childCount: 6, 
          ),
        ),
      ),
      error: (error, stack) {
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