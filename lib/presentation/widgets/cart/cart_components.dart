// lib/presentation/widgets/cart/cart_components.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:migue_iphones/domain/models/cart_item.dart';
import 'package:migue_iphones/domain/models/shipping_models.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:migue_iphones/presentation/providers/shipping_provider.dart';
import 'package:migue_iphones/presentation/widgets/shared/address_map_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

final currencyFormatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemCard({super.key, required this.item, required this.onIncrement, required this.onDecrement, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = item.product.discount > 0;
    return Card(
      elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.product.imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 70, height: 70, color: Colors.grey))),
            const SizedBox(width: 15),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                if (hasDiscount) ...[
                  Text(currencyFormatter.format(item.product.price), style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                  Row(children: [
                    Text(currencyFormatter.format(item.product.finalPrice), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
                    const SizedBox(width: 6),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)), child: Text('-${item.product.discount}%', style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold)))
                  ]),
                ] else ...[Text(currencyFormatter.format(item.product.price), style: const TextStyle(fontSize: 13, color: Colors.black87))],
                const SizedBox(height: 4),
                Text('Subtotal: ${currencyFormatter.format(item.subtotal)}', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor, fontSize: 13)),
              ]),
            ),
            Column(children: [
              Row(children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: onDecrement, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: onIncrement, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ]),
              TextButton(onPressed: onRemove, child: const Text('Quitar', style: TextStyle(color: Colors.red, fontSize: 11)))
            ]),
          ],
        ),
      ),
    );
  }
}

class EmptyCartView extends StatelessWidget {
  final VoidCallback? onContinueShopping;
  const EmptyCartView({super.key, this.onContinueShopping});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
        const SizedBox(height: 20),
        const Text('Tu carrito está vacío', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white), onPressed: onContinueShopping ?? () => context.go('/'), child: const Text('Seguir comprando')),
      ]),
    );
  }
}

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
  String? _warningMessage;
  bool _isProcessingPayment = false;
  
  LatLng? _mapCoordinates;
  bool _isLocationApproximate = false;
  bool _isValidatingAddress = false;

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

  // --- LÓGICA DE VALIDACIÓN MEJORADA ---
  Future<bool> _validateAndGeocode() async {
    final street = _streetController.text.trim();
    final number = _numberController.text.trim();
    final city = _cityController.text.trim();
    final state = _selectedProvince ?? "";
    final userCp = _cpController.text.trim();

    if (street.isEmpty || city.isEmpty || number.isEmpty) {
      setState(() => _shippingError = "Completa la dirección para validar.");
      return false;
    }

    setState(() {
      _isValidatingAddress = true;
      _shippingError = null;
      _warningMessage = null;
      _mapCoordinates = null;
    });

    final query = "$street $number, $city, $state, Argentina";
    
    // Solicitamos 'addressdetails': '1' para obtener el CP real de esa ubicación
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {'q': query, 'format': 'json', 'limit': '1', 'addressdetails': '1'});
    
    try {
      final response = await http.get(uri, headers: {'User-Agent': 'migue_iphones_app'});
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is List && data.isEmpty) {
          if (mounted) setState(() { _isValidatingAddress = false; _shippingError = "No encontramos esa dirección. Verifique calle y altura."; });
          return false;
        }

        if (data is List && data.isNotEmpty) {
          final item = data[0];
          final lat = double.parse(item['lat']);
          final lon = double.parse(item['lon']);
          final rank = int.tryParse(item['place_rank'].toString()) ?? 0;
          
          // --- VALIDACIÓN DE CÓDIGO POSTAL ---
          // Extraemos el CP que nos devuelve el mapa para esta dirección
          final addressInfo = item['address'] ?? {};
          final detectedPostcode = addressInfo['postcode']?.toString();

          if (detectedPostcode != null && userCp.isNotEmpty) {
            // Limpiamos strings para comparar (sacar espacios o letras si las hubiera)
            final cleanUserCp = userCp.replaceAll(RegExp(r'[^0-9]'), '');
            final cleanDetected = detectedPostcode.replaceAll(RegExp(r'[^0-9]'), '');

            // Si hay una discrepancia clara (ej: puso 1000 y es 5000), mostramos error.
            // Usamos contains porque a veces OSM devuelve "B1618" y el usuario puso "1618".
            if (cleanUserCp.isNotEmpty && cleanDetected.isNotEmpty && 
                !cleanDetected.contains(cleanUserCp) && !cleanUserCp.contains(cleanDetected)) {
              
              if (mounted) {
                setState(() {
                  _isValidatingAddress = false;
                  _shippingError = "El C.P. ingresado ($userCp) no coincide con la ubicación detectada ($detectedPostcode). Verifique la localidad.";
                });
              }
              return false; // Detenemos porque el CP está mal
            }
          }

          if (mounted) {
            setState(() { 
              _mapCoordinates = LatLng(lat, lon); 
              _isLocationApproximate = rank < 28; // < 28 suele ser nivel ciudad/barrio, no casa exacta
              _isValidatingAddress = false; 
            });
          }
          return true;
        }
      }
    } catch (e) {
      // Si falla la API, permitimos continuar pero avisamos (fail-safe)
      if (mounted) setState(() => _isValidatingAddress = false);
      return true; 
    }
    
    if (mounted) setState(() => _isValidatingAddress = false);
    return true;
  }

  void _calculateShipping() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_cpController.text.isEmpty || _cityController.text.isEmpty || _streetController.text.isEmpty || _numberController.text.isEmpty) {
      setState(() => _shippingError = "Completa todos los campos de dirección.");
      return;
    }
    
    // Primero validamos la dirección y el CP
    final isAddressValid = await _validateAndGeocode();
    if (!isAddressValid) return; // Si falló la validación (ej: CP incorrecto), no calculamos envío

    final cartItems = ref.read(cartNotifierProvider).value ?? [];
    double totalWeight = cartItems.fold(0.1, (sum, item) => sum + (item.product.weight * item.quantity));
    
    await ref.read(shippingRatesProvider.notifier).calculateRates(
      zipCode: _cpController.text, 
      city: _cityController.text, 
      stateName: _selectedProvince ?? "Buenos Aires", 
      totalWeight: totalWeight
    );
  }

  Map<String, dynamic>? _submitFormValidation() {
    setState(() => _shippingError = null); 
    if (!_formKey.currentState!.validate()) return null;
    final selectedRate = ref.read(selectedShippingRateProvider);
    if (selectedRate == null) {
      setState(() => _shippingError = 'Debes calcular y seleccionar una opción de envío.');
      return null;
    }
    return { 
        'shipping_cost': selectedRate.price,
        'payer_email': _emailController.text,
        'shipping_address': { 'zip_code': _cpController.text, 'street_name': _streetController.text, 'street_number': _numberController.text, 'city': _cityController.text, 'state': _selectedProvince },
        'carrier_slug': selectedRate.carrierName.toLowerCase().contains('andreani') ? 'andreani' : 'correoArgentino',
        'service_level': selectedRate.serviceName,
    };
  }

  Future<void> _processPayment({required bool useTransparent}) async {
    final checkoutData = _submitFormValidation();
    if (checkoutData == null) return;
    setState(() => _isProcessingPayment = true);
    try {
      final cartItems = ref.read(cartNotifierProvider).value ?? [];
      final itemsPayload = cartItems.map((item) => {
        'id': item.product.id, 'title': item.product.name, 'quantity': item.quantity, 'unit_price': item.product.finalPrice, 'price': item.product.finalPrice, 'picture_url': item.product.imageUrl, 'image_url': item.product.imageUrl, 'description': item.product.name,
      }).toList();
      final response = await Supabase.instance.client.functions.invoke('create-preference', body: {
          'items': itemsPayload, 'payer_email': checkoutData['payer_email'], 'shipping_cost': checkoutData['shipping_cost'], 'shipping_address': checkoutData['shipping_address'], 'is_transparent': useTransparent, 'carrier_slug': checkoutData['carrier_slug'], 'service_level': checkoutData['service_level'],
      });
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('error')) throw Exception(data['error']);
      if (useTransparent) {
        if (data != null && data['preference_id'] != null) {
          ref.read(isCartDrawerOpenProvider.notifier).state = false;
          if (mounted) context.push('/checkout?preferenceId=${data['preference_id']}&orderId=${data['order_id']}');
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

  Widget _buildShippingOptions(List<ShippingRate> rates, ShippingRate? selectedRate) {
    final groupedRates = <String, List<ShippingRate>>{};
    for (var rate in rates) {
      if (!groupedRates.containsKey(rate.carrierName)) groupedRates[rate.carrierName] = [];
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
          elevation: 0, margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: CircleAvatar(backgroundColor: Colors.grey.shade100, child: Icon(carrierIcon, color: Colors.black87, size: 20)),
              title: Text(carrierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text("Desde ${currencyFormatter.format(minPrice)}", style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
              children: options.map((rate) {
                return RadioListTile<ShippingRate>(
                  value: rate, groupValue: selectedRate,
                  title: Text(rate.serviceName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  subtitle: Text("${rate.minDays}-${rate.maxDays} días hábiles", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  secondary: Text(currencyFormatter.format(rate.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  activeColor: Colors.black, dense: true,
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
    final finalTotal = widget.totalPrice + (selectedRate?.price ?? 0.0);

    return Card(
      elevation: 4, shadowColor: Colors.black12, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Resumen de Compra', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 20),
                _buildSectionTitle("Contacto"),
                TextFormField(controller: _emailController, decoration: _inputDecoration("Correo electrónico", Icons.email_outlined), validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null),
                const SizedBox(height: 16),
                _buildSectionTitle("Entrega"),
                Row(children: [
                  Expanded(flex: 3, child: TextFormField(controller: _cpController, decoration: _inputDecoration("C.P.", null), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(flex: 5, child: DropdownButtonFormField<String>(
                    value: _selectedProvince, decoration: _inputDecoration("Provincia", null),
                    items: _provincias.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setState(() => _selectedProvince = val),
                  )),
                ]),
                const SizedBox(height: 12),
                TextFormField(controller: _cityController, decoration: _inputDecoration("Localidad", Icons.location_city_outlined)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(flex: 3, child: TextFormField(controller: _streetController, decoration: _inputDecoration("Calle", null))),
                  const SizedBox(width: 12),
                  Expanded(flex: 1, child: TextFormField(controller: _numberController, decoration: _inputDecoration("Altura", null), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: FilledButton.tonal(
                    onPressed: (shippingState.isLoading || _isValidatingAddress) ? null : _calculateShipping,
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: (shippingState.isLoading || _isValidatingAddress)
                      ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 12), Text("Validando dirección...", style: TextStyle(fontWeight: FontWeight.bold))])
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.calculate_outlined, size: 18), SizedBox(width: 8), Text("Calcular envío", style: TextStyle(fontWeight: FontWeight.bold))]),
                  ),
                ),
                if (_shippingError != null) _buildErrorMessage(_shippingError!),
                if (_mapCoordinates != null) ...[
                  const SizedBox(height: 16),
                  AddressMapPreview(lat: _mapCoordinates!.latitude, lng: _mapCoordinates!.longitude, isApproximate: _isLocationApproximate, onPositionChanged: (c) => _mapCoordinates = c),
                ],
                if (shippingState.hasValue && shippingState.value!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildShippingOptions(shippingState.value!, selectedRate),
                ],
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total a pagar', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  Text(currencyFormatter.format(finalTotal), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),
                ]),
                const SizedBox(height: 24),
                _buildMercadoPagoButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) => InputDecoration(
    labelText: label, prefixIcon: icon != null ? Icon(icon, size: 20) : null,
    isDense: true, filled: true, fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
  );

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.2)));

  Widget _buildErrorMessage(String msg) => Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.error_outline, size: 16, color: Colors.red), const SizedBox(width: 8), Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)))]));

  Widget _buildMercadoPagoButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(colors: [Color(0xFF009EE3), Color(0xFF007EB5)]),
        boxShadow: [BoxShadow(color: const Color(0xFF009EE3).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessingPayment ? null : () => _processPayment(useTransparent: false),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isProcessingPayment 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [FaIcon(FontAwesomeIcons.handshake, color: Colors.white, size: 20), SizedBox(width: 12), Text('Pagar con Mercado Pago', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))],
                ),
          ),
        ),
      ),
    );
  }
}