// lib/presentation/widgets/cart/cart_components.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:migue_iphones/domain/models/cart_item.dart';
import 'package:migue_iphones/domain/models/shipping_models.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/providers/shipping_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Formatter global
final currencyFormatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);

// --- 1. TARJETA DE ITEM DEL CARRITO ---
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
            // Imagen del producto
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
            
            // Detalles (Nombre y Precio)
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
                  if (hasDiscount) ...[
                    Text(
                      currencyFormatter.format(item.product.price),
                      style: const TextStyle(
                        fontSize: 12, 
                        color: Colors.grey, 
                        decoration: TextDecoration.lineThrough
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          currencyFormatter.format(item.product.finalPrice),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text('-${item.product.discount}%', style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ] else ...[
                    Text(currencyFormatter.format(item.product.price), style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ],
                  const SizedBox(height: 4),
                  Text('Subtotal: ${currencyFormatter.format(item.subtotal)}', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor, fontSize: 13)),
                ],
              ),
            ),
            
            // Controles de Cantidad (+ / -)
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20), 
                      onPressed: onDecrement, 
                      padding: EdgeInsets.zero, 
                      constraints: const BoxConstraints()
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8), 
                      child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold))
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20), 
                      onPressed: onIncrement, 
                      padding: EdgeInsets.zero, 
                      constraints: const BoxConstraints()
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onRemove, 
                  child: const Text('Quitar', style: TextStyle(color: Colors.red, fontSize: 11))
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: onContinueShopping ?? () => context.go('/'),
            child: const Text('Seguir comprando'),
          ),
        ],
      ),
    );
  }
}

// --- 3. RESUMEN DE ORDEN (Con Lógica de Envío) ---
class OrderSummaryCard extends ConsumerStatefulWidget {
  final double totalPrice; 

  const OrderSummaryCard({super.key, required this.totalPrice});

  @override
  ConsumerState<OrderSummaryCard> createState() => _OrderSummaryCardState();
}

class _OrderSummaryCardState extends ConsumerState<OrderSummaryCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _cpController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _cityController = TextEditingController(); 
  
  String? _selectedProvince = "Buenos Aires";
  String? _shippingError;
  bool _isProcessingPayment = false;

  final List<String> _provincias = ["Buenos Aires", "Capital Federal", "Catamarca", "Chaco", "Chubut", "Córdoba", "Corrientes", "Entre Ríos", "Formosa", "Jujuy", "La Pampa", "La Rioja", "Mendoza", "Misiones", "Neuquén", "Río Negro", "Salta", "San Juan", "San Luis", "Santa Cruz", "Santa Fe", "Santiago del Estero", "Tierra del Fuego", "Tucumán"];

  @override
  void dispose() {
    _emailController.dispose();
    _cpController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN DE CÁLCULO MEJORADA ---
  void _calculateShipping() async {
    // 1. Validamos que haya datos mínimos
    if (_cpController.text.isEmpty || _cityController.text.isEmpty) {
      setState(() => _shippingError = "Ingresa tu CP y Localidad para cotizar");
      return;
    }
    setState(() => _shippingError = null);
    
    // Ocultar teclado
    FocusManager.instance.primaryFocus?.unfocus();

    // 2. Calculamos el peso total sumando los productos del carrito
    final cartItems = ref.read(cartNotifierProvider).value ?? [];
    double totalWeight = 0.0;
    
    for (var item in cartItems) {
      totalWeight += (item.product.weight * item.quantity);
    }
    // Peso mínimo de seguridad (100g)
    if (totalWeight < 0.1) totalWeight = 0.1;

    // 3. Llamamos al Backend con TODOS los datos
    await ref.read(shippingRatesProvider.notifier).calculateRates(
      zipCode: _cpController.text,
      city: _cityController.text,
      stateName: _selectedProvince ?? "Buenos Aires",
      totalWeight: totalWeight
    );

    // 4. Verificación de "Localidad Incorrecta"
    final shippingState = ref.read(shippingRatesProvider);
    if (!shippingState.isLoading && !shippingState.hasError) {
       if (shippingState.value == null || shippingState.value!.isEmpty) {
          if (mounted) {
            setState(() => _shippingError = "No encontramos envíos. Verifica que el CP coincida con la Localidad.");
          }
       }
    }
  }

  Map<String, dynamic>? _submitFormValidation() {
    setState(() => _shippingError = null); 
    if (!_formKey.currentState!.validate()) return null;
    
    final selectedRate = ref.read(selectedShippingRateProvider);
    if (selectedRate == null) {
      setState(() => _shippingError = 'Debes calcular y seleccionar una opción de envío.');
      return null;
    }

    String carrierSlug = 'correoArgentino';
    String serviceCode = selectedRate.serviceName;

    if (selectedRate.carrierName.toLowerCase().contains('andreani')) {
      carrierSlug = 'andreani';
    } else {
      carrierSlug = 'correoArgentino';
    }

    return { 
        'shipping_cost': selectedRate.price,
        'payer_email': _emailController.text,
        'shipping_address': {
            'zip_code': _cpController.text,
            'street_name': _streetController.text,
            'street_number': _numberController.text,
            'city': _cityController.text, 
            'state': _selectedProvince,
        },
        'carrier_slug': carrierSlug,
        'service_level': serviceCode,
    };
  }
  
  Future<void> _processPayment({required bool useTransparent}) async {
    final checkoutData = _submitFormValidation();
    if (checkoutData == null) return;

    setState(() => _isProcessingPayment = true);

    try {
      final cartItems = ref.read(cartNotifierProvider).value ?? [];
      
      final itemsPayload = cartItems.map((item) => {
        'id': item.product.id,
        'title': item.product.name,
        'quantity': item.quantity,
        'unit_price': item.product.finalPrice, 
        'price': item.product.finalPrice,      
        'picture_url': item.product.imageUrl, 
        'image_url': item.product.imageUrl,   
        'description': item.product.name,      
      }).toList();
      
      final supabaseClient = Supabase.instance.client;

      final response = await supabaseClient.functions.invoke(
        'create-preference',
        body: {
          'items': itemsPayload,
          'payer_email': checkoutData['payer_email'],
          'shipping_cost': checkoutData['shipping_cost'],
          'shipping_address': checkoutData['shipping_address'],
          'is_transparent': useTransparent,
          'carrier_slug': checkoutData['carrier_slug'], 
          'service_level': checkoutData['service_level'],
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('error')) throw Exception(data['error']);

      if (useTransparent) {
        if (data != null && data['preference_id'] != null) {
          final prefId = data['preference_id'];
          final orderId = data['order_id'];
          ref.read(isCartDrawerOpenProvider.notifier).state = false;
          if (mounted) context.push('/checkout?preferenceId=$prefId&orderId=$orderId');
        }
      } else {
        if (data != null && data['init_point'] != null) {
           final url = Uri.parse(data['init_point'] as String);
           if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
             ref.read(cartNotifierProvider.notifier).clearCart();
             ref.read(isCartDrawerOpenProvider.notifier).state = false;
           }
        }
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  // --- WIDGET ACORDEÓN PARA ENVÍOS ---
  Widget _buildShippingOptions(List<ShippingRate> rates, ShippingRate? selectedRate) {
    final groupedRates = <String, List<ShippingRate>>{};
    for (var rate in rates) {
      if (!groupedRates.containsKey(rate.carrierName)) {
        groupedRates[rate.carrierName] = [];
      }
      groupedRates[rate.carrierName]!.add(rate);
    }

    return Column(
      children: groupedRates.entries.map((entry) {
        final carrierName = entry.key;
        final options = entry.value;
        final minPrice = options.map((e) => e.price).reduce((a, b) => a < b ? a : b);

        IconData carrierIcon = Icons.local_shipping_outlined;
        if (carrierName.toLowerCase().contains('andreani')) carrierIcon = Icons.local_post_office; 
        if (carrierName.toLowerCase().contains('correo')) carrierIcon = Icons.markunread_mailbox_outlined;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Icon(carrierIcon, color: Colors.black87),
              title: Text(carrierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text("Desde ${currencyFormatter.format(minPrice)}", style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
              textColor: Colors.black,
              childrenPadding: const EdgeInsets.only(bottom: 10),
              children: options.map((rate) {
                return RadioListTile<ShippingRate>(
                  value: rate,
                  groupValue: selectedRate,
                  title: Text(rate.serviceName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  subtitle: Text("${rate.minDays}-${rate.maxDays} días hábiles", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  secondary: Text(currencyFormatter.format(rate.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  activeColor: Colors.black,
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  onChanged: (val) {
                    ref.read(selectedShippingRateProvider.notifier).state = val;
                    setState(() => _shippingError = null);
                  },
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shippingState = ref.watch(shippingRatesProvider);
    final selectedRate = ref.watch(selectedShippingRateProvider);
    final cartItems = ref.watch(cartNotifierProvider).value ?? [];
    
    double totalOriginal = cartItems.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
    final shippingCost = selectedRate?.price ?? 0.0;
    final finalTotal = widget.totalPrice + shippingCost;

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
              const Text('Datos de Contacto', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // Email
              TextFormField(
                controller: _emailController, 
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email', isDense: true, border: OutlineInputBorder()), 
                validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null
              ),
              
              const SizedBox(height: 20),
              const Text("Dirección de Envío", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(flex: 1, child: TextFormField(
                    controller: _cpController, 
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'C.P.', isDense: true, border: OutlineInputBorder()), 
                    keyboardType: TextInputType.number, 
                    validator: (v) => v!.isEmpty ? 'Requerido' : null
                  )),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: DropdownButtonFormField<String>(value: _selectedProvince, decoration: const InputDecoration(labelText: 'Provincia', isDense: true, border: OutlineInputBorder()), items: _provincias.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (val) => setState(() => _selectedProvince = val))),
                ],
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _cityController, 
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Localidad / Barrio', isDense: true, border: OutlineInputBorder(), hintText: "Ej: El Talar"), 
                validator: (v) => v!.isEmpty ? 'Requerido' : null
              ),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(flex: 2, child: TextFormField(
                    controller: _streetController, 
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Calle', isDense: true, border: OutlineInputBorder()), 
                    validator: (v) => v!.isEmpty ? 'Requerido' : null
                  )),
                  const SizedBox(width: 10),
                  Expanded(flex: 1, child: TextFormField(
                    controller: _numberController, 
                    // CAMBIO: Al dar Enter en "Altura" (el último), se calcula
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _calculateShipping(),
                    decoration: const InputDecoration(labelText: 'Altura', isDense: true, border: OutlineInputBorder()), 
                    keyboardType: TextInputType.number, 
                    validator: (v) => v!.isEmpty ? 'Requerido' : null
                  )),
                ],
              ),
              const SizedBox(height: 10),
              
              // --- BOTÓN CON LOADING ---
              ElevatedButton(
                onPressed: shippingState.isLoading ? null : _calculateShipping,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                child: shippingState.isLoading 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text("Calculando costo...")
                      ],
                    )
                  : const Text("Calcular Costo de Envío"),
              ),

              if (_shippingError != null) Padding(padding: const EdgeInsets.only(top: 5), child: Text(_shippingError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
              
              // --- LISTA AGRUPADA (ACORDEÓN) ---
              if (shippingState.hasValue && shippingState.value!.isNotEmpty) ...[
                const SizedBox(height: 15),
                const Text("Opciones de Envío:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                _buildShippingOptions(shippingState.value!, selectedRate),
              ],
              
              const Divider(height: 30),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Final:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(currencyFormatter.format(finalTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
              const SizedBox(height: 20),
              ElevatedButton.icon(onPressed: _isProcessingPayment ? null : () => _processPayment(useTransparent: false), icon: const FaIcon(FontAwesomeIcons.handshake, size: 18), label: _isProcessingPayment ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Pagar con Mercado Pago'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009EE3), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15))),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: _isProcessingPayment ? null : () => _processPayment(useTransparent: true), icon: const Icon(Icons.credit_card, size: 18), label: const Text('Pagar con Tarjeta'), style: OutlinedButton.styleFrom(foregroundColor: Colors.black, side: const BorderSide(color: Colors.black), padding: const EdgeInsets.symmetric(vertical: 15))),
            ],
          ),
        ),
      ),
    );
  }
}