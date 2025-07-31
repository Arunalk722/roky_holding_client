import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/number_format.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/input_widget.dart';
import 'package:roky_holding/env/platform_ind/csv_exporter.dart';
import '../env/print_debug.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';


class ProjectWiseEstimateItemConsume extends StatefulWidget {
  final bool isEdit;
  const ProjectWiseEstimateItemConsume({super.key, required this.isEdit});

  @override
  ProjectWiseEstimateItemConsumeState createState() =>
      ProjectWiseEstimateItemConsumeState();
}

class ProjectWiseEstimateItemConsumeState
    extends State<ProjectWiseEstimateItemConsume> {
  final _txtDropDownProject = TextEditingController();
  final _txtDropDownLocation = TextEditingController();
  final _txtDropDownWorkType = TextEditingController();
  final _txtDropDownCostCategoty = TextEditingController();
  bool isEditAlow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dropDownToProject();
      isEditAlow = widget.isEdit;
    });
  }

  String? selectedProject;
  List<String> projects = [];
  Future<void> _dropDownToProject() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading project');

      String reqUrl = '${APIHost().apiURL}/project_controller.php/listAll';
      PD.pd(text: reqUrl);
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
                    .map((item) => item['project_name'].toString()));
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
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_estimate_Item_consume.dart');
      PD.pd(text: e.toString());
    }
  }

  String? selectedLocation;
  List<String> locations = [];
  Future<void> _dropDownToProjectLocation(String project) async {
    locations.clear();
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading location');

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
          "project_name": project
        }),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            locations = List<String>.from(
                (responseData['data'] ?? [])
                    .map((item) => item['location_name'].toString()));
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
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_estimate_Item_consume.dart');
      PD.pd(text: e.toString());
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  List<EstimationItem> _activeEstimationList = [];

  Future<void> _loadProjectsLocationEstimateItemConsume() async {
    try {
      if (selectedProject == null || selectedLocation == null) {
        throw Exception("Please select project and location first");
      }

      WaitDialog.showWaitDialog(context, message: 'Loading list');
      String reqUrl =
          '${APIHost().apiURL}/report_controller.php/ProjectWiseEstimateItemConsume';

      PD.pd(text: reqUrl.toString());
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
                .map((item) => EstimationItem.fromJson(item))
                .toList();
          });
        } else {
          throw Exception(
              responseData['message'] ?? 'Error fetching estimations');
        }
      } else {
        throw Exception("HTTP Error: ${response.statusCode}");
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_estimate_Item_consume.dart');

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

      String reqUrl = '${APIHost().apiURL}/estimation_controller.php/DeleteItems';
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
            if (value == true) {
              _loadProjectsLocationEstimateItemConsume();
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
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_estimate_Item_consume.dart');
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appname: 'Estimation Consume list'),
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
                                Expanded(child:  CustomDropdown(
                                label: 'Select Project',
                                suggestions: projects,
                                icon: Icons.assignment,
                                controller: _txtDropDownProject,
                                onChanged: (value) {
                                  selectedProject = value;
                                  _dropDownToProjectLocation(value.toString());
                                },
                              ),),
                                Expanded(child:  CustomDropdown(
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
                            const SizedBox(height: 20),
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
                                  _loadProjectsLocationEstimateItemConsume();
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
               Center(
                 child:  buildTable(),
               )
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_activeEstimationList.isNotEmpty) {
            _showExportOptions();
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
        backgroundColor: Colors.blue[600],
        child: const Icon(FontAwesomeIcons.fileExport, color: Colors.white),
      ),
    );
  }

  Widget buildTable() {
    double totalEstimateAmount = _activeEstimationList.fold(
      0,
          (sum, item) => sum + (item.estimatedAmount),
    );
    double totalReqAmount = _activeEstimationList.fold(
      0,
          (sum, item) => sum + (item.totalRequestedAmount),
    );
    double totalRemBal = _activeEstimationList.fold(
      0,
          (sum, item) => sum + (item.estimatedAmount-item.totalRequestedAmount),
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1200,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
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
                  8: FlexColumnWidth(2),
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
                          "Material Name",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          "Description",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          "Est. Qty",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          "Unit Cost",
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
                          "Req. Qty",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          "Req. Amount",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          "Rem. Act. Bal.",
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
                            estimation.costCategory,
                            style: TextStyle(color: Colors.grey[800], fontSize: 13),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            estimation.materialName,
                            style: TextStyle(color: Colors.grey[800], fontSize: 13),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            estimation.materialDescription,
                            style: TextStyle(color: Colors.grey[800], fontSize: 13),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            NumberStyles.qtyStyle(estimation.estimatedQuantity.toString()),
                            style: TextStyle(color: Colors.grey[800], fontSize: 13),textAlign: TextAlign.right,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            NumberStyles.currencyStyle(estimation.actualUnitPrice.toString()),
                            style: TextStyle(color: Colors.grey[800], fontSize: 13),textAlign: TextAlign.right,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            NumberStyles.currencyStyle(estimation.estimatedAmount.toString()),
                            style: TextStyle(color: Colors.grey[800], fontSize: 13),textAlign: TextAlign.right,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            NumberStyles.qtyStyle(estimation.totalRequestedQuantity.toString()),
                            style: TextStyle(color: Colors.grey[800], fontSize: 13),textAlign: TextAlign.right,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            NumberStyles.currencyStyle(estimation.totalRequestedAmount.toString()),
                            style: TextStyle(color: Colors.grey[800], fontSize: 13),textAlign: TextAlign.right,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            NumberStyles.currencyStyle((estimation.estimatedAmount-estimation.totalRequestedAmount).toString()),
                            style: TextStyle(
                              color: _getBalanceColor(double.tryParse((estimation.estimatedAmount-estimation.totalRequestedAmount).toString()) ?? 0),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),textAlign: TextAlign.right,
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
                      for (int i = 0; i < 5; i++)
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
                              fontSize: 14),textAlign: TextAlign.right,
                        ),
                      ),
                      for (int i = 0; i < 1; i++)
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(""),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          NumberStyles.currencyStyle(totalReqAmount.toString()),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 14),textAlign: TextAlign.right,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          NumberStyles.currencyStyle(totalRemBal.toString()),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 14),textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
      ),
    );
  }

  Color _getBalanceColor(double balance) {
    if (balance < 0) {
      return Colors.red; // Negative balance - red
    } else if (balance > 0) {
      return Colors.green; // Positive balance - green
    }
    return Colors.grey[800]!; // Zero balance - default color
  }

  void _showExportOptions() {
    if (_activeEstimationList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final parentContext = context; // ✅ Save current widget context

    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Export as PDF'),
                onTap: () {
                  Navigator.pop(context);
                  // _exportAsPdf(); // <- safe
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Colors.green),
                title: const Text('Export as CSV'),
                onTap: () {
                  Navigator.pop(context);
                  exportToCSV(parentContext, _activeEstimationList); // ✅ use saved context
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> exportToCSV(BuildContext context, List<EstimationItem> estimations) async {
    try {

      List<List<String>> rows = [
        [
          "#",
          "Work Type",
          "Cost Category",
          "Material Name",
          "Material Description",
          "Estimated Quantity",
          "Estimated Amount",
          "Actual Unit Price",
          "Total Requested Quantity",
          "Total Requested Amount",
          "Remaining Estimate Balance",
          "Request Status"
        ],
      ];
      // Populate data rows with all fields
      for (int i = 0; i < estimations.length; i++) {
        final estimation = estimations[i];
        rows.add([
          (i + 1).toString(), // Serial number
          estimation.workType,
          estimation.costCategory,
          estimation.materialName,
          estimation.materialDescription,
          NumberStyles.qtyStyle(estimation.estimatedQuantity.toString()),
          NumberStyles.currencyStyle(estimation.estimatedAmount.toString()),
          NumberStyles.currencyStyle(estimation.actualUnitPrice.toString()),
          NumberStyles.qtyStyle(estimation.totalRequestedQuantity.toString()),
          NumberStyles.currencyStyle(estimation.totalRequestedAmount.toString()),
          NumberStyles.currencyStyle((estimation.estimatedAmount-estimation.totalRequestedAmount).toString()),
          estimation.requestStatus,
        ]);
      }
      await MobileCSVExporter.export(
        context: context,
        headersAndRows: rows,
        fileNamePrefix: 'consume list $selectedProject $selectedLocation',
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
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_estimate_Item_consume.dart');
      PD.pd(text: e.toString());
      OneBtnDialog.oneButtonDialog(
        context,
        title: "Errors",
        message: "Failed to export CSV: $e",
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
    }
  }
}

class EstimationItem {
  final String workType;
  final String costCategory;
  final String materialName;
  final String materialDescription;
  final double estimatedQuantity;
  final double estimatedAmount;
  final double actualQuantity;
  final double actualUnitPrice;
  final double totalRequestedQuantity;
  final double totalRequestedAmount;
  final double remainingEstimateBalance;
  final double remainingActualBalance;
  final String requestStatus;

  EstimationItem({
    required this.workType,
    required this.costCategory,
    required this.materialName,
    required this.materialDescription,
    required this.estimatedQuantity,
    required this.estimatedAmount,
    required this.actualQuantity,
    required this.actualUnitPrice,
    required this.totalRequestedQuantity,
    required this.totalRequestedAmount,
    required this.remainingEstimateBalance,
    required this.remainingActualBalance,
    required this.requestStatus,
  });

  factory EstimationItem.fromJson(Map<String, dynamic> json) {
    return EstimationItem(
      workType: json['work_name'] ?? '',
      costCategory: json['cost_category'] ?? '',
      materialName: json['material_name'] ?? '',
      materialDescription: json['material_description'] ?? '',
      estimatedQuantity: double.tryParse(json['estimated_quantity']) ?? 0,
      estimatedAmount: double.tryParse(json['estimated_amount']) ?? 0,
      actualQuantity: double.tryParse(json['actual_quantity']) ?? 0,
      actualUnitPrice: double.tryParse(json['actual_unit_price']) ?? 0,
      totalRequestedQuantity: double.tryParse(json['total_requested_quantity']) ?? 0,
      totalRequestedAmount: double.tryParse(json['total_requested_amount']) ?? 0,
      remainingEstimateBalance: double.tryParse(json['remaining_estimate_balance']) ?? 0,
      remainingActualBalance:double.tryParse(json['remaining_actual_balance']) ?? 0,
      requestStatus: json['request_status'] ?? '',
    );
  }
}