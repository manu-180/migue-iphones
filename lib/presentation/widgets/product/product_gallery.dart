// lib/presentation/widgets/product/product_gallery.dart

import 'package:flutter/material.dart';

class ProductGallery extends StatefulWidget {
  final List<String> images;
  final bool isDesktop;

  const ProductGallery({
    super.key,
    required this.images,
    this.isDesktop = true,
  });

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  // Controlador para mover el slider programáticamente
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Función para mover la imagen
  void _jumpToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    // El setState se hace en onPageChanged, pero forzamos aquí para feedback instantáneo
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    // Si solo hay una imagen, mostramos el diseño simple
    if (widget.images.length <= 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          widget.images.first,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      );
    }

    return Column(
      children: [
        // 1. EL SLIDER PRINCIPAL
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController, // CONECTAMOS EL CONTROLADOR
                  itemCount: widget.images.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return Container(
                      color: Colors.white, // Fondo blanco para que no se vea transparente
                      child: Image.network(
                        widget.images[index],
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    );
                  },
                ),
                
                // Flechas de navegación (Solo Desktop y si corresponde)
                if (widget.isDesktop) ...[
                  if (_currentPage > 0)
                    Positioned(
                      left: 10, top: 0, bottom: 0,
                      child: Center(
                        child: _NavButton(
                          icon: Icons.arrow_back_ios_rounded, 
                          onTap: () => _jumpToPage(_currentPage - 1),
                        ),
                      ),
                    ),
                  if (_currentPage < widget.images.length - 1)
                    Positioned(
                      right: 10, top: 0, bottom: 0,
                      child: Center(
                        child: _NavButton(
                          icon: Icons.arrow_forward_ios_rounded, 
                          onTap: () => _jumpToPage(_currentPage + 1),
                        ),
                      ),
                    )
                ]
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 15),

        // 2. MINIATURAS INTERACTIVAS
        SizedBox(
          height: 70, // Altura un poco mayor para que sea cómodo
          child: Center(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true, // Se ajusta al centro
              itemCount: widget.images.length,
              separatorBuilder: (_,__) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final isSelected = _currentPage == index;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _jumpToPage(index), // Al hacer clic, mueve el slider grande
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 70,
                      height: 70,
                      padding: const EdgeInsets.all(2), // Espacio para el borde
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(
                          widget.images[index],
                          fit: BoxFit.cover,
                          // Efecto visual: opaco si no está seleccionado
                          color: isSelected ? null : Colors.white.withOpacity(0.4),
                          colorBlendMode: isSelected ? null : BlendMode.lighten,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 24, color: Colors.black87),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: const CircleBorder(),
        shadowColor: Colors.black.withOpacity(0.2),
        elevation: 3,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}