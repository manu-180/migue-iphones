// lib/presentation/providers/sort_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SortOption {
  nombreAZ,
  nombreZA,
  precioMenorMayor,
  precioMayorMenor,
}

// Provider que guarda la opción seleccionada actualmente
final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.nombreAZ);