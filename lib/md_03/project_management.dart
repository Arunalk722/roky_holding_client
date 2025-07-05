import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roky_holding/env/DialogBoxs.dart';
import 'package:roky_holding/env/user_data.dart';
import '../env/api_info.dart';
import '../env/app_bar.dart';
import '../env/app_logs_to.dart';
import '../env/custome_icon.dart';
import '../env/input_widget.dart';
import '../env/print_debug.dart';

class ProjectManagementScreen extends StatefulWidget {
  const ProjectManagementScreen({super.key});

  @override
  State<ProjectManagementScreen> createState() =>
      _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _txtTender = TextEditingController();
  final _txtProjectName = TextEditingController();
  final _txtTenderCost = TextEditingController();
  final _txtProjectId = TextEditingController();
  final _txtClientName = TextEditingController();
  late bool _isActive = false;
  late bool _userVisible = false;
  String _startDate = ''; //DateTime.now().toString();
  String _endDate =
      ''; //DateTime.now().add(Duration(days: 1)).toLocal().toString().split(' ')[0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActiveProjects();
    });
  }

  List<dynamic> _activeProjects = [];
  bool _isLoadingProjects = false;

  Future<void> _loadActiveProjects() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading project');

      String reqUrl =
          '${APIHost().apiURL}/project_controller.php/ListAllProjects';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token}),
      );

      PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        Navigator.pop(context);
        try {
          final responseData = jsonDecode(response.body);
          PD.pd(text: responseData.toString());
          if (responseData['status'] == 200) {
            clearText();
            _activeProjects = responseData['data'] ?? [];
            _startDate = DateTime.now().toString().split(' ')[0];
            _endDate = DateTime.now()
                .add(Duration(days: 1))
                .toLocal()
                .toString()
                .split(' ')[0];
          } else {
            final String message = responseData['message'] ?? 'Error';
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
        } catch (e, st) {
          ExceptionLogger.logToError(
              message: e.toString(),
              errorLog: st.toString(),
              logFile: 'project_management.dart');
          PD.pd(text: e.toString());
        }
      } else {
        Navigator.pop(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_management.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    }
  }

  Future<void> _loadProjectUsingTender() async {
    WaitDialog.showWaitDialog(context, message: 'Loading..');

    try {
      String reqUrl =
          '${APIHost().apiURL}/project_controller.php/ListTenderNumber';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "project_name": _txtProjectName.text,
        }),
      );
      clearText();
      WaitDialog.hideDialog(context);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());

        final int status = responseData['status'];

        if (status == 200) {
          final List<dynamic>? dataList = responseData['data'];

          if (dataList != null && dataList.isNotEmpty) {
            final projectData = dataList[0];
            _txtProjectId.text = projectData['idtbl_projects'].toString();
            _txtProjectName.text = projectData['project_name'] ?? '';
            _txtTender.text = projectData['tender'] ?? '';
            _txtTenderCost.text = projectData['tender_cost'] ?? '';
            _txtClientName.text = projectData['client_name'] ?? '';
            _startDate = projectData['start_date'];
            _endDate = projectData['end_date'];

            setState(() {
              _isActive = projectData['is_active'] == 1;
              _userVisible = projectData['user_visible'] == 1;
            });
          } else {
            // No data received
            PD.pd(text: "No project found with that name.");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("No project data found."),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          final String message =
              responseData['message'] ?? 'Failed to fetch project';
          PD.pd(text: message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        String errorMessage = 'Failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e, st) {
            ExceptionLogger.logToError(
                message: e.toString(),
                errorLog: st.toString(),
                logFile: 'project_management.dart');
            errorMessage = response.body;
          }
        }

        PD.pd(text: errorMessage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_management.dart');

      String errorMessage = 'An error occurred: $e';
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
      appBar: const MyAppBar(appname: 'Project Management'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 700;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: isWideScreen
                ? Row(
                    // Two columns if screen is wide
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildCreateProjectForm(isWideScreen)),
                      const SizedBox(width: 20), // Spacing between columns
                      Expanded(
                          child: _buildActiveProjectsListCard(isWideScreen)),
                    ],
                  )
                : Column(
                    // Stack in a single column if screen is narrow
                    children: [
                      _buildCreateProjectForm(isWideScreen),
                      const SizedBox(height: 20), // Spacing between sections
                      _buildActiveProjectsListCard(isWideScreen),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCreateProjectForm(bool isWidthScreen) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: 400, // Keep max width limited
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Center(
                    child: Text(
                      'Create Project',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  leading: Container(
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 20,
                  runSpacing: 15,
                  children: [
                    buildTextField(_txtProjectId, 'Project ID', 'Project ID',
                        Icons.key, false, 10),
                    buildTextField(
                        _txtTender,
                        'Tender/Project Number',
                        'Enter Tender/Project number',
                        Icons.receipt_long,
                        true,
                        45),
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                              _txtProjectName,
                              'Enter Tender/project name',
                              'Enter Tender/project name',
                              Icons.business,
                              true,
                              45),
                        ),
                        Container(
                          padding: EdgeInsets.only(bottom: 20),
                          child: IconButton(
                            icon: Icon(Icons.find_in_page, color: Colors.blue),
                            tooltip: 'Scan Project',
                            onPressed: () {
                              _loadProjectUsingTender();
                            },
                          ),
                        )
                      ],
                    ),
                    buildNumberField(_txtTenderCost, 'Tender/Project Value',
                        'Enter cost', LKRIcon(), true, 15),
                    buildTextField(_txtClientName, 'Client Name', 'Client Name',
                        Icons.person, true, 45),
                    Row(
                      children: [
                        Expanded(
                          child: DatePickerWidget(
                            label: 'Start Date',
                            initialDate: _startDate, // Pass current date
                            onDateSelected: (selectedDate) {
                              setState(() {
                                _startDate = selectedDate;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: DatePickerWidget(
                            label: 'Plan to End',
                            initialDate: _endDate, // Pass current date
                            onDateSelected: (selectedDate) {
                              setState(() {
                                _endDate = selectedDate;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    _buildCheckboxes(),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: isWidthScreen
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                            ),
                            _buildSubmitButton(),
                            SizedBox(
                              width: 16,
                            ),
                            _buildEditButton(),
                            SizedBox(
                              width: 16,
                            ),
                            _buildCleanButton(),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 16,
                            ),
                            _buildSubmitButton(),
                            SizedBox(
                              height: 16,
                            ),
                            _buildEditButton(),
                            SizedBox(
                              height: 16,
                            ),
                            _buildCleanButton(),
                          ],
                        ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add this method to handle scanning

  Widget _buildCheckboxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Checkbox(
                value: _isActive,
                onChanged: (bool? newValue) {
                  setState(() {
                    _isActive = newValue ?? false;
                  });
                },
                activeColor: Colors.blueAccent,
              ),
              const Text('Is Active'),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Checkbox(
                value: _userVisible,
                onChanged: (bool? newValue) {
                  setState(() {
                    _userVisible = newValue ?? false;
                  });
                },
                activeColor: Colors.blueAccent,
              ),
              const Text('User Visibility'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          PD.pd(text: "Form is valid!");
          YNDialogCon.ynDialogMessage(
            context,
            messageBody: 'Confirm to create a new project',
            messageTitle: 'Project Creating',
            icon: Icons.verified_outlined,
            iconColor: Colors.black,
            btnDone: 'YES',
            btnClose: 'NO',
          ).then((value) async {
            if (value == 1) {
              await _createProjectManagement(context);
            }
          });
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green, // Background color
        foregroundColor: Colors.white, // Text color
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500, // Font weight
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5, // Elevation
        shadowColor: Colors.black26, // Shadow color
      ),
      child: const Text('Create Project'),
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          PD.pd(text: "Form is valid!");
          YNDialogCon.ynDialogMessage(
            context,
            messageBody: 'Confirm to Edit existing project',
            messageTitle: 'Project edit',
            icon: Icons.edit_calendar_outlined,
            iconColor: Colors.black,
            btnDone: 'YES',
            btnClose: 'NO',
          ).then((value) async {
            if (value == 1) {
              await _editProjectManagement(context);
            }
          });
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // Background color
        foregroundColor: Colors.white, // Text color
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500, // Font weight
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5, // Elevation
        shadowColor: Colors.black26, // Shadow color
      ),
      child: const Text('Edit Project'),
    );
  }

  Widget _buildCleanButton() {
    return ElevatedButton(
      onPressed: () {
        PD.pd(text: "Form is valid!");
        YNDialogCon.ynDialogMessage(
          context,
          messageBody: 'Confirm to Clear layout ',
          messageTitle: 'layout Clear',
          icon: Icons.edit_calendar_outlined,
          iconColor: Colors.black,
          btnDone: 'YES',
          btnClose: 'NO',
        ).then((value) async {
          if (value == 1) {
            clearText();
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red, // Background color
        foregroundColor: Colors.white, // Text color
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500, // Font weight
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5, // Elevation
        shadowColor: Colors.black26, // Shadow color
      ),
      child: const Text('Clear Form'),
    );
  }

  Widget _buildActiveProjectsListCard(bool isWideScreen) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Active Projects",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildActiveProjectsTable(isWideScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveProjectsTable(bool isWideScreen) {
    if (_isLoadingProjects) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeProjects.isEmpty) {
      return const Center(child: Text('No active projects found.'));
    }

    return SizedBox(
      width: 600, // Fixed width of 600px
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          border: TableBorder.all(width: 1, color: Colors.grey),
          columnSpacing: 12,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 50,
          headingRowHeight: 45,
          columns: [
            _buildDataColumn('Tender/Project\nName'),
            _buildDataColumn('Tender/Project\nNumber'),
            _buildDataColumn('Budgeted Cost\nLKR'),
            _buildDataColumn('Actions'),
          ],
          rows: _activeProjects.map((project) {
            return DataRow(cells: [
              DataCell(SizedBox(
                width: 150, // Fixed width for this column
                child: Text(project['project_name'] ?? 'N/A'),
              )),
              DataCell(SizedBox(
                width: 120, // Fixed width for this column
                child: Text(project['tender'] ?? 'N/A'),
              )),
              DataCell(SizedBox(
                width: 120, // Fixed width for this column
                child: Text(NumberFormat('#,###.00', 'en_US')
                    .format(double.tryParse(project['exp_estimation_cost']))),
              )),
              DataCell(SizedBox(
                width: 150, // Fixed width for this column
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _editProject(project);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        project['user_visible'] == 1
                            ? Icons.visibility_off_outlined
                            : Icons.visibility,
                        color: project['user_visible'] == 1
                            ? Colors.blue
                            : Colors.red,
                      ),
                      onPressed: () => _toggleVisibility(context, project),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteProject(context, project),
                    ),
                  ],
                ),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  void _editProject(Map<String, dynamic> project) {
    _isActive = project['is_active'].toString() == '1';
    _userVisible = project['user_visible'].toString() == '1';
    _txtTender.text = project['tender'] ?? '';
    _txtProjectName.text = project['project_name'] ?? '';
    _txtProjectId.text = project['idtbl_projects']?.toString() ?? '0';
    _txtTenderCost.text = project['tender_cost']?.toString() ?? '';
    _txtClientName.text = project['client_name']?.toString() ?? '';
    setState(() {
      _endDate = project['end_date']?.toString() ?? '';
      _startDate = project['start_date']?.toString() ?? '';
    });
  }

  void _toggleVisibility(
      BuildContext context, Map<String, dynamic> project) async {
    int vis = project['user_visible'] as int;
    String mg = vis == 0 ? 'enable visibility' : 'disable visibility';
    int result = await YNDialogCon.ynDialogMessage(
      context,
      messageTitle: mg,
      messageBody: "Are you sure you want to $mg project ${project['tender']}?",
      icon: vis == 0 ? Icons.visibility : Icons.visibility_off_outlined,
      iconColor: Colors.orange,
      btnDone: vis == 0 ? "Yes, Visible" : "Yes, Invisible",
      btnClose: "Cancel",
    );
    if (result == 1) {
      _changeVisibility(
          context, project['idtbl_projects'].toString(), vis == 0);
    }
  }

  void _confirmDeleteProject(
      BuildContext context, Map<String, dynamic> project) async {
    int result = await YNDialogCon.ynDialogMessage(
      context,
      messageTitle: "Confirm Deletion",
      messageBody:
          "Are you sure you want to delete project ${project['tender']}?",
      icon: Icons.warning,
      iconColor: Colors.orange,
      btnDone: "Yes, Delete",
      btnClose: "Cancel",
    );

    if (result == 1) {
      _deleteProject(context, project['idtbl_projects']);
    }
  }

  DataColumn _buildDataColumn(String title) {
    return DataColumn(
      label: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  //create project
  Future<void> _createProjectManagement(BuildContext context) async {
    // Add BuildContext
    try {
      WaitDialog.showWaitDialog(context, message: 'project creating');

      String reqUrl =
          '${APIHost().apiURL}/project_controller.php/CreateProject';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "client_name": _txtClientName.text,
          "tender": _txtTender.text,
          "project_name": _txtProjectName.text,
          "tender_cost": _txtTenderCost.text.replaceAll(',', ''),
          "created_by": UserCredentials().UserName,
          "change_by": UserCredentials().UserName,
          "is_active": _isActive ? '1' : '0',
          "start_date": _startDate,
          "end_date": _endDate,
          "user_visible": _userVisible == true ? '1' : '0',
        }),
      );

      PD.pd(text: "Response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final int status = responseData['status'];
          if (status == 200) {
            PD.pd(text: responseData.toString());
            OneBtnDialog.oneButtonDialog(context,
                title: "Successful",
                message: responseData['message'],
                btnName: 'Ok',
                icon: Icons.verified_outlined,
                iconColor: Colors.black,
                btnColor: Colors.green);
            _loadActiveProjects();
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
        } catch (e, st) {
          ExceptionLogger.logToError(
              message: e.toString(),
              errorLog: st.toString(),
              logFile: 'project_management.dart');
          PD.pd(
              text: "Error decoding JSON: $e, Body: ${response.body}"); // Debug
          ExceptionDialog.exceptionDialog(
            context,
            title: 'JSON Error',
            message: "Error decoding JSON response: $e",
            btnName: 'OK',
            icon: Icons.error,
            iconColor: Colors.red,
            btnColor: Colors.black,
          );
        }
      } else {
        WaitDialog.hideDialog(context);
        String errorMessage =
            'Project Management failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e, st) {
            ExceptionLogger.logToError(
                message: e.toString(),
                errorLog: st.toString(),
                logFile: 'project_management.dart');
            errorMessage = response.body;
          }
        }
        PD.pd(text: errorMessage);
        ExceptionDialog.exceptionDialog(
          context,
          title: 'HTTP Error',
          message: errorMessage,
          btnName: 'OK',
          icon: Icons.error,
          iconColor: Colors.red,
          btnColor: Colors.black,
        );
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_management.dart');
      WaitDialog.hideDialog(context);
      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      PD.pd(text: errorMessage);
      ExceptionDialog.exceptionDialog(
        context,
        title: 'General Error',
        message: errorMessage,
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
    }
  }

  //delete project
  Future<void> _deleteProject(BuildContext context, int projectId) async {
    // Add BuildContext
    try {
      WaitDialog.showWaitDialog(context, message: 'Delete Project $projectId');

      String reqUrl =
          '${APIHost().apiURL}/project_controller.php/DeleteProject';
      PD.pd(text: reqUrl);
      final response = await http.delete(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "idtbl_projects": projectId,
        }),
      );

      PD.pd(text: "Response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final int status = responseData['status'];

          if (status == 200) {
            PD.pd(text: responseData.toString());
            OneBtnDialog.oneButtonDialog(context,
                title: "Successful",
                message: responseData['message'],
                btnName: 'Ok',
                icon: Icons.verified_outlined,
                iconColor: Colors.black,
                btnColor: Colors.green);
            _loadActiveProjects();
          } else {
            final String message = responseData['message'];
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
        } catch (e, st) {
          ExceptionLogger.logToError(
              message: e.toString(),
              errorLog: st.toString(),
              logFile: 'project_management.dart');
          PD.pd(
              text: "Error decoding JSON: $e, Body: ${response.body}"); // Debug
          ExceptionDialog.exceptionDialog(
            context,
            title: 'JSON Error',
            message: "Error decoding JSON response: $e",
            btnName: 'OK',
            icon: Icons.error,
            iconColor: Colors.red,
            btnColor: Colors.black,
          );
        }
      } else {
        WaitDialog.hideDialog(context);
        String errorMessage =
            'Project Management failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e, st) {
            ExceptionLogger.logToError(
                message: e.toString(),
                errorLog: st.toString(),
                logFile: 'project_management.dart');
            errorMessage = response.body;
          }
        }
        PD.pd(text: errorMessage);
        ExceptionDialog.exceptionDialog(
          context,
          title: 'HTTP Error',
          message: errorMessage,
          btnName: 'OK',
          icon: Icons.error,
          iconColor: Colors.red,
          btnColor: Colors.black,
        );
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_management.dart');
      WaitDialog.hideDialog(context);
      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      PD.pd(text: errorMessage);
      ExceptionDialog.exceptionDialog(
        context,
        title: 'General Error',
        message: errorMessage,
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
    }
  }

  //change visibility
  Future<void> _changeVisibility(
      BuildContext context, String projectId, bool vis) async {
    try {
      WaitDialog.showWaitDialog(context,
          message: 'Change Project $projectId visibility');

      String reqUrl =
          '${APIHost().apiURL}/project_controller.php/changeVisibility';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "idtbl_projects": projectId,
          "user_visible": vis,
          "change_by": UserCredentials().UserName
        }),
      );

      PD.pd(text: "Response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final int status = responseData['status'];

          if (status == 200) {
            PD.pd(text: responseData.toString());
            OneBtnDialog.oneButtonDialog(context,
                title: "Successful",
                message: responseData['message'],
                btnName: 'Ok',
                icon: Icons.verified_outlined,
                iconColor: Colors.black,
                btnColor: Colors.green);
            _loadActiveProjects();
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
        } catch (e, st) {
          ExceptionLogger.logToError(
              message: e.toString(),
              errorLog: st.toString(),
              logFile: 'project_management.dart');
          PD.pd(
              text: "Error decoding JSON: $e, Body: ${response.body}"); // Debug
          ExceptionDialog.exceptionDialog(
            context,
            title: 'JSON Error',
            message: "Error decoding JSON response: $e",
            btnName: 'OK',
            icon: Icons.error,
            iconColor: Colors.red,
            btnColor: Colors.black,
          );
        }
      } else {
        WaitDialog.hideDialog(context);
        String errorMessage =
            'Project Management failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e, st) {
            ExceptionLogger.logToError(
                message: e.toString(),
                errorLog: st.toString(),
                logFile: 'project_management.dart');
            errorMessage = response.body;
          }
        }
        PD.pd(text: errorMessage);
        ExceptionDialog.exceptionDialog(
          context,
          title: 'HTTP Error',
          message: errorMessage,
          btnName: 'OK',
          icon: Icons.error,
          iconColor: Colors.red,
          btnColor: Colors.black,
        );
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_management.dart');
      WaitDialog.hideDialog(context);
      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      PD.pd(text: errorMessage);
      ExceptionDialog.exceptionDialog(
        context,
        title: 'General Error',
        message: errorMessage,
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
    }
  }

  Future<void> _editProjectManagement(BuildContext context) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Updating project...');
      String reqUrl = '${APIHost().apiURL}/project_controller.php/EditProject';
      PD.pd(text: reqUrl);
      final response = await http.put(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "tender": _txtTender.text,
          "project_name": _txtProjectName.text,
          "client_name": _txtClientName.text,
          "tender_cost": _txtTenderCost.text.replaceAll(',', ''),
          "change_by": UserCredentials().UserName,
          "end_date": _endDate,
          "start_date": _startDate,
          "is_active": _isActive ? '1' : '0',
          "user_visible": _userVisible ? '1' : '0',
          "idtbl_projects": _txtProjectId.text,
        }),
      );

      PD.pd(text: "Response: ${response.statusCode} - ${response.body}");
      WaitDialog.hideDialog(context);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final int status = responseData['status'];
        if (status == 200) {
          PD.pd(text: responseData.toString());
          OneBtnDialog.oneButtonDialog(
            context,
            title: "Successful",
            message: responseData['message'],
            btnName: 'Ok',
            icon: Icons.verified_outlined,
            iconColor: Colors.black,
            btnColor: Colors.green,
          );
          _loadActiveProjects();
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
      } else {
        WaitDialog.hideDialog(context);
        String errorMessage =
            'Project update failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e, st) {
            ExceptionLogger.logToError(
                message: e.toString(),
                errorLog: st.toString(),
                logFile: 'project_management.dart');
            errorMessage = response.body;
          }
        }
        PD.pd(text: errorMessage);
        ExceptionDialog.exceptionDialog(
          context,
          title: 'HTTP Error',
          message: errorMessage,
          btnName: 'OK',
          icon: Icons.error,
          iconColor: Colors.red,
          btnColor: Colors.black,
        );
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_management.dart');
      WaitDialog.hideDialog(context);
      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      PD.pd(text: errorMessage);
      ExceptionDialog.exceptionDialog(
        context,
        title: 'General Error',
        message: errorMessage,
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
    }
  }

  void clearText() {
    setState(() {
      _txtProjectId.text = "";
      _txtTender.text = "";
      _txtProjectName.text = "";
      _txtTenderCost.text = "";
      _txtProjectId.text = "";
      _txtClientName.text = '';
      _isActive = false;
      _startDate = "";
      _endDate = '';
    });
  }
}
