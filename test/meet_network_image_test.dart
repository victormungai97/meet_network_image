import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:meet_network_image/meet_network_image.dart';

void main() {
  test('check response bodyBytes', () async {
    String imageUrl =
        "https://random.dog/3f62f2c1-e0cb-4077-8cd9-1ca76bfe98d5.jpg";

    MeetNetworkImage meetNetworkImage = MeetNetworkImage(
      imageUrl: imageUrl,
      loadingBuilder: (BuildContext context) => Container(),
      errorBuilder: (BuildContext context, Object error) => Container(),
    );

    var actualResponse = await meetNetworkImage.getUrlResponse();

    var currentResponse = await http.get(imageUrl);

    expect(currentResponse.bodyBytes, actualResponse.bodyBytes);
  });
}
