/// Here, we shall build a custom image loader.
/// There shall be a placeholder widget for when the image is loading,
/// an error widget for when there is a network failure and the actual image widget.
/// Implemented using a [FutureBuilder],
/// Courtesy of https://github.com/onatcipli/meet_network_image

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:async/async.dart';

/// Builds a widget when the connectionState is none and waiting
typedef LoadingBuilder = Widget Function(BuildContext context);

/// Builds a widget if some error occurs
typedef ErrorBuilder = Widget Function(BuildContext context, Object? error);

class MeetNetworkImage extends StatelessWidget {
  /// Image url that you want to show in app
  final String imageUrl;

  /// While the image data is loading from the [imageUrl],
  /// you can build specific widgets with [loadingBuilder]
  final LoadingBuilder loadingBuilder;

  /// When some error occurs while loading from the [imageUrl],
  /// you can build specific error widget with [errorBuilder]
  final ErrorBuilder errorBuilder;

  /// Scale of the image
  final double scale;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  ///
  /// It is strongly recommended that either both the [width] and the [height]
  /// be specified, or that the widget be placed in a context that sets tight
  /// layout constraints, so that the image does not change size as it loads.
  /// Consider using [fit] to adapt the image's rendering to fit the given width
  /// and height if the exact image dimensions are not known in advance.
  final double? width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  ///
  /// It is strongly recommended that either both the [width] and the [height]
  /// be specified, or that the widget be placed in a context that sets tight
  /// layout constraints, so that the image does not change size as it loads.
  /// Consider using [fit] to adapt the image's rendering to fit the given width
  /// and height if the exact image dimensions are not known in advance.
  final double? height;

  /// If non-null, this color is blended with each image pixel using [colorBlendMode].
  final Color? color;

  /// Used to set the [FilterQuality] of the image.
  ///
  /// Use the [FilterQuality.low] quality setting to scale the image with
  /// bilinear interpolation, or the [FilterQuality.none] which corresponds
  /// to nearest-neighbor.
  final FilterQuality filterQuality;

  /// Used to combine [color] with this image.
  ///
  /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
  /// the source and this image is the destination.
  ///
  /// See also:
  ///
  ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
  final BlendMode? colorBlendMode;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit? fit;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while an
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// To display a sub part of an image, consider using a [CustomPainter] and
  /// [Canvas.drawImageRect].
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  final Rect? centerSlice;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// images); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with images in right-to-left environments, for
  /// images that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip images with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  /// Whether to continue showing the old image (true), or briefly show nothing
  /// (false), when the image provider changes.
  final bool gaplessPlayback;

  /// A Semantic description of the image.
  ///
  /// Used to provide a description of the image to TalkBack on Android, and
  /// VoiceOver on iOS.
  final String? semanticLabel;

  /// Whether to exclude this image from semantics.
  ///
  /// Useful for images which do not contribute meaningful information to an
  /// application.
  final bool excludeFromSemantics;

  /// Headers required when loading the image, if any
  final Map<String, String>? headers;

  MeetNetworkImage({
    Key? key,
    required this.imageUrl,
    required this.loadingBuilder,
    required this.errorBuilder,
    this.fit,
    this.color,
    this.width,
    this.height,
    this.headers,
    this.centerSlice,
    this.semanticLabel,
    this.colorBlendMode,
    this.scale = 1.0,
    this.gaplessPlayback = false,
    this.matchTextDirection = false,
    this.alignment = Alignment.center,
    this.excludeFromSemantics = false,
    this.repeat = ImageRepeat.noRepeat,
    this.filterQuality = FilterQuality.low,
  });

  Future<http.Response> getUrlResponse() {
      return this._memoizer.runOnce(() async => http.get(Uri.parse(imageUrl), headers: headers));
  }

  /// This function will check to ensure that the [imageUrl] provided exists
  bool isURLEmpty() => imageUrl != null && imageUrl.isNotEmpty;
  
  final _memoizer = AsyncMemoizer<String>();

  @override
  Widget build(BuildContext context) {
    return isURLEmpty()
        ? errorBuilder(context, "Image URL not provided")
        : FutureBuilder(
            builder:
                (BuildContext context, AsyncSnapshot<http.Response> snapshot) {
              late Widget result;
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  result = loadingBuilder(context);
                  break;
                case ConnectionState.active:
                case ConnectionState.done:
                  if (snapshot.hasError || !snapshot.hasData) {
                    result = errorBuilder(context, snapshot.error);
                  } else {
                    result = Image.memory(
                      snapshot.data!.bodyBytes,
                      scale: scale,
                      height: height,
                      width: width,
                      color: color,
                      fit: fit,
                      alignment: alignment,
                      repeat: repeat,
                      centerSlice: centerSlice,
                      colorBlendMode: colorBlendMode,
                      excludeFromSemantics: excludeFromSemantics,
                      filterQuality: filterQuality,
                      gaplessPlayback: gaplessPlayback,
                      matchTextDirection: matchTextDirection,
                      semanticLabel: semanticLabel,
                    );
                  }
                  break;
              }
              return result;
            },
            future: getUrlResponse(),
          );
  }
}
