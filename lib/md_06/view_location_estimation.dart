import 'dart:convert';
import 'package:roky_holding/env/platform_ind/csv_exporter.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/number_format.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/input_widget.dart';
import '../env/print_debug.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;

class ViewLocationWiseEstimationPage extends StatefulWidget {
  final bool isEdit;
  const ViewLocationWiseEstimationPage({super.key,required this.isEdit});

  @override
  ViewLocationWiseEstimationPageState createState() =>
      ViewLocationWiseEstimationPageState();
}

class ViewLocationWiseEstimationPageState
    extends State<ViewLocationWiseEstimationPage> {

  final _txtDropDownProject = TextEditingController();
  final _txtDropDownLocation = TextEditingController();
  final _txtDropDownWorkType = TextEditingController();
  final _txtDropDownCostCategoty = TextEditingController();
  bool isEditAlow=false;
  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dropDownToProject();
      isEditAlow=widget.isEdit;
    });
  }

  String? selectedProject;
  List<String> projects = [];
  Future<void> _dropDownToProject() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading project');


      String reqUrl = '${APIHost().apiURL}/project_controller.php/listAll';
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token}),
      );
      PD.pd(text: reqUrl);
      WaitDialog.hideDialog(context);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            projects = List<String>.from(
                (responseData['data'] ?? [])
                    .map((item) => item['project_name'].toString())
            );
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
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_location_estimation.dart');
      PD.pd(text: e.toString());
    }
  }

  void clearDropDown()
  {
    _txtDropDownCostCategoty.text='';
    _txtDropDownWorkType.text='';
    setState(() {

    });
  }

  void clearCategory()
  {
    _txtDropDownCostCategoty.text='';
    setState(() {

    });
  }
  String? _selectedValueWorkType;
  List<String> _dropdownWorkType = [];
  Future<void> _loadActiveWorkList() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading works');

      clearDropDown();
      String reqUrl =
          '${APIHost().apiURL}/project_payment_controller.php/WorkCategoryTypeSelection';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token,
          "location_name":_txtDropDownLocation.text,
          "project_name":_txtDropDownProject.text
        }),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {

            _dropdownWorkType =  List<String>.from(
                (responseData['data'] ?? [])
                    .map((item) => item['work_name'].toString())
            );
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
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_wise_item_request_list.dart');
      PD.pd(text: e.toString());
    } finally {

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }


  //cost category
  String? _selectedValueCostCategory;
  List<String> _dropdownCostCategory = [];
  Future<void> _loadActiveCostList(String? workName) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Category');
      clearCategory();


      String reqUrl =
          '${APIHost().apiURL}/project_payment_controller.php/CostCategorySelectionByEstimationAndWorkId';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token,
          "work_name":workName,
          "location_name":_txtDropDownLocation.text,
          "project_name":_txtDropDownProject.text,
        }),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _dropdownCostCategory =  List<String>.from(
                (responseData['data'] ?? [])
                    .map((item) => item['cost_category'].toString())
            );
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
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_wise_item_request_list.dart');
      PD.pd(text: e.toString());
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  String? selectedLocation;
  List<String> locations = [];
  Future<void> _dropDownToProjectLocation(String project) async {
    locations.clear();
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading location');

      String reqUrl = '${APIHost().apiURL}/location_controller.php/ListProjectActiveLocation';
      PD.pd(text: reqUrl);
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token,
          "project_name": project}),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            locations = List<String>.from(
                (responseData['data'] ?? [])
                    .map((item) => item['location_name'].toString())
            );
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
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_location_estimation.dart');
      PD.pd(text: e.toString());
    } finally {

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  List<Estimation> _activeEstimationList = [];

  Future<void> _loadProjectsLocationEstimationList() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading estimations');

      String reqUrl =
          '${APIHost().apiURL}/estimation_controller.php/GetEstimations';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "project_name": selectedProject,
          "location_name": selectedLocation,
          "work_type":_txtDropDownWorkType.text??'',
          "cost_category":_txtDropDownCostCategoty.text??''
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {

          setState(() {
            _activeEstimationList = (responseData['data'] as List)
                .map((item) => Estimation.fromJson(item))
                .toList();
          });
        } else {
          throw Exception(
              responseData['message'] ?? 'Error fetching estimations');
        }
      } else {

        throw Exception("HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_location_estimation.dart');

      PD.pd(text: e.toString());
      OneBtnDialog.oneButtonDialog(
        context,
        title: 'Error',
        message: e.toString(),
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
    }
  }

  Future<void> _deleteItem(int id) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading');

      String reqUrl =
          '${APIHost().apiURL}/estimation_controller.php/DeleteItems';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "idtbl_project_location_estimations_list": id,
        }),
      );

      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          OneBtnDialog.oneButtonDialog(
            context,
            title: 'Successful',
            message: responseData['message'],
            btnName: 'OK',
            icon: Icons.notification_add,
            iconColor: Colors.green,
            btnColor: Colors.black,
          ).then((value) async {
            if (value ==true) {
            _loadProjectsLocationEstimationList();
            }
          });
        } else {
          throw Exception(
              responseData['message'] ?? 'Error deleting estimations');
        }
      } else {
        WaitDialog.hideDialog(context);
        throw Exception("HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_location_estimation.dart');
      WaitDialog.hideDialog(context);
      PD.pd(text: e.toString());
      OneBtnDialog.oneButtonDialog(
        context,
        title: 'Error',
        message: e.toString(),
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appname: 'View Location Wise Estimation'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFf5f7fa), Color(0xFFe4e8f0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    collapsedBackgroundColor: Colors.transparent,
                    backgroundColor: Colors.transparent,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_alt_rounded,
                              color: Colors.deepPurple, size: 28),
                          const SizedBox(width: 10),
                          const Text(
                            "SELECT PROJECT AND LOCATION",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8),
                        child: Column(
                          children: [

                            Row(
                              children: [
                                Expanded(child: CustomDropdown(
                                label: 'Select Project',
                                suggestions: projects,
                                icon: Icons.assignment,
                                controller: _txtDropDownProject,
                                onChanged: (value) {
                                  selectedProject = value;
                                  _dropDownToProjectLocation(value.toString());
                                },
                              )),
                                Expanded(child: CustomDropdown(
                                  label: 'Select Location',
                                  suggestions: locations,
                                  icon: Icons.location_on,
                                  controller: _txtDropDownLocation,
                                  onChanged: (value) {
                                    selectedLocation = value;
                                    _loadActiveWorkList();

                                  },
                                ))],
                            ),

                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(

                                  child: CustomDropdown(
                                    label: 'Select Work Type',
                                    suggestions: _dropdownWorkType,
                                    icon: Icons.construction,
                                    controller: _txtDropDownWorkType,
                                    onChanged: (value) {
                                      _selectedValueWorkType = value;
                                      _loadActiveCostList(value.toString());
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: CustomDropdown(
                                    label: 'Select Category',
                                    suggestions: _dropdownCostCategory,
                                    icon: Icons.category,
                                    controller: _txtDropDownCostCategoty,
                                    onChanged: (value) {
                                      _selectedValueCostCategory = value;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.deepPurple,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 3,
                                ),
                                onPressed: () {
                                  _loadProjectsLocationEstimationList();
                                },
                                child: const Text(
                                  "VIEW REPORT",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Results Table
                buildTable(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_activeEstimationList.isNotEmpty) {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: Wrap(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Export Options',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple[800]),
                        ),
                      ),
                     ListTile(
                          leading: Icon(Icons.file_download,
                              color: Colors.blue[600]),
                          title: Text('Export CSV',
                              style:
                              TextStyle(fontWeight: FontWeight.w500)),
                          onTap: () {
                            Navigator.pop(context);
                            exportToCSV(_activeEstimationList);
                          },
                        ),
                      ListTile(
                        leading:
                        Icon(Icons.print, color: Colors.green[600]),
                        title: Text('Print PDF',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        onTap: () {
                          _exportAndPrintPdf();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            OneBtnDialog.oneButtonDialog(
              context,
              title: 'No Data',
              message: 'No Data to export',
              btnName: 'Ok',
              icon: Icons.warning_rounded,
              iconColor: Colors.red,
              btnColor: Colors.black,
            );
          }
        },
        tooltip: 'Export Options',
        backgroundColor: Colors.deepPurple,
        child: const Icon(FontAwesomeIcons.fileExport, color: Colors.white),
      ),
    );
  }

  Widget buildTable() {
    double totalEstimateAmount = _activeEstimationList.fold(
      0,
          (sum, item) => sum + (double.tryParse(item.ttemEstimateAmount) ?? 0),
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final minTableWidth = 1024.0;

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.only(top: 16),
    child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: ConstrainedBox(
    constraints: BoxConstraints(
    minWidth: screenWidth < minTableWidth ? minTableWidth : screenWidth,
    ),
    child: Table(
    border: TableBorder.all(
    color: Colors.grey[300]!,
    width: 1,
    borderRadius: BorderRadius.circular(12),
    ),
    columnWidths: const {
    0: FlexColumnWidth(2),
    1: FlexColumnWidth(2),
    2: FlexColumnWidth(3),
    3: FlexColumnWidth(2),
    4: FlexColumnWidth(2),
    5: FlexColumnWidth(2),
    6: FlexColumnWidth(2),
    7: FlexColumnWidth(2),
    8: FlexColumnWidth(1.5),
    },
            children: [
              // Table Header
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.deepPurple[600],
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Work Name",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Cost Category",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Material Description",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Estimated Qty",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Est. Amount",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Actual Cost",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Actual Unit Amt",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Created Date",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Action",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
              // Table Rows
              for (var estimation in _activeEstimationList)
                TableRow(
                  decoration: BoxDecoration(
                    color: _activeEstimationList.indexOf(estimation) % 2 == 0
                        ? Colors.white
                        : Colors.grey[50],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        estimation.workName,
                        style:
                        TextStyle(color: Colors.grey[800], fontSize: 13),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        estimation.costCategory,
                        style:
                        TextStyle(color: Colors.grey[800], fontSize: 13),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        estimation.materialDescription,
                        style:
                        TextStyle(color: Colors.grey[800], fontSize: 13),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        '${NumberStyles.qtyStyle(estimation.estimateQty)} ${estimation.uom}',
                        style:
                        TextStyle(color: Colors.grey[800], fontSize: 13), textAlign: TextAlign.right,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        NumberStyles.currencyStyle(
                            estimation.ttemEstimateAmount),
                        style:
                        TextStyle(color: Colors.grey[800], fontSize: 13), textAlign: TextAlign.right,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        NumberStyles.currencyStyle(estimation.actualCost),
                        style:
                        TextStyle(color: Colors.grey[800], fontSize: 13), textAlign: TextAlign.right,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        NumberStyles.currencyStyle(
                            estimation.actualUnitAmount),
                        style:
                        TextStyle(color: Colors.grey[800], fontSize: 13), textAlign: TextAlign.right,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        '${estimation.createdBy}\n${estimation.createdDate}',
                        style:
                        TextStyle(color: Colors.grey[800], fontSize: 13),
                      ),
                    ),
                    Visibility(
                      visible: isEditAlow,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () {
                            YNDialogCon.ynDialogMessage(
                              context,
                              messageBody:
                              'Confirm to remove item from estimation',
                              messageTitle: 'Remove item',
                              icon: Icons.verified_outlined,
                              iconColor: Colors.black,
                              btnDone: 'YES',
                              btnClose: 'NO',
                            ).then((value) async {
                              if (value == 1) {
                                await _deleteItem(int.tryParse(estimation
                                    .idtblProjectLocationEstimationsList) ??
                                    0);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),

              // Total Row
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.deepPurple[100],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Total',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 14),
                    ),
                  ),
                  for (int i = 0; i < 3; i++)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(""),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      NumberStyles.currencyStyle(totalEstimateAmount.toString()),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 14), textAlign: TextAlign.right,
                    ),
                  ),
                  for (int i = 0; i < 4; i++)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(""),
                    ),
                ],
              ),
            ],
    ),
    ),
    ),
        ),
    );
  }


  Future<void> exportToCSV( List<Estimation> estimations) async {
    try {
      // Define headers for the CSV
      List<List<String>> rows = [
        [
          "#",
          "Work Name",
          "Cost Category",
          "Material Description",
          "Estimated Quantity",
          "UOM",
          "Actual Unit Amount",
          "Estimation Amount",
          "Actual Cost",
          "Created By",
          "Created Date"
        ],
      ];

      // Populate data rows
      for (var estimation in estimations) {
        rows.add([
          estimation.idtblProjectLocationEstimationsList,
          estimation.workName,
          estimation.costCategory,
          estimation.materialDescription,
          NumberStyles.qtyStyle(estimation.estimateQty),
          estimation.uom,
          NumberStyles.currencyStyle(estimation.actualUnitAmount),
          NumberStyles.currencyStyle(estimation.ttemEstimateAmount),
          NumberStyles.currencyStyle(estimation.actualCost),
          estimation.createdBy,
          estimation.createdDate,
        ]);
      }

      // Convert to CSV format
      await MobileCSVExporter.export(
        context: context,
        headersAndRows: rows,
        fileNamePrefix: 'location estimations $selectedProject $selectedLocation',
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("CSV exported successfully.")),
          );
        },
        onError: (e, st) {
          debugPrint('CSV Export Error: $e\n$st');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to export CSV.")),
          );
        },
      );
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_location_estimation.dart');
      PD.pd(text: e.toString());
      OneBtnDialog.oneButtonDialog(
        context,
        title: "Error",
        message: "Failed to export CSV: $e",
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
    }
  }
  Future<pw.Document> generateEstimationPdf(List<Estimation> estimationList,String projectName,String locationName,) async {
    final pdf = pw.Document();
    final printedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // Load Unicode Fonts
    final fontData = await rootBundle.load("assets/fonts/iskpota.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load("assets/fonts/iskpotab.ttf");
    final ttfBold = pw.Font.ttf(boldFontData);

    // Load images (replace with actual asset paths)
    final footerLogo = pw.MemoryImage(
      (await rootBundle.load('assets/image/HBiz.jpg')).buffer.asUint8List(),
    );

    final headerLogo = pw.MemoryImage(
      (await rootBundle.load('assets/image/logo.png')).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.MultiPage(
        footer: (pw.Context context) => pw.Container(
          alignment: pw.Alignment.centerLeft,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Container(
                width: 30,
                height: 30,
                child: pw.Image(footerLogo),
              ),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Software by Hela Software Solution',
                    style: pw.TextStyle(fontSize: 10, font: ttf, fontStyle: pw.FontStyle.italic),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Contact: +94 70 157 3582',
                    style: pw.TextStyle(fontSize: 9, font: ttf),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Website: www.helasoftsolution.com',
                    style: pw.TextStyle(fontSize: 9, font: ttf),
                  ),
                ],
              ),
            ],
          ),
        ),
        build: (pw.Context context) {
          // Calculate totals
          double totalEstimate = estimationList.fold(0.0, (sum, item) =>
          sum + (double.tryParse(item.estimateAmount) ?? 0));
          double totalActual = estimationList.fold(0.0, (sum, item) =>
          sum + (double.tryParse(item.actualCost) ?? 0));

          return [
            // Header with logo and title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  width: 80,
                  height: 80,
                  child: pw.Image(headerLogo),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Project Estimation Report',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, font: ttfBold),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Printed on: $printedDateTime',
                      style: pw.TextStyle(fontSize: 10, font: ttf, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Divider(),

            // Project and location info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Project: $projectName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: ttfBold)),
                pw.Text('Location: $locationName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: ttfBold)),
              ],
            ),
            pw.SizedBox(height: 20),

            // Estimation table
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey500),
              headerDecoration: pw.BoxDecoration(color: PdfColors.deepPurple),
              headerHeight: 30,
              cellHeight: 25,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: ttfBold),
              cellStyle: pw.TextStyle(fontSize: 10, font: ttf),
              cellAlignment: pw.Alignment.centerLeft,
              headers: [
                'Work',
                'Cost Category',
                'Material',
                'Qty',
                'Amount (LKR)',
                'Actual Cost (LKR)',
                'Unit Cost (LKR)'
              ],
              data: estimationList.map((estimation) {
                return [
                  estimation.workName,
                  estimation.costCategory,
                  estimation.materialDescription,
                  estimation.estimateQty,
                  NumberFormat('#,###.00', 'en_US').format(double.tryParse(estimation.estimateAmount) ?? 0),
                  NumberFormat('#,###.00', 'en_US').format(double.tryParse(estimation.actualCost) ?? 0),
                  NumberFormat('#,###.00', 'en_US').format(double.tryParse(estimation.actualUnitAmount) ?? 0),
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            // Summary totals
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Budgeted Cost (LKR):',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: ttfBold),
                ),
                pw.Text(
                  NumberFormat('#,###.00', 'en_US').format(totalEstimate),
                  style: pw.TextStyle(fontSize: 12, font: ttf),
                ),
              ],
            ),

            pw.SizedBox(height: 10),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Actual Cost (LKR):',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: ttfBold),
                ),
                pw.Text(
                  NumberFormat('#,###.00', 'en_US').format(totalActual),
                  style: pw.TextStyle(fontSize: 12, font: ttf),
                ),
              ],
            ),

            pw.SizedBox(height: 40),

            // Footer copyright
            pw.Center(
              child: pw.Text(
                '© ${DateTime.now().year} Hela Software Solution',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, font: ttf),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }
  Future<void> _exportAndPrintPdf() async {
    try {
      if (selectedProject == null || selectedLocation == null) {
        throw Exception("Please select project and location first");
      }

      if (_activeEstimationList.isEmpty) {
        throw Exception("No estimation data to export");
      }

      WaitDialog.showWaitDialog(context, message: 'Generating PDF');

      final pdf = await generateEstimationPdf(
        _activeEstimationList,
        selectedProject!,
        selectedLocation!,
      );

      WaitDialog.hideDialog(context);

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_location_estimation.dart');
      WaitDialog.hideDialog(context);
      OneBtnDialog.oneButtonDialog(
        context,
        title: 'Error',
        message: e.toString(),
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
    }
  }
}
class Estimation {
  final String idtblProjectLocationEstimationsList;
  final String materialDescription;
  final String estimateQty;
  final String estimateAmount;
  final String ttemEstimateAmount;
  final String actualCost;
  final String actualUnitAmount;
  final String createdDate;
  final String createdBy;
  final String costCategory;
  final String workName;
  final String uom;

  Estimation({
    required this.idtblProjectLocationEstimationsList,
    required this.materialDescription,
    required this.estimateQty,
    required this.estimateAmount,
    required this.actualCost,
    required this.actualUnitAmount,
    required this.createdDate,
    required this.createdBy,
    required this.costCategory,
    required this.workName,
    required this.ttemEstimateAmount,
    required this.uom
  });

  factory Estimation.fromJson(Map<String, dynamic> json) {
    return Estimation(
        ttemEstimateAmount: json['ItemEstimateAmount'] ?? 0,
        idtblProjectLocationEstimationsList: json['idtbl_project_location_estimations_list']
            .toString(),
        materialDescription: json['material_description'],
        estimateQty: json['estimate_qty'].toString(),
        estimateAmount: json['estimate_amount'].toString(),
        actualCost: json['actual_cost'].toString(),
        actualUnitAmount: json['actual_unit_amount'].toString(),
        createdDate: json['created_date'],
        createdBy: json['created_by'],
        costCategory: json['cost_category'],
        workName: json['work_name'],
        uom: json['uom']
    );
  }
}