// lib/presentation/widgets/shared/no_search_results.dart

import 'package:flutter/material.dart';

class NoSearchResults extends StatelessWidget {
  final String query;

  const NoSearchResults({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.grey.shade800;
    final subTextColor = isDark ? Colors.white38 : Colors.grey.shade500;

    return Center(
      child: Container(
        // Ancho máximo para que no se estire demasiado en pantallas grandes
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          // Sombra suave y difusa (Estilo "Card profesional")
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono de Lupa tachada o Caja vacía
            Icon(
              Icons.search_off_rounded, 
              size: 80, 
              color: Colors.black54,
            ),
            const SizedBox(height: 20),
            
            // Título
            Text(
              "Sin resultados",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            
            // Subtítulo con el término buscado
            Text.rich(
              TextSpan(
                text: "No encontramos coincidencias para ",
                style: TextStyle(fontSize: 16, color: subTextColor, height: 1.5),
                children: [
                  if (query.isNotEmpty)
                    TextSpan(
                      text: '"$query"',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  const TextSpan(text: ".\nIntenta verificar la ortografía o usar otros términos."),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}