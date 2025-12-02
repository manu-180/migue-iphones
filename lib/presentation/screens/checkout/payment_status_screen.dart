// lib/screens/payment_status_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:migue_iphones/presentation/widgets/shared/custom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// --- LOGICA DE ESTADO (State) ---

class SuccessPaymentScreen extends ConsumerStatefulWidget {
  final String? paymentId;
  final String? status;

  const SuccessPaymentScreen({
    super.key,
    required this.paymentId,
    required this.status,
  });

  @override
  ConsumerState<SuccessPaymentScreen> createState() => _SuccessPaymentScreenState();
}

class _SuccessPaymentScreenState extends ConsumerState<SuccessPaymentScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _orderDetails;
  RealtimeChannel? _orderChannel;
  String _currentStatus = 'unknown';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status ?? 'unknown';
    _fetchOrderDataAndSubscribe();
  }

  @override
  void dispose() {
    if (_orderChannel != null) {
      Supabase.instance.client.removeChannel(_orderChannel!);
    }
    super.dispose();
  }

  bool get _isUuid => widget.paymentId != null && widget.paymentId!.contains('-');

  Future<void> _fetchOrderDataAndSubscribe() async {
    if (widget.paymentId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final supabase = Supabase.instance.client;
    final searchColumn = _isUuid ? 'id' : 'mp_payment_id';

    try {
      final response = await supabase
          .from('orders_pulpiprint')
          .select()
          .eq(searchColumn, widget.paymentId!)
          .maybeSingle();

      if (response != null) {
        _orderDetails = response;
        if (response['status'] == 'approved') {
          if (mounted) setState(() => _currentStatus = 'approved');
        }
      }

      // Auto-fix status if frontend says approved but DB says pending
      if (widget.status == 'approved' &&
          _orderDetails != null &&
          _orderDetails!['status'] != 'approved' &&
          _isUuid) {
        await supabase
            .from('orders_pulpiprint')
            .update({'status': 'approved'}).eq('id', widget.paymentId!);
        if (mounted) setState(() => _currentStatus = 'approved');
      }

      if (_currentStatus != 'approved' && _currentStatus != 'success') {
        _subscribeToOrderUpdates();
      }
    } catch (e) {
      debugPrint('Error al recuperar orden: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToOrderUpdates() {
    final supabase = Supabase.instance.client;
    final paymentId = widget.paymentId.toString();
    final searchColumn = _isUuid ? 'id' : 'mp_payment_id';

    _orderChannel = supabase
        .channel('public:orders_pulpiprint:$paymentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders_pulpiprint',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: searchColumn,
            value: paymentId,
          ),
          callback: (payload) {
            if (payload.newRecord['status'] == 'approved') {
              if (mounted) {
                setState(() {
                  _currentStatus = 'approved';
                  _orderDetails = {...?_orderDetails, ...payload.newRecord};
                });
                if (_orderChannel != null) supabase.removeChannel(_orderChannel!);
              }
            }
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return _PaymentStatusUI(
      status: _currentStatus,
      orderId: widget.paymentId,
      orderData: _orderDetails,
    );
  }
}

// --- UI REFACTOREADA Y MEJORADA ---

class _PaymentStatusUI extends StatelessWidget {
  final String status;
  final String? orderId;
  final Map<String, dynamic>? orderData;

  const _PaymentStatusUI({
    required this.status,
    this.orderId,
    this.orderData,
  });

  bool get isSuccess => status == 'success' || status == 'approved';
  bool get isPending => status == 'pending' || status == 'in_process';

  void _launchWhatsApp() async {
    const phone = '5491168930600';
    final text = Uri.encodeComponent(
        'Hola PulpiPrint! Hice la compra #${orderId ?? ""}. ¿Me ayudan?');
    final url = Uri.parse('https://wa.me/$phone?text=$text');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    // Configuración de Tema
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isSuccess
        ? const Color(0xFFE8F5E9) // Verde muy claro
        : (isPending ? const Color(0xFFFFF3E0) : const Color(0xFFFFEBEE)); // Naranja/Rojo claro
    
    final accentColor = isSuccess
        ? const Color(0xFF00C853)
        : (isPending ? const Color(0xFFFF9800) : const Color(0xFFD32F2F));

    final lottieAsset = isSuccess
        ? 'assets/animations/compraconfirmada.json'
        : (isPending
            ? 'assets/animations/esperandopago.json'
            : 'assets/animations/pagorechazado.json');

    final title = isSuccess
        ? '¡Pago Exitoso!'
        : (isPending ? 'Procesando Pago' : 'Pago Rechazado');

    final message = isSuccess
        ? 'Tu orden fue recibida correctamente.\nTe enviamos el comprobante por email.'
        : (isPending
            ? 'Estamos confirmando la transacción con tu banco.'
            : 'Algo salió mal con el método de pago seleccionado.');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : bgColor,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Animación Principal
              SizedBox(
                height: 180,
                child: Lottie.asset(lottieAsset, repeat: isPending),
              ),
              const SizedBox(height: 20),
              
              // Título Principal
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // TICKET CARD
              _TicketCard(
                orderId: orderId,
                orderData: orderData,
                accentColor: accentColor,
                isSuccess: isSuccess,
              ),

              const SizedBox(height: 30),

              // BOTONES DE ACCIÓN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text("Volver a la Tienda", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
              TextButton.icon(
                onPressed: _launchWhatsApp,
                icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                label: const Text("Necesito ayuda con mi pedido"),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.white60 : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET DEL TICKET (Diseño Avanzado) ---

class _TicketCard extends StatelessWidget {
  final String? orderId;
  final Map<String, dynamic>? orderData;
  final Color accentColor;
  final bool isSuccess;

  const _TicketCard({
    required this.orderId,
    required this.orderData,
    required this.accentColor,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

    final items = List.from(orderData?['order_items'] ?? []);
    final total = orderData?['total_amount'] ?? 0;
    final shipping = orderData?['shipping_address'];
    
    // Formateo del ID
    final displayId = orderId != null && orderId!.length > 8 
        ? orderId!.substring(0, 8).toUpperCase() 
        : (orderId ?? "---");

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header del Ticket
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ORDEN #$displayId", 
                        style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: accentColor, 
                            letterSpacing: 1
                        )),
                    const SizedBox(height: 4),
                    Text(DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.copy, size: 20, color: accentColor),
                  onPressed: () {
                    if (orderId != null) {
                      Clipboard.setData(ClipboardData(text: orderId!));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ID copiado al portapapeles')));
                    }
                  },
                )
              ],
            ),
          ),

          // Cuerpo del Ticket
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (items.isNotEmpty) ...[
                  ...items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("x${item['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['title'], 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (item['selected_size'] != null)
                                Text(item['selected_size'], 
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (items.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text("+ ${items.length - 3} productos más...", 
                          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                    ),
                  const Divider(height: 30),
                ],

                // Dirección de envío simplificada
                if (shipping != null && shipping['street_name'] != null) ...[
                   Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${shipping['street_name']}, ${shipping['zip_code']}",
                          style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                   ),
                   const SizedBox(height: 20),
                ],

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("TOTAL PAGADO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    Text(currencyFormat.format(total), 
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: isDark ? Colors.white : Colors.black)),
                  ],
                ),
              ],
            ),
          ),
          
          // Decoración "ZigZag" o Borde inferior (Simulado visualmente)
          Container(
             height: 6,
             decoration: BoxDecoration(
               color: accentColor,
               borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
             ),
          ),
        ],
      ),
    );
  }
}