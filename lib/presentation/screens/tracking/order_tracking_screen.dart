import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  List<String> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    print("🚀 INIT STATE: OrderTrackingScreen arrancó");
    _loadAndAutoSearch();
  }

  void _loadAndAutoSearch() async {
    print("📂 STORAGE: Intentando leer historial...");
    
    // 1. Cargamos el historial local
    final orders = await LocalStorageService.getOrders();
    print("📂 STORAGE: Ordenes encontradas -> ${orders.length} items: $orders");
    
    if (mounted) {
      setState(() => _recentOrders = orders);
      
      // 2. Si hay órdenes, buscamos la última automáticamente
      if (orders.isNotEmpty) {
        final lastOrder = orders.first;
        print("🤖 AUTO-SEARCH: Iniciando búsqueda automática para: $lastOrder");
        _searchController.text = lastOrder;
        _searchOrder(lastOrder);
      } else {
        print("🤷 STORAGE: No hay órdenes recientes para auto-cargar.");
      }
    }
  }

  Future<void> _searchOrder(String input) async {
    final cleanInput = input.trim();
    print("🔍 SEARCH: Input recibido: '$cleanInput'");

    if (cleanInput.isEmpty) {
      print("⚠️ SEARCH: Input vacío, cancelando.");
      return;
    }
    
    // Ocultar teclado y resetear estado visual
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { _isLoading = true; _errorMsg = null; _orderData = null; });

    try {
      final supabase = Supabase.instance.client;
      
      // --- INTELIGENCIA DE BÚSQUEDA ---
      // Detectamos si es un UUID válido (formato de base de datos)
      final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      final isUuid = uuidRegex.hasMatch(cleanInput);

      print("🧠 LOGIC: ¿Es UUID? -> $isUuid");

      Map<String, dynamic>? response;

      // ATENCIÓN: Imprimimos la query que vamos a hacer
      if (isUuid) {
        print("📡 DB QUERY: Buscando por ID (UUID)...");
        final query = supabase
            .from('orders_pulpiprint')
            .select()
            .eq('id', cleanInput)
            .maybeSingle(); // Usamos query builder para imprimir si fuera necesario, pero ejecutamos directo
        
        response = await query;
      } else {
        print("📡 DB QUERY: Buscando por Tracking Number...");
        response = await supabase
            .from('orders_pulpiprint')
            .select()
            .eq('tracking_number', cleanInput)
            .maybeSingle();
      }

      print("📨 DB RESPONSE: $response");

      if (response == null) {
        print("❌ RESULTADO: Null (No encontrado o bloqueado por RLS)");
        setState(() => _errorMsg = 'No encontramos el pedido con ese número.');
      } else {
        print("✅ RESULTADO: Datos encontrados -> ID: ${response['id']} | Status: ${response['status']}");
        setState(() => _orderData = response);
        // Guardamos esta búsqueda exitosa en el historial
        print("💾 GUARDANDO: Actualizando LocalStorage con $cleanInput");
        LocalStorageService.saveOrder(cleanInput);
      }
    } catch (e) {
      print("💥 ERROR CRÍTICO: $e");
      setState(() => _errorMsg = 'Ocurrió un error al buscar. Intenta nuevamente.');
    } finally {
      setState(() => _isLoading = false);
      print("🏁 FIN SEARCH: Loading false");
    }
  }

  void _launchCarrierLink() async {
    if (_orderData == null) return;
    final tracking = _orderData!['tracking_number'];
    final carrier = _orderData!['carrier_slug'] ?? 'correo-argentino';

    print("🔗 LINK: Intentando abrir mapa. Carrier: $carrier | Tracking: $tracking");

    if (tracking == null) return;

    Uri url;
    // Detectar carrier para armar la URL correcta
    if (carrier.toString().toLowerCase().contains('andreani')) {
      url = Uri.parse('https://www.andreani.com/#!/informacionEnvio/$tracking');
    } else {
      // Correo Argentino
      url = Uri.parse('https://www.correoargentino.com.ar/formularios/e-commerce?id=$tracking');
    }

    print("🌐 URL FINAL: $url");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("🚫 ERROR LINK: No se pudo lanzar la URL");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el mapa')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Estado de mi Pedido'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black), 
          onPressed: () => context.go('/')
        ),
        titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            
            // 1. INDICADOR DE CARGA
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: CircularProgressIndicator(color: Colors.black)),
              ),

            // 2. TARJETA DE RESULTADO
            if (!_isLoading && _orderData != null) 
              _buildStatusCard(context),

            // 3. MENSAJE DE ERROR
            if (!_isLoading && _errorMsg != null)
              Container(
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_errorMsg!, style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),

            const SizedBox(height: 30),
            
            // 4. HISTORIAL (Visible si no hay resultado activo)
            if (_recentOrders.isNotEmpty && _orderData == null) ...[
               Align(
                 alignment: Alignment.centerLeft,
                 child: Text("VISITADOS RECIENTEMENTE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 12, letterSpacing: 1))
               ),
               const SizedBox(height: 10),
               ..._recentOrders.map((o) => Card(
                 margin: const EdgeInsets.only(bottom: 8),
                 elevation: 0,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
                 child: ListTile(
                   title: Text(o, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                   leading: const Icon(Icons.history, color: Colors.black54),
                   trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                   onTap: () {
                     _searchController.text = o;
                     _searchOrder(o);
                   },
                 ),
               )),
               const SizedBox(height: 20),
            ],

            // 5. INPUT DE BÚSQUEDA
            const Divider(height: 40),
            const Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: Text("¿Buscas otro pedido?", style: TextStyle(color: Colors.grey)),
            ),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ingresa Tracking o ID de Orden',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.black)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.black),
                  onPressed: () => _searchOrder(_searchController.text),
                ),
              ),
              onSubmitted: (val) => _searchOrder(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final status = _orderData!['status'];
    final tracking = _orderData!['tracking_number'];
    final carrier = _orderData!['carrier_slug'] ?? 'Correo';
    
    // Lógica visual de pasos
    int currentStep = 0;
    if (status == 'approved') currentStep = 1;
    if (tracking != null) currentStep = 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TU COMPRA", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey, letterSpacing: 1.2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF009EE3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Text(
                  "#${_orderData!['id'].toString().substring(0,8).toUpperCase()}",
                  style: const TextStyle(color: Color(0xFF009EE3), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              )
            ],
          ),
          const SizedBox(height: 30),
          
          _buildStep(0, "Orden Recibida", "Procesando", currentStep >= 0),
          _buildConnector(currentStep >= 1),
          _buildStep(1, "Pago Confirmado", "¡Todo listo!", currentStep >= 1),
          _buildConnector(currentStep >= 2),
          _buildStep(2, "En Camino", 
            tracking != null ? "Tracking generado" : "Preparando envío", 
            currentStep >= 2, isFinal: true
          ),

          const SizedBox(height: 35),

          if (tracking != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _launchCarrierLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                icon: const FaIcon(FontAwesomeIcons.mapLocationDot, size: 18),
                label: Text("VER UBICACIÓN ($carrier)".toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            )
          else if (status == 'approved')
             Center(
               child: Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                 child: Text("Estamos generando tu etiqueta...", style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w600))
               )
             )
        ],
      ),
    );
  }

  Widget _buildStep(int step, String title, String sub, bool isActive, {bool isFinal = false}) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? Colors.black : Colors.grey.shade300)
          ),
          child: isActive ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isActive ? Colors.black : Colors.grey)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 13, color: isActive ? Colors.grey.shade600 : Colors.grey.shade400)),
          ],
        )
      ],
    );
  }

  Widget _buildConnector(bool isActive) {
    return Container(
      margin: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
      height: 25,
      width: 2,
      color: isActive ? Colors.black : Colors.grey.shade200,
    );
  }
}