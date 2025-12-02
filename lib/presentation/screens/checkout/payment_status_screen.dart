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
      // IMPORTANTE: Aquí traemos order_items desde la tabla directamente
      final response = await supabase
          .from('orders_pulpiprint')
          .select() // Trae todo, incluyendo la columna JSONB order_items
          .eq(searchColumn, widget.paymentId!)
          .maybeSingle();

      if (response != null) {
        _orderDetails = response;
        if (response['status'] == 'approved') {
          if (mounted) setState(() => _currentStatus = 'approved');
        }
      }

      if (widget.status == 'approved' && _orderDetails != null && _orderDetails!['status'] != 'approved' && _isUuid) {
         await supabase
          .from('orders_pulpiprint')
          .update({'status': 'approved'})
          .eq('id', widget.paymentId!);
         
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
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("¡Pago confirmado exitosamente!"), 
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  )
                );
              }
            }
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final appBarHeight = isMobile ? 70.0 : 100.0;

    if (_isLoading) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(appBarHeight),
          child: const CustomAppBar(),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text('Verificando estado del pago...', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    return PaymentStatusScreen(
      status: _currentStatus,
      orderId: widget.paymentId,
      orderData: _orderDetails,
    );
  }
}

class PaymentStatusScreen extends StatelessWidget {
  final String status;
  final String? orderId;
  final Map<String, dynamic>? orderData;
  
  const PaymentStatusScreen({
    super.key, 
    required this.status,
    this.orderId,
    this.orderData,
  });

  void _launchWhatsApp() async {
    final phone = '5491168930600'; // TU NÚMERO REAL
    final text = Uri.encodeComponent('Hola PulpiPrint! Hice la compra #${orderId ?? ""}. ¿Podemos coordinar?');
    final url = Uri.parse('https://wa.me/$phone?text=$text');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _launchCorreoTracking() async {
    final url = Uri.parse('https://www.correoargentino.com.ar/formularios/e-commerce');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final isMobile = MediaQuery.of(context).size.width < 900;
    final appBarHeight = isMobile ? 70.0 : 100.0;
    
    final bool isSuccess = status == 'success' || status == 'approved';
    final bool isPending = status == 'pending' || status == 'in_process';
    
    Color stateColor;
    String title;
    String message;
    Widget heroWidget;
    String buttonText;

    if (isSuccess) {
      stateColor = Colors.green.shade600;
      title = '¡Pago Aprobado!';
      message = 'Tu orden ha sido procesada correctamente. Te enviamos el comprobante a tu email.';
      buttonText = 'Volver al Inicio';
      heroWidget = const _DelayedLottie(
        asset: 'assets/animations/compraconfirmada.json',
        delay: Duration(milliseconds: 500),
      );
    } else if (isPending) {
      stateColor = Colors.orange.shade700;
      title = 'Pago en Proceso';
      message = 'Estamos esperando la confirmación. Te avisaremos apenas se acredite.';
      buttonText = 'Volver al Inicio';
      heroWidget = Lottie.asset(
        'assets/animations/esperandopago.json',
        height: 250, 
        repeat: true, 
      );
    } else {
      stateColor = Colors.red.shade700;
      title = 'No se pudo procesar';
      message = 'La operación fue rechazada por el medio de pago.';
      buttonText = 'Intentar Nuevamente';
      heroWidget = const _DelayedLottie(
        asset: 'assets/animations/pagorechazado.json',
        delay: Duration(milliseconds: 500),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: const CustomAppBar(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Card(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    heroWidget,
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: stateColor,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        height: 1.5,
                        fontSize: 16,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 20),

                    if (isSuccess && orderData != null)
                      _buildOrderSummary(context, orderData!, colorScheme)
                    else if (!isSuccess && !isPending)
                      _buildFailureTips(context),

                    const SizedBox(height: 30),

                    if (orderId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                        ),
                        child: InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: orderId!));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID copiado')));
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 18, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ID Ref: ${orderId!.length > 8 ? orderId!.substring(0, 8) + '...' : orderId}', 
                                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.copy_rounded, size: 16, color: colorScheme.primary),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),

                    // BOTONES DE ACCIÓN
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // BOTÓN DE CONTACTO (Siempre visible)
                        ElevatedButton.icon(
                          onPressed: _launchWhatsApp,
                          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                          label: const Text("Contactar por WhatsApp"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        // BOTÓN VOLVER
                        OutlinedButton(
                          onPressed: () => context.go('/'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: colorScheme.primary),
                          ),
                          child: Text(buttonText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, Map<String, dynamic> data, ColorScheme colors) {
    // Leer items de la orden (si existen)
    final items = List.from(data['order_items'] ?? []); 
    final totalAmount = data['total_amount'] ?? 0;
    final deliveryType = data['delivery_type'];
    final address = data['shipping_address'];
    
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Resumen de compra', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${items.length} productos', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        
        if (items.isEmpty)
           const Padding(
             padding: EdgeInsets.symmetric(vertical: 10),
             child: Text("Detalle no disponible", style: TextStyle(color: Colors.grey)),
           )
        else
          ...items.take(2).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.shopping_bag, size: 20, color: colors.primary.withOpacity(0.7)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] ?? 'Producto', 
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), 
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (item['selected_size'] != null)
                         Text(item['selected_size'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Text('x${item['quantity']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          )),
        
        if (items.length > 2)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('+ ${items.length - 2} más...', style: TextStyle(fontSize: 12, color: colors.primary)),
          ),
        
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: DottedDivider(), 
        ),
        
        // INFO DE ENTREGA
        if (deliveryType == 'envio' && address != null) ...[
           Container(
             width: double.infinity,
             padding: const EdgeInsets.all(15),
             margin: const EdgeInsets.only(bottom: 15),
             decoration: BoxDecoration(
               color: Colors.blue.withOpacity(0.05),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: Colors.blue.withOpacity(0.2)),
             ),
             child: Column(
               children: [
                 const Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.local_shipping, size: 18, color: Colors.blue),
                     SizedBox(width: 8),
                     Text("Envío a Domicilio", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                   ],
                 ),
                 const SizedBox(height: 8),
                 Text("${address['address'] ?? ''}, ${address['city'] ?? ''}", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                 const SizedBox(height: 12),
                 OutlinedButton.icon(
                   onPressed: _launchCorreoTracking,
                   icon: const Icon(Icons.search, size: 16),
                   label: const Text("Seguimiento Correo Arg."),
                   style: OutlinedButton.styleFrom(
                     minimumSize: const Size(0, 35),
                     side: const BorderSide(color: Colors.blue),
                     foregroundColor: Colors.blue,
                   ),
                 )
               ],
             ),
           )
        ] else ...[
           // MODO RETIRO
           Container(
             width: double.infinity,
             padding: const EdgeInsets.all(15),
             margin: const EdgeInsets.only(bottom: 15),
             decoration: BoxDecoration(
               color: Colors.green.withOpacity(0.05),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: Colors.green.withOpacity(0.2)),
             ),
             child: Column(
               children: [
                 const Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.store, size: 18, color: Colors.green),
                     SizedBox(width: 8),
                     Text("Retiro en Local", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                   ],
                 ),
                 const SizedBox(height: 8),
                 Text("¡Todo listo! Coordina el retiro abajo.", style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
               ],
             ),
           )
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Pagado', style: TextStyle(fontSize: 16)),
            Text(currencyFormat.format(totalAmount), 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: colors.primary)),
          ],
        ),
      ],
    );
  }

  Widget _buildFailureTips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sugerencias:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 8),
          _buildTipRow(Icons.credit_card_off, "Revisa si tienes saldo suficiente."),
          _buildTipRow(Icons.lock_outline, "Verifica si tu banco necesita autorización."),
          _buildTipRow(Icons.edit, "Controla que el código de seguridad (CVC) sea correcto."),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.red.shade300),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }
}

class DottedDivider extends StatelessWidget {
  const DottedDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade300),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }
}

class _DelayedLottie extends StatefulWidget {
  final String asset;
  final Duration delay;

  const _DelayedLottie({required this.asset, required this.delay});

  @override
  State<_DelayedLottie> createState() => _DelayedLottieState();
}

class _DelayedLottieState extends State<_DelayedLottie> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    
    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await Future.delayed(widget.delay);
        if (mounted) {
          _controller.forward(from: 0);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      widget.asset,
      controller: _controller,
      height: 250,
      onLoaded: (composition) {
        _controller.duration = composition.duration;
        _controller.forward(); 
      },
    );
  }
}