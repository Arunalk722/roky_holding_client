import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String appname;
  const MyAppBar({super.key, required this.appname,required });
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),

      title: Text( // Use appname here
        appname, // Dynamic title
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      elevation: 5.0,
      shadowColor: Colors.black26,
      // leading: IconButton(
      //   icon: const Icon(Icons.menu, color: Colors.white),
      //   onPressed: () {
      //     // Handle menu press
      //   },
      // ),

      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            // Handle search
          },
        ),
      ],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}


class ControllerWithAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String appname;
  final TabController tabController;

  const ControllerWithAppBar({required this.appname, required this.tabController, super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Text(
        appname, // Dynamic title
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      elevation: 5.0,
      shadowColor: Colors.black,
      bottom: TabBar(
        controller: tabController,
        tabs: const [
          Tab(text: 'Request Form'),
          Tab(text: 'Item Selection'),
          Tab(text: 'Post'),
        ],
        labelColor: Colors.white, // Active tab color
        unselectedLabelColor: Colors.black, // Inactive tab color
        indicatorColor: Colors.black, // Tab indicator color
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: () {
            // Handle search functionality
          },
        ),
      ],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }


  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 50.0); // Adds space for TabBar
}
