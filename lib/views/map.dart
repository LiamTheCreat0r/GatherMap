import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class Map extends StatelessWidget{
  const Map({super.key});
  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(51.2, 27.2),
        zoom: 5,
      ),
      styleString: 'https://api.maptiler.com/maps/01a1343d-e0c3-7e05-93c1-743d65f9b644/style.json?key={key}',
    );
  }
}