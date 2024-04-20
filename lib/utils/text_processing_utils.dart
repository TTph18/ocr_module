import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'character_utils.dart';

extension TextLineJsonMethod on TextLine {
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'elements': elements.map((element) => element.toJson()).toList(),
      'rect': boundingBox.toJson(),
      'recognizedLanguages': recognizedLanguages,
      'points': cornerPoints.map((point) => [point.x, point.y]).toList(),
      'angle': angle,
    };
  }
}

extension TextElementJsonMethod on TextElement {
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'rect': boundingBox.toJson(),
      'recognizedLanguages': recognizedLanguages,
      'points': cornerPoints.map((point) => [point.x, point.y]).toList(),
      'confidence': confidence,
      'angle': angle,
    };
  }
}

extension RectJsonMethod on Rect {
  Map<String, dynamic> toJson() {
    return {
      'top': top,
      'left': left,
      'right': right,
      'bottom': bottom,
      'width': width,
      'height': height,
    };
  }
}

enum BillType {
  S3FNB('s3fnb', s3fnbBillTop, s3fnbBillBottom),
  GRAB('Grab', grabFoodTop, grabFoodBottom),
  SHOPEE('ShopeeFood', shopeeFoodTop, shopeeFoodBottom);

  const BillType(this.name, this.textTop, this.textBottom);

  final String name;
  final List<String> textTop;
  final List<String> textBottom;
}

const List<String> s3fnbBillTop = ['ten sp', 'so luong', 'thanh tien'];
const List<String> s3fnbBillBottom = [
  'tam tinh',
  'giam gia',
  'tong tien thanh toan',
  'ghi chu'
];

const List<String> shopeeFoodTop = ['mon', 'tong tien', 'gia'];
const List<String> shopeeFoodBottom = [
  'tong mon',
  'tong tien mon (gia goc)',
  'tong tien mon',
  'giam gia mon',
  'tong tien'
];

///TODO: Gab top undefined
const List<String> grabFoodTop = [];
const List<String> grabFoodBottom = [
  'tong (tam tinh)',
  'giam gia',
  'tong cong'
];

///Class contain method for filtering OCR text result
abstract class OCRResultFilterUtils {
  ///Evaluate if text belong to the compareList
  ///Base on identical point
  static bool isInList(String text, List<String> compareList) {
    String normalizedText = CharacterUtil.parse(text);
    for (String text in compareList) {
      int numberOfIdentical = 0;

      if ((text.length - normalizedText.length).abs() < 5) numberOfIdentical++;
      if (normalizedText.contains(text)) numberOfIdentical++;
      if (CharacterUtil.evaluateStringDiffer(text, normalizedText)) {
        numberOfIdentical++;
      }

      if (numberOfIdentical >= 2) return true;
    }
    return false;
  }

  ///Method to get maximum top coordination in a list
  static double? getMaxCoordinate(List<TextLine> textLines) {
    if (textLines.isEmpty) return null;

    List<double> topCoordinates =
        textLines.map((textLine) => textLine.boundingBox.top).toList();

    double maximumTop;
    double minimumTop;
    double threshold = 10.0;

    // Repeat the process until only one coordinate remains
    while (topCoordinates.length > 1) {
      maximumTop = topCoordinates
          .reduce((value, element) => value > element ? value : element);
      minimumTop = topCoordinates
          .reduce((value, element) => value < element ? value : element);

      // Check if all items have approximately the same top coordinate
      if (maximumTop - minimumTop > threshold) {
        // If an item is significantly higher than others, exclude it
        topCoordinates.remove(maximumTop);
      } else {
        // If all items have approximately the same top coordinate, return it
        return maximumTop;
      }
    }

    // If only one coordinate remains after filtering, return it
    return topCoordinates.first;
  }

  static double? getMinCoordinate(List<TextLine> textLines) {
    if (textLines.isEmpty) return null;

    List<double> topCoordinates =
        textLines.map((textLine) => textLine.boundingBox.top).toList();

    double maximumTop;
    double minimumTop;
    double threshold = 10.0;

    // Repeat the process until only one coordinate remains
    while (topCoordinates.length > 1) {
      maximumTop = topCoordinates
          .reduce((value, element) => value > element ? value : element);
      minimumTop = topCoordinates
          .reduce((value, element) => value < element ? value : element);

      // Check if all items have approximately the same top coordinate
      if (maximumTop - minimumTop > threshold) {
        // If an item is significantly higher than others, exclude it
        topCoordinates.remove(maximumTop);
      } else {
        // If all items have approximately the same top coordinate, return it
        return minimumTop;
      }
    }

    // If only one coordinate remains after filtering, return it
    return topCoordinates.first;
  }

  ///Method look for the input target in a list and return its right coordination
  ///Return right coordination if found
  ///Return null if none satisfy
  static double? findAndGetRightCoordinate(
      String target, List<TextLine> textLines) {
    List<TextLine> compareList = textLines.map((textLine) => textLine).toList();

    while (compareList.length > 1) {
      if (CharacterUtil.evaluateStringDiffer(target, compareList.last.text)) {
        return compareList.last.boundingBox.right;
      } else {
        compareList.removeLast();
      }
    }

    return null;
  }

  static String filterParenthesesText(String input) {
    // Define a regular expression to match text inside parentheses
    RegExp regex = RegExp(r'\([^)]*\)');

    // Replace all matches of the regular expression with an empty string
    return input.replaceAll(regex, '');
  }
}
