import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/presentation/providers/products/products_provider.dart';
import 'package:migue_iphones/presentation/providers/search_provider.dart';
import 'package:migue_iphones/presentation/providers/global_search_provider.dart'; // Asegúrate de importar el provider nuevo

class ProductSearchBar extends ConsumerStatefulWidget {
  const ProductSearchBar({super.key});

  @override
  ConsumerState<ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends ConsumerState<ProductSearchBar> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _removeOverlay();
      } else {
        // Solo mostramos overlay si NO estamos en tracking
        if (_controller.text.isNotEmpty && !_isTrackingRoute(context)) {
          _showOverlay();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  // Helper para detectar si estamos en la pantalla de envíos
  bool _isTrackingRoute(BuildContext context) {
    // GoRouterState.of(context).uri da la ruta actual
    // Verificamos si contiene '/tracking'
    try {
      final uri = GoRouterState.of(context).uri.toString();
      return uri.contains('/tracking');
    } catch (e) {
      return false;
    }
  }

  void _onSearchChanged(String value) {
    if (_isTrackingRoute(context)) {
      // MODO TRACKING: No usamos el search provider de productos ni overlay
      _removeOverlay();
    } else {
      // MODO PRODUCTOS (Normal)
      ref.read(searchQueryProvider.notifier).state = value;
      if (value.isEmpty) {
        _removeOverlay();
      } else {
        if (_overlayEntry == null) {
          _showOverlay();
        } else {
          _overlayEntry?.markNeedsBuild();
        }
      }
    }
  }

  void _onSubmitted(String value) {
    if (_isTrackingRoute(context)) {
      // Disparamos la búsqueda en el provider de Tracking
      ref.read(trackingSearchQueryProvider.notifier).state = value;
      _focusNode.unfocus();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    if (_isTrackingRoute(context)) return; // Doble check de seguridad

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width, 
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 8), 
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: _SearchSuggestionsList(
              query: _controller.text,
              onProductSelected: (product) {
                _removeOverlay();
                _focusNode.unfocus();
                context.push('/product/${product.id}');
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    // Determinamos el modo actual para cambiar la UI
    final isTracking = _isTrackingRoute(context);
    final hintText = isTracking 
        ? 'Buscar Tracking, ID o Email...' 
        : 'Buscar productos...';

    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        height: 40,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          onSubmitted: _onSubmitted, // Importante para Tracking
          textInputAction: isTracking ? TextInputAction.search : TextInputAction.done,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(
              isTracking ? Icons.local_shipping : Icons.search, 
              color: Colors.grey, 
              size: 20
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                    onPressed: () {
                      _controller.clear();
                      _onSearchChanged('');
                      _focusNode.unfocus();
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          ),
        ),
      ),
    );
  }
}

// ... (La clase _SearchSuggestionsList queda igual, no necesita cambios)
class _SearchSuggestionsList extends ConsumerWidget {
  final String query;
  final Function(Product) onProductSelected;

  const _SearchSuggestionsList({required this.query, required this.onProductSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsNotifierProvider);
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

    return productsAsync.when(
      data: (products) {
        final matches = products.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).take(5).toList();

        if (matches.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No se encontraron coincidencias', style: TextStyle(color: Colors.grey, fontSize: 13)),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: matches.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final product = matches[index];
            return InkWell(
              onTap: () => onProductSelected(product),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(product.imageUrl, width: 40, height: 40, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          Text(formatter.format(product.price), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}