// lib/presentation/widgets/shared/address_map_preview.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AddressMapPreview extends StatefulWidget {
  final double lat;
  final double lng;
  final bool isApproximate;
  final Function(LatLng)? onPositionChanged; 

  const AddressMapPreview({
    super.key,
    required this.lat,
    required this.lng,
    this.isApproximate = false,
    this.onPositionChanged,
  });

  @override
  State<AddressMapPreview> createState() => _AddressMapPreviewState();
}

class _AddressMapPreviewState extends State<AddressMapPreview> {
  late final MapController _mapController;
  late LatLng _currentMarkerPosition;
  bool _userHasCorrected = false;
  bool _showInfoCard = false; // Control de la tarjeta de información

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentMarkerPosition = LatLng(widget.lat, widget.lng);
  }

  @override
  void didUpdateWidget(covariant AddressMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lng != widget.lng) {
      setState(() {
        _currentMarkerPosition = LatLng(widget.lat, widget.lng);
        _userHasCorrected = false;
        _mapController.move(_currentMarkerPosition, 16);
      });
    }
  }

  void _zoom(double amount) {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + amount);
  }

  @override
  Widget build(BuildContext context) {
    final markerColor = widget.isApproximate ? Colors.orange.shade800 : Colors.red;
    
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentMarkerPosition,
                initialZoom: 16.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate & ~InteractiveFlag.scrollWheelZoom,
                ),
                onTap: (_, point) {
                  setState(() {
                    _currentMarkerPosition = point;
                    _userHasCorrected = true;
                  });
                  widget.onPositionChanged?.call(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.migueiphones.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentMarkerPosition,
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.location_on, 
                        color: _userHasCorrected ? Colors.green : markerColor, 
                        size: 50,
                        shadows: const [Shadow(blurRadius: 10, color: Colors.black38)],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // BOTONES DE CONTROL
            Positioned(
              top: 10,
              right: 10,
              child: Column(
                children: [
                  _buildMapButton(Icons.add, () => _zoom(1)),
                  const SizedBox(height: 8),
                  _buildMapButton(Icons.remove, () => _zoom(-1)),
                  const SizedBox(height: 8),
                  _buildMapButton(Icons.my_location, () => _mapController.move(_currentMarkerPosition, 16)),
                  const SizedBox(height: 8),
                  // NUEVO BOTÓN DE INFO
                  _buildMapButton(
                    _showInfoCard ? Icons.close : Icons.info_outline, 
                    () => setState(() => _showInfoCard = !_showInfoCard),
                    color: _showInfoCard ? Colors.black : Colors.white,
                    iconColor: _showInfoCard ? Colors.white : Colors.black87,
                  ),
                ],
              ),
            ),

            // CARD DE INFORMACIÓN ESTÉTICA
            if (_showInfoCard)
              Positioned(
                top: 10,
                left: 10,
                right: 60,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 20, color: Colors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Ubicación referencial. El correo utilizará la dirección exacta escrita en el formulario para la entrega.",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ETIQUETA DE ESTADO (Inferior)
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                ),
                child: Text(
                  _userHasCorrected ? "Ubicación Ajustada" : (widget.isApproximate ? "Aproximada" : "Exacta"),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapButton(IconData icon, VoidCallback onPressed, {Color color = Colors.white, Color iconColor = Colors.black87}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: iconColor),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}