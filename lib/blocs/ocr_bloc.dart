import 'dart:async';
import 'dart:io';

import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
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

    final fixedImage =
    await FlutterExifRotation.rotateAndSaveImage(path: event.path);

    final inputImage = InputImage.fromFilePath(fixedImage.path);
    final recognizedText = await textRecognizer.processImage(inputImage);

    Size imageSize =
        await ImageUtils.getImageSize(Image.file(File(fixedImage.path)));

    String recognizedString = '';

    List<TextLine> detectedProducts = [];

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        detectedProducts.add(line);
      }
    }

    emit(_OCRLoadedState(
        data: state.data.copyWith(
            image: File(fixedImage.path),
            imageSize: imageSize,
            ocrTextLines: detectedProducts,
            ocrTextResult: recognizedString)));
  }
}
