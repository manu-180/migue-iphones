// lib/presentation/widgets/home/category_filter_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/presentation/providers/products/products_provider.dart';

class CategoryFilterBar extends ConsumerWidget {
  const CategoryFilterBar({super.key});

  // Lista de categorías que quieres mostrar
  final List<String> categories = const ['Todos', 'iPhones', 'Accesorios', 'Fundas'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Wrap(
        spacing: 30, // Espacio entre items
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          
          return InkWell(
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = category;
            },
            borderRadius: BorderRadius.circular(20),
            hoverColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                // Si está seleccionado, le damos un fondo muy sutil o solo texto negrita
                border: isSelected 
                    ? Border(bottom: BorderSide(color: Colors.black, width: 2)) 
                    : const Border(bottom: BorderSide(color: Colors.transparent, width: 2)),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w400,
                  color: isSelected ? Colors.black : Colors.grey.shade600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}