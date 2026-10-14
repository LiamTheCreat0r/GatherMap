import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class Map extends StatelessWidget {
  const Map({super.key});
  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      onMapCreated: (MapLibreMapController controller) {
        // controller is now ready
        controller.addGeoJsonSource('IUT', {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'id': 'f1',  // optional, needed for setGeoJsonFeature()
              'properties': {
                'name': 'IUT Toulouse',
                'country': 'France',
              },
              'geometry': {
                'type': 'Point',
                'coordinates': [1.46480387, 43.5703174],  // [lng, lat]
              },
            },
          ],
        });
        controller.addSymbolLayer(
          'IUT',
          'IUT-layer',
          const SymbolLayerProperties(
            //iconImage: 'my-marker',
            iconSize: 1.0,
            iconAnchor: 'bottom',
            iconAllowOverlap: true,
            textField: [Expressions.get, 'name'],
            textSize: 13,
            textOffset: [0, 1.2],
            textAnchor: 'top',
            textHaloColor: '#ffffff',
            textHaloWidth: 2,
          ),
        );
      },
      initialCameraPosition: const CameraPosition(
        target: LatLng(43.57, 1.464),
        zoom: 15,
      ),
      styleString:
          'https://api.maptiler.com/maps/01a1343d-e0c3-7e05-93c1-743d65f9b644/style.json?key=nHhdC9Q6mdTwQ6qo9eiV',
    );
  }
}
