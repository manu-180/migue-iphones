// lib/presentation/widgets/shared/app_footer.dart (SIN IMAGEN)

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
              // --- Sección Principal (2 columnas) ---
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

// Layout para pantallas anchas (2 Columnas)
class _DesktopFooterLayout extends StatelessWidget {
  final TextStyle? textStyle;
  final Future<void> Function(String) launchURL;
  
  const _DesktopFooterLayout({this.textStyle, required this.launchURL});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      // 1. ELIMINADA LA COLUMNA DE IMAGEN
      children: [
        // Columna 1: Contacto
        Expanded(
          flex: 1, // Ajustado a 1
          child: _ContactInfoColumn(textStyle: textStyle, launchURL: launchURL),
        ),
        // Columna 2: Navegación
        Expanded(
          flex: 1, // Ajustado a 1
          child: _NavigationColumn(textStyle: textStyle),
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
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        // 2. IMAGEN Y SIZEDBOX ELIMINADOS
        _ContactInfoColumn(textStyle: textStyle, launchURL: launchURL),
        // Columna de Navegación eliminada en móvil (como se solicitó)
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
          icon: FontAwesomeIcons.store, 
          text: 'Catálogo', 
          textStyle: textStyle,
          onTap: () => context.go('/'), // Vuelve al Home
        ),
        const SizedBox(height: 10),
        _ClickableNavigationItem(
          icon: FontAwesomeIcons.shoppingCart, 
          text: 'Mi Carrito',
          textStyle: textStyle,
          onTap: () => context.pushNamed(CartScreen.name), // Abre el carrito
        ),
      ],
    );
  }
}

// 3. Columna 3: Imagen (WIDGET ELIMINADO)


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

// Widget para un item de navegación (solo texto)
class _ClickableNavigationItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle? textStyle;
  final VoidCallback onTap;

  const _ClickableNavigationItem({
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