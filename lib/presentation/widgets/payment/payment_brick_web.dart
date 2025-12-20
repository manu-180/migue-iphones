// // lib/presentation/widgets/payment/payment_brick_web.dart

// import 'dart:async';
// import 'dart:convert';
// // ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;
// // ignore: avoid_web_libraries_in_flutter
// import 'dart:js' as js;
// // ignore: avoid_web_libraries_in_flutter
// import 'dart:js_util' as js_util;
// import 'dart:ui_web' as ui_web;

// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:migue_iphones/infrastructure/repositories/payment_repository.dart';
// import 'package:migue_iphones/presentation/providers/cart/cart_provider.dart';
// import 'package:shimmer/shimmer.dart'; 

// class PaymentBrickContainer extends ConsumerStatefulWidget {
//   final String preferenceId;
//   final String orderId;
//   final Function(Map<String, dynamic>) onPaymentResult;

//   const PaymentBrickContainer({
//     super.key,
//     required this.preferenceId,
//     required this.orderId,
//     required this.onPaymentResult,
//   });

//   @override
//   ConsumerState<PaymentBrickContainer> createState() => _PaymentBrickContainerState();
// }

// class _PaymentBrickContainerState extends ConsumerState<PaymentBrickContainer> {
//   late final String _containerId;
//   bool _isLoading = true;
//   bool _hasError = false;
//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     // ID único para evitar conflictos
//     _containerId = 'payment-brick-${widget.orderId}-${DateTime.now().millisecondsSinceEpoch}';
//     _registerViewFactory();
//     _loadMercadoPagoScript();
//   }

//   void _registerViewFactory() {
//     // Registramos un DIV transparente
//     ui_web.platformViewRegistry.registerViewFactory(_containerId, (int viewId) {
//       final element = html.DivElement()
//         ..id = _containerId
//         ..style.width = '100%'
//         ..style.height = '100%'
//         ..style.border = 'none'
//         ..style.backgroundColor = 'transparent'; 
//       return element;
//     });
//   }

//   Future<void> _loadMercadoPagoScript() async {
//     if (html.document.querySelector('script[src="https://sdk.mercadopago.com/js/v2"]') != null) {
//       await Future.delayed(const Duration(milliseconds: 300));
//       _initializeBrick();
//       return;
//     }

//     final script = html.ScriptElement()
//       ..src = "https://sdk.mercadopago.com/js/v2"
//       ..type = "text/javascript"
//       ..async = true;

//     script.onLoad.listen((_) {
//       // Pequeña espera para asegurar carga
//       Future.delayed(const Duration(milliseconds: 200), _initializeBrick);
//     });

//     script.onError.listen((_) {
//       if (mounted) setState(() { _isLoading = false; _hasError = true; _errorMessage = "No se pudo conectar con el servidor de pagos."; });
//     });

//     html.document.head!.append(script);
//   }

//   void _initializeBrick() async {
//     final publicKey = dotenv.env['MP_PUBLIC_KEY'] ?? '';
//     if (publicKey.isEmpty) {
//       if (mounted) setState(() { _isLoading = false; _hasError = true; _errorMessage = "Error interno de configuración."; });
//       return;
//     }

//     // ESPERA CRÍTICA: Damos tiempo a Flutter para pintar el HTML View
//     await Future.delayed(const Duration(milliseconds: 800));

//     try {
//       if (!js.context.hasProperty('MercadoPago')) {
//          throw Exception("MP SDK no listo");
//       }

//       final mpConstructor = js.context['MercadoPago'];
//       final mp = js.JsObject(mpConstructor, [publicKey]);
//       final bricksBuilder = mp.callMethod('bricks');

//       final initialization = js.JsObject.jsify({
//         'amount': ref.read(cartTotalPriceProvider),
//         'preferenceId': widget.preferenceId,
//       });

//       final customization = js.JsObject.jsify({
//         'visual': {
//           'style': {
//             'theme': 'default', 
//             'customVariables': {
//               'formBackgroundColor': '#ffffff',
//               'baseColor': '#000000', // Botones negros (estilo Apple)
//               'inputBackgroundColor': '#f3f4f6', // Gris muy suave
//               'inputBorderColor': '#e5e7eb',
//               'inputFocusedBorderColor': '#000000',
//             }
//           }
//         },
//         'paymentMethods': {
//           'ticket': 'all',
//           'bankTransfer': 'all',
//           'creditCard': 'all',
//           'debitCard': 'all',
//           'mercadoPago': 'all',
//         },
//       });

//       final callbacks = js.JsObject.jsify({
//         'onReady': () {
//           // Cuando MP termina, sacamos el skeleton
//           if (mounted) {
//             Future.delayed(const Duration(milliseconds: 200), () {
//                if (mounted) setState(() => _isLoading = false);
//             });
//           }
//         },
//         'onSubmit': (cardFormData) {
//            return _handlePaymentSubmit(cardFormData);
//         },
//         'onError': (error) {
//           print("Brick Error: $error");
//           if (mounted) setState(() { _isLoading = false; _hasError = true; _errorMessage = "Hubo un problema al cargar el formulario."; });
//         },
//       });

//       final settings = js.JsObject.jsify({
//         'initialization': initialization,
//         'customization': customization,
//         'callbacks': callbacks,
//       });

//       final renderPromise = bricksBuilder.callMethod('create', ['payment', _containerId, settings]);
//       await js_util.promiseToFuture(renderPromise);

//     } catch (e) {
//       print("Init Exception: $e");
//       if (mounted) setState(() { _isLoading = false; _hasError = true; _errorMessage = "No pudimos iniciar el pago. Por favor recargá."; });
//     }
//   }

//   Future<void> _handlePaymentSubmit(dynamic cardFormData) async {
//     final rawData = _convertJsObjectToDart(cardFormData);
//     final currentAmount = ref.read(cartTotalPriceProvider);

//     try {
//         final data = await ref.read(paymentRepositoryProvider).processPayment(
//           rawData: rawData,
//           currentAmount: currentAmount,
//           orderId: widget.orderId,
//         );
//         widget.onPaymentResult(data);
//     } catch(e) {
//       print("Procesamiento fallido: $e");
//       throw e; 
//     }
//   }

//   Map<String, dynamic> _convertJsObjectToDart(dynamic jsObject) {
//     try {
//       final jsonString = js.context['JSON'].callMethod('stringify', [jsObject]);
//       return jsonDecode(jsonString);
//     } catch (e) {
//       return {};
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 750, 
//       child: Stack(
//         children: [
//           // 1. FORMULARIO REAL (Aparece suavemente)
//           AnimatedOpacity(
//             opacity: _isLoading || _hasError ? 0.0 : 1.0,
//             duration: const Duration(milliseconds: 600),
//             curve: Curves.easeInOut,
//             child: HtmlElementView(viewType: _containerId),
//           ),
          
//           // 2. SKELETON LOADER (Se ve mientras carga)
//           if (_isLoading)
//             Positioned.fill(
//               child: Container(
//                 color: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 20),
//                 child: _buildPremiumSkeleton(),
//               ),
//             ),
            
//           // 3. PANTALLA DE ERROR (Diseño limpio)
//           if (_hasError)
//             Positioned.fill(
//               child: Container(
//                 color: Colors.white,
//                 padding: const EdgeInsets.all(30),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.wifi_off_rounded, color: Colors.grey.shade400, size: 50),
//                     const SizedBox(height: 20),
//                     Text(
//                       "Algo salió mal",
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       _errorMessage ?? "Error de conexión.",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(color: Colors.grey.shade600),
//                     ),
//                     const SizedBox(height: 30),
//                     SizedBox(
//                       width: 200,
//                       height: 50,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           setState(() { _isLoading = true; _hasError = false; _errorMessage = null; });
//                           _initializeBrick();
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.black,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           elevation: 0,
//                         ),
//                         child: const Text("Reintentar"),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // WIDGET SKELETON PREMIUM
//   Widget _buildPremiumSkeleton() {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey.shade100,
//       highlightColor: Colors.grey.shade50,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Título tarjeta
//           Container(width: 180, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)), margin: const EdgeInsets.only(bottom: 30)),
          
//           // Input Tarjeta Grande
//           Container(width: double.infinity, height: 55, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.only(bottom: 20)),
          
//           // Dos inputs (Vencimiento / CVV)
//           Row(
//             children: [
//               Expanded(child: Container(height: 55, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
//               const SizedBox(width: 20),
//               Expanded(child: Container(height: 55, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
//             ],
//           ),
//           const SizedBox(height: 20),
          
//           // Titular
//           Container(width: double.infinity, height: 55, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.only(bottom: 40)),
          
//           // Botón Pagar (Grande y redondo)
//           Container(width: double.infinity, height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30))),
//         ],
//       ),
//     );
//   }
// }