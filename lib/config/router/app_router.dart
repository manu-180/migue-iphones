// lib/config/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migue_iphones/presentation/layouts/main_layout.dart';
import 'package:migue_iphones/presentation/screens/checkout/checkout_screen.dart';
import 'package:migue_iphones/presentation/screens/checkout/payment_status_screen.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:migue_iphones/presentation/screens/home/home_screen.dart';
import 'package:migue_iphones/presentation/screens/cart/cart_screen.dart';
import 'package:migue_iphones/presentation/screens/product/product_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // 1. HOME - AQUÍ ACTIVAMOS LOS FILTROS
      GoRoute(
        path: '/',
        name: HomeScreen.name,
        pageBuilder: (context, state) {
          return const NoTransitionPage(
            child: MainLayout(
              showFilters: true, // <--- ÚNICA PANTALLA CON FILTROS
              child: HomeScreen(),
            ),
          );
        },
      ),

      // 2. PRODUCTO DETALLE - SIN FILTROS (Por defecto false)
      GoRoute(
        path: '/product/:id',
        name: ProductScreen.name,
        pageBuilder: (context, state) {
          final productId = state.pathParameters['id'] ?? '0';
          return NoTransitionPage(
            child: MainLayout(
              // showFilters es false por defecto, así que no se verán aquí
              child: ProductScreen(productId: productId),
            ),
          );
        },
      ),

      // 3. CARRITO
      GoRoute(
        path: '/cart',
        name: CartScreen.name,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        name: CheckoutScreen.name,
        builder: (context, state) {
          final prefId = state.uri.queryParameters['preferenceId'] ?? '';
          final orderId = state.uri.queryParameters['orderId'] ?? '';
          return CheckoutScreen(preferenceId: prefId, orderId: orderId);
        },
      ),
      GoRoute(
        path: '/success',
        builder: (context, state) => PaymentStatusScreen(
          status: 'success',
          externalReference: state.uri.queryParameters['external_reference'],
        ),
      ),
      GoRoute(
        path: '/failure',
        builder: (context, state) => PaymentStatusScreen(
          status: 'failure',
          externalReference: state.uri.queryParameters['external_reference'],
        ),
      ),
      GoRoute(
        path: '/pending',
        builder: (context, state) => PaymentStatusScreen(
          status: 'pending',
          externalReference: state.uri.queryParameters['external_reference'],
        ),
      ),
    ],
    
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Página no encontrada: ${state.uri}')),
    ),
  );
}