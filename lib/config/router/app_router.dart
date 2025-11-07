// lib/config/router/app_router.dart (RESTAURADO)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Importa las pantallas
import 'package:migue_iphones/presentation/screens/home/home_screen.dart';
import 'package:migue_iphones/presentation/screens/cart/cart_screen.dart';
import 'package:migue_iphones/presentation/screens/product/product_screen.dart';

// La directiva 'part' DEBE ir después de todos los 'import'
part 'app_router.g.dart';

@Riverpod(keepAlive: true)
// Usamos el 'Ref' tipado que el generador crea.
GoRouter appRouter(AppRouterRef ref) { 
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: HomeScreen.name,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/cart',
        name: CartScreen.name,
        pageBuilder: (context, state) {
          return const MaterialPage(
            fullscreenDialog: true, 
            child: CartScreen(),
          );
        },
      ),
      // NUEVA RUTA DE DETALLE
      GoRoute(
        path: '/product/:id', // Ruta dinámica con parámetro 'id'
        name: ProductScreen.name,
        builder: (context, state) {
          // Extraemos el ID de la ruta
          final productId = state.pathParameters['id'] ?? '0'; 
          return ProductScreen(productId: productId);
        },
      ),
    ],
    // Manejo de errores 404
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('Página no encontrada: ${state.uri}'),
      ),
    ),
  );
}