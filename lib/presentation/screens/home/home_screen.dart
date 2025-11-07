// lib/presentation/screens/home/home_screen.dart (ACTUALIZADO)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:migue_iphones/presentation/providers/products/products_provider.dart';
import 'package:migue_iphones/presentation/widgets/home/product_card.dart';

class HomeScreen extends StatelessWidget {
  static const String name = 'home_screen';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // Utilizamos un CustomScrollView para combinar el contenido y el footer de manera flexible
      body: CustomScrollView(
        slivers: [
          // Sección principal del catálogo
          SliverToBoxAdapter(child: _HeaderSection()),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            sliver: _MainCatalogView(),
          ),
          
          // Footer
          SliverToBoxAdapter(child: _AppFooter()),
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
      padding: const EdgeInsets.all(40),
      color: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          // App Bar Minimalista (a la izquierda el logo, a la derecha el carrito)
          const _MinimalAppBar(),
          const SizedBox(height: 50),
          
          // Título principal
          Text(
            'Catálogo de IPhones y Accesorios',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w200,
              fontSize: 48,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Los mejores productos Apple, garantizados.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.w400
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          
          // TODO: Implementar filtros y barra de búsqueda aquí
          
        ],
      ),
    );
  }
}

class _MinimalAppBar extends StatelessWidget {
  const _MinimalAppBar();

  @override
  Widget build(BuildContext context) {
    // Usamos el layout builder para manejar el responsive en web
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo o Título
            Row(
              children: [
                const Icon(FontAwesomeIcons.apple, size: 30, color: Colors.black),
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

            // Carrito (con el "globo" de cantidad - A implementar)
            const Stack(
              children: [
                Icon(Icons.shopping_bag_outlined, size: 30),
                // TODO: Implementar el globo con el número de artículos
                Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(
                    Icons.circle,
                    color: Color(0xFF007AFF), // Apple Blue
                    size: 14,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MainCatalogView extends ConsumerWidget {
  const _MainCatalogView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observar el estado de los productos (AsyncValue<List<Product>>)
    final productsState = ref.watch(filteredProductsProvider);
    
    // El tamaño de la pantalla para calcular cuántas columnas mostrar
    final size = MediaQuery.of(context).size;

    // 2. Manejo de estado: Loading, Error, Data
    return productsState.when(
      data: (products) {
        if (products.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Text('No hay productos disponibles en este momento.'),
            ),
          );
        }

        // Diseño de Cuadrícula (adaptable en web)
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            // Número de columnas basado en el ancho de la pantalla
            crossAxisCount: (size.width / 350).floor().clamp(1, 4),
            mainAxisSpacing: 30.0,
            crossAxisSpacing: 30.0,
            childAspectRatio: 0.7, // Proporción de la tarjeta (ancho/alto)
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = products[index];
              return ProductCard(product: product);
            },
            childCount: products.length,
          ),
        );
      },
      // Estado de Carga
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      ),
      // Estado de Error
      error: (error, stack) {
        print('Error de carga: $error');
        return SliverToBoxAdapter(
          child: Center(
            child: Text('Error al cargar el catálogo: $error'),
          ),
        );
      },
    );
  }
}


class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white70,
    );

    return Container(
      padding: const EdgeInsets.all(30.0),
      color: Colors.black, // Footer en negro para contraste Apple-style
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTACTO',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white30),
          const SizedBox(height: 10),

          // Correo Electrónico
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.envelope, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text('geimul@gmail.com', style: textStyle),
            ],
          ),
          const SizedBox(height: 5),

          // WhatsApp
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text('+54 9 11 3139-0974', style: textStyle),
            ],
          ),
          const SizedBox(height: 5),

          // Instagram
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.instagram, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text('@miguenavarrook', style: textStyle),
            ],
          ),
          
          const SizedBox(height: 20),
          Center(
            child: Text(
              '© ${DateTime.now().year} Migue IPhones. Todos los derechos reservados.',
              style: textStyle?.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}