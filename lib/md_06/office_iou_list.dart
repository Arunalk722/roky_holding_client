import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/sp_format_data.dart';
import 'package:roky_holding/md_04/view_ofz_request_list.dart';
import 'package:roky_holding/env/print_debug.dart';
import 'package:roky_holding/env/platform_ind/csv_exporter.dart';
import '../env/DialogBoxs.dart';
import '../env/app_logs_to.dart';
import 'package:pdf/widgets.dart' as pw;
import '../env/input_widget.dart';
import '../env/number_format.dart';

class PaymentRequest {
  final int id;
  final String refNum;
  final String receiverName;
  final String receiverMobile;
  final String requestDate;
  final String comment;
  final String totalAmount;

  final String vat;
  final String sscl;
  final String addDis;
  final String itemDis;

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
  final String? paymentRef;
  final String? payedDate;
  final String? createdBy;
  final String? createdDate;
  final String? eventType;
  final String? iouNumber;
  PaymentRequest({
    required this.id,
    required this.refNum,
    required this.receiverName,
    required this.receiverMobile,
    required this.requestDate,
    required this.comment,
    required this.totalAmount,
    required this.isAuth,
    required this.isAppro,
    required this.paymentType,
    required this.iouNumber,
    required this.bankBranch,
    required this.accountNumber,
    required this.authCmt,
    required this.authUser,
    required this.authTime,
    required this.approCmt,
    required this.approUser,
    required this.approTime,
    required this.paymentRef,
    required this.payedDate,
    required this.createdBy,
    required this.createdDate,
    required this.eventType,

    required this.vat,
    required this.sscl,
    required this.addDis,
    required this.itemDis,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['idtbl_ofz_request'] as int? ?? 0,
      iouNumber:json['iou_number'] ,
      refNum: json['req_ref_number'] as String? ?? '',
      receiverName: json['receiver_name'] as String? ?? '',
      receiverMobile: json['receiver_mobile'] as String? ?? '',
      requestDate: json['request_date'] as String? ?? '',
      comment: json['cmt'] as String? ?? '',
      totalAmount: json['total'] as String? ?? '0.00',
      isAuth: json['is_auth'] as int? ?? 0,
      isAppro: json['is_appro'] as int? ?? 0,
      paymentType: json['payment_type'] as String? ?? '',
      bankBranch: json['bank_branch'] as String?,
      accountNumber: json['account_number'] as String?,
      authCmt: json['auth_cmt'] as String?,
      authUser: json['auth_user'] as String?,
      authTime: json['auth_time'] as String?,
      approCmt: json['appro_cmt'] as String?,
      approUser: json['appro_user'] as String?,
      approTime: json['appro_time'] as String?,
      paymentRef: json['payment_ref'] as String?,
      payedDate: json['iou_Date'] as String?,
      createdBy: json['created_by'] as String?,
      createdDate: json['created_date'] as String?,
      eventType: json['event_type'] as String?,
      vat: json['vat'],
      sscl: json['sscl'],
      addDis: json['add_dis'],
      itemDis: json['item_dis'],

    );
  }
}


class OfficeIOUList extends StatefulWidget {
  const OfficeIOUList({super.key});

  @override
  OfficeIOUListState createState() =>
      OfficeIOUListState();
}

class OfficeIOUListState
    extends State<OfficeIOUList> {
  List<PaymentRequest> _requests = [];

  String? _fromDate;
  String? _toDate;
  Map<String, Map<String, List<PaymentRequest>>> groupedRequests = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOfzMainCategoryList();
    });
  }

  final _txtMainCategoryDropDown = TextEditingController();
  final _txtSubCategoryDropDown = TextEditingController();


  List<String> _dropdownOfzMainCategory = [];
  List<dynamic> _activeOfzMainCategoryListMap = [];

  Future<void> _loadOfzMainCategoryList() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Item Category');


      String reqUrl =
          '${APIHost().apiURL}/ofz_payment_controller.php/GetMainCategory';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token,
        }),
      );

      PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _activeOfzMainCategoryListMap = responseData['data'] ?? [];
            _dropdownOfzMainCategory = _activeOfzMainCategoryListMap
                .map<String>((item) => item['main_name'].toString())
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
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'office_iou.dart');
      PD.pd(text: e.toString());
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }


  List<String> _dropdownOfzSubCategory = [];
  List<dynamic> _activeOfzSubCategoryListMap = [];

  Future<void> _loadOfzSubCategoryList(String? mainCategory) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Sub Category');
      String reqUrl = '${APIHost()
          .apiURL}/ofz_payment_controller.php/GetSubCategory';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "main_name": mainCategory,
        }),
      );
      PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            Navigator.pop(context);
            _activeOfzSubCategoryListMap = responseData['data'] ?? [];
            _dropdownOfzSubCategory = _activeOfzSubCategoryListMap
                .map<String>((item) => item['sub_name'].toString())
                .toList();
            _txtSubCategoryDropDown.clear();
          });
        } else {
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
        Navigator.pop(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'office_iou.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    }
  }

  bool _hasData = false;

  Future<void> fetchRequests() async {
    void scaffoleMessage(String message, Color color) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }

    String apiURL = '${APIHost()
        .apiURL}/ofz_payment_controller.php/ViewOfficeIOUReport';
    PD.pd(text: apiURL.toString());
    try {
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "start_date": _fromDate,
          "end_date": _toDate,
          "main_category": _txtMainCategoryDropDown.text,
          "sub_category": _txtSubCategoryDropDown.text,
          "item_name": _txtMaterialDropDown.text
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
            scaffoleMessage('Scanned'.toString(), Colors.green);
          });
        } else {
          scaffoleMessage(responseData['message'].toString(), Colors.red);
        }
      } else {
        scaffoleMessage('HTTP Error: ${response.statusCode}', Colors.red);
      }
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'office_iou_list.dart');
      scaffoleMessage('Error: ${e.toString()}', Colors.red);
    }
  }

  final _txtMaterialDropDown = TextEditingController();
  String? _selectedOfzItem;
  List<String> _dropdownOfzItem = [];
  List<dynamic> _activeOfzItemListMap = [];

  Future<void> _loadOfzItemList(String? mainCategory, String? subName) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Items');
      String reqUrl = '${APIHost()
          .apiURL}/ofz_payment_controller.php/GetMaterialItem';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "main_name": mainCategory, // Use the stored value
          "sub_name": subName,
        }),
      );

      PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            Navigator.pop(context);
            _activeOfzItemListMap = responseData['data'] ?? [];
            _dropdownOfzItem = _activeOfzItemListMap
                .map<String>((item) => item['item_name'].toString())
                .toList();
            _selectedOfzItem = null;
            _txtMaterialDropDown.clear();
          });
        } else {
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
        Navigator.pop(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'office_payment_request_form.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appname: 'Office IOU Lists'),
      body: Column(
        children: [
          Card(
            elevation: 5,
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            child: ExpansionTile(
              initiallyExpanded: true,
              collapsedBackgroundColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              tilePadding: const EdgeInsets.symmetric(horizontal: 10),
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.filter_alt_rounded,
                        color: Colors.deepPurple, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      "Filter Options",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Main and Sub Category Dropdowns
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Main Category',
                              items: _dropdownOfzMainCategory,
                              controller: _txtMainCategoryDropDown,
                              onChanged: (value) {
                                _txtMainCategoryDropDown.text = value ?? '';
                                _loadOfzSubCategoryList(value);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Sub Category',
                              items: _dropdownOfzSubCategory,
                              controller: _txtSubCategoryDropDown,
                              onChanged: (value) {
                                _txtSubCategoryDropDown.text = value ?? '';
                                _loadOfzItemList(_txtMainCategoryDropDown.text,
                                    _txtSubCategoryDropDown.text);
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                              flex: 6,
                              child: Padding(padding: EdgeInsets.only(top: 0),
                                child: _buildMaterialSection(),
                              )),
                        ],
                      ),
                      const SizedBox(height: 0),
                      // Date Picker Row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return constraints.maxWidth > 600
                              ? Row(children: _buildDatePickers())
                              : Column(children: _buildDatePickers());
                        },
                      ),
                      const SizedBox(height: 24),

                      // Search Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: fetchRequests,
                          icon: const Icon(Icons.search, size: 20),
                          label: const Text(
                            'SEARCH IOU RECORDS',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: buildTable(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_requests.isNotEmpty) {
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
    // Sort the requests by IOU ID
    _requests.sort((a, b) =>
        DateTime.parse(a.payedDate.toString()).compareTo(
            DateTime.parse(b.payedDate.toString())));

    var groupedIOUs = <String, List<PaymentRequest>>{};
    var projectTotals = <String, double>{};
    var projectCounts = <String, int>{};
    double grandTotal = 0.0;
    int grandCount = 0;

    for (var iou in _requests) {
      var groupKey = DateFormat('yyyy-MM-dd').format(
          DateTime.parse(iou.payedDate.toString()));
      groupedIOUs.putIfAbsent(groupKey, () => []).add(iou);

      double totalAmo = double.tryParse(iou.totalAmount) ?? 0.0;
      double vat = double.tryParse(iou.vat) ?? 0.0;
      double sscl = double.tryParse(iou.sscl) ?? 0.0;
      double addDis = double.tryParse(iou.addDis) ?? 0.0;
      double itemDis = double.tryParse(iou.itemDis) ?? 0.0;
      double amount = totalAmo + vat + sscl - addDis - itemDis;
      projectTotals.update(
          groupKey, (val) => val + amount, ifAbsent: () => amount);
      projectCounts.update(groupKey, (val) => val + 1, ifAbsent: () => 1);

      grandTotal += amount;
      grandCount++;
    }

    // Sort group keys by date (parsed from groupKey string)
    var sortedGroupKeys = groupedIOUs.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
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
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(color: Colors.blue[600]),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text("Date", style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text("IOU ID", style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text("Ref No.", style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text("Receiver/Beneficiary",
                                style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),

                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text("Type", style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text("Amount (Rs.)", style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text("Payment Ref", style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text("Paid Account", style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text("View", style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),

                      // Grouped rows
                      for (var groupKey in sortedGroupKeys)
                        ...[
                          // Group Header Row
                          TableRow(
                            decoration: BoxDecoration(color: Colors.blue[50]),
                            children: [
                              Padding(padding: EdgeInsets.all(12.0),
                                  child: Container()),
                              Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text(
                                  groupKey,
                                  style: TextStyle(color: Colors.blue[800],
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text("IOUs: ${projectCounts[groupKey]}",
                                    style: TextStyle(color: Colors.blue[800],
                                        fontWeight: FontWeight.bold)),
                              ),
                              for (int i = 0; i < 2; i++) Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Container()),
                              Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text(
                                    NumberStyles.currencyStyle(
                                        projectTotals[groupKey].toString()),
                                    style: TextStyle(color: Colors.blue[800],
                                        fontWeight: FontWeight.bold), textAlign: TextAlign.right,),
                              ),
                              for (int i = 0; i < 3; i++) Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Container()),
                            ],
                          ),
                          // Data rows
                          for (var iou in groupedIOUs[groupKey]!)
                            TableRow(
                              decoration: BoxDecoration(
                                color: groupedIOUs[groupKey]!.indexOf(iou) %
                                    2 == 0 ? Colors.white : Colors.grey[50],
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text(iou.requestDate.toString()),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text(IOUNumber.iouNumber(
                                      val: iou.id.toString()),
                                      style: TextStyle(
                                          color: Colors.grey[800])),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text(iou.refNum, style: TextStyle(
                                      color: Colors.grey[800])),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text(iou.receiverName,
                                      style: TextStyle(
                                          color: Colors.grey[800])),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text(iou.paymentType,
                                      style: TextStyle(
                                          color: Colors.grey[800])),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    NumberStyles.currencyStyle(
                                        (
                                            (double.tryParse(iou.totalAmount) ??
                                                0.0) +
                                                (double.tryParse(iou.vat) ??
                                                    0.0) +
                                                (double.tryParse(iou.sscl) ??
                                                    0.0) -
                                                (double.tryParse(iou.addDis) ??
                                                    0.0) -
                                                (double.tryParse(iou.itemDis) ??
                                                    0.0)
                                        ).toStringAsFixed(2)
                                    ),
                                    style: TextStyle(color: Colors.grey[800]),
                                    textAlign: TextAlign.right,
                                  ),
                                ),

                                Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text(iou.paymentRef.toString(),
                                      style: TextStyle(
                                          color: Colors.grey[800])),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text(iou.accountNumber.toString(),
                                      style: TextStyle(
                                          color: Colors.grey[800])),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: IconButton(
                                    icon: const Icon(Icons.visibility_rounded,
                                        color: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ViewOfzRequestList(
                                                requestId: iou.id.toString(),
                                                isNotApprove: false,
                                                refNumber: iou.refNum,
                                              ),
                                        ),
                                      );
                                    },),
                                ),
                              ],
                            ),
                        ],

                      // Grand Total Row
                      TableRow(
                        decoration: BoxDecoration(color: Colors.green[50]),
                        children: [
                          Padding(padding: EdgeInsets.all(12.0),
                              child: Container()),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text("GRAND TOTAL", style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text("IOUs: $grandCount", style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold)),
                          ),
                          for (int i = 0; i < 2; i++) Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Container()),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(NumberStyles.currencyStyle(
                                grandTotal.toString()),
                                style: TextStyle(color: Colors.green[800],
                                    fontWeight: FontWeight.bold) ,textAlign: TextAlign.right,),
                          ),
                          for (int i = 0; i < 3; i++) Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Container()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),)
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required TextEditingController controller,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      value: controller.text.isNotEmpty ? controller.text : null,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }


  List<Widget> _buildDatePickers() {
    return [
      Expanded(
        child: DatePickerWidget(
          label: 'From Date',
          initialDate: _fromDate,
          onDateSelected: (d) => setState(() => _fromDate = d),
        ),
      ),
      const SizedBox(width: 15, height: 15),
      Expanded(
        child: DatePickerWidget(
          label: 'To Date',
          initialDate: _toDate,
          onDateSelected: (d) => setState(() => _toDate = d),
        ),
      ),
    ];
  }

  Widget _buildMaterialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _selectedOfzItem ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) {
            // Filter workTypes based on user input
            return _dropdownOfzItem.where((word) =>
                word.toLowerCase().contains(
                    textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) {
            setState(() {
              _selectedOfzItem = selection;
              _txtMaterialDropDown.text = selection;
            });
          },
          fieldViewBuilder: (context, textEditingController, focusNode,
              onFieldSubmitted) {
            return TextFormField(
              maxLength: 45,
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: '',
                labelText: 'Item List',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _txtMaterialDropDown.text = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Item List';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }

  void _showExportOptions() {
    if (_requests.isEmpty) {
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
                leading: const Icon(
                    Icons.insert_drive_file, color: Colors.green),
                title: const Text('Export as CSV'),
                onTap: () {
                  Navigator.pop(context);
                  exportPaymentRequestsToCSV(
                      parentContext, _requests); // ✅ use saved context
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> exportPaymentRequestsToCSV(BuildContext context,
      List<PaymentRequest> requests) async {
    try {
      List<List<String>> rows = [
        [
          "Ref No.",
          "Receiver Name",
          "Receiver Mobile",
          "Request Date",
          "Payment Type",
          "Bank Branch",
          "Account Number",
          "Amount (Rs.)",
          "VAT",
          "SSCL",
          "ADD Dis",
          "Item Dis",
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
      for (var request in requests) {
        rows.add([
          request.refNum ?? "N/A",
          request.receiverName,
          request.receiverMobile,
          request.requestDate,
          request.paymentType,
          request.bankBranch ?? "N/A",
          request.accountNumber ?? "N/A",
          NumberStyles.currencyStyle(request.totalAmount),
          NumberStyles.currencyStyle(request.vat),
          NumberStyles.currencyStyle(request.sscl),
          NumberStyles.currencyStyle(request.addDis),
          NumberStyles.currencyStyle(request.itemDis),
          request.eventType ?? "N/A",
          request.authUser ?? "N/A",
          request.authTime ?? "N/A",
          request.authCmt ?? "N/A",
          request.approUser ?? "N/A",
          request.approTime ?? "N/A",
          request.approCmt ?? "N/A",
          request.createdBy ?? "N/A",
          request.createdDate ?? "N/A",
          request.comment ?? "N/A",
        ]);
      }
      await MobileCSVExporter.export(
        context: context,
        headersAndRows: rows,
        fileNamePrefix: 'office_iou_lisst',
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
        logFile: 'office_iou_list.dart',
      );
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