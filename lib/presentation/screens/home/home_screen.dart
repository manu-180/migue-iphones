import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/presentation/providers/products/products_provider.dart';
import 'package:migue_iphones/presentation/providers/search_provider.dart';
import 'package:migue_iphones/presentation/widgets/home/category_filter_bar.dart';
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
        const SliverToBoxAdapter(child: CategoryFilterBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        const _MainCatalogView(),

        // Espacio para que el footer no choque con las últimas cards
        const SliverToBoxAdapter(child: SizedBox(height: 100)),

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
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 10),
      child: Column(
        children: [
          Text(
            'Experiencia Tech Premium',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w200,
                  fontSize: 48,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Tecnología de vanguardia para conectar y disfrutar.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
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

    // --- LÓGICA DE RESPONSIVIDAD MEJORADA ---
    final width = MediaQuery.of(context).size.width;
    
    // Calculamos columnas basadas en el ancho total para tener control
    int crossAxisCount;
    double childAspectRatio;

    // Breakpoints manuales para control total sobre la altura de la card
    if (width < 450) {
      // Móvil muy pequeño (1 columna o 2 ajustadas)
      // Usamos maxCrossAxisExtent abajo, pero aquí definimos el ratio
      childAspectRatio = 0.68; 
    } else if (width < 700) {
      // Móvil grande / Tablet pequeña
      childAspectRatio = 0.65; 
    } else if (width < 1100) {
      // Tablet / Laptop pequeña
      childAspectRatio = 0.70; 
    } else {
      // Desktop (Cards más cortas porque hay más ancho)
      childAspectRatio = 0.7; 
    }

    // Configuración del Grid
    final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 280.0, // Ancho máximo ideal para legibilidad
      mainAxisSpacing: 20.0,
      crossAxisSpacing: 20.0,
      childAspectRatio: childAspectRatio, // Controla la altura (Mayor número = Card más corta)
    );

    return productsState.when(
      data: (products) {
        if (products.isEmpty) {
          return SliverToBoxAdapter(child: NoSearchResults(query: searchQuery));
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0), // Padding lateral reducido para móviles
          sliver: SliverGrid(
            gridDelegate: gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(product: products[index]),
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
      error: (error, stack) => SliverToBoxAdapter(
        child: Center(child: Text('Error: $error')),
      ),
    );
  }
}