// lib/main.dart (CORREGIDO con CardThemeData)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/config/router/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ADVERTENCIA: Usaremos placeholders aquí, pero DEBES usar tus propias credenciales.
const String supabaseUrl = 'TU_URL_DE_SUPABASE';
const String supabaseAnonKey = 'TU_ANON_KEY_DE_SUPABASE_PUBLICA';

void main() async {
  // Asegura que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializar Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    // Riverpod debe envolver el widget principal
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escucha el proveedor del router para reconstruir cuando cambien las rutas
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      title: 'Migue IPhones',
      theme: _appTheme(),
    );
  }

  ThemeData _appTheme() {
    return ThemeData(
      // Estética Apple: colores neutros, tipografía limpia.
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF007AFF), // Apple Blue para acentos
        brightness: Brightness.light,
        primary: const Color(0xFF007AFF),
        secondary: const Color(0xFF5AC8FA),
        surface: const Color(0xFFF2F2F7), // Gris claro para fondos de tarjetas
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // CORRECCIÓN APLICADA: Usando CardThemeData
      cardTheme: CardThemeData( 
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black54),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
      useMaterial3: true,
    );
  }
}