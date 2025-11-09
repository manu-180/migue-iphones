// lib/presentation/widgets/shared/app_footer.dart (ACTUALIZADO)

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:migue_iphones/presentation/screens/cart/cart_screen.dart';
import 'package:url_launcher/url_launcher.dart'; 

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  // Función helper para lanzar URLs
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      print('No se pudo lanzar $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white70,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          color: Colors.black,
          width: double.infinity,
          child: Column(
            children: [
              // --- Sección Principal (3 columnas) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: isDesktop
                    ? _DesktopFooterLayout(textStyle: textStyle, launchURL: _launchURL)
                    : _MobileFooterLayout(textStyle: textStyle, launchURL: _launchURL),
              ),
              
              const Divider(color: Colors.white30, height: 60),

              // --- Copyright (Centrado) ---
              Center(
                child: Text(
                  '© ${DateTime.now().year} Migue IPhones. Todos los derechos reservados.',
                  style: textStyle?.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------
// LAYOUTS RESPONSIVE INTERNOS
// ---------------------------------------------------

// Layout para pantallas anchas (3 Columnas)
class _DesktopFooterLayout extends StatelessWidget {
  final TextStyle? textStyle;
  final Future<void> Function(String) launchURL;
  
  const _DesktopFooterLayout({this.textStyle, required this.launchURL});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Columna 1: Contacto
        Flexible(
          flex: 2,
          child: _ContactInfoColumn(textStyle: textStyle, launchURL: launchURL),
        ),
        // Columna 2: Navegación
        Flexible(
          flex: 2,
          child: _NavigationColumn(textStyle: textStyle),
        ),
        // Columna 3: Imagen
        Flexible(
          flex: 1,
          child: _FooterImage(),
        ),
      ],
    );
  }
}

// Layout para pantallas móviles (Apilado)
class _MobileFooterLayout extends StatelessWidget {
  final TextStyle? textStyle;
  final Future<void> Function(String) launchURL;

  const _MobileFooterLayout({this.textStyle, required this.launchURL});

  @override
  Widget build(BuildContext context) {
    return Column(
      // Alineado a la izquierda para que los títulos se vean bien
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Center(child: _FooterImage()), // Imagen sí va centrada
        const SizedBox(height: 30),
        _ContactInfoColumn(textStyle: textStyle, launchURL: launchURL),
        // Columna de Navegación eliminada en móvil (Request 4)
      ],
    );
  }
}


// ---------------------------------------------------
// WIDGETS DE CONTENIDO COMPARTIDOS
// ---------------------------------------------------

// Columna 1: Información de contacto
class _ContactInfoColumn extends StatelessWidget {
  final TextStyle? textStyle;
  final Future<void> Function(String) launchURL;

  const _ContactInfoColumn({this.textStyle, required this.launchURL});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTACTO',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 20),
        _ClickableContactItem(
          icon: FontAwesomeIcons.envelope,
          text: 'geimul@gmail.com',
          textStyle: textStyle,
          onTap: () => launchURL('mailto:geimul@gmail.com'),
        ),
        const SizedBox(height: 10),
        _ClickableContactItem(
          icon: FontAwesomeIcons.whatsapp,
          text: '+54 9 11 3139-0974',
          textStyle: textStyle,
          onTap: () => launchURL('https://wa.me/5491131390974'), 
        ),
        const SizedBox(height: 10),
        _ClickableContactItem(
          icon: FontAwesomeIcons.instagram,
          text: '@miguenavarrook',
          textStyle: textStyle,
          onTap: () => launchURL('https://instagram.com/miguenavarrook'),
        ),
      ],
    );
  }
}

// Columna 2: Navegación
class _NavigationColumn extends StatelessWidget {
  final TextStyle? textStyle;
  const _NavigationColumn({this.textStyle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NAVEGACIÓN',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 20),
        _ClickableNavigationItem(
          // Request 2: Icono añadido
          icon: FontAwesomeIcons.store, 
          // Request 1: Texto "Inicio" eliminado
          text: 'Catálogo', 
          textStyle: textStyle,
          onTap: () => context.go('/'), // Vuelve al Home
        ),
        const SizedBox(height: 10),
        _ClickableNavigationItem(
          // Request 2: Icono añadido
          icon: FontAwesomeIcons.shoppingCart, 
          text: 'Mi Carrito',
          textStyle: textStyle,
          onTap: () => context.pushNamed(CartScreen.name), // Abre el carrito
        ),
      ],
    );
  }
}

// Columna 3: Imagen
class _FooterImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Image.asset(
        'assets/images/applefooter.png',
        // Request 3: Imagen más grande
        height: 140, 
        fit: BoxFit.contain,
      ),
    );
  }
}


// ---------------------------------------------------
// Items Clickeables
// ---------------------------------------------------

// Widget para un item de contacto (con ícono)
class _ClickableContactItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle? textStyle;
  final VoidCallback onTap;

  const _ClickableContactItem({
    required this.icon,
    required this.text,
    this.textStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, 
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, color: Colors.white70, size: 16),
              const SizedBox(width: 10),
              Text(text, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para un item de navegación (AHORA CON ÍCONO)
class _ClickableNavigationItem extends StatelessWidget {
  final IconData icon; // Request 2: Icono añadido
  final String text;
  final TextStyle? textStyle;
  final VoidCallback onTap;

  const _ClickableNavigationItem({
    required this.icon, // Request 2: Icono añadido
    required this.text,
    this.textStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, 
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          // Request 2: Convertido en Row para incluir ícono
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, color: Colors.white70, size: 16),
              const SizedBox(width: 10),
              Text(text, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}