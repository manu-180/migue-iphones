// lib/presentation/widgets/payment/payment_brick_container.dart

import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util; // Usamos js_util para mejor interop

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui_web' as ui_web;

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
  // ID único para evitar colisiones si se abre más de una vez
  late final String _containerId; 
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _containerId = 'payment-brick-${widget.orderId}'; // ID único basado en la orden
    _registerViewFactory();
    _loadMercadoPagoScript();
  }

  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(_containerId, (int viewId) {
      final element = html.DivElement()
        ..id = _containerId
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none';
      return element;
    });
  }

  Future<void> _loadMercadoPagoScript() async {
    if (html.document.querySelector('script[src="https://sdk.mercadopago.com/js/v2"]') != null) {
      // Script ya cargado, esperar un tick para asegurar que el div esté en el DOM
      await Future.delayed(const Duration(milliseconds: 100));
      _initializeBrick();
      return;
    }

    final script = html.ScriptElement()
      ..src = "https://sdk.mercadopago.com/js/v2"
      ..type = "text/javascript"
      ..async = true;

    script.onLoad.listen((_) {
      _initializeBrick();
    });

    html.document.head!.append(script);
  }

  void _initializeBrick() async {
    final publicKey = dotenv.env['MP_PUBLIC_KEY'] ?? '';
    if (publicKey.isEmpty) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = "Falta MP_PUBLIC_KEY"; });
      return;
    }

    // Esperar a que el objeto MercadoPago esté disponible
    if (!js.context.hasProperty('MercadoPago')) {
       await Future.delayed(const Duration(milliseconds: 500));
       if (!mounted) return;
    }

    try {
      final mpConstructor = js.context['MercadoPago'];
      final mp = js.JsObject(mpConstructor, [publicKey]);
      final bricksBuilder = mp.callMethod('bricks');

      // Configuración JS convertida
      final initialization = js.JsObject.jsify({
        'amount': ref.read(cartTotalPriceProvider),
        'preferenceId': widget.preferenceId,
      });

      final customization = js.JsObject.jsify({
        'paymentMethods': {
          'ticket': 'all',
          'bankTransfer': 'all',
          'creditCard': 'all',
          'debitCard': 'all',
          'mercadoPago': 'all',
        },
        'visual': {
          'style': {
            'theme': 'default', 
            'customVariables': {
              'formBackgroundColor': '#ffffff',
              'baseColor': '#000000' // Botones negros para tu estética
            }
          }
        }
      });

      final callbacks = js.JsObject.jsify({
        'onReady': () {
          if (mounted) setState(() => _isLoading = false);
        },
        'onSubmit': (cardFormData) {
           // Retornamos una promesa al Brick para que muestre su loading interno
           return _handlePaymentSubmit(cardFormData);
        },
        'onError': (error) {
          if (mounted) setState(() { _errorMessage = "Error de carga en MP."; });
          print("Brick Error: $error");
        },
      });

      final settings = js.JsObject.jsify({
        'initialization': initialization,
        'customization': customization,
        'callbacks': callbacks,
      });

      // Renderizar el Brick
      final renderPromise = bricksBuilder.callMethod('create', ['payment', _containerId, settings]);
      
      // Manejar la promesa de renderizado
      await js_util.promiseToFuture(renderPromise);

    } catch (e) {
      print("Brick Init Exception: $e");
      if (mounted) setState(() { _isLoading = false; _errorMessage = "Error iniciando pago: $e"; });
    }
  }

  // IMPORTANTE: Esta función debe retornar una Promise de JS para que el Brick espere
  Future<void> _handlePaymentSubmit(dynamic cardFormData) async {
    // Convertir el objeto JS a Mapa Dart
    final rawData = _convertJsObjectToDart(cardFormData);
    final currentAmount = ref.read(cartTotalPriceProvider);

    // Aplanar formData si viene anidado
    if (rawData.containsKey('formData') && rawData['formData'] is Map) {
      final innerData = Map<String, dynamic>.from(rawData['formData']);
      rawData.addAll(innerData);
    }
    
    // Normalización de claves (camelCase vs snake_case)
    if (rawData['payment_method_id'] == null && rawData['paymentMethodId'] != null) {
      rawData['payment_method_id'] = rawData['paymentMethodId'];
    }
    if (rawData['issuer_id'] == null && rawData['issuerId'] != null) {
      rawData['issuer_id'] = rawData['issuerId'];
    }

    try {
        final response = await Supabase.instance.client.functions.invoke(
          'process-payment',
          body: {
             ...rawData,
             'transaction_amount': currentAmount,
             'external_reference': widget.orderId,
             // No olvides pasar el payer si el Brick lo captura
             'payer': {
                'email': rawData['payer']?['email'] ?? 'unknown@email.com',
                'identification': rawData['payer']?['identification']
             }
          }
        );
        
        final data = response.data;
        widget.onPaymentResult(data);

    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error procesando: $e"), backgroundColor: Colors.red)
        );
      }
      // Relanzar para que el Brick sepa que falló (opcional, depende del UX deseado)
      throw e; 
    }
  }

  Map<String, dynamic> _convertJsObjectToDart(dynamic jsObject) {
    try {
      final jsonString = js.context['JSON'].callMethod('stringify', [jsObject]);
      return jsonDecode(jsonString);
    } catch (e) {
      print("Error converting JS object: $e");
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 750, 
      child: Stack(
        children: [
          // El View debe estar siempre presente para que el script lo encuentre
          HtmlElementView(viewType: _containerId),
          
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.black),
                    SizedBox(height: 15),
                    Text("Cargando pasarela segura..."),
                  ],
                ),
              ),
            ),
            
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 10),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  TextButton(
                    onPressed: _initializeBrick,
                    child: const Text("Reintentar"),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}