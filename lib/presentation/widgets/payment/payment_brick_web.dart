// lib/presentation/widgets/payment/payment_brick_web.dart

import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/infrastructure/repositories/payment_repository.dart';
import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
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
  late final String _containerId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _containerId = 'payment-brick-${widget.orderId}';
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

    if (!js.context.hasProperty('MercadoPago')) {
       await Future.delayed(const Duration(milliseconds: 500));
       if (!mounted) return;
    }

    try {
      final mpConstructor = js.context['MercadoPago'];
      final mp = js.JsObject(mpConstructor, [publicKey]);
      final bricksBuilder = mp.callMethod('bricks');

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
              'baseColor': '#000000'
            }
          }
        }
      });

      final callbacks = js.JsObject.jsify({
        'onReady': () {
          if (mounted) setState(() => _isLoading = false);
        },
        'onSubmit': (cardFormData) {
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

      final renderPromise = bricksBuilder.callMethod('create', ['payment', _containerId, settings]);
      
      await js_util.promiseToFuture(renderPromise);

    } catch (e) {
      print("Brick Init Exception: $e");
      if (mounted) setState(() { _isLoading = false; _errorMessage = "Error iniciando pago: $e"; });
    }
  }

  Future<void> _handlePaymentSubmit(dynamic cardFormData) async {
    final rawData = _convertJsObjectToDart(cardFormData);
    final currentAmount = ref.read(cartTotalPriceProvider);

    try {
        final data = await ref.read(paymentRepositoryProvider).processPayment(
          rawData: rawData,
          currentAmount: currentAmount,
          orderId: widget.orderId,
        );
        
        widget.onPaymentResult(data);

    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error procesando: $e"), backgroundColor: Colors.red)
        );
      }
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