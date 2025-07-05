import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/user_data.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/input_widget.dart';
import '../env/print_debug.dart';

class LocationManagement extends StatefulWidget {
  const LocationManagement({super.key});

  @override
  State<LocationManagement> createState() => _LocationManagementState();
}

class _LocationManagementState extends State<LocationManagement> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _txtLocationName = TextEditingController();
  final TextEditingController _txtTenderNumber = TextEditingController();

  Future<void> _updateLocation(BuildContext context, int idtblProjectLocation,
      int projectId, String locationName, String isActive) async {
    try {
      // Show loading message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Updating location...'),
            duration: Duration(seconds: 2)),
      );

      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        // If token is missing, show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Authentication token is missing."),
              backgroundColor: Colors.red),
        );
        return;
      }

      String reqUrl = '${APIHost().apiURL}/location_controller.php/EditLocation';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "idtbl_project_location": idtblProjectLocation,
          "project_id": projectId,
          "location_name": locationName,
          "is_active": 1,
          "change_by": UserCredentials().UserName,
        }),
      );

      if (response.statusCode == 200) {
        // Hide loading message

        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          PD.pd(text: responseData.toString());
          final int status = responseData['status'];
          if (status == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(responseData['message'] ?? 'Success'),
                  backgroundColor: Colors.green),
            );
          } else {
            final String message = responseData['message'] ?? 'Error';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          }
        } catch (e,st) {
          ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'location_management.dart');
          // JSON decoding error
          String errorMessage =
              "Error decoding JSON: $e, Body: ${response.body}";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } else {
        String errorMessage = 'Error with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e,st) {
            ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'location_management.dart');
            errorMessage = response.body;
          }
        }
        // Display error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'location_management.dart');
      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      // Display network or other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteLocation(BuildContext context, int idtblProjectLocation,
      int projectId, String locationName, String projectName) async {
    try {
      // Show loading message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Delete location...'),
            duration: Duration(seconds: 2)),
      );

      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        // If token is missing, show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Authentication token is missing."),
              backgroundColor: Colors.red),
        );
        return;
      }
      String reqUrl = '${APIHost().apiURL}/location_controller.php/DeleteLocation';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "idtbl_project_location": idtblProjectLocation,
          "project_id": projectId,
          "project_name": projectName,
          "location_name": locationName
        }),
      );

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          PD.pd(text: responseData.toString());
          final int status = responseData['status'];
          if (status == 200) {
            // Success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(responseData['message'] ?? 'Success'),
                  backgroundColor: Colors.green),
            );
            _loadProjectsLocationList(projectName);
          } else {
            final String message = responseData['message'] ?? 'Error';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          }
        } catch (e,st) {
          ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'location_management.dart');
          String errorMessage =
              "Error decoding JSON: $e, Body: ${response.body}";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } else {
        String errorMessage = 'Error with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'location_management.dart');
            errorMessage = response.body;
          }
        }
        // Display error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'location_management.dart');
      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      // Display network or other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  //project list dropdown
  List<dynamic> _activeProjectDropDownMap = [];
  bool _isProjectsDropDown = false;
  Future<void> _dropDownToProject() async {
    setState(() {
      _isProjectsDropDown = true;
    });
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Project');
      String reqUrl = '${APIHost().apiURL}/project_controller.php/listAll';
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
            _dropdownProjects = _activeProjectDropDownMap
                .map<String>((item) => item['project_name'].toString())
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
      } else {
        Navigator.pop(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'location_management.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    } finally {
      setState(() {
        _isProjectsDropDown = false;
      });
    }
  }

  //select project dropdown
  String? _selectedProjectName;
  List<String> _dropdownProjects = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dropDownToProject();
    });
  }

  //project location list
  List<dynamic> _activeProjectsLocationList = [];
  bool _isProjectsLocationLoad = false;
  Future<void> _loadProjectsLocationList(String project) async {
    setState(() {
      _isProjectsLocationLoad = true;
    });
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Location');
      String reqUrl =
          '${APIHost().apiURL}/location_controller.php/ListProjectActiveLocation';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "project_name": project,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        Navigator.pop(context);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            _activeProjectsLocationList = List.from(responseData['data'] ?? []);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Project locations loaded successfully'),
                backgroundColor: Colors.green),
          );
        } else {
          final String message = responseData['message'] ?? 'Error';
          PD.pd(text: message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("HTTP Error: ${response.statusCode}"),
              backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'location_management.dart');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isProjectsLocationLoad = false;
      });
    }
  }

  Future<void> _loadTenderNumber(String project) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading..');
      String reqUrl = '${APIHost().apiURL}/project_controller.php/ListTenderNumber';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "project_name": project,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        Navigator.pop(context);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          List<dynamic> dataList = responseData['data'] ?? [];
          for (var item in dataList) {
            if (item.containsKey('tender')) {
              _txtTenderNumber.text = item['tender'];
            }
          }
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Tender/Project number found'),
                backgroundColor: Colors.green),
          );
          _loadProjectsLocationList(project);
        } else {
          final String message = responseData['message'] ?? 'Error';
          PD.pd(text: message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("HTTP Error: ${response.statusCode}"),
              backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'location_management.dart');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Text field controllers and validation
  final _txtLocationNameController = TextEditingController();
  final _civilWorkCostController = TextEditingController();
  final _filtersCostController = TextEditingController();
  final _serviceCostController = TextEditingController();
  final _labourCostController = TextEditingController();
  final _materialCostController = TextEditingController();
  final _equipmentCostController = TextEditingController();
  final _otherCostController = TextEditingController();
  final _dropdown1Controller = TextEditingController();
  final _dropdown2Controller = TextEditingController();

  double _totalCost = 0;

  @override
  void dispose() {
    _txtLocationNameController.dispose();
    _civilWorkCostController.dispose();
    _filtersCostController.dispose();
    _serviceCostController.dispose();
    _labourCostController.dispose();
    _materialCostController.dispose();
    _equipmentCostController.dispose();
    _otherCostController.dispose();
    super.dispose();
  }

  void _calculateTotalCost() {
    setState(() {
      _totalCost = 0;
      _totalCost += double.tryParse(_civilWorkCostController.text) ?? 0;
      _totalCost += double.tryParse(_filtersCostController.text) ?? 0;
      _totalCost += double.tryParse(_serviceCostController.text) ?? 0;
      _totalCost += double.tryParse(_labourCostController.text) ?? 0;
      _totalCost += double.tryParse(_materialCostController.text) ?? 0;
      _totalCost += double.tryParse(_equipmentCostController.text) ?? 0;
      _totalCost += double.tryParse(_otherCostController.text) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(appname: 'Project Location Management'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 600; // Check screen width

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: isWideScreen
                ? Row(
                    // Two columns if screen is wide
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildCreateLocationForm()),
                      const SizedBox(width: 20), // Spacing between columns
                      Expanded(child: _buildActiveLocationCostListCard()),
                    ],
                  )
                : Column(
                    // Stack in a single column if screen is narrow
                    children: [
                      _buildCreateLocationForm(),
                      const SizedBox(height: 20), // Spacing between sections
                      _buildActiveLocationCostListCard(),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCreateLocationForm() {
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
                      'Create New Location',
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
                    CustomDropdown(
                      label: 'Select Project',
                      suggestions: _dropdownProjects,
                      icon: Icons.category_sharp,
                      controller: _dropdown1Controller,
                      onChanged: (value) {
                        _selectedProjectName = value;
                        _loadTenderNumber(_selectedProjectName.toString());
                      },
                    ),
                    buildTextField(
                        _txtLocationName,
                        'Location Name',
                        'Building construction downtown',
                        Icons.create,
                        true,
                        45),
                    buildTextField(_txtTenderNumber, 'Tender/Project Number',
                        'TX00001', Icons.query_builder, true, 45),
                  ],

                ),
                const SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> createProjectLocation(BuildContext context) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'location creating');
      String reqUrl='${APIHost().apiURL}/location_controller.php/RegisterLocation';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "project_name": _selectedProjectName.toString(),
          "location_name": _txtLocationName.text,
          "tender": _txtTenderNumber.text,
          "is_active": "1",
          "created_by": UserCredentials().UserName,
          "change_by": UserCredentials().UserName,
        }),
      );
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final int status = responseData['status'];
        final String message = responseData['message'] ?? 'Error';

        PD.pd(text: responseData.toString());

        OneBtnDialog.oneButtonDialog(
          context,
          title: status == 200 ? "Successful" : "Error",
          message: message,
          btnName: 'OK',
          icon: status == 200 ? Icons.verified_outlined : Icons.error,
          iconColor: status == 200 ? Colors.black : Colors.red,
          btnColor: status == 200 ? Colors.green : Colors.black,
        );

        if (status == 200) createNewEstimationId();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Location creation failed.');
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'location_management.dart');
      String errorMessage = e is FormatException
          ? 'Invalid JSON response'
          : e is SocketException
              ? 'Network error. Please check your connection.'
              : 'An error occurred: $e';

      PD.pd(text: errorMessage);
      ExceptionDialog.exceptionDialog(
        context,
        title: 'Error',
        message: errorMessage,
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
    }
  }

  Future<void> createNewEstimationId() async {
    // Add BuildContext
    try {
      WaitDialog.showWaitDialog(context, message: 'location estimations');
      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        PD.pd(text: "Authentication token is missing.");
        ExceptionDialog.exceptionDialog(
          context,
          title: 'Authentication Error',
          message: "Authentication token is missing.",
          btnName: 'OK',
          icon: Icons.error,
          iconColor: Colors.red,
          btnColor: Colors.black,
        );
        return;
      }

      String reqUrl =
          '${APIHost().apiURL}/estimation_controller.php/CreateEstimation';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "location_name": _txtLocationName.text,
          "project_name": _selectedProjectName.toString(),
          "is_active": '1',
          "created_by": UserCredentials().UserName,
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
            _loadProjectsLocationList(_selectedProjectName.toString());
          } else if (status == 409) {
            PD.pd(text: responseData.toString());
            OneBtnDialog.oneButtonDialog(context,
                title: "Scanning",
                message: responseData['message'],
                btnName: 'Ok',
                icon: Icons.find_in_page,
                iconColor: Colors.black,
                btnColor: Colors.green);
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
        } catch (e,st) {
          ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'location_management.dart');
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
            'estimation creating failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'location_management.dart');
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
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'location_management.dart');
      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      WaitDialog.hideDialog(context);
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

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          PD.pd(text: "Form is valid!");
          PD.pd(
              text:
                  "Selected Project: $_selectedProjectName"); // Print selected cost type

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
              await createProjectLocation(context);
            }
          });
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        // Background color
        foregroundColor: Colors.white,
        // Text color
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500, // Font weight
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5,
        // Elevation
        shadowColor: Colors.black26, // Shadow color
      ),
      child: const Text('Create Locations'),
    );
  }

  Widget _buildActiveLocationCostListCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Active Location",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildActiveProjectsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveProjectsList() {
    if (_isProjectsLocationLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeProjectsLocationList.isEmpty) {
      return const Center(
          child: Text(
        'No active location found.',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activeProjectsLocationList.length,
      itemBuilder: (context, index) {
        final location = _activeProjectsLocationList[index];
        TextEditingController txtLocationNameController =
            TextEditingController(text: location['location_name']);
        TextEditingController txtProjectName =
            TextEditingController(text: location['project_name']);

        return Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade100, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business,
                          color: Theme.of(context).primaryColor, size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildTextFieldReadOnly(
                                txtProjectName,
                                'Tender/Project Name',
                                '',
                                Icons.construction,
                                true,
                                45),
                            buildTextField(txtLocationNameController,
                                'Location Name', '', Icons.pin_drop, true, 45),
                            Text('Estimation Amount :${NumberFormat('#,###.00', 'en_US')
                                .format(double.tryParse(location['total_estimate_amount'])??0)} LKR',style: TextStyle(fontSize: 20),)
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: SizedBox(
                        width: 50,
                      )),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: const Text('Delete',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              YNDialogCon.ynDialogMessage(
                                context,
                                messageBody: 'Confirm to Remove location.',
                                messageTitle: 'location remove',
                                icon: Icons.delete_forever,
                                iconColor: Colors.red,
                                btnDone: 'YES',
                                btnClose: 'NO',
                              ).then((value) async {
                                if (value == 1) {
                                  await _deleteLocation(
                                      context,
                                      location['idtbl_project_location'],
                                      location['project_id'],
                                      txtLocationNameController.text,
                                      txtProjectName.text);
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text('Edit',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              YNDialogCon.ynDialogMessage(
                                context,
                                messageBody: 'Confirm to update location Name.',
                                messageTitle: 'location update',
                                icon: Icons.update,
                                iconColor: Colors.green,
                                btnDone: 'YES',
                                btnClose: 'NO',
                              ).then((value) async {
                                if (value == 1) {
                                  await _updateLocation(
                                      context,
                                      location['idtbl_project_location'],
                                      location['project_id'],
                                      txtLocationNameController.text,
                                      txtProjectName.text);
                                }
                              });
                            },
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
