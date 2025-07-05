import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/app_logs_to.dart';
import 'package:roky_holding/env/number_format.dart';
import 'package:roky_holding/env/print_debug.dart';
import 'package:roky_holding/md_03/estimation_approve_dialog.dart';
import 'package:roky_holding/md_03/estimation_authorized_dialog.dart';
import 'package:roky_holding/md_03/pending_estimation_item_view.dart';

class ApprovelPendingEstimations extends StatefulWidget {

 final bool isAuth;
 final bool isApprov;


  const ApprovelPendingEstimations({super.key,required this.isAuth,required this.isApprov});

  @override
  _ApprovelPendingEstimationsState createState() => _ApprovelPendingEstimationsState();
}

class _ApprovelPendingEstimationsState extends State<ApprovelPendingEstimations> {
  List<ProjectLocationEstimationEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    PD.pd(text: widget.isApprov.toString());
    _fetchEstimationEvents();
  }

  Future<void> _fetchEstimationEvents() async {
    try {
      setState(() => _isLoading = true);

      String apiUrl='${APIHost()
          .apiURL}/estimation_controller.php/ViewPendingApproveList';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Authorization": APIToken().token}),
      );
    PD.pd(text: apiUrl);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
        //  PD.pd(text:responseData.toString());
          setState(() {
            _events = (responseData['data'] as List)
                .map((item) => ProjectLocationEstimationEvent.fromJson(item))
                .toList();
          });
        } else {
          _showError(
              responseData['message'] ?? 'Failed to load estimation events');
        }
      } else {
        _showError("HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      _showError("Error: ${e.toString()}");
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_pending_estimations.dart');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: MyAppBar(appname: 'Approve Estimations'),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchEstimationEvents,
        backgroundColor: Colors.blue.shade800,
        child: Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }


  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: _buildLoadingIndicator());
    }

    if (_events.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          SizedBox(height: 16),
          _buildSummaryCard(),
          SizedBox(height: 16),
          Expanded(child: _buildEventList()),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
          strokeWidth: 5,
        ),
        SizedBox(height: 20),
        Text("Loading estimations...",
            style: TextStyle(color: Colors.blue.shade800, fontSize: 16)),
      ],
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty,size: 300,),
          SizedBox(height: 20),
          Text("No Pending Approvals",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("All estimations are approved and up to date",
              style: TextStyle(color: Colors.grey.shade600)),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchEstimationEvents,
            icon: Icon(Icons.refresh),
            label: Text("Refresh"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue.shade800,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final pendingCount = _events
        .where((e) => e.isAuth == 0)
        .length;
    final totalAmount = _events.fold(0.0, (sum, e) => sum + e.newAmountCalc+e.previewAmount);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem("Pending", "$pendingCount"),
                _buildSummaryItem("Total Amount",
                    "Rs. ${NumberStyles.currencyStyle(totalAmount.toString())}"),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: pendingCount / _events.length,
              backgroundColor: Colors.blue.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
        SizedBox(height: 4),
        Text(value,
            style: TextStyle(color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEventList() {
    return RefreshIndicator(
      onRefresh: _fetchEstimationEvents,
      color: Colors.blue.shade800,
      child: ListView.separated(
        padding: EdgeInsets.only(bottom: 20),
        itemCount: _events.length,
        separatorBuilder: (_, __) => SizedBox(height: 12),
        itemBuilder: (context, index) => _buildEventCard(_events[index]),
      ),
    );
  }

  Widget _buildEventCard(ProjectLocationEstimationEvent event) {
    final statusColor = event.statusColor;
    final statusText = event.status;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Estimation Request: ${event.listId}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Project: ${event.projectName}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  border: Border.all(color: statusColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusText,
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text("Location: ${event.locationName}"),
          Divider(),

          _buildAmountRow("Preview Amount:", event.previewAmount),
          _buildAmountRow("New Estimated:", event.newAmountCalc-event.previewAmount),
          _buildAmountRow("Total:", event.newAmountCalc),

          Divider(),
          Text("Created by: ${event.createdBy} | ${DateFormat('MMM d, yyyy')
              .format(event.createdDate)}",
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),

          if (event.isAuth == 1 || event.isAuth == -1) ...[
            SizedBox(height: 6),
            Text("${event.isAuth==-1?'Authorizing Reject':"Authorized"} by: ${event.authBy}",style: TextStyle(color: event.isAuth==-1?Colors.red:Colors.green),),
            Text("Comment: ${event.authCom}"),
            Text("Time: ${event.authTime != null ? DateFormat('MMM d, yyyy')
                .format(event.authTime!) : 'N/A'}"),
          ],

          if (event.isAppr == 1) ...[
            SizedBox(height: 6),
            Text("${event.isAuth==-1?'Approving Reject':"Approved"} by: ${event.apprBy}",style: TextStyle(color: event.isAuth==-1?Colors.red:Colors.green),),
            Text("Comment: ${event.authCom}"),
            Text("Time: ${event.apprTime != null ? DateFormat('MMM d, yyyy')
                .format(event.apprTime!) : 'N/A'}"),
          ],

          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // View Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PendingEstimationItemView(
                        projectId: event.projectId.toString(),
                        estimationId: event.estimationId.toString(),
                        locationId: event.locationId.toString(),
                        estimationReqId: event.estimationReqId.toString(),
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.view_agenda),
                label: Text("View"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // Authorized Button (if isAuth == 0 or -1)
              if (event.isAuth != 1&&widget.isAuth!=false) ...[
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _handleAuthorized(event),
                  icon: Icon(Icons.approval),
                  label: Text("Authorized"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],

              // Approve Button (only if isAuth == 1 and isAppr == 0)
              if (event.isAppr != 1&&widget.isApprov!=false) ...[
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _handleApproval(event),
                  icon: Icon(Icons.check),
                  label: Text("Approve"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          )


        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Text("Rs. ${NumberStyles.currencyStyle(value.toString())}",
              style: TextStyle(fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade900)),
        ],
      ),
    );
  }
  void _handleAuthorized(ProjectLocationEstimationEvent request) async {
    bool? result = await showDialog(
      context: context,
      builder: (context) => EstimationAuthorizedDialog(
        id: request.estimationReqId.toString(),
        estimationId: request.estimationId.toString(),
        locationID: request.locationId.toString(),
      ),
    );
    if (result == true) _fetchEstimationEvents();

  }
  void _handleApproval(ProjectLocationEstimationEvent request) async {
    bool? result = await showDialog(
      context: context,
      builder: (context) => EstimationApprovingDialog(
        id: request.estimationReqId.toString(),
        estimationId: request.estimationId.toString(),
        locationID: request.locationId.toString(),
        newAmount:request.newAmountCalc,

      ),
    );
    if (result == true) _fetchEstimationEvents();
  }
}


// Add this import for DateFormat

class ProjectLocationEstimationEvent {
  final int listId;
  final String projectName;
  final String locationName;
  final int estimationId;
  final int locationId;
  final int projectId;
  final double previewAmount;
  final double newAmount;
  final int isActive;
  final String createdBy;
  final DateTime createdDate;
  final int isAuth;
  final String authBy;
  final DateTime? authTime;
  final int isAppr;
  final String apprBy;
  final DateTime? apprTime;
  final String changeBy;
  final DateTime changeDate;
  final int estimationReqId;
  final double newAmountCalc;
  final String authCom;
  final String appCom;
  ProjectLocationEstimationEvent({
    required this.projectName,
    required this.locationName,
    required this.listId,
    required this.estimationId,
    required this.locationId,
    required this.projectId,
    required this.previewAmount,
    required this.newAmount,
    required this.isActive,
    required this.createdBy,
    required this.createdDate,
    required this.isAuth,
    required this.authBy,
    this.authTime,
    required this.isAppr,
    required this.apprBy,
    this.apprTime,
    required this.changeBy,
    required this.changeDate,
    required this.estimationReqId,
    required this.newAmountCalc,
    required this.appCom,
    required this.authCom,
  });

  factory ProjectLocationEstimationEvent.fromJson(Map<String, dynamic> json) {
    return ProjectLocationEstimationEvent(
      listId: json['idtbl_project_location_estimation_events'] ?? 0,
      projectName: json['project_name'] ?? 'Unknown',
      locationName: json['location_name'] ?? 'Unknown',
      estimationId: json['estimation_id'] ?? 0,
      locationId: json['location_id'] ?? 0,
      projectId: json['project_id'] ?? 0,
      previewAmount: double.tryParse(json['preview_amount'].toString()) ?? 0.0,
      newAmount: double.tryParse(json['new_amount'].toString()) ?? 0.0,
      isActive: json['is_active'] ?? 0,
      createdBy: json['created_by'] ?? 'Unknown',
      createdDate: DateTime.parse(json['created_date']),
      isAuth: json['is_auth'] ?? 0,
      authBy: json['auth_by'] ?? 'NA',
      authTime: json['auth_time'] != null ? DateTime.parse(json['auth_time']) : null,
      isAppr: json['is_appr'] ?? 0,
      apprBy: json['appr_by'] ?? 'NA',
      apprTime: json['appr_time'] != null ? DateTime.parse(json['appr_time']) : null,
      changeBy: json['change_by'] ?? 'Unknown',
      changeDate: DateTime.parse(json['change_date']),
      estimationReqId: json['estimation_req_id'] ?? 0,
      newAmountCalc: double.tryParse(json['new_amount_calc'].toString()) ?? 0.0,
      appCom: json['appr_cmt'] ?? 0,
      authCom: json['auth_cmt'] ?? 0,
    );
  }

  String get status {
    if (isAppr == 1) return 'Approved';
    if (isAppr == -1) return 'Approving Rejected';
    if (isAuth == 1) return 'Authorized';
    if (isAuth == -1) return 'Authorizing Rejected';
    return 'Pending';
  }

  Color get statusColor {
    if (isAppr == 1) return Colors.green;
    if (isAuth == 1) return Colors.blue;
    return Colors.orange;
  }
}