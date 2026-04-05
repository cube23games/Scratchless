import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

class PlacePinConfirmScreen extends StatefulWidget {
  final LatLng initialPoint;
  final String placeLabel;

  const PlacePinConfirmScreen({
    super.key,
    required this.initialPoint,
    required this.placeLabel,
  });

  @override
  State<PlacePinConfirmScreen> createState() => _PlacePinConfirmScreenState();
}

class _PlacePinConfirmScreenState extends State<PlacePinConfirmScreen> {
  late LatLng _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
  }

  String _coordLabel(double value) => value.toStringAsFixed(6);

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
                        'Tap the map to move the saved point, then use this location when it looks right.',
                        style: TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 14,
                        ),
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
                    Navigator.of(context).pop(_selectedPoint);
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
