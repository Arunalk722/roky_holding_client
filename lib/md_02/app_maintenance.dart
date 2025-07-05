import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_bar.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';

class AppMaintenanceScreen extends StatefulWidget {
  const AppMaintenanceScreen({super.key});

  @override
  State<AppMaintenanceScreen> createState() => _AppMaintenanceScreenState();
}

class _AppMaintenanceScreenState extends State<AppMaintenanceScreen> {

  Future<void> backUp() async {
    WaitDialog.showWaitDialog(context, message: 'Backing up..');
    try {
      final response = await http.post(
        Uri.parse('${APIHost().apiURL}/backup_controller.php/DBBackUp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
        }),
      );
      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        final int status = responseData['status'];
        if (status == 200) {
          OneBtnDialog.oneButtonDialog(context, title: 'database backup', message: '${responseData['message']} \nfile:${responseData['file']}', btnName: 'OK', icon: Icons.verified, iconColor: Colors.green, btnColor: Colors.black);
        }
      }
      else {
        WaitDialog.hideDialog(context);
        final String message = 'backup failed';
        PD.pd(text: message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to backup: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, st) {
      WaitDialog.hideDialog(context);
      ExceptionLogger.logToError(
        message: e.toString(),
        errorLog: st.toString(),
        logFile: 'app_maintenance.dart',
      );
      String errorMessage = 'An error occurred during backup: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      PD.pd(text: errorMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appname: 'App Maintenance'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _buildActionCard(
                    icon: Icons.backup_rounded,
                    title: 'Backup Database',
                    subtitle: 'Secure a full backup now',
                    color: Colors.black,
                    onTap: () {
                      backUp();
                    },
                  ),
                  // _buildActionCard(
                  //   icon: Icons.cleaning_services_rounded,
                  //   title: 'Clear Logs',
                  //   subtitle: 'Delete unnecessary log data',
                  //   color: Colors.black,
                  //   onTap: () {},
                  // ),
                  // _buildActionCard(
                  //   icon: Icons.system_update_alt_rounded,
                  //   title: 'Check for Updates',
                  //   subtitle: 'Find available system updates',
                  //   color: Colors.black,
                  //   onTap: () {},
                  // ),
                  // _buildActionCard(
                  //   icon: Icons.settings_rounded,
                  //   title: 'System Settings',
                  //   subtitle: 'Manage system preferences',
                  //   color: Colors.black,
                  //   onTap: () {},
                  // ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 250,
      height: 150,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
