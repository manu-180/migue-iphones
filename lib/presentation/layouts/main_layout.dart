// lib/presentation/layouts/main_layout.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/domain/models/product.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/widgets/cart/cart_drawer.dart';
import 'package:migue_iphones/presentation/widgets/shared/added_to_cart_popup.dart';
import 'package:migue_iphones/presentation/widgets/shared/custom_app_bar.dart';
import 'package:migue_iphones/presentation/widgets/shared/wpp_floating_button.dart';
import 'dart:math' as math;

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  // Parámetro para decidir si mostramos filtros en la barra
  final bool showFilters; 

  const MainLayout({
    super.key, 
    required this.child,
    this.showFilters = false, 
  });

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  Timer? _overlayTimer;
  LastAddedItem? _lastAddedItem; 

  @override
  void dispose() {
    _overlayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCartOpen = ref.watch(isCartDrawerOpenProvider);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 900;
    final drawerWidth = math.min(450.0, screenSize.width * 0.95);
    final double appBarHeight = isSmallScreen ? 80.0 : 100.0;

    // 1. Escuchar cuando se agrega un item -> MOSTRAR POPUP
    ref.listen(lastAddedItemProvider, (previous, next) {
      if (next != null) {
        _overlayTimer?.cancel();
        setState(() => _lastAddedItem = next);
        _overlayTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() => _lastAddedItem = null);
            ref.read(lastAddedItemProvider.notifier).state = null;
          }
        });
      }
    });

    // 2. NUEVO: Escuchar cuando se abre el carrito -> CERRAR POPUP
    ref.listen(isCartDrawerOpenProvider, (previous, isOpen) {
      if (isOpen == true) {
        // Si el usuario abre el carrito, matamos el popup inmediatamente
        _overlayTimer?.cancel();
        if (_lastAddedItem != null) {
          setState(() => _lastAddedItem = null);
          ref.read(lastAddedItemProvider.notifier).state = null;
        }
      }
    });

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              CustomAppBar(showFilters: widget.showFilters),
              Expanded(
                child: widget.child,
              ),
            ],
          ),
          floatingActionButton: const WhatsappFloatingButton(),
        ),

        // Capa Oscura
        if (isCartOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => ref.read(isCartDrawerOpenProvider.notifier).state = false,
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),

        // Drawer Lateral
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 0,
          bottom: 0,
          right: isCartOpen ? 0 : -drawerWidth, 
          child: SizedBox(
            width: drawerWidth,
            child: const CartDrawerView(),
          ),
        ),

        // Popup Flotante (Solo se muestra si _lastAddedItem no es nulo)
        if (_lastAddedItem != null)
          Positioned(
            top: appBarHeight - 20, 
            right: isSmallScreen ? 10 : 40,
            child: Material(
              type: MaterialType.transparency,
              child: SizedBox(
                width: 350,
                child: AddedToCartPopup(
                  product: _lastAddedItem!.product,
                  quantity: _lastAddedItem!.quantity,
                ),
              ),
            ),
          ),
      ],
    );
  }
}