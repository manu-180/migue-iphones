// lib/presentation/widgets/home/product_card_skeleton.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos el widget Shimmer para el efecto de brillo
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // El fondo del shimmer
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Placeholder de la Imagen
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
              ),
            ),
            
            // 2. Placeholder de los Detalles
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Placeholder de Nombre
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  
                  // Placeholder de Precio
                  Container(
                    width: 100, // Ancho fijo para el precio
                    height: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),

                  // Placeholder de Botón
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}