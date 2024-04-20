import 'dart:async';
import 'dart:io';

import 'package:ocr_module/utils/image_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../utils/text_processing_utils.dart';

part 'ocr_bloc.freezed.dart';

part 'ocr_event.dart';

part 'ocr_state.dart';

class OCRBloc extends Bloc<OCREvent, OCRState> {
  final TextRecognizer textRecognizer;

  OCRBloc({required this.textRecognizer}) : super(const _OCRInitialState()) {
    on<ProcessImageEvent>(_processImage);
    on<ChangeBillTypeEvent>(_changeBillType);
  }

  void _changeBillType(ChangeBillTypeEvent event, Emitter<OCRState> emit) {
    emit(OCRState.loading(data: state.data));

    if (state.data.image == null) {
      emit(OCRState.loaded(
          data: state.data.copyWith(
              ocrTextResult: '', ocrTextLines: [], billType: event.type)));
      return;
    }

    emit(OCRState.loaded(data: state.data.copyWith(billType: event.type)));

    add(ProcessImageEvent(path: state.data.image!.path));
  }

  Future<void> _processImage(
      ProcessImageEvent event, Emitter<OCRState> emit) async {
    emit(_OCRLoadingState(
        data: state.data.copyWith(ocrTextResult: '', ocrTextLines: [])));

    final inputImage = InputImage.fromFilePath(event.path);
    final recognizedText = await textRecognizer.processImage(inputImage);

    Size imageSize =
        await ImageUtils.getImageSize(Image.file(File(event.path)));

    String recognizedString = '';

    List<TextLine> detectedProducts = [];

    List<TextLine> filteredProducts = [];

    List<TextLine> possibleTop = [];

    List<TextLine> possibleBottom = [];

    ///Grouping detected texts
    ///TODO: Separate logic
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        if (OCRResultFilterUtils.isInList(
            line.text, state.data.billType.textTop)) {
          possibleTop.add(line);
          continue;
        } else if (OCRResultFilterUtils.isInList(
            line.text, state.data.billType.textBottom)) {
          possibleBottom.add(line);
          continue;
        }
        if (int.tryParse(line.text
              ..replaceAll('.', '')
              ..replaceAll(',', '')
              ..replaceAll('d', '')) ==
            null) {
          detectedProducts.add(line);
        }
      }
    }

    print(possibleBottom.map((e) => e.text));
    print(possibleTop.map((e) => e.text));

    double? maxTop = OCRResultFilterUtils.getMaxCoordinate(possibleTop);
    double? maxBottom = OCRResultFilterUtils.getMinCoordinate(possibleBottom);
    double? rightBoundary = OCRResultFilterUtils.findAndGetRightCoordinate(
        s3fnbBillTop[1], possibleTop);

    print(maxTop);
    print(maxBottom);

    ///Filter text within specific coordinations
    ///TODO: Separate logic and refactor
    if (maxTop == null && maxBottom == null) {
      filteredProducts.addAll(detectedProducts);
    } else if (maxTop != null && maxBottom == null) {
      filteredProducts.addAll(detectedProducts.where((element) =>
          element.boundingBox.top > maxTop &&
          (rightBoundary != null
              ? element.boundingBox.right < rightBoundary
              : true)));
    } else if (maxTop == null && maxBottom != null) {
      filteredProducts.addAll(detectedProducts.where((element) =>
          element.boundingBox.bottom < maxBottom &&
          (rightBoundary != null
              ? element.boundingBox.right < rightBoundary
              : true)));
    } else if (maxTop != null && maxBottom != null) {
      filteredProducts.addAll(detectedProducts.where((element) =>
          element.boundingBox.top > maxTop &&
          element.boundingBox.bottom < maxBottom &&
          (rightBoundary != null
              ? element.boundingBox.right < rightBoundary
              : true)));
    }

    emit(_OCRLoadedState(
        data: state.data.copyWith(
            image: File(event.path),
            imageSize: imageSize,
            ocrTextLines: filteredProducts,
            ocrTextResult: recognizedString)));
  }
}
