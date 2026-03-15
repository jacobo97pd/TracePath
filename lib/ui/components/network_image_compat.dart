import 'package:flutter/widgets.dart';

import 'network_image_compat_stub.dart'
    if (dart.library.html) 'network_image_compat_web.dart' as impl;

Widget buildNetworkImageCompat({
  required String url,
  required BoxFit fit,
  required FilterQuality filterQuality,
  Widget? fallback,
}) {
  return impl.buildNetworkImageCompat(
    url: url,
    fit: fit,
    filterQuality: filterQuality,
    fallback: fallback,
  );
}

