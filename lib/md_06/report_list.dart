import 'package:flutter/material.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/md_06/project_wise_dashboard.dart';
import 'package:roky_holding/md_06/project_wise_estimate_Item_Consume.dart';
import 'package:roky_holding/md_06/view_iou_screen.dart';
import 'package:roky_holding/md_06/office_iou_list.dart';
import 'package:roky_holding/md_06/project_wise_item_request_list.dart';
import 'package:roky_holding/md_06/view_project_wise_request_list.dart';
import 'package:roky_holding/md_06/view_location_estimation.dart';
import 'package:roky_holding/md_06/view_material_list.dart';

import 'office_iou_items_list.dart';

class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appname: 'Reports'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(  // Center content within the screen
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Select a Report",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                       // _buildReportCard(context, "Project Report", Icons.assignment, Colors.blue, ProjectReportPage()),
                        //_buildReportCard(context, "Location Wise Report", Icons.location_on, Colors.green, LocationReportPage()),

                        _buildReportCard(context, "Estimation Report", Icons.calculate, Colors.orange, ViewLocationWiseEstimationPage(isEdit: false,)),
                        _buildReportCard(context, "Material Report", Icons.inventory, Colors.redAccent, ViewMaterialListPage(isEdit: false,)),
                        _buildReportCard(context, "View Project Wise Request List", Icons.visibility, Colors.pink, ProjectPaymentRequestReportScreen()),
                        _buildReportCard(context, "Project Wise Item Request List", Icons.list, Colors.pink.shade100, ProjectPaymentRequestItemsReportScreen()),
                        _buildReportCard(context, "View Office IOU", Icons.local_post_office, Colors.black54, OfficeIOUList()),
                        _buildReportCard(context, "View IOU List", Icons.visibility, Colors.pink, ViewIOUScreen()),
                        _buildReportCard(context, "Project Dashboard", Icons.dashboard, Colors.pink, ProjectDashboard()),
                        _buildReportCard(context, "Item Consume", Icons.request_page_outlined, Colors.orangeAccent, ProjectWiseEstimateItemConsume(isEdit: false,)),
                        _buildReportCard(context, "Office IOU Items", Icons.request_page_outlined, Colors.grey, OfficeIOUItemsList()),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, IconData icon, Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 160,
        height: 100,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy report pages (Replace with actual report pages)
class ProjectReportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Project Report")),
      body: const Center(child: Text("Project Report Page")),
    );
  }
}

class LocationReportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location Wise Report")),
      body: const Center(child: Text("Location Wise Report Page")),
    );
  }
}


class MaterialReportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Material Report")),
      body: const Center(child: Text("Material Report Page")),
    );
  }
}


