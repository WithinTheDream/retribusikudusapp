import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng? initialLocation;

  const MapPickerPage({super.key, this.initialLocation});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late LatLng _selectedLocation;
  late final MapController _mapController;
  double _currentZoom = 14.5;

  // Koordinat Utama Kabupaten Kudus
  static const LatLng _kudusCenter = LatLng(-6.804825, 110.840660);

  // Daftar Titik Cepat Kecamatan di Kudus
  final List<Map<String, dynamic>> _quickLocations = const [
    {'nama': 'Pusat Kudus', 'lat': -6.804825, 'lng': 110.840660},
    {'nama': 'Kec. Jati', 'lat': -6.828500, 'lng': 110.840200},
    {'nama': 'Kec. Bae', 'lat': -6.782000, 'lng': 110.865000},
    {'nama': 'Kec. Gebog', 'lat': -6.742000, 'lng': 110.835000},
    {'nama': 'Kec. Kaliwungu', 'lat': -6.795000, 'lng': 110.795000},
    {'nama': 'Kec. Mejobo', 'lat': -6.825000, 'lng': 110.895000},
    {'nama': 'Kec. Jekulo', 'lat': -6.810000, 'lng': 110.935000},
    {'nama': 'Kec. Dawe', 'lat': -6.720000, 'lng': 110.885000},
    {'nama': 'Kec. Undaan', 'lat': -6.905000, 'lng': 110.815000},
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? _kudusCenter;
    _mapController = MapController();
  }

  void _moveTo(LatLng target, {double? zoom}) {
    final newZoom = zoom ?? _currentZoom;
    _mapController.move(target, newZoom);
    setState(() {
      _selectedLocation = target;
      _currentZoom = newZoom;
    });
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(3.0, 18.0);
    });
    _mapController.move(_selectedLocation, _currentZoom);
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(3.0, 18.0);
    });
    _mapController.move(_selectedLocation, _currentZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pilih Titik Pin Lokasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Color(0xFF059669)),
            tooltip: 'Ke Pusat Kudus',
            onPressed: () => _moveTo(_kudusCenter, zoom: 15.0),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Interactive Flutter Map with OpenStreetMap tiles
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: _currentZoom,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kudus.retribusikudusapp',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 60,
                    height: 60,
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Lokasi Objek',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(
                          Icons.location_pin,
                          color: Color(0xFFDC2626),
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Quick Kecamatan Selector Chips
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickLocations.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      backgroundColor: Colors.white.withValues(alpha: 0.95),
                      elevation: 2,
                      side: BorderSide(color: Colors.grey.shade300),
                      label: Text(
                        item['nama'] as String,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                      onPressed: () {
                        _moveTo(
                          LatLng(item['lat'] as double, item['lng'] as double),
                          zoom: 15.0,
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 3. Right Floating Map Controls (Zoom In, Zoom Out)
          Positioned(
            right: 16,
            bottom: 210,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'btnZoomIn',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E293B),
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'btnZoomOut',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E293B),
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // 4. Bottom Coordinate Card & Confirmation Button
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pin_drop, color: Color(0xFFDC2626), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Titik Koordinat Terpilih',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '💡 Ketuk di mana saja pada peta untuk menggeser pin lokasi objek retribusi.',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, _selectedLocation);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'GUNAKAN TITIK LOKASI INI',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

