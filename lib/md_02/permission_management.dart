import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/user_data.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/custome_icon.dart';
import '../env/input_widget.dart';
import '../env/print_debug.dart';
import '../env/text_input_object.dart';

class PermissionManagementPage extends StatefulWidget {
  const PermissionManagementPage({super.key});

  @override
  State<PermissionManagementPage> createState() =>
      _PermissionManagementPageState();
}

class _PermissionManagementPageState extends State<PermissionManagementPage> {
  String? _selectedUser;
  final _txtCreditLimit = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dropDownToUsers();
    });
  }

  List<String> _users = [];
  List<dynamic> _activeProjectDropDownMap = [];
  bool _isUserDropDown = false;

  Future<void> _dropDownToUsers() async {
    setState(() {
      _isUserDropDown = true;
    });
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Users');
      String reqUrl = '${APIHost().apiURL}/user_controller.php/ListUser';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        Navigator.pop(context);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            _activeProjectDropDownMap = responseData['data'] ?? [];
            _users = _activeProjectDropDownMap
                .map<String>((item) => item['user_name'].toString())
                .toList();
          });
        } else {
          final String message = responseData['message'] ?? 'Error';
          PD.pd(text: message);
          OneBtnDialog.oneButtonDialog(
            context,
            title: 'Error',
            message: message,
            btnName: 'OK',
            icon: Icons.error,
            iconColor: Colors.red,
            btnColor: Colors.black,
          );
        }
      }
      else {
        Navigator.pop(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'permission_management.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    } finally {
      setState(() {
        _isUserDropDown = false;
      });
    }
  }


  final List<dynamic> _activeUserPermissionList = [];
  bool _isUserPermissionLoad = false;
  Future<void> _loadUserPermissions(String userName) async {
    setState(() {
      _isUserPermissionLoad = true;
    });
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Permissions');
      String reqUrl = '${APIHost().apiURL}/user_controller.php/GetUserPermission';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "user_name": userName,
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
            _txtCreditLimit.text = userPermission['aut_credit_limit']?.toString() ?? "0.0";
            _permissions['Approve Project IOU'] = userPermission['alw_auth'] == 1;
            _permissions['Approve Office IOU'] = userPermission['alw_ofz_auth'] == 1;
            _permissions['Pending Payment'] = userPermission['alw_req_pay'] == 1;
            _permissions['Office IOU Request'] = userPermission['alw_ofz_exp'] == 1;
            _permissions['Data Entry'] = userPermission['alw_cons_exp'] == 1;
            _permissions['Permission Manager'] = userPermission['alw_pm'] == 1;
            _permissions['Allow to Material Management'] = userPermission['alw_mm'] == 1;
            _permissions['Allow to Estimation Creating'] = userPermission['alw_ec'] == 1;
            _permissions['Report View'] = userPermission['alw_rpt'] == 1;
            _permissions['My IOU Request'] = userPermission['alw_prl'] == 1;
            _permissions['Allow To Project Management'] = userPermission['alw_pm_create'] == 1;
            _permissions['Active User'] = userPermission['is_active'] == 1;
            _permissions['Location Management'] = userPermission['alw_lm'] == 1;
            _permissions['Expense & Task Designer'] = userPermission['alw_exp_task_plan'] == 1;
            _permissions['IOU Request'] = userPermission['alw_pbc'] == 1;
            _permissions['Office Expenses Design'] = userPermission['alw_ofz_tsk_desg'] == 1;
            _permissions['Project Estimation Edit'] = userPermission['alw_est_edit'] == 1;
            _permissions['Project Estimation Authorized'] = userPermission['alw_est_auth'] == 1;
            _permissions['Project Estimation Approve'] = userPermission['alw_est_appr'] == 1;


          });

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
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'permission_management.dart');
      _clearUserPermissions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isUserPermissionLoad = false;
      });
    }
  }

  void _clearUserPermissions() {
    setState(() {
      _txtCreditLimit.text = "0.0"; // Reset credit limit
      _permissions.updateAll((key, value) => false); // Reset all permissions
    });
  }
  final Map<String, bool> _permissions = {
    'Approve Project IOU': false,
    'Approve Office IOU': false,
    'Pending Payment': false,
    'Office IOU Request': false,
    'Data Entry': false,
    'Permission Manager': false,
    'Allow to Material Management': false,
    'Allow to Estimation Creating': false,
    'Report View': false,
    'My IOU Request': false,
    "Location Management":false,
    "Office Expenses Design":false,
    "Active User": false,
    "Expense & Task Designer": false,
    "Allow To Project Management":false,
    "IOU Request":false,
    "Project Estimation Edit":false,
    "Project Estimation Authorized":false,
    "Project Estimation Approve":false,
  };

  Future<void> _manageUserPermission() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a user first."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isUserPermissionLoad = true;
    });
    try {
      WaitDialog.showWaitDialog(context, message: 'Updating Permissions');

      String reqUrl = '${APIHost().apiURL}/user_controller.php/ManageUserPermission';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "user_name": _selectedUser,
          "created_by": UserCredentials().UserName, // Change accordingly
          "aut_credit_limit": _txtCreditLimit.text.isNotEmpty ? _txtCreditLimit.text.replaceAll(',', '') : "0",
          "change_by": UserCredentials().UserName, // Change accordingly
          "alw_auth": _permissions['Approve Project IOU']==false?0:1,
          "alw_ofz_auth": _permissions['Approve Office IOU']==false?0:1,
          "alw_req_pay": _permissions['Pending Payment']==false?0:1,
          "alw_ofz_exp": _permissions['Office IOU Request']==false?0:1,
          "alw_cons_exp": _permissions['Data Entry']==false?0:1,
          "alw_pm": _permissions['Permission Manager']==false?0:1,
          "alw_mm": _permissions['Allow to Material Management']==false?0:1,
          "alw_ec": _permissions['Allow to Estimation Creating']==false?0:1,
          "alw_rpt": _permissions['Report View']==false?0:1,
          "alw_prl": _permissions['My IOU Request']==false?0:1,
          "alw_pm_create": _permissions['Allow To Project Management']==false?0:1,
          "alw_lm":_permissions['Location Management']==false?0:1,
          "alw_ofz_tsk_desg":_permissions['Office Expenses Design']==false?0:1,



          "alw_est_edit":_permissions['Project Estimation Edit']==false?0:1,
          "alw_est_auth":_permissions['Project Estimation Authorized']==false?0:1,
          "alw_est_appr":_permissions['Project Estimation Approve']==false?0:1,


          "is_active": _permissions['Active User']==false?0:1,
          "alw_exp_task_plan": _permissions['Expense & Task Designer']==false?0:1,
          "alw_pbc": _permissions['IOU Request']==false?0:1,
        }),
      );

      PD.pd(text: _permissions['Active User'].toString());

      Navigator.pop(context);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());

        if (responseData['status'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissions updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final String message = responseData['message'] ?? 'Error';
          PD.pd(text: message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("HTTP Error: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'permission_management.dart');
      PD.pd(text: e.toString());
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isUserPermissionLoad = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      MyAppBar(appname: 'User Permission Managements'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select User",
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF673AB7)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputTextDecoration.inputDecoration(
                      lable_Text: 'Select User',
                      hint_Text: "Select User",
                      icons: Icons.person,
                    ),
                    value: _selectedUser,
                    items: _users.map((user) {
                      return DropdownMenuItem<String>(
                        value: user,
                        child: Text(user),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUser = value;
                        _loadUserPermissions(_selectedUser.toString());
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // Authorization Permissions
                  _buildPermissionSection(
                    "Authorization Permissions",
                    [
                      "Approve Project IOU",
                      "Approve Office IOU",
                      "Pending Payment",
                    ],
                  ),
                  buildNumberField(
                    _txtCreditLimit,
                    'Credit limit',
                    '1500',
                    LKRIcon(),
                    true,
                    12,
                  ),
                  const SizedBox(height: 10),

                  // Use Request Allowing Permissions
                  _buildPermissionSection("Requests Allowing", [
                    "Office IOU Request",
                    "Data Entry",
                  ]),
                  _buildPermissionSection("User Status", [
                    "Active User"
                  ]),

                  const SizedBox(height: 10),

                  // Use Permission Allowing
                  _buildPermissionSection("Permission Allowing", [
                    "Permission Manager",
                    "Allow to Material Management",
                    "Allow to Estimation Creating",
                    "Report View",
                    "My IOU Request",
                    "Location Management",
                    "Office Expenses Design",
                    "Expense & Task Designer",
                    "Allow To Project Management",
                    "IOU Request",
                    "Project Estimation Edit",
                    "Project Estimation Authorized",
                    "Project Estimation Approve"
                  ]),

                  const SizedBox(height: 10),

                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        _manageUserPermission();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: const Text("Save Permissions",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionSection(String title, List<String> permissions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme
              .of(context)
              .textTheme
              .titleMedium!
              .copyWith(
              fontWeight: FontWeight.bold, color: const Color(0xFF673AB7)),
        ),
        const SizedBox(height: 16),
        for (var permission in permissions)
          _buildPermissionRow(permission, _permissions[permission]!, (value) {
            setState(() {
              _permissions[permission] = value!;
            });
          }),
      ],
    );
  }

  Widget _buildPermissionRow(String label, bool value,
      ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blueAccent,
        ),
        Text(label),
      ],
    );
  }
}
