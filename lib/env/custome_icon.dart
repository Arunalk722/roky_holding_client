import 'package:flutter/material.dart';

class LKRIcon extends StatelessWidget {

  const LKRIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      padding: EdgeInsets.only(top: 8,left: 8),
        child: Text(
            'LKR',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ))
    );
  }
}
