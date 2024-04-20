interface OcrModule {
  startFlutterActivity: (callback: (text: string[]) => void) => void;
}

export default OcrModule;