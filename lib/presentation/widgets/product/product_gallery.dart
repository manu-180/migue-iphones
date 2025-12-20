// lib/presentation/widgets/product/product_gallery.dart

import 'dart:ui';
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
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _jumpToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
    );
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();
    
    if (widget.images.length <= 1) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.network(
            widget.images.first,
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      // SOLUCIÓN: Eliminamos InteractiveViewer para que no capture el scroll (ruedita)
                      return Image.network(
                        widget.images[index],
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColor.withOpacity(0.5),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Indicador de página elegante
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            color: Colors.black.withOpacity(0.05),
                            child: Text(
                              '${_currentPage + 1} / ${widget.images.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  if (widget.isDesktop) ...[
                    if (_currentPage > 0)
                      Positioned(
                        left: 20, top: 0, bottom: 0,
                        child: Center(
                          child: _GlassNavButton(
                            icon: Icons.chevron_left_rounded, 
                            onTap: () => _jumpToPage(_currentPage - 1),
                          ),
                        ),
                      ),
                    if (_currentPage < widget.images.length - 1)
                      Positioned(
                        right: 20, top: 0, bottom: 0,
                        child: Center(
                          child: _GlassNavButton(
                            icon: Icons.chevron_right_rounded, 
                            onTap: () => _jumpToPage(_currentPage + 1),
                          ),
                        ),
                      ),
                  ]
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildThumbnails(),
      ],
    );
  }

  Widget _buildThumbnails() {
    return SizedBox(
      height: 75,
      child: Center(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: widget.images.length,
          separatorBuilder: (_,__) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final isSelected = _currentPage == index;
            return GestureDetector(
              onTap: () => _jumpToPage(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: isSelected ? 80 : 70,
                height: 75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.black.withOpacity(0.05),
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ] : [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isSelected ? 1.0 : 0.6,
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GlassNavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassNavButton({required this.icon, required this.onTap});

  @override
  State<_GlassNavButton> createState() => _GlassNavButtonState();
}

class _GlassNavButtonState extends State<_GlassNavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: _isHovered ? 1.1 : 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isHovered 
                    ? Colors.white.withOpacity(0.4) 
                    : Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon, 
                  size: 26, 
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}