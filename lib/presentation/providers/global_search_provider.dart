import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider simple para comunicar el input del AppBar hacia la pantalla de Tracking
final trackingSearchQueryProvider = StateProvider<String>((ref) => '');