import 'dart:convert';
import 'package:roky_holding/env/platform_ind/csv_exporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/input_widget.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/number_format.dart';
import 'package:roky_holding/env/print_debug.dart';
import 'package:roky_holding/env/sp_format_data.dart';
import '../env/DialogBoxs.dart';
import '../env/app_logs_to.dart';
import '../md_04/view_ofz_request_list.dart';
import '../md_04/view_project_request_item_list.dart';

class ViewIOUScreen extends StatefulWidget {
  const ViewIOUScreen({super.key});

  @override
  State<ViewIOUScreen> createState() => _ViewIOUScreenState();
}

class _ViewIOUScreenState extends State<ViewIOUScreen> {
  List<dynamic> _iouList = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String? _fromDate = "";
  String? _toDate = "";
  bool _groupByDate = false; // New state for grouping option

  @override
  void initState() {
    super.initState();
    // Set default date range to current month
    final now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    _fromDate = formatter.format(DateTime(now.year, now.month, 1));
    _toDate = formatter.format(now);

    _fetchIOUList();
  }

  Future<void> _fetchIOUList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String apiURL = '${APIHost().apiURL}/report_controller.php/ViewIOUList';

      PD.pd(text: apiURL);
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "start_date": _fromDate.toString(),
          "end_date": _toDate.toString(),
          "is_office": isOffice,
          "is_project": isProject,
        }),
      );

      PD.pd(text: 'IOU LIST');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            _iouList = responseData['data'] ?? [];
          });
        } else {
          setState(() {
            _errorMessage =
                responseData['message'] ?? 'Failed to load IOU list';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'HTTP Error: ${response.statusCode}';
        });
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'view_iou_screen.dart');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool isOffice = true;
  bool isProject = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appname: 'View IOU Records'),
      body: Column(
        children: [
          Card(
            elevation: 5,
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            child: ExpansionTile(
              initiallyExpanded: true,
              collapsedBackgroundColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              tilePadding: EdgeInsets.symmetric(horizontal: 10),
              title: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_alt_rounded,
                        color: Colors.deepPurple, size: 28),
                    SizedBox(width: 12),
                    Text(
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
                SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // First Row - Grouping and Filters
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Grouping Options
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 0),
                                  child: Text(
                                    "Group By:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<bool>(
                                        title: Text('Project',
                                            style: TextStyle(fontSize: 14)),
                                        value: false,
                                        groupValue: _groupByDate,
                                        onChanged: (value) {
                                          setState(() {
                                            _groupByDate = value!;
                                          });
                                        },
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<bool>(
                                        title: Text('Date',
                                            style: TextStyle(fontSize: 14)),
                                        value: true,
                                        groupValue: _groupByDate,
                                        onChanged: (value) {
                                          setState(() {
                                            _groupByDate = value!;
                                          });
                                        },
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Vertical divider
                          Container(
                            width: 1,
                            height: 80,
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            color: Colors.grey[300],
                          ),

                          // Filter Options
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 0.0),
                                  child: Text(
                                    "Filter By:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                Wrap(
                                  spacing: 20,
                                  runSpacing: 12,
                                  children: [
                                    _buildFilterChip(
                                      value: isOffice,
                                      label: "Office IOU",
                                      onChanged: (v) =>
                                          setState(() => isOffice = v!),
                                    ),
                                    _buildFilterChip(
                                      value: isProject,
                                      label: "Project IOU",
                                      onChanged: (v) =>
                                          setState(() => isProject = v!),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Date Picker Row - Responsive Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return constraints.maxWidth > 600
                              ? Row(
                            children: _buildDatePickers(),
                          )
                              : Column(
                            children: _buildDatePickers(),
                          );
                        },
                      ),
                      SizedBox(height: 24),
                      // Search Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _fetchIOUList,
                          icon: Icon(Icons.search, size: 20),
                          label: Text(
                            'SEARCH IOU RECORDS',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
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

          SizedBox(height: 10),

          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _groupByDate
                    ? buildDateGroupedTable()
                    : buildProjectGroupedTable(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_iouList.isNotEmpty) {
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
                          exportIOUToCSV(_iouList);
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

  Widget _buildFilterChip({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  List<Widget> _buildDatePickers() {
    return [
      Expanded(
        flex: 1,
        child: DatePickerWidget(
          label: 'From Date',
          initialDate: _fromDate,
          onDateSelected: (d) => setState(() => _fromDate = d),
        ),
      ),
      SizedBox(width: 15, height: 15),
      Expanded(
        flex: 1,
        child: DatePickerWidget(
          label: 'To Date',
          initialDate: _toDate,
          onDateSelected: (d) => setState(() => _toDate = d),
        ),
      ),
    ];
  }

  Widget buildProjectGroupedTable() {
    // First, sort the entire _iouList by iou_id
    _iouList.sort((a, b) {
      int idA = int.tryParse(a['iou_id']?.toString() ?? '0') ?? 0;
      int idB = int.tryParse(b['iou_id']?.toString() ?? '0') ?? 0;
      return idA.compareTo(idB);
    });

    // Grouping IOU records by project and location
    var groupedIOUs = <String, List<dynamic>>{};
    var projectTotals = <String, double>{}; // For amount totals per project
    var projectCounts = <String, int>{}; // For count totals per project
    double grandTotal = 0.0;
    int grandCount = 0;

    for (var iou in _iouList) {
      var groupKey = "${iou['project_name'] ?? ''} - ${iou['location_name'] ??
          ''}";
      if (groupedIOUs[groupKey] == null) {
        groupedIOUs[groupKey] = [];
      }
      groupedIOUs[groupKey]!.add(iou);
      PD.pd(text: groupKey);

      double amount = double.tryParse(iou['amount']?.toString() ?? '0') ?? 0.0;
      projectTotals.update(
          groupKey, (value) => value + amount, ifAbsent: () => amount);
      projectCounts.update(groupKey, (value) => value + 1, ifAbsent: () => 1);

      grandTotal += amount;
      grandCount++;
    }

    // Sort the groups by their first IOU's iou_id to maintain order
    var sortedGroupKeys = groupedIOUs.keys.toList()
      ..sort((a, b) {
        int idA = int.tryParse(
            groupedIOUs[a]!.first['iou_id']?.toString() ?? '0') ?? 0;
        int idB = int.tryParse(
            groupedIOUs[b]!.first['iou_id']?.toString() ?? '0') ?? 0;
        return idA.compareTo(idB);
      });

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
                      8: FlexColumnWidth(1),
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
                              "IOU ID",
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
                              "Receiver/Beneficiary",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              "Type",
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
                              "Payment Ref",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              "Paid Account",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),


                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              "View",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      // Dynamically create table rows, grouped by project and location
                      // Now using sortedGroupKeys instead of groupedIOUs.keys
                      for (var groupKey in sortedGroupKeys)
                        ...[
                          // Group header
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  groupKey == ' - '
                                      ? 'Office IOU'
                                      : "Project: ${groupKey.split(
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
                                  "IOUs: ${projectCounts[groupKey]}",
                                  style: TextStyle(
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              for (int i = 0; i < 2; i++)
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
                              for (int i = 0; i < 3; i++)
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Container(),
                                ),
                            ],
                          ),
                          // Table rows for this group
                          for (var iou in groupedIOUs[groupKey]!)
                            TableRow(
                              decoration: BoxDecoration(
                                color: groupedIOUs[groupKey]!.indexOf(iou) %
                                    2 == 0
                                    ? Colors.white
                                    : Colors.grey[50],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                      DateFormat('yyyy-MM-dd').format(
                                          DateTime.parse(
                                              iou['iou_created_date'])),
                                      style: TextStyle(
                                          color: Colors.grey[800])),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(IOUNumber.iouNumber(
                                      val: iou['iou_id'].toString()),
                                      style: TextStyle(
                                          color: Colors.grey[800])),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(iou['request_ref'] ?? "N/A",
                                      style: TextStyle(
                                          color: Colors.grey[800])),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                      iou['request_type'] == 'office'
                                          ? iou['ofz_beneficiary'] ?? 'N/A'
                                          : iou['receiver_name'] ?? 'N/A',
                                      style: TextStyle(
                                          color: Colors.grey[800])),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                      iou['request_type']
                                          ?.toString()
                                          .toUpperCase() ?? 'N/A',
                                      style: TextStyle(
                                          color: Colors.grey[800])),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    NumberStyles.currencyStyle(
                                        iou['amount']?.toString() ?? '0'),
                                    style: TextStyle(color: Colors.grey[800]),
                                    textAlign: TextAlign.right,),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                      iou['request_type'] == 'office'
                                          ? iou['ofz_payment_ref'] ?? 'N/A'
                                          : iou['payment_ref'] ?? 'N/A',
                                      style: TextStyle(
                                          color: Colors.grey[800])),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                      iou['our_account_number'] ?? "N/A",
                                      style: TextStyle(
                                          color: Colors.grey[800])),
                                ),


                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: IconButton(
                                    icon: const Icon(Icons.visibility_rounded,
                                        color: Colors.blue),
                                    onPressed: () {
                                      iou['request_type'] == 'office' ?
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ViewOfzRequestList(
                                                requestId: iou['ofz_request_id']
                                                    .toString(),
                                                isNotApprove: false,
                                                refNumber: iou['request_ref']
                                                    .toString(),
                                              ),
                                        ),
                                      ) :
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ViewConstructionRequestList(
                                                  requestId: iou['payment_request_id']
                                                      .toString(),
                                                  isNotApprove: false,
                                                  refNumber: iou['request_ref']
                                                      .toString(),
                                                ),
                                          ));
                                    },),
                                ),
                              ],
                            ),
                        ],
                      // Grand Total Row (unchanged)
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Container(),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              "GRAND TOTAL",
                              style: TextStyle(
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              "IOUs: $grandCount",
                              style: TextStyle(
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          for (int i = 0; i < 2; i++)
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(),
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
                          for (int i = 0; i < 3; i++)
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(),
                            ),
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

  Widget buildDateGroupedTable() {
    // First, sort the entire _iouList by iou_id
    _iouList.sort((a, b) {
      int idA = int.tryParse(a['iou_id']?.toString() ?? '0') ?? 0;
      int idB = int.tryParse(b['iou_id']?.toString() ?? '0') ?? 0;
      return idA.compareTo(idB);
    });

    // Grouping IOU records by date
    var groupedIOUs = <String, List<dynamic>>{};
    var dateTotals = <String, double>{}; // For amount totals per date
    var dateCounts = <String, int>{}; // For count totals per date
    double grandTotal = 0.0;
    int grandCount = 0;

    for (var iou in _iouList) {
      var date = iou['iou_created_date'];
      if (date == null) continue;

      var formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
      if (groupedIOUs[formattedDate] == null) {
        groupedIOUs[formattedDate] = [];
      }
      groupedIOUs[formattedDate]!.add(iou);

      double amount = double.tryParse(iou['amount']?.toString() ?? '0') ?? 0.0;
      dateTotals.update(
          formattedDate, (value) => value + amount, ifAbsent: () => amount);
      dateCounts.update(formattedDate, (value) => value + 1, ifAbsent: () => 1);

      grandTotal += amount;
      grandCount++;
    }

    // Sort the dates in chronological order
    var sortedDates = groupedIOUs.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: MediaQuery
                      .of(context)
                      .size
                      .width * 0.9,
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
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                    4: FlexColumnWidth(2),
                    5: FlexColumnWidth(2),
                    6: FlexColumnWidth(2),
                    7: FlexColumnWidth(2),
                    8: FlexColumnWidth(1),
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
                            "Project",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            "IOU ID",
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
                            "Receiver/Beneficiary",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            "Type",
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
                            "Payment Ref",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            "Paid Account",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),


                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            "View",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Dynamically create table rows, grouped by date
                    for (var date in sortedDates)
                      ...[
                        // Date group header
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                "Date: $date",
                                style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                "IOUs: ${dateCounts[date]}",
                                style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            for (int i = 0; i < 2; i++)
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                NumberStyles.currencyStyle(
                                    dateTotals[date].toString()),
                                style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            for (int i = 0; i < 3; i++)
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(),
                              ),
                          ],
                        ),
                        // Table rows for this date
                        for (var iou in groupedIOUs[date]!)
                          TableRow(
                            decoration: BoxDecoration(
                              color: groupedIOUs[date]!.indexOf(iou) % 2 == 0
                                  ? Colors.white
                                  : Colors.grey[50],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                    iou['project_name'] ?? 'Office',
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(IOUNumber.iouNumber(
                                    val: iou['iou_id'].toString()),
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(iou['request_ref'] ?? "N/A",
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                    iou['request_type'] == 'office'
                                        ? iou['ofz_beneficiary'] ?? 'N/A'
                                        : iou['receiver_name'] ?? 'N/A',
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                    iou['request_type']
                                        ?.toString()
                                        .toUpperCase() ?? 'N/A',
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  NumberStyles.currencyStyle(
                                      iou['amount']?.toString() ?? '0'),
                                  style: TextStyle(color: Colors.grey[800]),
                                  textAlign: TextAlign.right,),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                    iou['request_type'] == 'office'
                                        ? iou['ofz_payment_ref'] ?? 'N/A'
                                        : iou['payment_ref'] ?? 'N/A',
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(iou['our_account_number'] ?? "N/A",
                                    style: TextStyle(color: Colors.grey[800])),
                              ),


                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: IconButton(
                                  icon: const Icon(Icons.visibility_rounded,
                                      color: Colors.blue),
                                  onPressed: () {
                                    iou['request_type'] == 'office' ?
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ViewOfzRequestList(
                                              requestId: iou['ofz_request_id']
                                                  .toString(),
                                              isNotApprove: false,
                                              refNumber: iou['request_ref']
                                                  .toString(),
                                            ),
                                      ),
                                    ) :
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ViewConstructionRequestList(
                                                requestId: iou['payment_request_id']
                                                    .toString(),
                                                isNotApprove: false,
                                                refNumber: iou['request_ref']
                                                    .toString(),
                                              ),
                                        ));
                                  },),
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
                          child: Container(),
                        ),
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
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            "IOUs: $grandCount",
                            style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        for (int i = 0; i < 2; i++)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Container(),
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
                        for (int i = 0; i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Container(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            )
        ),
      ),
    );
  }

  Future<void> exportIOUToCSV(List<dynamic> iouList) async {
    try {
      // Define headers for the CSV with only the requested fields
      List<List<String>> rows = [
        [
          "IOU ID",
          "Payment Account",
          "Request Type",
          "Category",
          "Project Name",
          "Location Name",
          "Amount (LKR)",
          "Request Ref",
          "Payment/Request ID",
          "Receiver Name",
          "Beneficiary Name",
          "Account Number",
          "Payment Ref",
          "Created Date",
        ],
      ];

      // Populate data rows with only the requested fields
      for (var iou in iouList) {
        // Determine which ID to show based on request type
        String paymentRequestId = iou['request_type'] == 'office'
            ? iou['ofz_request_id']?.toString() ?? 'N/A'
            : iou['payment_request_id']?.toString() ?? 'N/A';
        String beneficiaryName = iou['request_type'] == 'office'
            ? iou['ofz_beneficiary']?.toString() ?? 'N/A'
            : iou['beneficiary_name']?.toString() ?? 'N/A';
        String accountNumber = iou['request_type'] == 'office'
            ? iou['ofz_account']?.toString() ?? 'N/A'
            : iou['account_number']?.toString() ?? 'N/A';
        String paymentRef = iou['request_type'] == 'office'
            ? iou['ofz_payment_ref']?.toString() ?? 'N/A'
            : iou['payment_ref']?.toString() ?? 'N/A';
        String categorys = iou['request_type'] == 'office'
            ? iou['sub_name']?.toString() ?? 'N/A'
            : iou['cost_category']?.toString() ?? 'N/A';
        rows.add([
          iou['iou_id']?.toString() ?? 'N/A',
          iou['our_account_number']?.toString() ?? 'N/A',
          iou['request_type']?.toString() ?? 'N/A',
          categorys,
          iou['project_name']?.toString() ?? 'N/A',
          iou['location_name']?.toString() ?? 'N/A',
          iou['amount']?.toString() ?? '0.00',
          iou['request_ref']?.toString() ?? 'N/A',
          paymentRequestId,
          iou['receiver_name']?.toString() ?? iou['OfzReceiver']?.toString() ??
              'N/A',
          beneficiaryName,
          accountNumber,
          paymentRef,
          iou['iou_created_date']?.toString() ?? 'N/A',
        ]);
      }
      await MobileCSVExporter.export(
        context: context,
        headersAndRows: rows,
        fileNamePrefix: 'iou list',
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
          logFile: 'view_iou_screen.dart'
      );
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