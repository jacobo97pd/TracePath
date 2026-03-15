import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

int _webImageViewCounter = 0;

Widget buildNetworkImageCompat({
  required String url,
  required BoxFit fit,
  required FilterQuality filterQuality,
  Widget? fallback,
}) {
  return _WebCompatNetworkImage(
    url: url,
    fit: fit,
    fallback: fallback,
  );
}

String _objectFitToCss(BoxFit fit) {
  switch (fit) {
    case BoxFit.cover:
      return 'cover';
    case BoxFit.contain:
      return 'contain';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.fitHeight:
      return 'scale-down';
    case BoxFit.fitWidth:
      return 'scale-down';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
  }
}

class _WebCompatNetworkImage extends StatefulWidget {
  const _WebCompatNetworkImage({
    required this.url,
    required this.fit,
    this.fallback,
  });

  final String url;
  final BoxFit fit;
  final Widget? fallback;

  @override
  State<_WebCompatNetworkImage> createState() => _WebCompatNetworkImageState();
}

class _WebCompatNetworkImageState extends State<_WebCompatNetworkImage> {
  late String _viewType;
  late html.ImageElement _image;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initImageElement();
  }

  @override
  void didUpdateWidget(covariant _WebCompatNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.fit != widget.fit) {
      _initImageElement();
    }
  }

  void _initImageElement() {
    _failed = false;
    _viewType = 'tracepath-netimg-${_webImageViewCounter++}';
    _image = html.ImageElement()
      ..src = widget.url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = _objectFitToCss(widget.fit)
      ..style.display = 'block'
      ..style.pointerEvents = 'none'
      ..draggable = false;

    _image.onError.first.then((_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
      });
    });

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return _image;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.fallback ?? const SizedBox.shrink();
    }
    return HtmlElementView(viewType: _viewType);
  }
}
