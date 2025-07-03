import 'package:flutter/foundation.dart';

class PD{
  static void pd({required String text}){
    if (kDebugMode) {
      print(text);
    }
  }
}