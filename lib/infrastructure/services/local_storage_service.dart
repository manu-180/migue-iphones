import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyOrders = 'recent_orders';

  // Guardar una nueva orden
  static Future<void> saveOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = prefs.getStringList(_keyOrders) ?? [];
    
    // Evitar duplicados y mantener solo las últimas 5
    if (!orders.contains(orderId)) {
      orders.insert(0, orderId); // Agregar al principio
      if (orders.length > 5) orders.removeLast();
      await prefs.setStringList(_keyOrders, orders);
    }
  }

  // Obtener órdenes guardadas
  static Future<List<String>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyOrders) ?? [];
  }
}