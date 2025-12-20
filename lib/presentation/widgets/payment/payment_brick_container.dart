// lib/presentation/widgets/payment/payment_brick_web.dart

import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/infrastructure/repositories/payment_repository.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:shimmer/shimmer.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentBrickContainer extends ConsumerStatefulWidget {
  final String preferenceId;
  final String orderId;
  final Function(Map<String, dynamic>) onPaymentResult;

  const PaymentBrickContainer({
    super.key,
    required this.preferenceId,
    required this.orderId,
    required this.onPaymentResult,
  });

  @override
  ConsumerState<PaymentBrickContainer> createState() => _PaymentBrickContainerState();
}

class _PaymentBrickContainerState extends ConsumerState<PaymentBrickContainer> {
  late final String _containerId;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Generamos ID único para evitar cache del DOM
    _containerId = 'payment-brick-${widget.orderId}-${DateTime.now().millisecondsSinceEpoch}';
    
    // 1. Registramos el DIV (Método clásico compatible con tu versión)
    _registerViewFactory();
    
    // 2. Cargamos script
    _loadMercadoPagoScript();
  }

  void _registerViewFactory() {
    // Usamos platformViewRegistry de dart:ui_web (o el hack de js context si falla)
    ui_web.platformViewRegistry.registerViewFactory(_containerId, (int viewId) {
      final element = html.DivElement()
        ..id = _containerId
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.backgroundColor = 'transparent';
      return element;
    });
  }

  Future<void> _loadMercadoPagoScript() async {
    // Verificar si ya cargó antes
    if (html.document.querySelector('script[src="https://sdk.mercadopago.com/js/v2"]') != null) {
      await Future.delayed(const Duration(milliseconds: 300));
      _initializeBrick();
      return;
    }

    final script = html.ScriptElement()
      ..src = "https://sdk.mercadopago.com/js/v2"
      ..type = "text/javascript"
      ..async = true;

    script.onLoad.listen((_) {
      // Pequeña espera para asegurar que 'MercadoPago' exista en window
      Future.delayed(const Duration(milliseconds: 200), _initializeBrick);
    });

    script.onError.listen((_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; _errorMessage = "No se pudo conectar con Mercado Pago."; });
    });

    html.document.head!.append(script);
  }

  void _initializeBrick() async {
    final publicKey = dotenv.env['MP_PUBLIC_KEY'] ?? '';
    
    if (publicKey.isEmpty) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; _errorMessage = "Error de configuración (Falta Key)"; });
      return;
    }

    // --- ESPERA CRÍTICA ---
    // Esto evita el error "Container not found". Damos tiempo a Flutter para pintar el HTML.
    await Future.delayed(const Duration(milliseconds: 800));

    // Usamos dart:js (Lógica Antigua que te funcionaba)
    if (js.context.hasProperty('MercadoPago')) {
      try {
        final mpConstructor = js.context['MercadoPago'];
        final mp = js.JsObject(mpConstructor, [publicKey]);
        final bricksBuilder = mp.callMethod('bricks');

        final amount = ref.read(cartTotalPriceProvider);

        // Configuración de Brick
        final settings = js.JsObject.jsify({
          'initialization': {
            'amount': amount,
            'preferenceId': widget.preferenceId,
          },
          'customization': {
            'paymentMethods': {
              'ticket': 'all',
              'bankTransfer': 'all',
              'creditCard': 'all',
              'debitCard': 'all',
              'mercadoPago': 'all',
            },
            'visual': {
              'style': {
                'theme': 'default', // Tema claro moderno
                'customVariables': {
                  'formBackgroundColor': '#ffffff',
                  'baseColor': '#000000', // Botones Negros
                  'inputBackgroundColor': '#f9fafb',
                  'inputBorderColor': '#e5e7eb',
                }
              }
            }
          },
          'callbacks': {
            'onReady': () {
              // AQUÍ QUITAMOS EL SKELETON LOADER
              if (mounted) {
                 Future.delayed(const Duration(milliseconds: 300), () {
                   if(mounted) setState(() => _isLoading = false);
                 });
              }
            },
            'onSubmit': (js.JsObject cardFormData) {
               _handlePaymentSubmit(cardFormData);
            },
            'onError': (error) {
              print("Brick Error: $error");
              if (mounted) setState(() { _isLoading = false; _hasError = true; _errorMessage = "Hubo un error cargando el formulario."; });
            },
          },
        });

        // Crear el brick
        bricksBuilder.callMethod('create', ['payment', _containerId, settings]);

      } catch (e) {
        print("Init Exception: $e");
        if (mounted) setState(() { _isLoading = false; _hasError = true; _errorMessage = "Error iniciando pago. Por favor recargá."; });
      }
    } else {
       if (mounted) setState(() { _isLoading = false; _hasError = true; _errorMessage = "Librería de pagos no disponible."; });
    }
  }

  void _handlePaymentSubmit(js.JsObject cardFormData) async {
    // Conversión segura de JS a Dart
    final rawData = _convertJsObjectToDart(cardFormData);
    final currentAmount = ref.read(cartTotalPriceProvider);

    // Normalización de datos que a veces vienen anidados
    if (rawData.containsKey('formData') && rawData['formData'] is Map) {
      final innerData = Map<String, dynamic>.from(rawData['formData']);
      rawData.addAll(innerData);
    }
    
    // Normalización de IDs (camelCase vs snake_case)
    if (rawData['payment_method_id'] == null && rawData['paymentMethodId'] != null) rawData['payment_method_id'] = rawData['paymentMethodId'];
    if (rawData['issuer_id'] == null && rawData['issuerId'] != null) rawData['issuer_id'] = rawData['issuerId'];

    try {
        // Tu lógica de backend con Supabase
        final response = await Supabase.instance.client.functions.invoke(
          'process-payment',
          body: {
             ...rawData,
             'transaction_amount': currentAmount,
             'external_reference': widget.orderId,
             // Fix para evitar error si falta email
             'payer': {
                'email': rawData['payer']?['email'] ?? 'unknown@email.com',
                'identification': rawData['payer']?['identification']
             }
          }
        );
        
        final data = response.data;
        widget.onPaymentResult(data);

    } catch(e) {
      print("Pago Error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error procesando pago: $e"), backgroundColor: Colors.red));
    }
  }

  Map<String, dynamic> _convertJsObjectToDart(js.JsObject jsObject) {
    try {
      final jsonString = js.context['JSON'].callMethod('stringify', [jsObject]);
      return jsonDecode(jsonString);
    } catch (e) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 750, 
      child: Stack(
        children: [
          // 1. CAPA DE FORMULARIO (HTML)
          // Usamos Opacity simple para evitar conflictos de renderizado con el iframe
          Opacity(
            opacity: _isLoading || _hasError ? 0.0 : 1.0,
            child: HtmlElementView(viewType: _containerId),
          ),
          
          // 2. CAPA DE CARGA (SKELETON PREMIUM)
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: _buildPremiumSkeleton(),
              ),
            ),
            
          // 3. CAPA DE ERROR (DISEÑO AMIGABLE)
          if (_hasError)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.credit_card_off_outlined, color: Colors.red.shade400, size: 40),
                    ),
                    const SizedBox(height: 20),
                    Text("Algo salió mal", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(_errorMessage ?? "No pudimos cargar el formulario.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 200, height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() { _isLoading = true; _hasError = false; _errorMessage = null; });
                          _initializeBrick();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: const Text("Reintentar"),
                      ),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // WIDGET SKELETON (Estilo App Bancaria)
  Widget _buildPremiumSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade100,
      highlightColor: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Container(width: 150, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)), margin: const EdgeInsets.only(bottom: 25)),
          // Input Tarjeta Grande
          Container(width: double.infinity, height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), margin: const EdgeInsets.only(bottom: 15)),
          // Fila Vencimiento + CVV
          Row(children: [
            Expanded(child: Container(height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
            const SizedBox(width: 15),
            Expanded(child: Container(height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
          ]),
          const SizedBox(height: 15),
          // Titular
          Container(width: double.infinity, height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), margin: const EdgeInsets.only(bottom: 25)),
          // Botón Pagar
          Container(width: double.infinity, height: 55, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30))),
        ],
      ),
    );
  }
}