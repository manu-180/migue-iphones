import 'dart:io'; // Importante para detectar la plataforma
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsappFloatingButton extends StatefulWidget {
  const WhatsappFloatingButton({super.key});

  @override
  State<WhatsappFloatingButton> createState() => _WhatsappFloatingButtonState();
}

class _WhatsappFloatingButtonState extends State<WhatsappFloatingButton> {
  bool _isHovered = false;

  void _openWhatsapp() async {
    const phone = "5491131390974";
    
    // 1. Intentamos el esquema profundo (Deep Link) que prioriza la App instalada
    // whatsapp://send es más agresivo para abrir la app directamente.
    final whatsappUrl = Uri.parse("whatsapp://send?phone=$phone");
    final webUrl = Uri.parse("https://wa.me/$phone");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        // En móviles, esto intentará abrir la aplicación oficial
        await launchUrl(whatsappUrl);
      } else {
        // Si falla (como en Web o si no hay App), usamos el link universal
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Fallback final en caso de cualquier error
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  bool get _esWebDesktop =>
      kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    final icono = AnimatedScale(
      scale: _esWebDesktop && _isHovered ? 1.6 : 1.2, // Ajustado para que no sea tan gigante
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366), // Color oficial de WhatsApp
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: const FaIcon(
          FontAwesomeIcons.whatsapp,
          color: Colors.white,
          size: 35,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _openWhatsapp,
          child: icono,
        ),
      ),
    );
  }
}