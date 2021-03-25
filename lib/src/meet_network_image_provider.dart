/// Here, we shall build a custom ImageProvider.
/// This class shall be essential in loading an image from a url
/// and then using that image in an [ImageProvider] setting.
/// In case of network failure, a placeholder asset image file shall be loaded.
/// Courtesy of: https://github.com/renefloor/flutter_cached_network_image/blob/master/lib/src/cached_network_image_provider.dart

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui show instantiateImageCodec, Codec;

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '_multi_image_stream_completer.dart';

/// Builds a function to be called in case of network failure
typedef void ErrorListener();

class MeetNetworkImageProvider extends ImageProvider<MeetNetworkImageProvider> {
  /// Web url of the image to load
  final String imageUrl;

  /// Scale of the image
  final double scale;

  /// Target image width to which the image shall be scaled after decoding
  final int width;

  /// Target image height to which the image shall be scaled after decoding
  final int height;

  /// Listener to be called when image fails to load
  final ErrorListener errorListener;

  /// Set optional headers for the image provider, eg for authentication
  final Map<String, String> headers;

  /// Path to placeholder asset image file.
  /// Should be non-null so as to be loaded in case of network failure
  final String placeholderAssetPath;

  /// Creates an [ImageProvider] which loads an image from the [_url], using the [scale].
  /// When the image fails to load, [errorListener] is called.
  const MeetNetworkImageProvider({
    @required this.imageUrl,
    this.scale = 1.0,
    this.width,
    this.height,
    this.headers,
    this.errorListener,

    /// Cache key of the image to cache. Unused here
    String cacheKey,
    @required this.placeholderAssetPath,
  })  : assert(imageUrl != null),
        assert(scale != null),
        assert(placeholderAssetPath != null);

  /// This function will check to ensure that the [imageUrl] provided exists
  bool isURLEmpty() => imageUrl == null || imageUrl == "" || imageUrl.isEmpty;

  @override
  Future<MeetNetworkImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<MeetNetworkImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(
      MeetNetworkImageProvider key, DecoderCallback decode) {
    return MultiImageStreamCompleter(
      chunkEvents: StreamController<ImageChunkEvent>().stream,
      codec: _loadAsync(key),
      scale: key.scale,
      informationCollector: _imageStreamInformationCollector(key),
    );
  }

  InformationCollector _imageStreamInformationCollector(
      MeetNetworkImageProvider key) {
    InformationCollector collector;
    assert(() {
      collector = () {
        return <DiagnosticsNode>[
          DiagnosticsProperty<ImageProvider>('Image provider', this),
          DiagnosticsProperty<MeetNetworkImageProvider>('Image key', key),
        ];
      };
      return true;
    }());
    return collector;
  }

  /// This will print errors to console
  void logError(String code, String message) =>
      print('Error: $code\nError Message: $message');

  Future<ui.Codec> _loadPlaceholderAsset() async {
    try {
      ByteData byteData = await rootBundle.load(placeholderAssetPath);
      Uint8List bytes = byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      return await ui.instantiateImageCodec(bytes,
          targetHeight: height, targetWidth: width);
    } catch (err) {
      print("Error!!:\t$err");
      return Future<ui.Codec>.error("Couldn't download or retrieve file");
    }
  }

  Future<ui.Codec> _loadAsync(MeetNetworkImageProvider key) async {
    assert(key == this);
    if (isURLEmpty()) return await _loadPlaceholderAsset();
    try {
      final response = await http.get(Uri.parse(imageUrl), headers: headers);
      if (response == null || response.statusCode != 200) {
        if (errorListener != null) {
          errorListener();
        } else {
          print('${response.statusCode ?? "NETWORK ERROR!!"}\t' +
              '${response.body ?? "Nothing received"}');
        }
        return Future<ui.Codec>.error("Couldn't download or retrieve file");
      }
      return await _loadAsyncFromResponse(key, response);
    } catch (err) {
      print('NYWELE IMAGE PROVIDER ERROR!!\n$err');
      errorListener?.call();
      return await _loadPlaceholderAsset();
    }
  }

  Future<ui.Codec> _loadAsyncFromResponse(
      MeetNetworkImageProvider key, http.Response response) async {
    assert(key == this);

    Uint8List bytes;
    bytes = response.bodyBytes;

    if (bytes.lengthInBytes == 0) {
      if (errorListener != null) {
        errorListener();
      } else {
        logError("NETWORK ERROR!!", "Response was empty");
      }
      return await _loadPlaceholderAsset();
    }

    return await ui.instantiateImageCodec(bytes,
        targetHeight: height, targetWidth: width);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final MeetNetworkImageProvider typedOther = other;
    return imageUrl == typedOther.imageUrl &&
        scale == typedOther.scale &&
        width == typedOther.width &&
        height == typedOther.height;
  }

  @override
  int get hashCode => hashValues(imageUrl, scale);

  @override
  String toString() => "$runtimeType('$imageUrl', scale: $scale)";
}
