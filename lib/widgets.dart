import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

Widget buildPercentIndicator(String className, double classConfidence) {
  return LinearPercentIndicator(
    width: 200.0,
    lineHeight: 18.0,
    percent: classConfidence,
    center: Text(
      "${(classConfidence * 100.0).toStringAsFixed(2)} %",
      style: const TextStyle(fontSize: 12.0),
    ),
    trailing: Text(className),
    leading: const Icon(Icons.arrow_forward_ios),
    // linearStrokeCap: LinearStrokeCap.roundAll,
    backgroundColor: Colors.grey,
    progressColor: Colors.blue,
    animation: true,
  );
}

Widget buildResultsIndicators(Map resultsDict) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildPercentIndicator(resultsDict['confidences'][0]['label'],
          (resultsDict['confidences'][0]['confidence'])),
      buildPercentIndicator(resultsDict['confidences'][1]['label'],
          (resultsDict['confidences'][1]['confidence'])),
      buildPercentIndicator(resultsDict['confidences'][2]['label'],
          (resultsDict['confidences'][2]['confidence']))
    ],
  );
}
