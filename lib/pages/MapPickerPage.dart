import 'package:azkar_new_app/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Interactive location picker. Tiles need network (OSM, attributed);
/// offline users keep the manual city list as the reliable fallback.
/// Nothing is saved until the user confirms.
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({
    super.key,
    required this.initial,
    required this.onConfirm,
    this.onCancel,
  });

  final LatLng initial;
  final ValueChanged<LatLng> onConfirm;
  final VoidCallback? onCancel;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late LatLng _picked;
  final MapController _controller = MapController();

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار الموقع'),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'إلغاء',
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onCancel?.call();
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: MapPickerMap(
              controller: _controller,
              center: _picked,
              onPicked: (p) => setState(() => _picked = p),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${_picked.latitude.toStringAsFixed(4)}، ${_picked.longitude.toStringAsFixed(4)}',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onConfirm(_picked);
                      Navigator.of(context).maybePop();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('تأكيد'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: () {
                      widget.onCancel?.call();
                      Navigator.of(context).maybePop();
                    },
                    child: const Text('إلغاء'),
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

/// The tappable map surface (separated for tests).
class MapPickerMap extends StatelessWidget {
  const MapPickerMap({
    super.key,
    required this.controller,
    required this.center,
    required this.onPicked,
  });

  final MapController controller;
  final LatLng center;
  final ValueChanged<LatLng> onPicked;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 11,
        onTap: (_, latlng) => onPicked(latlng),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.azkar_new_app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 48,
              height: 48,
              child: const Icon(Icons.location_on, size: 48, color: Colors.red),
            ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
        ),
      ],
    );
  }
}
