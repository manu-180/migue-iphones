// lib/presentation/widgets/cart/cart_components.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:migue_iphones/domain/models/cart_item.dart';
import 'package:migue_iphones/domain/models/shipping_models.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/providers/shipping_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Formatter global
final currencyFormatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);

// --- 1. TARJETA DE ITEM DEL CARRITO (ASUMIDO CORRECTO) ---
class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = item.product.discount > 0;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.product.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(width: 70, height: 70, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // LÓGICA DE PRECIOS
                  if (hasDiscount) ...[
                    // Precio Viejo (Tachado)
                    Text(
                      currencyFormatter.format(item.product.price),
                      style: const TextStyle(
                        fontSize: 12, 
                        color: Colors.grey, 
                        decoration: TextDecoration.lineThrough
                      ),
                    ),
                    // Precio Nuevo + Badge
                    Row(
                      children: [
                        Text(
                          currencyFormatter.format(item.product.finalPrice),
                          style: const TextStyle( 
                            fontWeight: FontWeight.w600, 
                            color: Colors.black87, 
                            fontSize: 13
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4)
                          ),
                          child: Text(
                            '-${item.product.discount}%',
                            style: TextStyle(
                              fontSize: 10, 
                              color: Colors.red.shade700, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        )
                      ],
                    ),
                  ] else ...[
                    // Precio Normal (NEGRO)
                    Text(
                      currencyFormatter.format(item.product.price), 
                      style: const TextStyle(fontSize: 13, color: Colors.black87)
                    ),
                  ],

                  const SizedBox(height: 4),
                  Text(
                    'Subtotal: ${currencyFormatter.format(item.subtotal)}',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            
            // Botones (+ -)
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: onDecrement,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: onIncrement,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onRemove,
                  child: const Text('Quitar', style: TextStyle(color: Colors.red, fontSize: 11)),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. VISTA DE CARRITO VACÍO ---
class EmptyCartView extends StatelessWidget {
  final VoidCallback? onContinueShopping;
  const EmptyCartView({super.key, this.onContinueShopping});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('Tu carrito está vacío', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: onContinueShopping ?? () => context.go('/'),
            child: const Text('Seguir comprando'),
          ),
        ],
      ),
    );
  }
}

class OrderSummaryCard extends ConsumerStatefulWidget {
  final double totalPrice; 

  const OrderSummaryCard({
    super.key,
    required this.totalPrice,
  });

  @override
  ConsumerState<OrderSummaryCard> createState() => _OrderSummaryCardState();
}

class _OrderSummaryCardState extends ConsumerState<OrderSummaryCard> {
  final _formKey = GlobalKey<FormState>();
  final _cpController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  String? _shippingError;
  bool _isProcessingPayment = false;

  @override
  void dispose() {
    _cpController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _calculateShipping() {
    if (_cpController.text.isEmpty) {
      setState(() => _shippingError = "Ingresa tu CP");
      return;
    }
    setState(() => _shippingError = null);
    ref.read(shippingRatesProvider.notifier).calculateRates(zipCode: _cpController.text);
  }

  // --- LÓGICA DE VALIDACIÓN Y DATOS ---
  Map<String, dynamic>? _submitFormValidation() {
    setState(() => _shippingError = null); 

    if (!_formKey.currentState!.validate()) {
        return null;
    }
    
    final selectedRate = ref.read(selectedShippingRateProvider);
    if (selectedRate == null) {
        setState(() => _shippingError = 'Debes calcular y seleccionar una opción de envío.');
        return null;
    }

    return { 
        'shipping_cost': selectedRate.price,
        'payer_email': _emailController.text,
        'zip_code': _cpController.text,
        'address': _addressController.text,
        'shipping_method': selectedRate.carrierName,
    };
  }
  
  // --- FUNCIÓN DE PAGO PRINCIPAL (REUSANDO EDGE FUNCTION) ---
Future<void> _processPayment({required bool useTransparent}) async {
  final checkoutData = _submitFormValidation();
  if (checkoutData == null) return;

  print('DEBUG: Iniciando _processPayment (Transparent: $useTransparent)');
  setState(() => _isProcessingPayment = true);

  try {
    final cartItems = ref.read(cartNotifierProvider).value ?? [];
    
    final itemsPayload = cartItems.map((item) => {
      'id': item.product.id,
      'title': item.product.name,
      'quantity': item.quantity,
      'price': item.product.finalPrice, 
      'picture_url': item.product.imageUrl, 
    }).toList();
    
    final supabaseClient = Supabase.instance.client;

    print('DEBUG: Invocando Edge Function "create-preference"...');

    final response = await supabaseClient.functions.invoke(
      'create-preference',
      body: {
        'items': itemsPayload,
        'payer_email': checkoutData['payer_email'],
        'shipping_cost': checkoutData['shipping_cost'],
        'shipping_address': {
          'zip_code': checkoutData['zip_code'],
          'street_name': checkoutData['address'],
        },
        'is_transparent': useTransparent,
      },
    );

    final data = response.data;
    print('DEBUG: Respuesta de la función recibida (Status: ${response.status}).');
    
    // 1. CAPTURA DE ERRORES INTERNOS DEL SERVIDOR
    if (data is Map<String, dynamic> && data.containsKey('error')) { 
      // Captura si la función devolvió un error explícito
      throw Exception(data['error'] ?? 'Error desconocido de la función.');
    }

    if (useTransparent) {
      // PAGO CON TARJETA (Brick)
      if (data is Map<String, dynamic> && data['preference_id'] != null) {
        final prefId = data['preference_id'];
        final orderId = data['order_id'];
        
        ref.read(isCartDrawerOpenProvider.notifier).state = false;
        if (mounted) context.push('/checkout?preferenceId=$prefId&orderId=$orderId');
      } else {
          throw Exception('Edge Function no devolvió preference_id o order_id.');
      }
    } else {
      // PAGO CON MERCADO PAGO (Redirección Externa)
      if (data is Map<String, dynamic> && data['init_point'] != null) {
        // CORRECCIÓN DE TIPADO: Forzamos el cast a String para evitar el TypeError
        if (data['init_point'] is String) { 
          final url = Uri.parse(data['init_point'] as String);
          if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
            ref.read(cartNotifierProvider.notifier).clearCart();
            ref.read(isCartDrawerOpenProvider.notifier).state = false;
          } else {
            throw Exception('No se pudo abrir la URL de Mercado Pago.');
          }
        } else {
          // Este caso se activa si el valor es 0 o un tipo no String (la causa del error original)
          throw Exception('Respuesta de función inválida. Init point no es una URL válida.');
        }
      } else {
          throw Exception('Edge Function no devolvió init_point o data inválida.');
      }
    }

  } catch (e) {
    String errorMsg = 'Error desconocido al iniciar el pago.';
    
    // LOGS DETALLADOS
    if (e is FunctionException) {
        print('ERROR: FunctionException - Status: ${e.status}, Details: ${e.details}');
        // Muestra el mensaje más específico del error (RLS violation, etc.)
        errorMsg = e.details?['error'] ?? "Error en el servidor (Edge Function).";
        
    } else if (e is ClientException) {
        print('ERROR: ClientException - $e');
        errorMsg = 'Error de red o conexión: Verifique su CP o red.';
    } else {
        print('ERROR: General Catch - $e');
        errorMsg = e.toString();
    }
    
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
    
  } finally {
    print('DEBUG: Proceso de pago finalizado.');
    if (mounted) setState(() => _isProcessingPayment = false);
  }
}
  
  Future<void> _handlePayment(bool useTransparent) async {
    await _processPayment(useTransparent: useTransparent); 
  }


  @override
  Widget build(BuildContext context) {
    final shippingState = ref.watch(shippingRatesProvider);
    final selectedRate = ref.watch(selectedShippingRateProvider);
    final cartItems = ref.watch(cartNotifierProvider).value ?? [];
    
    // Cálculo de Ahorros
    double totalOriginal = 0;
    for (var item in cartItems) {
      totalOriginal += item.product.price * item.quantity;
    }
    final savings = totalOriginal - widget.totalPrice;
    final hasSavings = savings > 1;

    // Total Final
    final double shippingCost = selectedRate?.price ?? 0.0;
    final double finalTotal = widget.totalPrice + shippingCost;

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Resumen del Pedido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 30),
              
              // EMAIL FIELD
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email de Contacto',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                validator: (v) => (v == null || v.isEmpty || !v.contains('@') || !v.contains('.')) ? 'Email inválido.' : null,
              ),
              const SizedBox(height: 15),

              const Text("Datos de Envío", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // CP FIELD
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cpController,
                      decoration: const InputDecoration(
                        labelText: 'C. Postal',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value == null || value.isEmpty) ? 'El CP es obligatorio.' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: shippingState.isLoading ? null : _calculateShipping,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                    child: shippingState.isLoading 
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Calcular"),
                  ),
                ],
              ),
              // MENSAJE DE ERROR DE CÁLCULO
              if (_shippingError != null)
                Padding(padding: const EdgeInsets.only(top: 5), child: Text(_shippingError!, style: const TextStyle(color: Colors.red, fontSize: 12))),

              // RESULTADOS DE ENVÍO
              if (shippingState.hasValue && shippingState.value!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: shippingState.value!.map((rate) {
                      return RadioListTile<ShippingRate>(
                        value: rate,
                        groupValue: selectedRate,
                        title: Text(rate.carrierName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text("Llega en ${rate.minDays}-${rate.maxDays} días", style: const TextStyle(fontSize: 12)),
                        secondary: Text(currencyFormatter.format(rate.price), style: const TextStyle(fontWeight: FontWeight.bold)),
                        activeColor: Colors.black,
                        dense: true,
                        onChanged: (val) {
                          ref.read(selectedShippingRateProvider.notifier).state = val;
                          setState(() => _shippingError = null);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
              
              const SizedBox(height: 15),
              // DIRECCIÓN FIELD
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección (Calle y Altura)',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'La dirección es obligatoria.' : null,
              ),

              const Divider(height: 30),

              // SECCIÓN TOTALES Y AHORROS
              if (hasSavings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ahorro:', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                      Text('- ${currencyFormatter.format(savings)}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:'),
                  Text(currencyFormatter.format(widget.totalPrice)),
                ],
              ),
              
              if (selectedRate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Envío:'),
                      Text(currencyFormatter.format(selectedRate.price)),
                    ],
                  ),
                ),
                
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Final:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(currencyFormatter.format(finalTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),

              const SizedBox(height: 20),
              
              // BOTÓN MERCADO PAGO (Redirección)
              ElevatedButton.icon(
                onPressed: _isProcessingPayment ? null : () => _handlePayment(false),
                icon: const FaIcon(FontAwesomeIcons.handshake, size: 18),
                label: _isProcessingPayment
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Pagar con Mercado Pago'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009EE3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 10),
              
              // BOTÓN TARJETA (Brick)
              OutlinedButton.icon(
                onPressed: _isProcessingPayment ? null : () => _handlePayment(true),
                icon: const Icon(Icons.credit_card, size: 18),
                label: const Text('Pagar con Tarjeta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}