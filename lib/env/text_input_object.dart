import 'package:flutter/material.dart';

class InputTextDecoration{
  static InputDecoration inputDecoration(
  {
    required String lable_Text,
    required String hint_Text,
    required IconData icons
}){
    return InputDecoration(
        labelText: lable_Text,
        labelStyle: const TextStyle(color: Colors.black,fontStyle: FontStyle.italic),
        hintText: hint_Text,
        hintStyle: const TextStyle(color: Colors.black,fontStyle: FontStyle.italic),
        prefixIcon: Icon(icons),
      border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),),focusColor: Colors.red
    );
  }
}