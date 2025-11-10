// lib/main.dart (CORREGIDO CON DOTENV)

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importar dotenv
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/config/router/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Asegura que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Cargar las variables de entorno
  await dotenv.load(fileName: ".env");
  
  // 2. Inicializar Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
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

  // lib/main.dart (Actualización de _appTheme)

  ThemeData _appTheme() {
    // Definición de las fuentes System-UI de Apple como fallback
    const String appleFontFamily = 'SF Pro Display, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica Neue, Arial, sans-serif';
    
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
          fontFamily: appleFontFamily, // <-- Usar la familia de fuentes de Apple
        ),
      ),
      cardTheme: CardThemeData( // Usando CardThemeData
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // APLICAR LA FUENTE A TODO EL TEMA
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black54),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
      ).apply(
        fontFamily: appleFontFamily, // <-- Aplicar a todo el TextTheme
      ),
      useMaterial3: true,
    );
  }
}