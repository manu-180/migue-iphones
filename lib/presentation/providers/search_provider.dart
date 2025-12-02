// lib/presentation/providers/search_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Este provider mantiene el texto actual de la búsqueda accesible para TODA la app.
final searchQueryProvider = StateProvider<String>((ref) => '');