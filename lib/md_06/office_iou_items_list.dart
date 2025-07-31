import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/print_debug.dart';
import 'package:roky_holding/env/platform_ind/csv_exporter.dart';
import 'package:roky_holding/env/sp_format_data.dart';
import '../env/DialogBoxs.dart';
import '../env/app_logs_to.dart';
import '../env/input_widget.dart';
import '../env/number_format.dart';
import '../md_04/view_ofz_request_list.dart';

class PaymentRequestItemsDetail {
  final int requestListId;
  final String materialItemName;
  final String mainCategoryName;
  final String subCategoryName;
  final String locationName;
  final String projectName;
  final String listDescription;
  final String quantity;
  final String uom;
  final String amount;
  final String totalAmount;
  final String itemDiscount;
  final int statusOfPayment;
  final int ofzRequestId;
  final String refNumber;
  final String bankName;
  final String eventType;
  final String paymentType;
  final String beneficiaryBank;
  final String beneficiaryAccount;
  final String beneficiaryName;
  final String receiverMobile;
  final String requestDate;
  final String receiverName;
  final String vat;
  final String sscl;
  final String additionalDiscount;
  final String requestComment;
  final int requestIsActive;
  final String? paymentRef;
  final String? payedDate;
  final String requestCreatedDate;
  final String requestCreatedBy;
  final String authComment;
  final String authUser;
  final String? authTime;
  final String approComment;
  final String approUser;
  final String? approTime;
  final String paymentComment;
  final String paymentUser;
  final String? paymentTime;
  final String iouNumber;
  final int? iouId;
  final String? iouAmount;
  final String? iouRequestRef;
  final String? iouRequestType;
  final String? iouCreatedDate;
  final String? iouCreatedBy;
  final int? iouIsActive;
  final int? isProject;
  final String? payedAccount;
  final String? iouChangeDate;
  final String? iouChangeBy;

  PaymentRequestItemsDetail({
    required this.requestListId,
    required this.isProject,
    required this.materialItemName,
    required this.mainCategoryName,
    required this.subCategoryName,
    required this.locationName,
    required this.projectName,
    required this.listDescription,
    required this.quantity,
    required this.uom,
    required this.amount,
    required this.totalAmount,
    required this.itemDiscount,
    required this.statusOfPayment,
    required this.ofzRequestId,
    required this.refNumber,
    required this.bankName,
    required this.eventType,
    required this.paymentType,
    required this.beneficiaryBank,
    required this.beneficiaryAccount,
    required this.beneficiaryName,
    required this.receiverMobile,
    required this.requestDate,
    required this.receiverName,
    required this.vat,
    required this.sscl,
    required this.additionalDiscount,
    required this.requestComment,
    required this.requestIsActive,
    this.paymentRef,
    this.payedDate,
    required this.requestCreatedDate,
    required this.requestCreatedBy,
    required this.authComment,
    required this.authUser,
    this.authTime,
    required this.approComment,
    required this.approUser,
    this.approTime,
    required this.paymentComment,
    required this.paymentUser,
    this.paymentTime,
    required this.iouNumber,
    this.iouId,
    this.iouAmount,
    this.iouRequestRef,
    this.iouRequestType,
    this.iouCreatedDate,
    this.iouCreatedBy,
    this.iouIsActive,
    this.payedAccount,
    this.iouChangeDate,
    this.iouChangeBy,
  });

  factory PaymentRequestItemsDetail.fromJson(Map<String, dynamic> json) {
    return PaymentRequestItemsDetail(
      requestListId: json['idtbl_ofz_request_list'] as int? ?? 0,
      materialItemName: json['material_item_name'] as String? ?? '',
      mainCategoryName: json['main_category_name'] as String? ?? '',
      subCategoryName: json['sub_category_name'] as String? ?? '',
      locationName: json['location_name'] as String? ?? '',
      projectName: json['project_name'] as String? ?? '',
      listDescription: json['list_des'] as String? ?? '',
      quantity: json['qty'] as String? ?? '0.000',
      uom: json['uom'] as String? ?? '',
      amount: json['amout'] as String? ?? '0.00',
      totalAmount: json['total_amout'] as String? ?? '0.00',
      itemDiscount: json['item_dis'] as String? ?? '0.00',
      statusOfPayment: json['status_of_payment'] as int? ?? 0,
      ofzRequestId: json['ofz_request_id'] as int? ?? 0,
      refNumber: json['req_ref_number'] as String? ?? '',
      bankName: json['bank_name'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      paymentType: json['paymentType'] as String? ?? '',
      beneficiaryBank: json['benf_bank'] as String? ?? '',
      beneficiaryAccount: json['benfAcc'] as String? ?? '',
      beneficiaryName: json['beneficiary_name'] as String? ?? '',
      receiverMobile: json['receiver_mobile'] as String? ?? '',
      requestDate: json['request_date'] as String? ?? '',
      receiverName: json['receiver_name'] as String? ?? '',
      vat: json['vat'] as String? ?? '0.00',
      sscl: json['sscl'] as String? ?? '0.00',
      additionalDiscount: json['add_dis'] as String? ?? '0.00',
      requestComment: json['request_cmt'] as String? ?? '',
      requestIsActive: json['request_is_active'] as int? ?? 1,
      paymentRef: json['payment_ref'] as String?,
      payedDate: json['payed_date'] as String?,
      requestCreatedDate: json['req_created_date'] as String? ?? '',
      requestCreatedBy: json['req_created_by'] as String? ?? '',
      authComment: json['auth_cmt'] as String? ?? '',
      authUser: json['auth_user'] as String? ?? '',
      authTime: json['auth_time'] as String?,
      approComment: json['appro_cmt'] as String? ?? '',
      approUser: json['appro_user'] as String? ?? '',
      approTime: json['appro_time'] as String?,
      paymentComment: json['pmt_cmt'] as String? ?? '',
      paymentUser: json['pmt_user'] as String? ?? '',
      paymentTime: json['pmt_time'] as String?,
      iouNumber: json['iou_number'] as String? ?? '0',
      iouId: json['idtbl_IOU_list'] as int?,
      iouAmount: json['amount'] as String?,
      iouRequestRef: json['request_ref'] as String?,
      iouRequestType: json['request_type'] as String?,
      iouCreatedDate: json['iou_created_date'] as String?,
      iouCreatedBy: json['iou_created_by'] as String?,
      iouIsActive: json['iou_is_active'] as int?,
      payedAccount: json['payedAccount'] as String?,
      iouChangeDate: json['iou_change_date'] as String?,
      iouChangeBy: json['iou_change_by'] as String?,
      isProject:json['is_project']??0
    );
  }
}



class OfficeIOUItemsList extends StatefulWidget {
  const OfficeIOUItemsList({super.key});

  @override
  OfficeIOUItemsListState createState() =>
      OfficeIOUItemsListState();
}

class OfficeIOUItemsListState
    extends State<OfficeIOUItemsList> {
  List<PaymentRequestItemsDetail> _requests = [];

  String? _fromDate;
  String? _toDate;
  Map<String, Map<String, List<PaymentRequestItemsDetail>>> groupedRequests = {
  };

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
          logFile: 'office_iou_items_list.dart');
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
          logFile: 'office_iou_items_list.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    }
  }

  Future<void> fetchRequests() async {
    String apiURL = '${APIHost()
        .apiURL}/report_controller.php/ViewOfficeIOUItemList';
    PD.pd(text: apiURL.toString());
    try {
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "start_date": _fromDate,
          "end_date": _toDate,
          "is_project": isProject == true ? 1 : 0,
          "is_paid": isPaid == true ? 1 : 0,
          "main_category_name": _txtMainCategoryDropDown.text,
          "sub_category_name": _txtSubCategoryDropDown.text,
          "material_item_name": _txtMaterialDropDown.text
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          List<dynamic> data = responseData['data'];
          setState(() {
            _requests =
                data.map((json) => PaymentRequestItemsDetail.fromJson(json))
                    .toList();
            scaffoleMessage('Scanned'.toString(), Colors.green);
          });
        } else {
          scaffoleMessage(
              'Error: ${responseData['message'].toString()}', Colors.red);
        }
      } else {
        scaffoleMessage('Error: ${response.statusCode.toString()}', Colors.red);
      }
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'office_iou_items_list_list.dart');

      scaffoleMessage('Error: ${e.toString()}', Colors.red);
    }
  }


  void scaffoleMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
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

  bool isProject = false;
  bool isPaid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appname: 'Office Requested items Lists'),
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
                                ))
                          ]
                      ),
                      const SizedBox(height: 0),
                      Row(
                        children: [
                          Checkbox(
                            value: isProject,
                            onChanged: (value) {
                              setState(() {
                                isProject = value ?? false;
                              });
                            },
                          ),
                          const Text('Project Related'),
                          Checkbox(
                            value: isPaid,
                            onChanged: (value) {
                              setState(() {
                                isPaid = value ?? false;
                              });
                            },
                          ),
                          const Text('Payment Completed'),
                        ],
                      ),
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
                            'SEARCH itemsList RECORDS',
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
    _requests.sort((a, b) =>
        DateTime.parse(a.requestDate).compareTo(DateTime.parse(b.requestDate)));

    var groupedItemsList = <String, List<PaymentRequestItemsDetail>>{};
    var projectTotals = <String, double>{};
    var projectCounts = <String, int>{};
    double grandTotal = 0.0;
    int grandCount = 0;

    for (var itemsList in _requests) {
      var groupKey = itemsList.refNumber;
      groupedItemsList.putIfAbsent(groupKey, () => []).add(itemsList);

      double sscl = double.tryParse(itemsList.sscl) ?? 0.0;
      double totalAmo = double.tryParse(itemsList.totalAmount) ?? 0.0;
      double addDis = double.tryParse(itemsList.additionalDiscount) ?? 0.0;
      double itemDis = double.tryParse(itemsList.itemDiscount) ?? 0.0;
      double vat = double.tryParse(itemsList.vat) ?? 0.0;
      double amount = totalAmo + vat + sscl - addDis - itemDis;
      projectTotals.update(
          groupKey, (val) => val + amount, ifAbsent: () => amount);
      projectCounts.update(groupKey, (val) => val + 1, ifAbsent: () => 1);
      grandTotal += amount;
      grandCount++;
    }

    var sortedGroupKeys = groupedItemsList.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 1024;
        double tableWidth = isMobile ? 1024 : constraints.maxWidth * 0.95;

        return Scrollbar(
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Scrollbar(
                  thumbVisibility: true,
                  trackVisibility: true,
                  controller: ScrollController(),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: tableWidth),
                      child: buildFullTable(
                        context,
                        groupedItemsList,
                        projectTotals,
                        projectCounts,
                        sortedGroupKeys,
                        grandTotal,
                        grandCount,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildFullTable(BuildContext context,
      Map<String, List<PaymentRequestItemsDetail>> groupedItemsList,
      Map<String, double> projectTotals,
      Map<String, int> projectCounts,
      List<String> sortedGroupKeys,
      double grandTotal,
      int grandCount,) {
    return Table(
      border: TableBorder.all(
        color: Colors.grey[300]!,
        width: 1,
        borderRadius: BorderRadius.circular(12),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(3),
        4: FlexColumnWidth(3),
        5: FlexColumnWidth(1),
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
                  color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Request ID", style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Ref No.", style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Memo", style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Items", style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Qty", style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Amount (Rs.)", style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Status", style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("View", style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),

        // Grouped data
        for (var groupKey in sortedGroupKeys) ...[
          // Group header
          TableRow(
            decoration: BoxDecoration(color: Colors.blue[50]),
            children: [
              const Padding(padding: EdgeInsets.all(12.0), child: SizedBox()),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(groupKey, style: TextStyle(
                    color: Colors.blue[800], fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text("Items: ${projectCounts[groupKey]}",
                    style: TextStyle(
                        color: Colors.blue[800], fontWeight: FontWeight.bold)),
              ),
              for (int i = 0; i < 3; i++) const Padding(
                  padding: EdgeInsets.all(12.0), child: SizedBox()),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(NumberStyles.currencyStyle(
                    projectTotals[groupKey]!.toString()),
                    style: TextStyle(
                        color: Colors.blue[800], fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right),
              ),
              for (int i = 0; i < 2; i++) const Padding(
                  padding: EdgeInsets.all(12.0), child: SizedBox()),
            ],
          ),

          // Item rows
          for (var item in groupedItemsList[groupKey]!)
            TableRow(
              decoration: BoxDecoration(
                color: groupedItemsList[groupKey]!.indexOf(item) % 2 == 0
                    ? Colors.white
                    : Colors.grey[50],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                      item.requestDate, style: const TextStyle(fontSize: 12)),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(item.ofzRequestId.toString(),
                      style: TextStyle(color: Colors.grey[800])),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(item.refNumber,
                      style: TextStyle(color: Colors.grey[800])),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    item.isProject == 1
                        ? "${item.projectName} - ${item.locationName}"
                        : item.requestComment.toString(),
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    "${item.mainCategoryName}\n${item.subCategoryName}\n${item
                        .materialItemName}",
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(item.quantity,
                      style: TextStyle(color: Colors.grey[800]),
                      textAlign: TextAlign.right),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    NumberStyles.currencyStyle(
                      ((double.tryParse(item.totalAmount) ?? 0.0) -
                          (double.tryParse(item.itemDiscount) ?? 0.0))
                          .toStringAsFixed(2),
                    ),
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(item.eventType.toString()),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: IconButton(
                    icon: const Icon(
                        Icons.visibility_rounded, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ViewOfzRequestList(
                                requestId: item.ofzRequestId.toString(),
                                isNotApprove: false,
                                refNumber: item.refNumber,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
        ],

        // Grand total row
        TableRow(
          decoration: BoxDecoration(color: Colors.green[50]),
          children: [
            const Padding(padding: EdgeInsets.all(12.0), child: SizedBox()),
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("GRAND TOTAL",
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text("ItemsList: $grandCount",
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            ),
            for (int i = 0; i < 3; i++) const Padding(
                padding: EdgeInsets.all(12.0), child: SizedBox()),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                NumberStyles.currencyStyle(grandTotal.toString()),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
            for (int i = 0; i < 2; i++) const Padding(
                padding: EdgeInsets.all(12.0), child: SizedBox()),
          ],
        ),
      ],
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
      List<PaymentRequestItemsDetail> requests) async {
    try {
      List<List<String>> rows = [
        [
          "Ref No.",
          "Material Item",
          "Main Category",
          "Sub Category",
          "Location",
          "Project",
          "Description",
          "Qty",
          "UOM",
          "Amount",
          "Total Amount",
          "Item Discount",
          "Status",
          "Request Date",
          "Receiver Name",
          "Receiver Mobile",
          "Beneficiary Name",
          "VAT",
          "SSCL",
          "Additional Discount",
          "Payment Type",
          "Bank Name",
          "Bank Branch",
          "Account Number",
          "Payment Ref",
          "Paid Date",
          "Created By",
          "Created Date",
          "IOU Number"
        ],
      ];

      for (var request in requests) {
        rows.add([
          request.refNumber,
          request.materialItemName,
          request.mainCategoryName,
          request.subCategoryName,
          request.locationName,
          request.projectName,
          request.listDescription,
          request.quantity,
          request.uom,
          request.amount,
          request.totalAmount,
          request.itemDiscount,
          request.statusOfPayment.toString(),
          request.requestDate,
          request.receiverName,
          request.receiverMobile,
          request.beneficiaryName,
          request.vat,
          request.sscl,
          request.additionalDiscount,
          request.paymentType,
          request.bankName,
          request.beneficiaryBank,
          request.beneficiaryAccount,
          request.paymentRef ?? "N/A",
          request.payedDate ?? "N/A",
          request.requestCreatedBy,
          request.requestCreatedDate,
          IOUNumber.iouNumber(val: request.iouNumber)
        ]);
      }

      await MobileCSVExporter.export(
        context: context,
        headersAndRows: rows,
        fileNamePrefix: 'office_iou_items_details',
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
        logFile: 'office_iou_items_list_list.dart',
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