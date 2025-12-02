// lib/presentation/widgets/payment/payment_brick_container.dart

import 'dart:async';
import 'dart:convert'; 
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
import 'package:shimmer/shimmer.dart';
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
  final String _containerId = 'payment-brick-container';
  bool _isLoading = true;
  bool _scriptLoaded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
    _loadMercadoPagoScript();
  }

  void _registerViewFactory() {
    // Registra el div HTML donde se pintará el formulario de MP
    ui_web.platformViewRegistry.registerViewFactory(_containerId, (int viewId) {
      final element = html.DivElement()
        ..id = _containerId
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.overflow = 'visible'; 
      return element;
    });
  }

  Future<void> _loadMercadoPagoScript() async {
    if (html.document.querySelector('script[src="https://sdk.mercadopago.com/js/v2"]') != null) {
      setState(() => _scriptLoaded = true);
      _initializeBrick();
      return;
    }

    final script = html.ScriptElement()
      ..src = "https://sdk.mercadopago.com/js/v2"
      ..type = "text/javascript"
      ..async = true;

    script.onLoad.listen((_) {
      setState(() => _scriptLoaded = true);
      _initializeBrick();
    });

    html.document.head!.append(script);
  }

  void _initializeBrick() {
    // IMPORTANTE: Asegúrate de tener MP_PUBLIC_KEY en tu archivo .env
    final publicKey = dotenv.env['MP_PUBLIC_KEY'] ?? '';
    
    if (publicKey.isEmpty) {
      setState(() { _isLoading = false; _errorMessage = "Falta MP_PUBLIC_KEY"; });
      return;
    }

    final amount = ref.read(cartTotalPriceProvider);

    if (js.context.hasProperty('MercadoPago')) {
      try {
        final mpConstructor = js.context['MercadoPago'];
        final mp = js.JsObject(mpConstructor, [publicKey]); 
        final bricksBuilder = mp.callMethod('bricks');

        final settings = js.JsObject.jsify({
          'initialization': {
            'amount': amount, 
            'preferenceId': widget.preferenceId, 
          },
          'customization': {
            'paymentMethods': {
              'creditCard': 'all',
              'debitCard': 'all',
              'mercadoPago': 'all',
            },
            'visual': {
              'style': { 'theme': 'default' } // O 'dark' si quisieras
            }
          },
          'callbacks': {
            'onReady': () { setState(() => _isLoading = false); },
            'onSubmit': (js.JsObject cardFormData) { _handlePaymentSubmit(cardFormData); },
            'onError': (error) { setState(() { _errorMessage = "Error de carga en MP."; }); },
          },
        });

        bricksBuilder.callMethod('create', ['payment', _containerId, settings]);

      } catch (e) {
        setState(() { _isLoading = false; _errorMessage = "Error interno: $e"; });
      }
    }
  }

 void _handlePaymentSubmit(js.JsObject cardFormData) async {
    var rawData = _convertJsObjectToDart(cardFormData);
    final currentAmount = ref.read(cartTotalPriceProvider);

    if (rawData.containsKey('formData') && rawData['formData'] is Map) {
      final innerData = Map<String, dynamic>.from(rawData['formData']);
      rawData.addAll(innerData);
    }
    
    // Normalización de campos
    if (rawData['payment_method_id'] == null && rawData['paymentMethodId'] != null) rawData['payment_method_id'] = rawData['paymentMethodId'];
    if (rawData['issuer_id'] == null && rawData['issuerId'] != null) rawData['issuer_id'] = rawData['issuerId'];

    try {
        // Llamada a la Edge Function de PulpiPrint
        final response = await Supabase.instance.client.functions.invoke(
          'process-payment',
          body: {
             ...rawData, 
             'transaction_amount': currentAmount, 
             'external_reference': widget.orderId, 
          }
        );
        
        final data = response.data;
        widget.onPaymentResult(data);

    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Map<String, dynamic> _convertJsObjectToDart(js.JsObject jsObject) {
    try {
      final jsonString = js.context['JSON'].callMethod('stringify', [jsObject]);
      return jsonDecode(jsonString);
    } catch (e) { return {}; }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 700, // Altura suficiente para el formulario
      child: Stack(
        children: [
          HtmlElementView(viewType: _containerId),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}