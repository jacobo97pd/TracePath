class UrbanGraffitiTrail {
  const UrbanGraffitiTrail._();

  static const String id = 'trail_urban_graffiti';
  static const String name = 'UrbanGraffitiTrail';
  static const bool debugUrbanGraffiti = false;

  static const Map<String, String> assetPaths = <String, String>{
    'graffitiSplash': 'assets/trails/urban_graffiti/graffiti_splash.png',
    'graffitiTag01': 'assets/trails/urban_graffiti/graffiti_tag_01.png',
    'paintDrip': 'assets/trails/urban_graffiti/paint_drip.png',
    'spraySoft': 'assets/trails/urban_graffiti/spray_soft.png',
  };

  static const List<String> requiredAssetKeys = <String>[
    'graffitiSplash',
    'graffitiTag01',
    'paintDrip',
    'spraySoft',
  ];
}
