import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/app_theme.dart';
import '../../core/services/distance_formatter_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

class PlacePinConfirmResult {
  final LatLng point;
  final int radiusMeters;

  const PlacePinConfirmResult({
    required this.point,
    required this.radiusMeters,
  });
}

class PlacePinConfirmScreen extends StatefulWidget {
  final LatLng initialPoint;
  final String placeLabel;
  final int radiusMeters;

  const PlacePinConfirmScreen({
    super.key,
    required this.initialPoint,
    required this.placeLabel,
    required this.radiusMeters,
  });

  @override
  State<PlacePinConfirmScreen> createState() => _PlacePinConfirmScreenState();
}

class _PlacePinConfirmScreenState extends State<PlacePinConfirmScreen> {
  static const List<_RadiusPreset> _radiusPresets = <_RadiusPreset>[
    _RadiusPreset(label: 'Small', meters: 150),
    _RadiusPreset(label: 'Medium', meters: 300),
    _RadiusPreset(label: 'Large', meters: 500),
  ];

  late LatLng _selectedPoint;
  late int _radiusMeters;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
    _radiusMeters = widget.radiusMeters;
  }

  String _coordLabel(double value) => value.toStringAsFixed(6);

  String _confidenceHint() {
    if (_radiusMeters <= 150) {
      return 'This is a tighter alert area. Check the pin if nearby stores are close together.';
    }
    if (_radiusMeters <= 300) {
      return 'Exact enough for most live alerts. Check the pin if the stop is large or close to other stores.';
    }
    return 'This is a wider alert area. Tighten it if you want a smaller live alert zone.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm on map'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pin confirmation',
                        style: TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.placeLabel.isEmpty
                            ? 'Confirm this place on the map'
                            : 'Confirm ${widget.placeLabel} on the map',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the map to move the center point. Use the size buttons to tighten or widen the alert area.',
                        style: TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alert size',
                        style: TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _radiusPresets.map((preset) {
                          return ChoiceChip(
                            label: Text(
                              '${preset.label} • ${DistanceFormatterService.usPlaceRadiusLabel(preset.meters)}',
                            ),
                            selected: _radiusMeters == preset.meters,
                            onSelected: (_) {
                              setState(() {
                                _radiusMeters = preset.meters;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 360,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _selectedPoint,
                        initialZoom: 16,
                        onTap: (_, point) {
                          setState(() {
                            _selectedPoint = point;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.cube23.scratchless',
                        ),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _selectedPoint,
                              radius: _radiusMeters.toDouble(),
                              useRadiusInMeter: true,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.16),
                              borderColor:
                                  Theme.of(context).colorScheme.primary,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedPoint,
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.location_on_rounded,
                                size: 42,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected coordinates',
                        style: TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lat ${_coordLabel(_selectedPoint.latitude)} • Lng ${_coordLabel(_selectedPoint.longitude)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Alert radius: ${DistanceFormatterService.usPlaceRadiusLabel(_radiusMeters)}',
                        style: const TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _confidenceHint(),
                        style: const TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                AppButton(
                  label: 'Use this location',
                  icon: Icons.check_rounded,
                  onPressed: () {
                    Navigator.of(context).pop(
                      PlacePinConfirmResult(
                        point: _selectedPoint,
                        radiusMeters: _radiusMeters,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadiusPreset {
  final String label;
  final int meters;

  const _RadiusPreset({
    required this.label,
    required this.meters,
  });
}
