import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:migue_iphones/infrastructure/services/local_storage_service.dart';
import 'package:migue_iphones/presentation/layouts/main_layout.dart';
import 'package:migue_iphones/presentation/providers/global_search_provider.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  static const name = 'order-tracking-screen';
  const OrderTrackingScreen({super.key});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _myOrders = [];
  String? _errorMsg;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistoryAndFetch();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadHistoryAndFetch() async {
    setState(() => _isLoading = true);
    
    final localIds = await LocalStorageService.getOrders();

    if (localIds.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final List<dynamic> response = await supabase
          .rpc('get_orders_batch', params: {'search_inputs': localIds});

      if (mounted) {
        setState(() {
          _myOrders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchSingleOrder(String input) async {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      final supabase = Supabase.instance.client;
      
      final List<dynamic> response = await supabase
          .rpc('get_order_for_tracking', params: {'search_input': cleanInput});

      if (response.isEmpty) {
        setState(() => _errorMsg = 'No encontramos pedidos con: $cleanInput');
      } else {
        int addedCount = 0;
        
        setState(() {
          for (var item in response) {
            final exists = _myOrders.any((o) => o['id'] == item['id']);
            if (!exists) {
              _myOrders.insert(0, item);
              addedCount++;
            }
          }
        });

        if (addedCount > 0) {
          await LocalStorageService.saveOrder(cleanInput);
        } else {
           setState(() => _errorMsg = 'Esos pedidos ya están en tu lista.');
        }
      }
    } catch (e) {
      setState(() => _errorMsg = 'Error al buscar: ${e.toString().split('\n').first}'); 
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(trackingSearchQueryProvider, (previous, next) {
      if (next.isNotEmpty) {
        _searchSingleOrder(next);
        ref.read(trackingSearchQueryProvider.notifier).state = ''; 
      }
    });

    return MainLayout(
      child: Container(
        color: const Color(0xFFF5F7FA),
        width: double.infinity,
        child: Column(
          children: [
            
            // 1. HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              color: Colors.white,
              child: Column(
                children: [
                  const Text("Mis Pedidos", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text("Historial de compras y seguimiento", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                  
                  if (_errorMsg != null)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFECACA))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 10),
                          Text(_errorMsg!, style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // 2. LISTA CON SCROLLBAR VISIBLE
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : _myOrders.isEmpty 
                    ? _buildEmptyState()
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        thickness: 8,
                        radius: const Radius.circular(10),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                          itemCount: _myOrders.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 20),
                          itemBuilder: (context, index) {
                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 850),
                                child: _OrderCard(orderData: _myOrders[index]),
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0,10))]),
            child: Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text("Aún no tienes pedidos registrados", style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text("Tus compras aparecerán aquí automáticamente.", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}

// --- TARJETA DE ORDEN REDISEÑADA ---

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const _OrderCard({required this.orderData});

 void _launchCarrierLink(BuildContext context) async {
    final tracking = orderData['tracking_number'];
    final carrier = orderData['carrier_slug'] ?? 'Correo';

    if (tracking == null) return;

    Uri url;
    if (carrier.toString().toLowerCase().contains('andreani')) {
      url = Uri.parse('https://www.andreani.com/#!/informacionEnvio/$tracking');
    } else {
      url = Uri.parse('https://envia.com/rastreo?label=$tracking&cntry_code=ar');
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el mapa')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = orderData['status'];
    final tracking = orderData['tracking_number'];
    final carrier = orderData['carrier_slug'] ?? 'Logística';
    final idShort = orderData['id'].toString().substring(0,8).toUpperCase();
    
    // --- LÓGICA DE RECUPERACIÓN DE DATOS E IMAGEN ---
    final items = orderData['order_items'] as List<dynamic>?;
    String title = "Compra MNL Tecno";
    String? imageUrl; // Variable para guardar la URL

    if (items != null && items.isNotEmpty) {
      final firstItem = items[0];
      // Intentamos obtener el título
      title = firstItem['title'] ?? firstItem['name'] ?? 'Producto';
      if (items.length > 1) title += " (+${items.length - 1} más)";
      
      // Intentamos obtener la imagen buscando las claves más comunes
      // Se adapta a 'imageUrl' (modelo Dart) o 'image_url' (snake_case DB)
      imageUrl = firstItem['imageUrl'] ?? firstItem['image_url'] ?? firstItem['image'];
    }
    
    int currentStep = 0;
    if (status == 'approved') currentStep = 1;
    if (tracking != null) currentStep = 2;

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- IMAGEN DEL PRODUCTO (Reemplaza al Icono de Bolsa) ---
              Container(
                width: 60, height: 60, // Un poco más grande para mejor visibilidad
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(12), 
                  border: Border.all(color: Colors.grey.shade200)
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // Si existe URL, mostramos la imagen. Si no, fallback al icono.
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.shopping_bag_outlined, color: Colors.grey);
                          },
                        )
                      : const Icon(Icons.shopping_bag_outlined, color: Colors.black54),
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text("ID: #$idShort", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5)),
                  ],
                ),
              ),
              if (tracking != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade100)),
                  child: Text("En camino", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                )
            ],
          ),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Divider(height: 1)),
          
          // Timeline
          _buildStep(0, "Orden Recibida", "Procesamos tu pedido", currentStep >= 0),
          _buildConnector(currentStep >= 1),
          _buildStep(1, "Pago Confirmado", "Pago exitoso", currentStep >= 1),
          _buildConnector(currentStep >= 2),
          _buildStep(2, tracking != null ? "En Camino ($carrier)" : "Preparando Envío", 
            tracking != null ? "Tracking: $tracking" : "Generando etiqueta...", 
            currentStep >= 2, isFinal: true
          ),

          if (tracking != null) ...[
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _launchCarrierLink(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const FaIcon(FontAwesomeIcons.mapLocationDot, size: 16),
                label: const Text("SEGUIR ENVÍO", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildStep(int step, String title, String subtitle, bool isActive, {bool isFinal = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: isActive ? Colors.black : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isActive ? Colors.black : Colors.grey.shade300, width: 2)
              ),
              child: isActive ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(
                fontSize: 15, 
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.black : Colors.grey.shade400
              )),
              if (subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildConnector(bool isActive) {
    return Container(
      margin: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      height: 30,
      width: 2,
      color: isActive ? Colors.black : Colors.grey.shade200,
    );
  }
}