import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/user_data.dart';
import 'package:roky_holding/md_01/account_setup.dart';
import 'package:roky_holding/md_01/login.dart';
import 'package:roky_holding/md_02/permission_management.dart';
import 'package:roky_holding/md_03/location_management.dart';
import 'package:roky_holding/md_03/ofz_exp_designer.dart';
import 'package:roky_holding/md_03/project_estimation_management.dart';
import 'package:roky_holding/md_03/material_create_management.dart';
import 'package:roky_holding/md_03/project_management.dart';
import 'package:roky_holding/md_03/exp_and_task_designer.dart';
import 'package:roky_holding/md_03/project_pending_estimations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';
import '../md_03/location_lockout_dialog.dart';
import 'app_maintenance.dart';

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
      _loadUserPermissions();
    });
  }

  void _remindPwd() {
    if (UserCredentials().Req_pw_change == 1) {
      YNDialogCon.ynDialogMessage(
        context,
        messageTitle: 'Action Required',
        messageBody: 'Your password was recently reset. Please update it now.',
        btnDone: 'Ok',
        icon: Icons.notification_add,
        iconColor: Colors.red,
        btnClose: 'Cancel',
      ).then((value) {
        if (value == 1) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => AccountSetupPage()));
        }
      });
    }
  }

  Future<void> _loadUserPermissions() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Permissions');
      String reqUrl =
          '${APIHost().apiURL}/user_controller.php/GetUserPermission';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "user_name": UserCredentials().UserName,
        }),
      );
      Navigator.pop(context);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        PD.pd(text: responseData.toString());

        if (responseData['status'] == 200 &&
            responseData['data'] is List &&
            responseData['data'].isNotEmpty) {
          final userPermission = responseData['data'][0];

          setState(() {
            UserCredentials().AuthCreditLimit =
                double.tryParse(userPermission['aut_credit_limit']);
            _permissions['alw_auth'] = userPermission['alw_auth'] == 1;
            _permissions['alw_ofz_auth'] = userPermission['alw_ofz_auth'] == 1;
            _permissions['alw_req_pay'] = userPermission['alw_req_pay'] == 1;
            _permissions['alw_pm'] = userPermission['alw_pm'] == 1;
            _permissions['alw_mm'] = userPermission['alw_mm'] == 1;
            _permissions['alw_ec'] = userPermission['alw_ec'] == 1;
            _permissions['alw_rpt'] = userPermission['alw_rpt'] == 1;
            _permissions['alw_prl'] = userPermission['alw_prl'] == 1;
            _permissions['alw_ofz_exp'] = userPermission['alw_ofz_exp'] == 1;
            _permissions['alw_cons_exp'] = userPermission['alw_cons_exp'] == 1;
            _permissions['alw_pm_create'] =
                userPermission['alw_pm_create'] == 1;
            _permissions['alw_lm'] = userPermission['alw_lm'] == 1;
            _permissions['is_active'] = userPermission['is_active'] == 1;
            _permissions['alw_exp_task_plan'] =
                userPermission['alw_exp_task_plan'] == 1;
            _permissions['alw_pbc'] = userPermission['alw_pbc'] == 1;
            _permissions['alw_ofz_tsk_desg'] =
                userPermission['alw_ofz_tsk_desg'] == 1;

            _permissions['alw_est_appr'] = userPermission['alw_est_appr'] == 1;
            _permissions['alw_est_auth'] = userPermission['alw_est_auth'] == 1;
            _permissions['alw_est_edit'] = userPermission['alw_est_edit'] == 1;
          });
          _remindPwd();
          _checkPendingRequestsForDialog();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User permissions loaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _clearUserPermissions();
          final String message = responseData['message'] ?? 'User not found!';
          PD.pd(text: message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      } else {
        _clearUserPermissions();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("HTTP Error: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'home_page.dart');
      _clearUserPermissions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _checkPendingRequestsForDialog() async {
    try {
      WaitDialog.showWaitDialog(context,
          message: 'Checking Pending Requests...');
      final response = await http.post(
        Uri.parse(
            '${APIHost().apiURL}/project_payment_controller.php/PaymentNotification'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "user_name": UserCredentials().UserName,
        }),
      );

      Navigator.pop(context);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200 && responseData['data'] is List) {
          await showRequestRefDialog(responseData['data'], context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    responseData['message'] ?? 'No pending requests found')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server Error: ${response.statusCode}')),
        );
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
        message: e.toString(),
        errorLog: st.toString(),
        logFile: 'request_check.dart',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    }
  }

  void _clearUserPermissions() {
    setState(() {
      _permissions.updateAll((key, value) => false);
    });
  }

  final Map<String, bool> _permissions = {
    'alw_auth': false,
    'alw_ofz_auth': false,
    'alw_req_pay': false,
    'alw_pm': false,
    'alw_mm': false,
    'alw_ec': false,
    'alw_rpt': false,
    'alw_prl': false,
    'alw_ofz_exp': false,
    'alw_cons_exp': false,
    'is_active': false,
    'alw_pm_create': false,
    'alw_lm': false,
    'alw_exp_task_plan': false,
    'alw_pbc': false,
    'alw_ofz_tsk_desg': false,
    'alw_est_edit': false,
    'alw_est_auth': false,
    'alw_est_appr': false,
  };

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchEstimationEvents();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logoutUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully!'),
      ),
    );
    APIToken().token = null;
    clearAllPrefs();
    UserCredentials().setUserData('', '', '', -1, -1);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => LoginApp()));
  }

  Future<void> _fetchEstimationEvents() async {
    try {
      String apiUrl = '${APIHost().apiURL}/login_controller.php/logout';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": APIToken().token}),
      );
      PD.pd(text: apiUrl);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          _logoutUser();
        } else {}
      } else {}
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'home_page.dart');
    }
  }

  Future<void> clearAllPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  Widget build(BuildContext context) {
    List<_TileInfo> tiles = [
      _TileInfo(
        permissionKey: 'alw_pm_create',
        title: 'Project Management',
        icon: FontAwesomeIcons.diagramProject,
        color: Colors.blueAccent, // Cool blue
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProjectManagementScreen()),
          );
        },
      ),
      _TileInfo(
        permissionKey: 'alw_lm',
        title: 'Location Management',
        color: Colors.greenAccent, // Vibrant green
        icon: FontAwesomeIcons.magnifyingGlassLocation,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LocationManagement()),
          );
        },
      ),
      _TileInfo(
        permissionKey: 'alw_mm',
        title: 'Material Management',
        color: Colors.purple, // Rich purple
        icon: FontAwesomeIcons.boxesStacked,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MaterialCreate()),
          );
        },
      ),
      _TileInfo(
        permissionKey: 'alw_ec',
        title: 'Estimation Creating',
        color: Colors.cyanAccent, // Bright cyan
        icon: FontAwesomeIcons.fileCirclePlus,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ConstructionEstimationCreate()),
          );
        },
      ),
      _TileInfo(
        color: Colors.blue, // Soft pink
        permissionKey: 'alw_est_edit',
        title: 'Estimation Lock time set',
        icon: FontAwesomeIcons.clock,
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => const LocationLockoutDialog(),
          );
        },
      ),
      _TileInfo(
        color: Colors.green, // Soft pink
        permissionKey: 'alw_est_auth',
        title: 'Estimation Request Approving',
        icon: Icons.approval,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ApprovelPendingEstimations(
                      isAuth: bool.tryParse(
                              _permissions['alw_est_auth'].toString()) ??
                          false,
                      isApprov: bool.tryParse(
                              _permissions['alw_est_appr'].toString()) ??
                          false,
                    )),
          );
        },
      ),
      _TileInfo(
        color: Colors.deepPurpleAccent, // Rich purple
        permissionKey: 'alw_pm',
        title: 'Permission Manager',
        icon: FontAwesomeIcons.moneyBill,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PermissionManagementPage()),
          );
        },
      ),
      _TileInfo(
        color: Colors.lime, // Bright lime green
        permissionKey: 'alw_exp_task_plan',
        title: 'Expense & Task Designer',
        icon: FontAwesomeIcons.list,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExpAndTaskDesigner()),
          );
        },
      ),
      _TileInfo(
        color: Colors.lime, // Bright lime green
        permissionKey: 'alw_ofz_tsk_desg',
        title: 'Office Expense & Task Designer',
        icon: FontAwesomeIcons.store,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OfzExpAndTaskDesigner()),
          );
        },
      ),
      _TileInfo(
        color: Colors.pink, // Soft pink
        permissionKey: 'is_active',
        title: 'Account Setup',
        icon: FontAwesomeIcons.userGear,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AccountSetupPage()),
          );
        },
      ),
      _TileInfo(
        color: Colors.deepOrangeAccent, // Soft pink
        permissionKey: 'alw_pm',
        title: 'Maintenance',
        icon: FontAwesomeIcons.gear,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AppMaintenanceScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple, // Updated AppBar color
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.notifications),
          tooltip: 'Notifications',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No new notifications'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isAdvancedLayout ? Icons.grid_view : Icons.list),
            tooltip: 'Switch Layout',
            onPressed: () {
              setState(() {
                _isAdvancedLayout = !_isAdvancedLayout;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutConfirmation();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white12, Colors.indigo], // Gradient background
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isAdvancedLayout
                ? _buildAdvancedLayout(tiles)
                : _buildEasyLayout(tiles),
          ),
        ),
      ),
    );
  }

  Widget _buildEasyLayout(List<_TileInfo> tiles) {
    return ListView(
      children: tiles
          .where((tile) => _permissions[tile.permissionKey] == true)
          .map((tile) {
        return Card(
          elevation: 6,
          color: tile.color, // Semi-transparent white
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: FaIcon(tile.icon, size: 30, color: Colors.black),
            title: Text(
              tile.title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: tile.onTap,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedLayout(List<_TileInfo> tiles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 740 ? 6 : 3;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: tiles
              .where((tile) => _permissions[tile.permissionKey] == true)
              .map((tile) {
            return GestureDetector(
              onTap: tile.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 160,
                height: 100,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [tile.color.withOpacity(0.7), tile.color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tile.color.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(6, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(tile.icon, size: 36, color: Colors.black),
                    const SizedBox(height: 8),
                    Text(
                      tile.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
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
