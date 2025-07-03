import 'package:flutter/material.dart';



class HomePage extends StatefulWidget {
  final bool isAdvance;

  const HomePage({super.key, required this.isAdvance});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isAdvancedLayout = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isAdvancedLayout = widget.isAdvance;


    });
  }


  @override
  Widget build(BuildContext context) {
   return Scaffold();
  }
 }

class _TileInfo {
  final String permissionKey;
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  Color color;
  _TileInfo({
    required this.color,
    required this.permissionKey,
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

