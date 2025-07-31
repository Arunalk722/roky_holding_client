import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/number_format.dart';
import 'package:roky_holding/env/print_debug.dart';
import '../env/DialogBoxs.dart';
import '../env/app_logs_to.dart';
import '../env/input_widget.dart';
import 'package:pdf/widgets.dart' as pw;
import '../md_04/view_project_request_item_list.dart';
import 'package:roky_holding/env/platform_ind/csv_exporter.dart';


class PaymentRequestItemList {
  final String costCategory;
  final String workName;
  final String materialName;
  final String projectName;
  final String locationName;
  final String requestId;
  final String materialDescription;
  final String requestedQuantity;
  final String requestedAmount;
  final String actualAmount;
  final String costAmount;
  final String isActive;
  final String isVisible;
  final String statusOfPayment;
  final String createdDate;
  final String createdBy;
  final String changeDate;
  final String changeBy;
  final String isPost;
  final String referenceNumber;
  final String totalEstimateQuantity;
  final String totalEstimateAmount;
  final String uom;
  final String itemDis;
  PaymentRequestItemList({
    required this.costCategory,
    required this.workName,
    required this.materialName,
    required this.projectName,
    required this.locationName,
    required this.requestId,
    required this.materialDescription,
    required this.requestedQuantity,
    required this.requestedAmount,
    required this.actualAmount,
    required this.costAmount,
    required this.isActive,
    required this.isVisible,
    required this.statusOfPayment,
    required this.createdDate,
    required this.createdBy,
    required this.changeDate,
    required this.changeBy,
    required this.isPost,
    required this.referenceNumber,
    required this.totalEstimateQuantity,
    required this.totalEstimateAmount,
    required this.uom,
    required this.itemDis
  });

  factory PaymentRequestItemList.fromJson(Map<String, dynamic> json) {
    return PaymentRequestItemList(
      costCategory: json['cost_category']?.toString() ?? '',
      workName: json['work_name']?.toString() ?? '',
      materialName: json['material_name']?.toString() ?? '',
      projectName: json['project_name']?.toString() ?? '',
      locationName: json['location_name']?.toString() ?? '',
      requestId: json['request_id']?.toString() ?? '0',
      materialDescription: json['material_des']?.toString() ?? '',
      requestedQuantity: json['req_qty']?.toString() ?? '0.0',
      requestedAmount: json['req_amout']?.toString() ?? '0.0',
      actualAmount: json['actual_amount']?.toString() ?? '0.0',
      costAmount: json['cost_amount']?.toString() ?? '0.0',
      isActive: json['is_active']?.toString() ?? '0',
      isVisible: json['is_visible']?.toString() ?? '0',
      statusOfPayment: json['status_of_payment']?.toString() ?? '0',
      createdDate: json['created_date']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? '',
      changeDate: json['change_date']?.toString() ?? '',
      changeBy: json['change_by']?.toString() ?? '',
      isPost: json['is_post']?.toString() ?? '0',
      referenceNumber: json['req_ref_number']?.toString() ?? '',
      totalEstimateQuantity: json['total_estimate_qty']?.toString() ?? '0.0',
      totalEstimateAmount: json['total_estimate_amount']?.toString() ?? '0.0',
      uom: json['uom'],
      itemDis: json['item_disc']

    );
  }
}




class ProjectPaymentRequestItemsReportScreen extends StatefulWidget {
  const ProjectPaymentRequestItemsReportScreen({super.key});

  @override
  ProjectPaymentRequestItemsReportScreenState createState() =>
      ProjectPaymentRequestItemsReportScreenState();
}

class ProjectPaymentRequestItemsReportScreenState
    extends State<ProjectPaymentRequestItemsReportScreen> {
  List<PaymentRequestItemList> _requests = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final _txtDropDownProject = TextEditingController();
  final _txtDropDownLocation = TextEditingController();
  final _txtDropDownWorkType = TextEditingController();
  final _txtDropDownCostCategoty = TextEditingController();
  final _txtDropDownMaterial = TextEditingController();
  final _txtRequestId = TextEditingController();

  Map<String, Map<String, List<PaymentRequestItemList>>> groupedRequests = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dropDownToProject();
    });
  }

  String? selectedProject;
  List<String> _dropdownProjects = [];

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
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            _dropdownProjects = List<String>.from(
                (responseData['data'] ?? [])
                    .map((item) => item['project_name'].toString())
            );
          });
          _isLoading = false;
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
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_item_request_list.dart');
      PD.pd(text: e.toString());
    }
  }


  String? _selectedValueWorkType;
  List<String> _dropdownWorkType = [];

  Future<void> _loadActiveWorkList() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading works');


      String reqUrl =
          '${APIHost()
          .apiURL}/project_payment_controller.php/WorkCategoryTypeSelection';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token,
          "location_name": _txtDropDownLocation.text,
          "project_name": _txtDropDownProject.text
        }),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _dropdownWorkType = List<String>.from(
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
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_item_request_list.dart');
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


      String reqUrl =
          '${APIHost()
          .apiURL}/project_payment_controller.php/CostCategorySelectionByEstimationAndWorkId';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token,
          "work_name": workName,
          "location_name": _txtDropDownLocation.text,
          "project_name": _txtDropDownProject.text,
        }),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _dropdownCostCategory = List<String>.from(
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
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_item_request_list.dart');
      PD.pd(text: e.toString());
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }


  String? _selectedValueMaterial;
  List<String> _dropdownMaterial = [];

  Future<void> _loadActiveMaterialList(String? workName,
      String? costCategory) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading items list');

      String reqUrl =
          '${APIHost()
          .apiURL}/project_payment_controller.php/ListProjectRegisterdMaterial';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({
          "Authorization": APIToken().token,
          "location_name": _txtDropDownLocation.text,
          "project_name": _txtDropDownProject.text,
          "work_name": workName,
          "cost_category": costCategory,
        }),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        Navigator.pop(context);
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            _dropdownMaterial = List<String>.from(
                (responseData['data'] ?? [])
                    .map((item) => item['material_name'].toString())
            );
          });
          //PD.pd(text: _dropdownMaterial.toString());
        }
        else {
          Navigator.pop(context);
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
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_item_request_list.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    }
  }


  String? selectedLocation;
  List<String> _dropdownlocations = [];

  Future<void> _dropDownToProjectLocation(String project) async {
    _dropdownlocations.clear();
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading location');
      String reqUrl = '${APIHost()
          .apiURL}/location_controller.php/ListProjectActiveLocation';
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
            _dropdownlocations = List<String>.from(
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
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_item_request_list.dart');
      PD.pd(text: e.toString());
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    String apiURL = '${APIHost()
        .apiURL}/project_payment_controller.php/FilteredListOfItems';

    PD.pd(text: apiURL);
    try {
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "project_name": _txtDropDownProject.text,
          "location_name": _txtDropDownLocation.text,
          "work_name": _txtDropDownWorkType.text,
          "cost_category": _txtDropDownCostCategoty.text,
          "material_name": _txtDropDownMaterial.text,
          "request_id": _txtRequestId.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          List<dynamic> data = responseData['data'];
          setState(() {
            _requests =
                data.map((json) => PaymentRequestItemList.fromJson(json))
                    .toList();
            _isLoading = false;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Error loading requests';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'HTTP Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_item_request_list.dart');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }


  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    bool isDesktop = screenWidth > 800;

    return Scaffold(
      appBar: MyAppBar(appname: 'Project Wise Item Request List'),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
      )
          : _errorMessage.isNotEmpty
          ? Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _errorMessage,
            style: TextStyle(color: Colors.red[800], fontSize: 16),
          ),
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 30 : 15, vertical: 15),
          child: Column(
            children: [
              // Filter Card
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    collapsedBackgroundColor: Colors.transparent,
                    backgroundColor: Colors.transparent,
                    tilePadding: EdgeInsets.zero,
                    title: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_alt_rounded,
                              color: Colors.deepPurple, size: 28),
                          const SizedBox(width: 10),
                          const Text(
                            "Filter Options",
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
                      SizedBox(height: 15),
                      // Project and Location Row
                      Row(
                        children: [
                          Expanded(
                            flex: isDesktop ? 1 : 2,
                            child: CustomDropdown(
                              label: 'Select Project',
                              suggestions: _dropdownProjects,
                              icon: Icons.assignment,
                              controller: _txtDropDownProject,
                              onChanged: (value) {
                                selectedProject = value;
                                _dropDownToProjectLocation(
                                    value.toString());
                              },
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            flex: isDesktop ? 1 : 2,
                            child: CustomDropdown(
                              label: 'Select Location',
                              suggestions: _dropdownlocations,
                              icon: Icons.location_on,
                              controller: _txtDropDownLocation,
                              onChanged: (value) {
                                selectedLocation = value;
                                _loadActiveWorkList();
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      // Work Type and Category Row
                      Row(
                        children: [
                          Expanded(
                            flex: isDesktop ? 1 : 2,
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
                          SizedBox(width: 15),
                          Expanded(
                            flex: isDesktop ? 1 : 2,
                            child: CustomDropdown(
                              label: 'Select Category',
                              suggestions: _dropdownCostCategory,
                              icon: Icons.category,
                              controller: _txtDropDownCostCategoty,
                              onChanged: (value) {
                                _selectedValueCostCategory = value;
                                _loadActiveMaterialList(
                                    _selectedValueWorkType,
                                    _selectedValueCostCategory);
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Material and Request ID Row
                      Row(
                        children: [
                          Expanded(
                            flex: isDesktop ? 1 : 2,
                            child: _buildMaterialSection(),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            flex: isDesktop ? 1 : 2,
                            child: TextField(
                              controller: _txtRequestId,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[50],
                                hintText: '01',
                                labelText: 'Request ID',
                                border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey[300]!),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 25),
                      // Filter Button
                      Center(
                        child: ElevatedButton(
                          onPressed: fetchRequests,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 14),
                            elevation: 3,
                          ),
                          child: Text(
                            'FILTER REQUESTS',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 25),
              // Results Table
              buildTable(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_requests.isNotEmpty) {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
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
                        padding: EdgeInsets.all(15),
                        child: Text(
                          'Export Options',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800]),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.file_download,
                            color: Colors.blue[600]),
                        title: Text('Export CSV',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        onTap: () {
                          Navigator.pop(context);
                          exportPaymentRequestsToCSV(_requests);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.print, color: Colors.green[600]),
                        title: Text('Print PDF',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        onTap: () {
                          Navigator.pop(context);
                          exportAndPrintPaymentRequestsPdf();
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
        backgroundColor: Colors.blue[600],
        child: const Icon(FontAwesomeIcons.fileExport, color: Colors.white),
      ),
    );
  }

  Widget buildTable() {
    // Nested grouping: First by Project-Location, then by Request Reference Number
    var groupedRequests = <String, Map<String, List<PaymentRequestItemList>>>{};

    // Calculate totals for each reference number
    var refCostTotals = <String, double>{};
    var refActualTotals = <String, double>{};

    for (var request in _requests) {
      var projectLocationKey = "${request.projectName} - ${request
          .locationName}";
      var refKey = request.referenceNumber;
      groupedRequests.putIfAbsent(projectLocationKey, () => {});
      groupedRequests[projectLocationKey]!.putIfAbsent(refKey, () => []);
      groupedRequests[projectLocationKey]![refKey]!.add(request);

      // Calculate cost amount total
      double itemCost = double.tryParse(request.requestedAmount) ?? 0.0;
      double qty = double.tryParse(request.requestedQuantity) ?? 0.0;
      double reqAmount = qty * itemCost;
      double itemDiscount = double.tryParse(request.itemDis) ?? 0.0;
      double costAmount = reqAmount - itemDiscount;
      refCostTotals.update(
          refKey, (value) => value + costAmount, ifAbsent: () => costAmount);

      // Calculate actual amount total
      double actualAmount = double.tryParse(request.actualAmount) ?? 0.0;
      refActualTotals.update(refKey, (value) => value + actualAmount,
          ifAbsent: () => actualAmount);
    }

    return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.only(bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1024, // Fixed width
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
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                    4: FlexColumnWidth(2),
                    5: FlexColumnWidth(2),
                    6: FlexColumnWidth(2),
                    7: FlexColumnWidth(2),
                  },
                  children: [
                    // Table Header (unchanged)
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text("Ref No.",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text("Material Name",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text("Material Description",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text("Requested Quantity",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text("Req Unit Amount (Rs.)",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text("Actual Amount (Rs.)",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text("Cost Amount (Rs.)",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text("Actions",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),

                    // Dynamically create table rows
                    for (var projectLocationKey in groupedRequests.keys) ...[
                      // Project-Location Header (unchanged)
                      TableRow(
                        decoration: BoxDecoration(color: Colors.blue[50]),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              "Project: ${projectLocationKey.split(
                                  ' - ')[0]}\nLocation: ${projectLocationKey
                                  .split(' - ')[1]}",
                              style: TextStyle(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          for (int i = 0; i < 7; i++)
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(),
                            ),
                        ],
                      ),

                      // Request Rows under the current Project-Location
                      for (var refKey in groupedRequests[projectLocationKey]!
                          .keys) ...[
                        // RefKey Header - Now shows both actual and cost totals
                        TableRow(
                          decoration: BoxDecoration(color: Colors.blue[100]),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                "Ref No: $refKey",
                                style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                "Items: ${groupedRequests[projectLocationKey]![refKey]!
                                    .length}",
                                style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                "Total:",
                                style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(),
                            ),
                            // Actual Amount Total
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                NumberStyles.currencyStyle(
                                    refActualTotals[refKey].toString()),
                                style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            // Cost Amount Total
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                NumberStyles.currencyStyle(
                                    refCostTotals[refKey].toString()),
                                style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(),
                            ),
                          ],
                        ),

                        // Table Rows for each request under this RefKey (unchanged)
                        for (var request in groupedRequests[projectLocationKey]![refKey]!)
                          TableRow(
                            decoration: BoxDecoration(
                              color: _requests.indexOf(request) % 2 == 0
                                  ? Colors.white
                                  : Colors.grey[50],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(request.referenceNumber,
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(request.materialName,
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(request.materialDescription,
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  '${request.requestedQuantity} ${request.uom}',
                                  style: TextStyle(color: Colors.grey[800]),
                                  textAlign: TextAlign.right,),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  NumberStyles.currencyStyle(
                                      request.requestedAmount.toString()),
                                  style: TextStyle(color: Colors.grey[800]),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  NumberStyles.currencyStyle(
                                      request.actualAmount.toString()),
                                  style: TextStyle(color: Colors.grey[800]),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  NumberStyles.currencyStyle('${
                                      (double.tryParse(request.requestedQuantity
                                          .toString()) ?? 0)
                                          * (double.tryParse(
                                          request.requestedAmount.toString()) ??
                                          0) -
                                          (double.tryParse(
                                              request.itemDis.toString()) ?? 0)
                                  }'),
                                  style: TextStyle(color: Colors.grey[800]),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ViewConstructionRequestList(
                                              requestId: request.requestId,
                                              isNotApprove: false,
                                              refNumber: request
                                                  .referenceNumber,
                                            ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  child: Text("View",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),)
    );
  }


  Widget _buildMaterialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _selectedValueMaterial ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) {
            // Filter workTypes based on user input
            return _dropdownMaterial.where((word) =>
                word.toLowerCase().contains(
                    textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) {
            setState(() {
              _selectedValueMaterial = selection;
              _txtDropDownMaterial.text =
                  selection; // Update controller when an item is selected
            });
          },
          fieldViewBuilder: (context, textEditingController, focusNode,
              onFieldSubmitted) {
            return TextFormField(
              maxLength: 45,
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'Cement',
                labelText: 'Material Creating',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _txtDropDownMaterial.text = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please select material';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }


  Future<void> exportPaymentRequestsToCSV(
      List<PaymentRequestItemList> requests) async {
    try {
      List<List<String>> rows = [
        [
          "Ref No.",
          "Cost Category",
          "Work Name",
          "Material Name",
          "Project Name",
          "Location Name",
          "Request ID",
          "Material Description",
          "Requested Quantity",
          "Req Unit Amount",
          "Actual Amount",
          "Cost Amount",
          "Is Active",
          "Is Visible",
          "Status of Payment",
          "Created Date",
          "Created By",
          "Change Date",
          "Change By",
          "Is Post",
          "Total Estimate Quantity",
          "Total Estimate Amount"
        ],
      ];
      for (var request in requests) {
        rows.add([
          request.referenceNumber,
          request.costCategory,
          request.workName,
          request.materialName,
          request.projectName,
          request.locationName,
          request.requestId,
          request.materialDescription,
          request.requestedQuantity,
          request.requestedAmount,
          request.actualAmount,
          request.costAmount,
          request.isActive,
          request.isVisible,
          request.statusOfPayment,
          request.createdDate,
          request.createdBy,
          request.changeDate ?? "N/A",
          request.changeBy ?? "N/A",
          request.isPost,
          request.totalEstimateQuantity,
          request.totalEstimateAmount,
        ]);
      }
      await MobileCSVExporter.export(
        context: context,
        headersAndRows: rows,
        fileNamePrefix: 'request item $selectedProject $selectedLocation',
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
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_item_request_list.dart');
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


  Future<pw.Document> generatePaymentRequestItemListPdf(
      List<PaymentRequestItemList> requests) async {
    final pdf = pw.Document();
    final printedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(
        DateTime.now());

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

    try {
      // Group requests by reference number
      Map<String, List<PaymentRequestItemList>> groupedRequests = {};
      for (var request in requests) {
        groupedRequests.putIfAbsent(request.referenceNumber ?? "N/A", () => []);
        groupedRequests[request.referenceNumber ?? "N/A"]?.add(request);
      }

      pdf.addPage(
        pw.MultiPage(
          footer: (pw.Context context) =>
              pw.Container(
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
                          style: pw.TextStyle(fontSize: 10,
                              font: ttf,
                              fontStyle: pw.FontStyle.italic),
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
            double totalAmount = requests.fold(0.0, (sum, item) {
              return sum + (double.tryParse(item.costAmount ?? '0') ?? 0);
            });

            // Log the total calculation result
            PD.pd(text: "Total Estimate Amount Calculated: $totalAmount");

            List<pw.Widget> content = [
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
                        'Payment Request Items Report',
                        style: pw.TextStyle(fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            font: ttfBold),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Printed on: $printedDateTime',
                        style: pw.TextStyle(fontSize: 10,
                            font: ttf,
                            fontStyle: pw.FontStyle.italic),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),

              // Filter information
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 10),
                  pw.Text('Total Items: ${requests.length}',
                      style: pw.TextStyle(fontSize: 12, font: ttfBold)),
                  pw.Text('Request Item Total Estimate Amount: ${NumberFormat(
                      '#,###.00', 'en_US').format(totalAmount)} LKR',
                      style: pw.TextStyle(fontSize: 12, font: ttfBold)),
                ],
              ),

              pw.SizedBox(height: 20),

              // Iterate over each group
              ...groupedRequests.entries.map((entry) {
                final groupReferenceNumber = entry.key;
                final groupRequests = entry.value;

                // Sum actual amount for the group
                double groupTotalActualAmount = groupRequests.fold(
                    0.0, (sum, item) {
                  return sum + (double.tryParse(item.actualAmount ?? '0') ?? 0);
                });

                return [
                  // Group Header
                  pw.Text(
                    'Reference No: $groupReferenceNumber',
                    style: pw.TextStyle(fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        font: ttfBold),
                  ),
                  pw.SizedBox(height: 10),

                  // Group Table
                  pw.Table.fromTextArray(
                    border: pw.TableBorder.all(color: PdfColors.grey500),
                    headerDecoration: pw.BoxDecoration(
                        color: PdfColors.deepPurple),
                    headerHeight: 30,
                    cellHeight: 25,
                    headerStyle: pw.TextStyle(color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        font: ttfBold),
                    cellStyle: pw.TextStyle(fontSize: 8, font: ttf),
                    cellAlignment: pw.Alignment.centerLeft,
                    headers: [
                      'Work Type',
                      'Category',
                      'Material',
                      'Req. Qty',
                      'Unit. Amt (LKR)',
                      'Act. Amt (LKR)',
                    ],
                    data: groupRequests.map((request) {
                      return [
                        request.workName,
                        request.costCategory,
                        request.materialDescription ?? "N/A",
                        '${request.requestedQuantity} ${request.uom}' ?? "N/A",
                        NumberFormat('#,###.00', 'en_US').format(
                            double.tryParse(request.requestedAmount ?? '0') ??
                                0),
                        NumberFormat('#,###.00', 'en_US').format(
                            double.tryParse(request.actualAmount ?? '0') ?? 0),
                      ];
                    }).toList(),
                  ),

                  // Group Total (Sum of Actual Amount)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Group Total (Actual Amt): ${NumberFormat(
                            '#,###.00', 'en_US').format(
                            groupTotalActualAmount)} LKR',
                        style: pw.TextStyle(fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            font: ttfBold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  // No margin needed, you can reduce this or remove it entirely
                ];
              }).expand((x) => x).toList(), // Flatten the list of widgets

              pw.SizedBox(height: 40),

              // Footer copyright
              pw.Center(
                child: pw.Text(
                  '© ${DateTime
                      .now()
                      .year} Hela Software Solution',
                  style: pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600, font: ttf),
                ),
              ),
            ];
            return content; // Return a list of widgets
          },
        ),
      );

      return pdf;
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_item_request_list.dart');

      OneBtnDialog.oneButtonDialog(
        context,
        title: "Error",
        message: "Failed to generate PDF: $e",
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
      rethrow;
    }
  }


  Future<void> exportAndPrintPaymentRequestsPdf() async {
    try {
      if (_requests.isEmpty) {
        throw Exception("No payment requests data to export");
      }
      WaitDialog.showWaitDialog(context, message: 'Generating PDF');
      final pdf = await generatePaymentRequestItemListPdf(
          _requests
      );
      WaitDialog.hideDialog(context);

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_item_request_list.dart');
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