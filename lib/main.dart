import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:empty_widget/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'widgets.dart';
import 'utils.dart';

final List<String> imgList = [
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/bacterial_leaf_blight/100023.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/bacterial_leaf_blight/100049.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/bacterial_leaf_streak/100042.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/bacterial_leaf_streak/100084.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/bacterial_panicle_blight/100043.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/bacterial_panicle_blight/100058.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/blast/100004.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/blast/100006.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/brown_spot/100022.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/brown_spot/100001.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/dead_heart/100008.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/dead_heart/100020.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/downy_mildew/100031.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/downy_mildew/100017.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/hispa/100003.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/hispa/100005.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/normal/100007.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/normal/100002.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/tungro/100011.jpg',
  'https://raw.githubusercontent.com/dnth/huggingface-timm-mobile-blogpost/main/sample_images/tungro/100013.jpg'
];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paddy Disease Classifier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Paddy Disease Classifier'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();

  String? _resultString;
  Map _resultDict = {
    "label": "None",
    "confidences": [
      {"label": "None", "confidence": 0.0},
      {"label": "None", "confidence": 0.0},
      {"label": "None", "confidence": 0.0}
    ]
  };

  File? imageURI; // Show on image widget on app
  Uint8List? imgBytes; // Store img to be sent for api inference
  bool isClassifying = false;

  String parseResultsIntoString(Map results) {
    return """
    ${results['confidences'][0]['label']} - ${(results['confidences'][0]['confidence'] * 100.0).toStringAsFixed(2)}% \n
    ${results['confidences'][1]['label']} - ${(results['confidences'][1]['confidence'] * 100.0).toStringAsFixed(2)}% \n
    ${results['confidences'][2]['label']} - ${(results['confidences'][2]['confidence'] * 100.0).toStringAsFixed(2)}% """;
  }

  clearInferenceResults() {
    _resultString = "";
    _resultDict = {
      "label": "None",
      "confidences": [
        {"label": "None", "confidence": 0.0},
        {"label": "None", "confidence": 0.0},
        {"label": "None", "confidence": 0.0}
      ]
    };
  }

  Widget buildModalBtmSheetItems() {
    return SizedBox(
      height: 120,
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text("Camera"),
            onTap: () async {
              final XFile? pickedFile =
                  await ImagePicker().pickImage(source: ImageSource.camera);

              if (pickedFile != null) {
                // Clear result of previous inference as soon as new image is selected
                setState(() {
                  clearInferenceResults();
                });

                File croppedFile = await cropImage(pickedFile);
                final imgFile = File(croppedFile.path);

                setState(() {
                  imageURI = imgFile;
                  _btnController.stop();
                  isClassifying = false;
                });
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text("Gallery"),
            onTap: () async {
              final XFile? pickedFile =
                  await ImagePicker().pickImage(source: ImageSource.gallery);

              if (pickedFile != null) {
                // Clear result of previous inference as soon as new image is selected
                setState(() {
                  clearInferenceResults();
                });

                File croppedFile = await cropImage(pickedFile);
                final imgFile = File(croppedFile.path);

                setState(
                  () {
                    imageURI = imgFile;
                    _btnController.stop();
                    isClassifying = false;
                  },
                );
                Navigator.pop(context);
              }
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> imageSliders = imgList
        .map((item) => Container(
              margin: const EdgeInsets.all(5.0),
              child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                  child: Stack(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () async {
                          context.loaderOverlay.show();

                          String imgUrl = imgList[imgList.indexOf(item)];

                          final imgFile = await getImage(imgUrl);

                          setState(() {
                            imageURI = imgFile;
                            _btnController.stop();
                            isClassifying = false;
                            clearInferenceResults();
                          });
                          context.loaderOverlay.hide();
                        },
                        child: CachedNetworkImage(
                          imageUrl: item,
                          fit: BoxFit.fill,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                      Positioned(
                        bottom: 0.0,
                        left: 0.0,
                        right: 0.0,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(200, 0, 0, 0),
                                Color.fromARGB(0, 0, 0, 0)
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 20.0),
                          child: Text(
                            'GT: ${imgList[imgList.indexOf(item)].split('/').reversed.elementAt(1)}', // get the class name from url
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
            ))
        .toList();

    return LoaderOverlay(
      child: Scaffold(
        drawer: const Drawer(),
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              imageURI == null
                  ? SizedBox(
                      height: 200,
                      child: EmptyWidget(
                        image: null,
                        packageImage: PackageImage.Image_3,
                        title: 'No image',
                        // subTitle: 'Select an image or upload your own',
                        titleTextStyle: const TextStyle(
                          fontSize: 15,
                          color: Color(0xff9da9c7),
                          fontWeight: FontWeight.w500,
                        ),
                        subtitleTextStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xffabb8d6),
                        ),
                      ),
                    )
                  : Image.file(imageURI!, height: 200, fit: BoxFit.cover),
              const SizedBox(
                height: 10,
              ),
              Text("Top 3 predictions",
                  style: Theme.of(context).textTheme.headline6),
              const SizedBox(height: 20),
              buildResultsIndicators(_resultDict),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Samples",
                    style: Theme.of(context).textTheme.headline6),
              ),
              CarouselSlider(
                options: CarouselOptions(
                  height: 180,
                  autoPlay: true,
                  // aspectRatio: 2.5,
                  viewportFraction: 0.4,
                  enlargeCenterPage: false,
                  enlargeStrategy: CenterPageEnlargeStrategy.height,
                ),
                items: imageSliders,
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: RoundedLoadingButton(
                  width: MediaQuery.of(context).size.width * 0.5,
                  color: Colors.blue,
                  successColor: Colors.green,
                  // resetAfterDuration: true,
                  // resetDuration: const Duration(seconds: 10),
                  child: const Text('Classify!',
                      style: TextStyle(color: Colors.white)),
                  controller: _btnController,
                  onPressed: isClassifying || imageURI == null
                      ? null // null value disables the button
                      : () async {
                          isClassifying = true;

                          imgBytes = imageURI!.readAsBytesSync();
                          String base64Image = "data:image/png;base64," +
                              base64Encode(imgBytes!);

                          try {
                            final result = await classifyRiceImage(base64Image);

                            setState(() {
                              _resultString = parseResultsIntoString(result);
                              _resultDict = result;
                            });
                            _btnController.success();
                          } catch (e) {
                            _btnController.error();
                          }
                          isClassifying = false;
                        },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.camera),
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              builder: (BuildContext context) {
                return buildModalBtmSheetItems();
              },
            );
          },
        ),
      ),
    );
  }
}
