// lib/presentation/widgets/shared/app_footer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  // Función optimizada para WhatsApp (Prioriza App común sobre Business)
  Future<void> _openWhatsApp() async {
    const phone = "5491131390974";
    final whatsappUrl = Uri.parse("whatsapp://send?phone=$phone");
    final webUrl = Uri.parse("https://wa.me/$phone");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo lanzar $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Colors.white10, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _BrandSection(onWppTap: _openWhatsApp, onIgTap: () => _launchURL('https://www.instagram.com/mna.0974/'))),
                        Expanded(child: _FooterColumn(title: 'MI CUENTA', children: const [_NavigationLinks()])),
                        Expanded(child: _FooterColumn(title: 'CONTACTO', children: [_ContactLinks(launchURL: _launchURL, onWppTap: _openWhatsApp)])),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BrandSection(onWppTap: _openWhatsApp, onIgTap: () => _launchURL('https://www.instagram.com/mna.0974/')),
                      const SizedBox(height: 50),
                      _FooterColumn(title: 'MI CUENTA', children: const [_NavigationLinks()]),
                      const SizedBox(height: 50),
                      _FooterColumn(title: 'CONTACTO', children: [_ContactLinks(launchURL: _launchURL, onWppTap: _openWhatsApp)]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 80),
              const Divider(color: Colors.white10),
              const SizedBox(height: 30),
              _BottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandSection extends StatelessWidget {
  final VoidCallback onWppTap;
  final VoidCallback onIgTap;
  const _BrandSection({required this.onWppTap, required this.onIgTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MNL TECNO',
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 15),
        Text(
          'Expertos en tecnología Apple.\nCalidad garantizada en cada producto.',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            _SocialIcon(icon: FontAwesomeIcons.instagram, onTap: onIgTap),
            const SizedBox(width: 15),
            _SocialIcon(icon: FontAwesomeIcons.whatsapp, onTap: onWppTap),
          ],
        ),
      ],
    );
  }
}

class _NavigationLinks extends ConsumerWidget {
  const _NavigationLinks();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FooterLink(icon: Icons.local_shipping_outlined, label: 'Seguir mi envío', onTap: () => context.push('/tracking')),
        _FooterLink(icon: Icons.shopping_bag_outlined, label: 'Ver mi carrito', onTap: () => ref.read(isCartDrawerOpenProvider.notifier).state = true),
      ],
    );
  }
}

class _ContactLinks extends StatelessWidget {
  final Function(String) launchURL;
  final VoidCallback onWppTap;
  const _ContactLinks({required this.launchURL, required this.onWppTap});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FooterLink(icon: Icons.email_outlined, label: 'geimul@gmail.com', onTap: () => launchURL('mailto:geimul@gmail.com')),
        _FooterLink(icon: Icons.phone_android_outlined, label: '+54 9 11 3139-0974', onTap: onWppTap),
        _FooterLink(icon: Icons.map_outlined, label: 'Buenos Aires, Argentina', onTap: () => launchURL('https://www.google.com/maps/search/?api=1&query=Buenos+Aires+Argentina')),
      ],
    );
  }
}

// --- COMPONENTES AUXILIARES ---

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FooterColumn({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 25),
          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        ),
        ...children,
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FooterLink({required this.icon, required this.label, required this.onTap});
  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 20, color: isHovered ? Colors.white : Colors.white.withOpacity(0.4)),
              const SizedBox(width: 15),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(color: isHovered ? Colors.white : Colors.white.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.w500),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialIcon({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50, width: 50,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
          child: Center(child: FaIcon(icon, color: Colors.white.withOpacity(0.8), size: 22)),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('© ${DateTime.now().year} MNL TECNO.', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
        Text('Premium Technology Experience', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
      ],
    );
  }
}