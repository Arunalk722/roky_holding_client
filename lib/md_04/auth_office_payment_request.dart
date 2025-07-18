import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/number_format.dart';
import 'package:roky_holding/env/user_data.dart';
import 'package:roky_holding/md_04/view_ofz_request_list.dart';
import 'package:roky_holding/md_05/approve_ofz_request_dialog_box.dart';
import 'package:roky_holding/md_05/auth_ofz_request_dialog_box.dart';
import '../env/DialogBoxs.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';
import '../env/sp_format_data.dart';

class OfzRequest {
  final int id;
  final String refNumber;
  final int bankId;
  final int statusId;
  final int paymentMethodId;
  final String bankBranch;
  final String accountNumber;
  final String beneficiaryName;
  final String receiverMobile;
  final String requestDate;
  final String receiverName;
  final String vat;
  final String sscl;
  final String addiDis;
  final String itemDis;
  final String comment;
  final int isActive;
  final String? paymentRef;
  final String? payedDate;
  final String createdDate;
  final String createBy;
  final int isAuth;
  final String? authCmt;
  final String? authUser;
  final String? authTime;
  final int isAppro;
  final String? approCmt;
  final String? approUser;
  final String? approTime;
  final int isPaid;
  final int paymentStatus;
  final String? paymentComment;
  final String? paymentUser;
  final String? paymentTime;
  final int isVisible;
  final String? changeDate;
  final String changeBy;
  final int isPost;
  final String? iouNumber;
  final double totalAmount;
  final String? bankName;
  final int isEnable;
  final int accId;

  OfzRequest({
    required this.id,
    required this.refNumber,
    required this.bankId,
    required this.statusId,
    required this.paymentMethodId,
    required this.bankBranch,
    required this.accountNumber,
    required this.beneficiaryName,
    required this.receiverMobile,
    required this.requestDate,
    required this.receiverName,
    required this.vat,
    required this.sscl,
    required this.addiDis,
    required this.comment,
    required this.isActive,
    this.paymentRef,
    this.payedDate,
    required this.createdDate,
    required this.createBy,
    required this.isAuth,
    this.authCmt,
    this.authUser,
    this.authTime,
    required this.isAppro,
    this.approCmt,
    this.approUser,
    this.approTime,
    required this.isPaid,
    required this.paymentStatus,
    this.paymentComment,
    this.paymentUser,
    this.paymentTime,
    required this.isVisible,
    this.changeDate,
    required this.changeBy,
    required this.isPost,
    this.iouNumber,
    required this.totalAmount,
    this.bankName,
    required this.isEnable,
    required this.accId,
    required this.itemDis
  });

  factory OfzRequest.fromJson(Map<String, dynamic> json) {
    return OfzRequest(
      id: json['idtbl_ofz_request'] ?? 0,
      refNumber: json['req_ref_number'] ?? '',
      bankId: json['bank_id'] ?? 0,
      statusId: json['status_id'] ?? 0,
      paymentMethodId: json['paymeth_id'] ?? 0,
      bankBranch: json['bank_branch'] ?? '',
      accountNumber: json['account_number'] ?? '',
      beneficiaryName: json['beneficiary_name'] ?? '',
      receiverMobile: json['receiver_mobile'] ?? '',
      requestDate: json['request_date'] ?? '',
      receiverName: json['receiver_name'] ?? '',
      vat: json['vat']?.toString() ?? '',
      sscl: json['sscl']?.toString() ?? '',
      addiDis: json['add_dis']?.toString() ?? '',
      comment: json['cmt']?.toString() ?? '',
      isActive: json['is_active'] ?? 0,
      paymentRef: json['payment_ref'],
      payedDate: json['payed_date'],
      createdDate: json['created_date'] ?? '',
      createBy: json['created_by'] ?? '',
      isAuth: json['is_auth'] ?? 0,
      authCmt: json['auth_cmt'],
      authUser: json['auth_user'],
      authTime: json['auth_time'],
      isAppro: json['is_appro'] ?? 0,
      approCmt: json['appro_cmt'],
      approUser: json['appro_user'],
      approTime: json['appro_time'],
      isPaid: json['is_paid'] ?? 0,
      paymentStatus: json['pmt_status'] ?? 0,
      paymentComment: json['pmt_cmt'],
      paymentUser: json['pmt_user'],
      paymentTime: json['pmt_time'],
      isVisible: json['is_visible'] ?? 0,
      changeDate: json['change_date'],
      changeBy: json['change_by'] ?? '',
      isPost: json['is_post'] ?? 0,
      iouNumber: json['iou_number'],
      totalAmount: double.tryParse(json['total']?.toString() ?? '0.0') ?? 0.0,
      bankName: json['bank_name'],
      isEnable: json['is_enable'] ?? 0,
      accId: json['acc_id'] ?? 0,
      itemDis: json['itemDis']??0
    );
  }
}



class AuthOfficePaymentRequest extends StatefulWidget {
  const AuthOfficePaymentRequest({super.key});

  @override
  AuthOfficePaymentRequestState createState() => AuthOfficePaymentRequestState();
}

class AuthOfficePaymentRequestState extends State<AuthOfficePaymentRequest> {
  List<OfzRequest> _requests = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchRequests();
    });
  }

  Future<void> fetchRequests() async {
    WaitDialog.showWaitDialog(context, message: 'Loading...');
    String apiURL = '${APIHost().apiURL}/ofz_payment_controller.php/ListOfRequest';
    PD.pd(text: apiURL);
    try {
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Authorization": APIToken().token}),
      );

      PD.pd(text: apiURL);
      if (response.statusCode == 200) {
        Navigator.pop(context);
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          List<dynamic> data = responseData['data'];
          setState(() {
            _requests = data.map((json) => OfzRequest.fromJson(json)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Error loading requests';
            _isLoading = false;
          });
        }
      } else {
        Navigator.pop(context);
        setState(() {
          _errorMessage = 'HTTP Error: ${response.statusCode}';
        });
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'auth_office_payment_request.dart'
      );
      Navigator.pop(context);
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group requests by payment method
    final paymentGroups = {
      "Cash": _requests.where((r) => r.paymentMethodId == 0).toList(),
      "Bank Transfer": _requests.where((r) => r.paymentMethodId == 2).toList(),
      "Cheque": _requests.where((r) => r.paymentMethodId == 1).toList(),
    };

    return Scaffold(
      appBar: MyAppBar(appname: 'Authorized Office Payment Requests'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
          : _buildPaymentGroups(paymentGroups),
    );
  }

  Widget _buildPaymentGroups(Map<String, List<OfzRequest>> paymentGroups) {
    return ListView(
      padding: EdgeInsets.all(12),
      children: paymentGroups.entries.map((entry) {
        final paymentType = entry.key;
        final requests = entry.value;
        if (requests.isEmpty) return SizedBox();
        final totalAmount = requests.fold(0.0, (sum, r) => sum + r.totalAmount);
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: _getPaymentIcon(paymentType),
            title: Text(
              paymentType,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${requests.length} request${requests.length > 1 ? 's' : ''} • Rs.${NumberFormat('#,###.00').format(totalAmount)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            children: requests.map((request) => _buildRequestCard(request)).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _getPaymentIcon(String paymentType) {
    switch (paymentType) {
      case "Cash": return Icon(Icons.money, color: Colors.green);
      case "Bank Transfer": return Icon(Icons.account_balance, color: Colors.blue);
      case "Cheque": return Icon(Icons.description, color: Colors.orange);
      default: return Icon(Icons.payment, color: Colors.grey);
    }
  }

  Widget _buildRequestCard(OfzRequest request) {
    final status = _getRequestStatus(request);
    double _vat=double.tryParse(request.vat.toString())??0;
    double _sscl=double.tryParse(request.sscl.toString())??0;
    double _addDis=double.tryParse(request.addiDis.toString())??0;
    double _billAmount=double.tryParse(request.totalAmount.toString())??0;
    double _itemsDis=double.tryParse(request.itemDis.toString())??0;
    double _billSubTotal=_billAmount+_vat+_sscl-(_addDis+_itemsDis);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ref: ${request.refNumber}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.text,
                  style: TextStyle(
                    color: status.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Amount:", style: TextStyle(fontWeight: FontWeight.w500)),
              Text(
                "Rs.${NumberStyles.currencyStyle(request.totalAmount.toString())}",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),

          Divider(),
         /* if (_itemsDis != 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Items Discount:", style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  "Rs.${NumberStyles.currencyStyle(_itemsDis.toString())}",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            Divider(),
          ],
          if (_vat != 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("VAT:", style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  "Rs.${NumberStyles.currencyStyle(_vat.toString())}",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            Divider(),
          ],
          if (_sscl != 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("SSCL:", style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  "Rs.${NumberStyles.currencyStyle(_sscl.toString())}",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            Divider(),
          ],
          if (_addDis != 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Additional discount:", style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  "Rs.${NumberStyles.currencyStyle(_addDis.toString())}",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            Divider(),
          ],*/
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Payable Amount:", style: TextStyle(fontWeight: FontWeight.w500)),
              Text(
                "Rs:.${NumberStyles.currencyStyle(_billSubTotal.toString())}",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text("Receiver: ${request.receiverName}", style: TextStyle(fontWeight: FontWeight.w500)),
          Text("Mobile: ${request.receiverMobile}"),
          Text("Requested Date: ${request.requestDate}"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Created on: ${request.createdDate} ${request.createBy}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text("Comment: ${request.comment}",
              style: TextStyle(fontStyle: FontStyle.italic)),
          if (request.paymentMethodId == 2) ...[
            SizedBox(height: 8),
            Text("Beneficiary Name: ${request.beneficiaryName ?? 'N/A'}"),
            Text("Bank: ${request.bankName ?? 'N/A'}"),
            Text("Branch: ${request.bankBranch ?? 'N/A'}"),
            Text("Account: ${request.accountNumber ?? 'N/A'}"),
          ],
          if (request.isAuth == 1||request.isAuth == -1) ...[
            SizedBox(height: 8),
            Text("${request.isAuth==-1?'Reject':'Authorized'} by: ${request.authUser ?? 'N/A'}"),
            Text("Comment: ${request.authCmt ?? 'N/A'}"),
            Text("Time: ${request.authTime ?? 'N/A'}"),
          ],
          if (request.isAppro == 1) ...[
            SizedBox(height: 8),
            Text("Approved by: ${request.approUser ?? 'N/A'}"),
            Text("Comment: ${request.approCmt ?? 'N/A'}"),
            Text("Time: ${request.approTime ?? 'N/A'}"),
          ],
          SizedBox(height: 12),
          _buildActionButtons(request),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OfzRequest request) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (request.isAuth == 0 || request.isAuth == -1)
          ElevatedButton(
            onPressed: () => _handleAuthorization(request),
            style: ElevatedButton.styleFrom(
              backgroundColor: request.isAuth == 0 ? Colors.orange : Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(request.isAuth == 0 ? "Authorize" : "Rejected", style: TextStyle(color: Colors.white)),
          ),
        SizedBox(width: 8),
        if (request.isAppro == 0 && (UserCredentials().AuthCreditLimit! > request.totalAmount))
          ElevatedButton(
            onPressed: () => _handleApproval(request),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text("Approve", style: TextStyle(color: Colors.white)),
          ),
        SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.visibility, color: Colors.blue),
          onPressed: () => _viewDetails(request),
        ),
      ],
    );
  }

  void _handleAuthorization(OfzRequest request) async {
    bool? result = await showDialog(
      context: context,
      builder: (context) => AuthorizationOfzRequestDialog(
        requestId: request.id,
        refNumber: request.refNumber,
      ),
    );
    if (result == true) fetchRequests();
  }

  void _handleApproval(OfzRequest request) async {
    bool? result = await showDialog(
      context: context,
      builder: (context) => ApproveOfzRequestDialog(
        requestId: request.id,
        refNumber: request.refNumber,
      ),
    );
    if (result == true) fetchRequests();
  }

  void _viewDetails(OfzRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewOfzRequestList(
          requestId: request.id.toString(),
          isNotApprove: false,
          refNumber: request.refNumber,
        ),
      ),
    );
  }

  _Status _getRequestStatus(OfzRequest request) {
    if (request.isAppro == 1) return _Status("Approved", Colors.green);
    if (request.isAppro == -1) return _Status("Rejected", Colors.red);
    if (request.isAuth == 1) return _Status("Authorized", Colors.blue);
    if (request.isAuth == -1) return _Status("Authorization Rejected", Colors.orange);
    return _Status("Pending", Colors.grey);
  }
}

class _Status {
  final String text;
  final Color color;

  _Status(this.text, this.color);
}
