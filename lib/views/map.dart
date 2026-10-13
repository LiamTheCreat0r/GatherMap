import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Map extends StatelessWidget{
  const Map({super.key});
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
    options: MapOptions(
      initialCenter: LatLng(51.509364, -0.128928), // Center the map over London, UK
      initialZoom: 9.2,
    ),
    children: [
      TileLayer( // Bring your own tiles
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', 
        userAgentPackageName: 'org.yourdomain.gathermap',// For demonstration only
        // And many more recommended properties!
      ),
      const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('© OpenStreetMap contributors'),
          ],
      ),
    ],
    );
  }
}