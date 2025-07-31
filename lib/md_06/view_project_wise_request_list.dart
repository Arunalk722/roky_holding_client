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
import 'package:roky_holding/env/sp_format_data.dart';
import 'package:roky_holding/env/text_input_object.dart';
import 'package:roky_holding/md_04/view_project_request_item_list.dart';
import 'package:roky_holding/env/print_debug.dart';
import '../env/DialogBoxs.dart';
import '../env/app_logs_to.dart';
import '../env/input_widget.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:roky_holding/env/platform_ind/csv_exporter.dart';


class PaymentRequest {
  final int id;
  final String receiverName;
  final String receiverMobile;
  final String requestDate;
  final String comment;
  final String totalAmount;
  final int isAuth;
  final int isAppro;
  final String paymentType;
  final String? bankBranch;
  final String? accountNumber;
  final String? authCmt;
  final String? authUser;
  final String? authTime;
  final String? approCmt;
  final String? approUser;
  final String? approTime;
  final String? refNum;
  final String? iouNumber;
  final String? createBy;
  final String? createdDate;
  final String? projectName;
  final String? locationName;
  final String? eventType;
  final String? benfName;

  // New fields
  final int? projectId;
  final int? locationId;
  final int? estimationId;
  final int? bankId;
  final int? statusId;
  final int? paymethId;
  final int? isActive;
  final int? accId;
  final int? isPaid;
  final int? pmtStatus;
  final int? isVisible;
  final int? isPost;
  final int? isEnable;

  final String? requestedAmount;
  final String? sscl;
  final String? vat;
  final String? addtDiscount;
  final String? paymentRef;
  final String? payedDate;
  final String? pmtCmt;
  final String? pmtUser;
  final String? pmtTime;
  final String? changeDate;
  final String? changeBy;
  final String? totalReqAmount;
  final String? totalItemDisc;

  PaymentRequest({
    required this.id,
    required this.receiverName,
    required this.receiverMobile,
    required this.requestDate,
    required this.comment,
    required this.totalAmount,
    required this.isAuth,
    required this.isAppro,
    required this.paymentType,
    this.benfName,
    this.iouNumber,
    this.createdDate,
    this.createBy,
    this.bankBranch,
    this.accountNumber,
    this.authCmt,
    this.authUser,
    this.authTime,
    this.approCmt,
    this.approUser,
    this.approTime,
    this.refNum,
    this.projectName,
    this.locationName,
    this.eventType,
    // new fields
    this.projectId,
    this.locationId,
    this.estimationId,
    this.bankId,
    this.statusId,
    this.paymethId,
    this.isActive,
    this.accId,
    this.isPaid,
    this.pmtStatus,
    this.isVisible,
    this.isPost,
    this.isEnable,
    this.requestedAmount,
    this.sscl,
    this.vat,
    this.addtDiscount,
    this.paymentRef,
    this.payedDate,
    this.pmtCmt,
    this.pmtUser,
    this.pmtTime,
    this.changeDate,
    this.changeBy,
    this.totalReqAmount,
    this.totalItemDisc,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['tbl_user_payment_request_id'] as int? ?? 0,
      receiverName: json['receiver_name'] as String? ?? '',
      receiverMobile: json['receiver_mobile'] as String? ?? '',
      requestDate: json['request_date'] as String? ?? '',
      comment: json['cmt'] as String? ?? '',
      totalAmount: json['total_actual_amount']?.toString() ?? '0.00',
      isAuth: json['is_auth'] as int? ?? 0,
      isAppro: json['is_appro'] as int? ?? 0,
      paymentType: json['payment_type'] as String? ?? '',
      bankBranch: json['bank_branch'] as String?,
      accountNumber: json['account_number']?.toString(),
      authCmt: json['auth_cmt'] as String?,
      authUser: json['auth_user'] as String?,
      authTime: json['auth_time'] as String?,
      approCmt: json['appro_cmt'] as String?,
      approUser: json['appro_user'] as String?,
      approTime: json['appro_time'] as String?,
      refNum: json['req_ref_number'] as String?,
      iouNumber: json['iou_number']?.toString() ?? 'NA',
      createBy: json['created_by'] as String?,
      createdDate: json['created_date'] as String?,
      projectName: json['project_name'] as String?,
      locationName: json['location_name'] as String?,
      eventType: json['event_type'] as String?,
      benfName: json['beneficiary_name']?.toString() ?? 'NA',

      // new fields
      projectId: json['project_id'] as int?,
      locationId: json['location_id'] as int?,
      estimationId: json['estimation_id'] as int?,
      bankId: json['bank_id'] as int?,
      statusId: json['status_id'] as int?,
      paymethId: json['paymeth_id'] as int?,
      isActive: json['is_active'] as int?,
      accId: json['acc_id'] as int?,
      isPaid: json['is_paid'] as int?,
      pmtStatus: json['pmt_status'] as int?,
      isVisible: json['is_visible'] as int?,
      isPost: json['is_post'] as int?,
      isEnable: json['is_enable'] as int?,
      requestedAmount: json['requested_amount']?.toString(),
      sscl: json['sscl']?.toString(),
      vat: json['vat']?.toString(),
      addtDiscount: json['addt_discount']?.toString(),
      paymentRef: json['payment_ref']?.toString(),
      payedDate: json['payed_date']?.toString(),
      pmtCmt: json['pmt_cmt']?.toString(),
      pmtUser: json['pmt_user']?.toString(),
      pmtTime: json['pmt_time']?.toString(),
      changeDate: json['change_date']?.toString(),
      changeBy: json['change_by']?.toString(),
      totalReqAmount: json['total_req_amount']?.toString(),
      totalItemDisc: json['total_item_disc']?.toString(),
    );
  }
}


class ProjectPaymentRequestReportScreen extends StatefulWidget {
  const ProjectPaymentRequestReportScreen({super.key});

  @override
  ProjectPaymentRequestReportScreenState createState() =>
      ProjectPaymentRequestReportScreenState();
}

class ProjectPaymentRequestReportScreenState
    extends State<ProjectPaymentRequestReportScreen> {
  List<PaymentRequest> _requests = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _fromDate;
  String? _toDate;
  final _txtDropDownProject = TextEditingController();
  final _txtDropDownLocation = TextEditingController();
  Map<String, Map<String, List<PaymentRequest>>> groupedRequests = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dropDownToProject();
    });
  }

  bool isPaymentOk = true;
  final _txtBeneficiaryName = TextEditingController();
  String? selectedProject;
  List<String> projects = [];

  Future<void> _dropDownToProject() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading project');
      String reqUrl = '${APIHost().apiURL}/project_controller.php/listAll';
      PD.pd(text: reqUrl.toString());
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
            projects = List<String>.from(
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
          logFile: 'view_project_wise_request_list.dart');
      PD.pd(text: e.toString());
    }
  }


  String? selectedLocation;
  List<String> locations = [];

  Future<void> _dropDownToProjectLocation(String project) async {
    locations.clear();
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
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'view_project_wise_request_list.dart');
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

    String reqUrl = '${APIHost()
        .apiURL}/project_payment_controller.php/ViewAllOnRpt';
    PD.pd(text: reqUrl);
    try {
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "start_date": _fromDate,
          "end_date": _toDate,
          "project_name": _txtDropDownProject.text,
          "location_name": _txtDropDownLocation.text,
          "is_paid": isPaymentOk ? '1' : '0',
          "beneficiary_name": _txtBeneficiaryName.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          List<dynamic> data = responseData['data'];
          setState(() {
            _requests =
                data.map((json) => PaymentRequest.fromJson(json)).toList();
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
          logFile: 'view_project_wise_request_list.dart');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    bool isDesktop = screenWidth > 800;

    return Scaffold(
      appBar: MyAppBar(appname: 'View Project Wise Request List'),
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
        child: Column(
          children: [
            // Filter Card with Icon
            Card(
              elevation: 4,
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Icon at the top of the ExpansionTile

                  ExpansionTile(
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
                    initiallyExpanded: true,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: isDesktop ? 1 : 2,
                                  child: CustomDropdown(
                                    label: 'Select Project',
                                    suggestions: projects,
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
                                    suggestions: locations,
                                    icon: Icons.location_on,
                                    controller: _txtDropDownLocation,
                                    onChanged: (value) {
                                      selectedLocation = value;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            Row(
                                children: [
                                  Expanded(flex: isDesktop ? 1 : 2,
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: isPaymentOk,
                                          onChanged: (value) {
                                            setState(() {
                                              isPaymentOk = value ?? false;
                                            });
                                          },
                                        ),
                                        const Text('Payment Completed'),
                                      ],
                                    ),),
                                  Expanded(flex: isDesktop ? 1 : 2,
                                    child: buildTextField(
                                        _txtBeneficiaryName, 'Beneficiary Name',
                                        'Enter beneficiary name', Icons.person,
                                        true, 45),)
                                ]
                            ),
                            SizedBox(height: 0),
                            Row(
                              children: [
                                Expanded(
                                  flex: isDesktop ? 1 : 2,
                                  child: DatePickerWidget(
                                    label: 'From Date',
                                    onDateSelected: (selectedDate) {
                                      setState(() {
                                        _fromDate = selectedDate;
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  flex: isDesktop ? 1 : 2,
                                  child: DatePickerWidget(
                                    label: 'To Date',
                                    onDateSelected: (selectedDate) {
                                      setState(() {
                                        _toDate = selectedDate;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Center(
                              child: ElevatedButton(
                                onPressed: fetchRequests,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 14),
                                  elevation: 3,
                                ),
                                child: Text(
                                  'APPLY FILTERS',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Results Table
            buildTable(),
          ],
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
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
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
                            style:
                            TextStyle(fontWeight: FontWeight.w500)),
                        onTap: () {
                          Navigator.pop(context);
                          exportPaymentRequestsToCSV(_requests);
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
    // Grouping requests by project and location name
    var groupedRequests = <String, List<PaymentRequest>>{};
    var projectTotals = <String, double>{}; // For amount totals per project
    var projectCounts = <String, int>{}; // For count totals per project
    double grandTotal = 0.0;
    int grandCount = 0;

    for (var request in _requests) {
      var groupKey = "${request.projectName} - ${request.locationName}";
      if (groupedRequests[groupKey] == null) {
        groupedRequests[groupKey] = [];
      }
      groupedRequests[groupKey]!.add(request);

      double totalAmount = double.tryParse(request.totalAmount) ?? 0.0;
      double itemsDiscount = double.tryParse(
          request.totalItemDisc.toString()) ?? 0.0;
      double vat = double.tryParse(request.vat.toString()) ?? 0.0;
      double sscl = double.tryParse(request.sscl.toString()) ?? 0.0;
      double addDisc = double.tryParse(request.addtDiscount.toString()) ?? 0.0;
      double costAmount = totalAmount + vat + sscl - addDisc - itemsDiscount;


      projectTotals.update(
          groupKey, (value) => value + costAmount, ifAbsent: () => costAmount);
      projectCounts.update(groupKey, (value) => value + 1, ifAbsent: () => 1);

      grandTotal += costAmount;
      grandCount++;
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
              width: 1024,
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
                    // Table Header
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            "Date",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            "Ref No.",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            "Receiver",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            "Benf Name",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            "Payment Type",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            "Amount (Rs.)",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            "Status",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            "Actions",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Dynamically create table rows, grouped by project and location
                    for (var groupKey in groupedRequests.keys)
                      ...[
                        // Group header
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                "Project: ${groupKey.split(
                                    ' - ')[0]}\nLocation: ${groupKey.split(
                                    ' - ')[1]}",
                                style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                "Requests: ${projectCounts[groupKey]}",
                                style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            for (int i = 0; i < 3; i++)
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                NumberStyles.currencyStyle(
                                    projectTotals[groupKey].toString()),
                                style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            for (int i = 0; i < 2; i++)
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(),
                              ),
                          ],
                        ),
                        // Table rows for this group
                        for (var request in groupedRequests[groupKey]!)
                          TableRow(
                            decoration: BoxDecoration(
                              color: groupedRequests[groupKey]!.indexOf(
                                  request) %
                                  2 ==
                                  0
                                  ? Colors.white
                                  : Colors.grey[50],
                            ),
                            children: [

                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(request.requestDate,
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(request.refNum ?? "N/A",
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(request.receiverName,
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(request.benfName.toString(),
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(request.paymentType,
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  NumberStyles.currencyStyle(
                                      '${(double.tryParse(
                                          request.totalAmount) ?? 0) +
                                          (double.tryParse(
                                              request.vat ?? '0') ?? 0) +
                                          (double.tryParse(
                                              request.sscl ?? '0') ?? 0) -
                                          (double.tryParse(
                                              request.addtDiscount ?? '0') ??
                                              0) -
                                          (double.tryParse(
                                              request.totalItemDisc ?? '0') ??
                                              0)}'
                                  ),
                                  style: TextStyle(color: Colors.grey[800]),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(request.eventType.toString(),
                                    style: TextStyle(color: Colors.grey[800])),
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
                                              requestId: request.id.toString(),
                                              isNotApprove: false,
                                              refNumber: request.refNum ??
                                                  "N/A",
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
                                  child: const Text("View",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    // Grand Total Row
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            "GRAND TOTAL",
                            style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        for (int i = 0; i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Container(),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            "Requests: $grandCount",
                            style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            NumberStyles.currencyStyle(
                                grandTotal.toString()),
                            style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        for (int i = 0; i < 2; i++)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Container(),
                          ),
                      ],
                    ),
                  ],
                ),)
          ),
        ),
      ),
    );
  }

  Future<void> exportPaymentRequestsToCSV(List<PaymentRequest> requests) async {
    try {
      // Define headers for the CSV
      List<List<String>> rows = [
        [
          "Ref No.",
          "IOU Number",
          "Project",
          "Location",
          "Receiver Name",
          "Receiver Mobile",
          "Request Date",
          "Payment Type",
          "Bank Branch",
          "Account Number",
          "Amount (Rs.)",
          "VAT (Rs.)",
          "SSCL (Rs.)",
          "Add Dis (Rs.)",
          "Items Dis (Rs.)",
          "Status",
          "Authorized By",
          "Authorized Time",
          "Authorized Comment",
          "Approved By",
          "Approved Time",
          "Approved Comment",
          "Created By",
          "Created Date",
          "Comment"
        ],
      ];

      // Populate data rows
      for (var request in requests) {
        rows.add([
          request.refNum ?? "N/A",
          IOUNumber.iouNumber(val: request.iouNumber.toString()) ?? "N/A",
          request.projectName ?? "N/A",
          request.locationName ?? "N/A",
          request.receiverName,
          request.receiverMobile,
          request.requestDate,
          request.paymentType,
          request.bankBranch ?? "N/A",
          request.accountNumber ?? "N/A",
          NumberStyles.currencyStyle(request.totalAmount),
          NumberStyles.currencyStyle(request.vat.toString()),
          NumberStyles.currencyStyle(request.sscl.toString()),
          '-${NumberStyles.currencyStyle(request.addtDiscount.toString())}',
          '-${NumberStyles.currencyStyle(request.totalItemDisc.toString())}',
          request.eventType ?? "N/A",
          request.authUser ?? "N/A",
          request.authTime ?? "N/A",
          request.authCmt ?? "N/A",
          request.approUser ?? "N/A",
          request.approTime ?? "N/A",
          request.approCmt ?? "N/A",
          request.createBy ?? "N/A",
          request.createdDate ?? "N/A",
          request.comment
        ]);
      }

      // Convert to CSV format
      await MobileCSVExporter.export(
        context: context,
        headersAndRows: rows,
        fileNamePrefix: 'project wise $selectedProject $selectedLocation',
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
          logFile: 'view_project_wise_request_list.dart');
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
}