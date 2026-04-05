import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PlaceMapPreview extends StatelessWidget {
  final double latitude;
  final double longitude;
  final int radiusMeters;

  const PlaceMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.cube23.scratchless',
          ),
          CircleLayer(
            circles: [
              CircleMarker(
                point: point,
                radius: radiusMeters.toDouble(),
                useRadiusInMeter: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.16),
                borderColor: Theme.of(context).colorScheme.primary,
                borderStrokeWidth: 2,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 44,
                height: 44,
                child: Icon(
                  Icons.location_on_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
