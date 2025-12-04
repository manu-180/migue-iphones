// lib/presentation/screens/tracking/order_tracking_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Importamos el servicio que creamos antes
import 'package:migue_iphones/infrastructure/services/local_storage_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  static const name = 'order-tracking-screen';
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _orderData;
  String? _errorMsg;
  
  // Variable para el historial
  List<String> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _loadHistory(); // Cargar historial al entrar
  }

  // Cargar lista de shared_preferences
  void _loadHistory() async {
    final orders = await LocalStorageService.getOrders();
    if (mounted) {
      setState(() => _recentOrders = orders);
    }
  }

  Future<void> _searchOrder() async {
    final input = _searchController.text.trim();
    if (input.isEmpty) return;

    setState(() { _isLoading = true; _errorMsg = null; _orderData = null; });

    try {
      final supabase = Supabase.instance.client;
      
      // Buscamos por tracking_number O por ID
      final response = await supabase
          .from('orders_pulpiprint')
          .select()
          .or('tracking_number.eq.$input,id.eq.$input')
          .maybeSingle();

      if (response == null) {
        setState(() => _errorMsg = 'No encontramos ninguna orden con ese número.');
      } else {
        setState(() => _orderData = response);
        // Guardamos esta búsqueda exitosa en el historial también
        LocalStorageService.saveOrder(response['id']);
      }
    } catch (e) {
      setState(() => _errorMsg = 'Formato inválido o orden no encontrada.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _launchCarrierTracking() async {
    if (_orderData == null) return;
    
    final tracking = _orderData!['tracking_number'];
    final carrier = _orderData!['carrier_slug'] ?? 'correo-argentino'; // Default si es null
    
    if (tracking == null) return;

    Uri url;
    // Detectar carrier para armar la URL correcta
    if (carrier.toString().toLowerCase().contains('andreani')) {
      url = Uri.parse('https://www.andreani.com/#!/informacionEnvio/$tracking');
    } else {
      // Correo Argentino
      url = Uri.parse('https://www.correoargentino.com.ar/formularios/e-commerce?id=$tracking');
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el mapa')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de Envío'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. CAJA DE BÚSQUEDA
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Rastrear mi pedido", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Ingresa tu número de seguimiento o el ID de tu orden.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Ej: TN1234... o ID de Orden',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchOrder,
                        ),
                      ),
                      onSubmitted: (_) => _searchOrder(),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _searchOrder,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text("BUSCAR"),
                      ),
                    ),
                    if (_errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 2. HISTORIAL DE BÚSQUEDAS (Solo se ve si no hay un resultado activo)
            if (_recentOrders.isNotEmpty && _orderData == null) ...[
              const Text("Mis últimas compras", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              // Mapeamos la lista de IDs a Widgets
              ..._recentOrders.map((id) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.local_mall_outlined, color: Colors.black87),
                  title: Text("Orden #${id.length > 8 ? id.substring(0, 8).toUpperCase() : id}", 
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(id, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {
                    _searchController.text = id;
                    _searchOrder(); // Autocompletar y buscar
                  },
                ),
              )),
            ],

            // 3. RESULTADOS DE LA ORDEN
            if (_orderData != null) ...[
              _buildStatusCard(context),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final status = _orderData!['status'];
    final tracking = _orderData!['tracking_number'];
    final carrier = _orderData!['carrier_slug'] ?? 'Transportista';
    
    int currentStep = 0;
    if (status == 'approved') currentStep = 1;
    if (tracking != null) currentStep = 2;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Orden #${_orderData!['id'].toString().substring(0,8).toUpperCase()}", 
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'approved' ? Colors.green.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text(status == 'approved' ? 'PAGADO' : 'PENDIENTE', 
                                style: TextStyle(color: status == 'approved' ? Colors.green.shade800 : Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ],
              ),
              const Divider(height: 30),
              
              _buildStep(0, "Orden Recibida", "Tu pedido ha sido registrado.", currentStep >= 0),
              _buildTimelineConnector(currentStep >= 1),
              _buildStep(1, "Pago Acreditado", "El pago se procesó correctamente.", currentStep >= 1),
              _buildTimelineConnector(currentStep >= 2),
              _buildStep(2, "Enviado", 
                  tracking != null ? "Tracking: $tracking" : "Estamos preparando tu paquete.", 
                  currentStep >= 2, 
                  isLink: tracking != null
              ),

              const SizedBox(height: 30),

              if (tracking != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _launchCarrierTracking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009EE3), 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    icon: const FaIcon(FontAwesomeIcons.truckFast, size: 18),
                    label: Text("Seguir envío en $carrier"),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(int stepIndex, String title, String subtitle, bool isActive, {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: isActive ? Colors.black : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: isActive ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 13, color: isLink ? Colors.blue : Colors.grey.shade600, fontWeight: isLink ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTimelineConnector(bool isActive) {
    return Container(
      margin: const EdgeInsets.only(left: 11),
      height: 30,
      width: 2,
      color: isActive ? Colors.black : Colors.grey.shade300,
    );
  }
}