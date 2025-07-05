import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';


class LocationLockoutDialog extends StatefulWidget {
  const LocationLockoutDialog({super.key});

  @override
  LocationLockoutDialogState createState() => LocationLockoutDialogState();
}

class LocationLockoutDialogState extends State<LocationLockoutDialog> {
  // Project related
  List<dynamic> _activeProjectDropDownMap = [];
  String? _selectedProjectName;
  List<String> _dropdownProjects = [];

  // Location related
  List<dynamic> _activeProjectLocationDropDownMap = [];
  String? _selectedProjectLocationName;
  List<String> _dropdownProjectLocation = [];

  // Time related
  DateTime _selectedDateTime = DateTime.now();
  final TextEditingController _timeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _timeController.text = _formatDateTime(_selectedDateTime);
    _dropDownToProject();
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _timeController.text = _formatDateTime(_selectedDateTime);
        });
      }
    }
  }

  Future<void> _dropDownToProject() async {
    try {
      setState(() => _isLoading = true);
      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        return;
      }

      String reqUrl = '${APIHost()
          .apiURL}/project_controller.php/ProjectByDate';
      PD.pd(text: reqUrl);

      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Authorization": token}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _activeProjectDropDownMap = responseData['data'] ?? [];
            _dropdownProjects = _activeProjectDropDownMap
                .map<String>((item) => item['project_name'].toString())
                .toList();
            if (_dropdownProjects.isNotEmpty) {
              _selectedProjectName = _dropdownProjects.first;
              _dropDownToProjectLocation(_selectedProjectName!);
            }
          });
        } else {
          _showErrorDialog(responseData['message'] ?? 'Error loading projects');
        }
      } else {
        _showErrorDialog("HTTP Error: ${response.statusCode}");
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'location_lockout_dialog.dart'
      );
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _dropDownToProjectLocation(String project) async {
    try {
      setState(() => _isLoading = true);
      String reqUrl = '${APIHost()
          .apiURL}/location_controller.php/ListProjectActiveLocation';
      PD.pd(text: reqUrl);

      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "project_name": project
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _activeProjectLocationDropDownMap = responseData['data'] ?? [];
            _dropdownProjectLocation = _activeProjectLocationDropDownMap
                .map<String>((item) => item['location_name'].toString())
                .toList();
            if (_dropdownProjectLocation.isNotEmpty) {
              _selectedProjectLocationName = _dropdownProjectLocation.first;
            }
          });
        } else {
          _showErrorDialog(
              responseData['message'] ?? 'Error loading locations');
        }
      } else {
        _showErrorDialog("HTTP Error: ${response.statusCode}");
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'location_lockout_dialog.dart'
      );
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
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

  Future<void> _updateLockoutTime() async {
    if (_selectedProjectName == null || _selectedProjectLocationName == null) {
      _showErrorDialog('Please select both project and location');
      return;
    }

    try {
      setState(() => _isLoading = true);
      String reqUrl = '${APIHost()
          .apiURL}/location_controller.php/LocationTimeSet';
      PD.pd(text: reqUrl);

      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "project_name": _selectedProjectName,
          "location_name": _selectedProjectLocationName,
          "location_lock": _timeController.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          bool? shouldClose = await OneBtnDialog.oneButtonDialog(
            context,
            title: "Success",
            message: "Lockout time updated successfully",
            btnName: 'OK',
            icon: Icons.check_circle,
            iconColor: Colors.green,
            btnColor: Colors.blue,
          );

          if (shouldClose == true) {
            Navigator.pop(context, true);
          }
        } else {
          _showErrorDialog(
              responseData['message'] ?? 'Failed to update lockout time');
        }
      } else {
        _showErrorDialog("HTTP Error: ${response.statusCode}");
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'location_lockout_dialog.dart'
      );
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String? selectedValue,
    required IconData icon,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedValue,
              icon: Icon(icon, color: CupertinoColors.activeBlue),
              iconSize: 24,
              elevation: 16,
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 16,
              ),
              underline: Container(height: 0),
              onChanged: enabled ? onChanged : null,
              items: items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lockout Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _selectDateTime(context),
            child: AbsorbPointer(
              child: CupertinoTextField(
                controller: _timeController,
                placeholder: 'Select lockout time',
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffix: const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.calendar_today, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 8,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery
                .of(context)
                .size
                .width * 0.6,
            maxHeight: MediaQuery
                .of(context)
                .size
                .height * 0.8,
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Set Location Lockout Time',
                    style: TextStyle(
                      fontSize: MediaQuery
                          .of(context)
                          .size
                          .width * 0.03,
                      fontWeight: FontWeight.bold,
                      color: Theme
                          .of(context)
                          .primaryColor,
                    ),textAlign: TextAlign.center,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ...[
                  _buildDropdown(
                    label: 'Project',
                    items: _dropdownProjects,
                    selectedValue: _selectedProjectName,
                    icon: Icons.work,
                    onChanged: (value) {
                      setState(() {
                        _selectedProjectName = value;
                        _selectedProjectLocationName = null;
                        _dropdownProjectLocation = [];
                        if (value != null) {
                          _dropDownToProjectLocation(value);
                        }
                      });
                    },
                  ),

                  _buildDropdown(
                    label: 'Location',
                    items: _dropdownProjectLocation,
                    selectedValue: _selectedProjectLocationName,
                    icon: Icons.location_on,
                    onChanged: (value) {
                      setState(() => _selectedProjectLocationName = value);
                    },
                    enabled: _dropdownProjectLocation.isNotEmpty,
                  ),

                  _buildDateTimePicker(),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ), child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),)),
                      const SizedBox(width: 10),
                      ElevatedButton(
                          onPressed: _updateLockoutTime,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ), child: Text(
                        'Update',
                        style: TextStyle(color: Colors.white),))
                    ],
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}