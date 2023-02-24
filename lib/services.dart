import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map> classifyRiceImage(String imageBase64) async {
  // Animefy the given image by requesting the gradio API of AnimeGANv2
  final response = await http.post(
    Uri.parse(
        'https://dnth-edgenext-paddy-disease-classifie-dc60651.hf.space/run/predict'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, List<String>>{
      'data': [imageBase64]
    }),
  );

  if (response.statusCode == 200) {
    final classificationResult = jsonDecode(response.body)["data"][0];
    return classificationResult;
    // If the server did return a 200 CREATED response,
    // then decode the image and return it.
    // final imageData = jsonDecode(response.body)["data"][0]
    //     .replaceAll('data:image/png;base64,', '');
    // return base64Decode(imageData);
  } else {
    // If the server did not return a 200 OKAY response,
    // then throw an exception.
    throw Exception('Failed to classify image.');
  }
}
