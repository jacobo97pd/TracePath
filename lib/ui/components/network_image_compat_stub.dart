import 'package:flutter/widgets.dart';

Widget buildNetworkImageCompat({
  required String url,
  required BoxFit fit,
  required FilterQuality filterQuality,
  Widget? fallback,
}) {
  return Image.network(
    url,
    fit: fit,
    filterQuality: filterQuality,
    errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
  );
}

