import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/number_format.dart';
import 'package:roky_holding/env/user_data.dart';
import 'package:roky_holding/md_04/show_estimation_vs_request_dialog.dart';
import 'package:roky_holding/md_05/approve_project_payment_dialog_box.dart';
import 'package:roky_holding/md_05/auth_project_payment_dialog_box.dart';
import 'package:roky_holding/md_04/view_project_request_item_list.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';
import 'estimation_category_wise_consume_list.dart';


class PaymentRequest {
  final int id;
  final String receiverName;
  final String receiverMobile;
  final String requestDate;
  final String comment;
  final String totalAmount;
  final String vat;
  final String sscl;
  final String addDisc;
  final String itemsDis;
  final int isAuth;
  final int isAppro;
  final String paymentType;
  final String? bankBranch;
  final String? accountNumber;
  final String? authCmt;
  final String? authUser;
  final String? authTime;
  final String? reqAmount;
  final String? approCmt;
  final String? approUser;
  final String? approTime;
  final String beneficiaryName;
  final String? refNum;
  final String? createBy;
  final String? createdDate;
  final String? bankName;
  final String? projectName;
  final String? locationName;
  final int paymethId;
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
    required this.reqAmount,
    required this.bankName,
    required this.sscl,
    required this.vat,
    required this.addDisc,
    required this.itemsDis,
    required this.locationName,
    required this.projectName,
    required this.paymethId,
    required this.createdDate,
    required this.beneficiaryName,
    required this.createBy,
    required this.bankBranch,
    required this.accountNumber,
    required this.authCmt,
    required this.authUser,
    required this.authTime,
    required  this.approCmt,
    required  this.approUser,
    required  this.approTime,
    required this.refNum
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
        reqAmount: json['requested_amount'],
        locationName: json['location_name'],
        paymethId:  json['paymeth_id'],
        projectName: json['project_name'],
        id: json['tbl_user_payment_request_id'],
        receiverName: json['receiver_name'],
        receiverMobile: json['receiver_mobile'],
        requestDate: json['request_date'],
        sscl: json['sscl']??0,
        vat: json['vat']??0,
        addDisc: json['addt_discount']??0,
        comment: json['cmt'],
        totalAmount: json['total_actual_amount'],
        isAuth: json['is_auth'],
        isAppro: json['is_appro'],
        paymentType: json['payment_type'],
        bankBranch: json['bank_branch'],
        bankName: json['bank_name'],
        accountNumber: json['account_number'],
        authCmt: json['auth_cmt'],
        authUser: json['auth_user'],
        authTime: json['auth_time'],
        approCmt: json['appro_cmt'],
        approUser: json['appro_user'],
        approTime: json['appro_time'],
        refNum: json['req_ref_number'],
        createBy: json['created_by'],
        createdDate: json['created_date'],
        beneficiaryName: json['beneficiary_name'],
        itemsDis: json['ItemsTotalDis'],
    );
  }
}
void showEstimationDialog(BuildContext context,String projectName,String locatioName) async {
  try {
    PD.pd(text: projectName.toString());
    String apiURL = '${APIHost().apiURL}/report_controller.php/ProjectWiseEstimateItemConsume';
    PD.pd(text: apiURL);
    final response = await http.post(
      Uri.parse(apiURL),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "Authorization": APIToken().token,
        'project_name': projectName,
        "location_name": locatioName,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['status'] == 200) {
        PD.pd(text: responseData.toString());

      }
    }
  } catch (e) {
    // Handle error
  }
}
class AuthConstructionPaymentRequestScreen extends StatefulWidget {
  const AuthConstructionPaymentRequestScreen({super.key});

  @override
  AuthConstructionPaymentRequestScreenState createState() => AuthConstructionPaymentRequestScreenState();
}

class AuthConstructionPaymentRequestScreenState extends State<AuthConstructionPaymentRequestScreen> {
  List<PaymentRequest> _requests = [];
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
    String apiURL = '${APIHost().apiURL}/project_payment_controller.php/ListOfRequest';
    PD.pd(text: apiURL);
    PD.pd(text: apiURL);
    try {
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Authorization": APIToken().token}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          PD.pd(text: responseData.toString());

          List<dynamic> data = responseData['data'];
          setState(() {
            _requests = data.map((json) => PaymentRequest.fromJson(json)).toList();
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
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'auth_project_payment_request.dart');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appname: 'Authorized Construction Payment Requests'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
          : _buildPaymentTypeGroups(),
    );
  }

  Widget _buildPaymentTypeGroups() {
    final paymentTypeGroups = <String, List<PaymentRequest>>{};
    for (var request in _requests) {
      paymentTypeGroups.putIfAbsent(request.paymentType, () => []).add(request);
    }

    return ListView(
      padding: EdgeInsets.all(12),
      children: paymentTypeGroups.entries.map((entry) {
        final paymentType = entry.key;
        final requests = entry.value;
        final _totalAmount = requests.fold(0.0, (sum, request) => sum + (double.tryParse(request.totalAmount) ?? 0));
        final _totalVat = requests.fold(0.0, (sum, request) => sum + (double.tryParse(request.vat) ?? 0));
        final _totalSSCL = requests.fold(0.0, (sum, request) => sum + (double.tryParse(request.sscl) ?? 0));
        final _totalAddDis = requests.fold(0.0, (sum, request) => sum + (double.tryParse(request.addDisc) ?? 0));
        final _sumTotal= _totalAmount+_totalVat+_totalSSCL-_totalAddDis;
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                _getPaymentTypeIcon(paymentType),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paymentType,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${requests.length} request${requests.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Rs.${NumberFormat('#,###.00', 'en_US').format(_sumTotal)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            children: requests.map((request) => _buildRequestItem(request)).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _getPaymentTypeIcon(String paymentType) {
    switch (paymentType) {
      case 'Cash':
        return Icon(Icons.money, color: Colors.green, size: 30);
      case 'Bank Transfer':
        return Icon(Icons.account_balance, color: Colors.blue, size: 30);
      case 'Cheque':
        return Icon(Icons.description, color: Colors.orange, size: 30);
      default:
        return Icon(Icons.payment, color: Colors.grey, size: 30);
    }
  }

  Widget _buildRequestItem(PaymentRequest request) {
    final statusColor = _getStatusColor(request);
    final statusText = _getStatusText(request);
    double _vat=double.tryParse(request.vat)??0;
    double _sscl=double.tryParse(request.sscl)??0;
    double _addDis=double.tryParse(request.addDisc)??0;
    double _billAmount=double.tryParse(request.totalAmount)??0;
    double _itemsDis=double.tryParse(request.itemsDis)??0;
    double _billSubTotal=_billAmount+_vat+_sscl-(_addDis+_itemsDis);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: EdgeInsets.all(12),
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
                "Ref: ${request.refNum}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Project: ${request.projectName}",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            "Location: ${request.locationName}",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Bill Value:", style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    "Rs.${NumberStyles.currencyStyle(request.reqAmount.toString())}",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              Divider(),

            /*  if (_itemsDis != 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Items Discount:", style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      "Rs.${NumberFormat('#,###.00', 'en_US').format(_itemsDis)}",
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
                      "Rs.${NumberFormat('#,###.00', 'en_US').format(_vat)}",
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
                      "Rs.${NumberFormat('#,###.00', 'en_US').format(_sscl)}",
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
                      "Rs.${NumberFormat('#,###.00', 'en_US').format(_addDis)}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                Divider(),
              ],*/

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Sub Total Value:", style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    "Rs.${NumberFormat('#,###.00', 'en_US').format(_billSubTotal)}",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              Divider(),
            ],
          ),

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

        if (request.paymethId == 2) ...[
            SizedBox(height: 8),
            Text("Beneficiary Name: ${request.beneficiaryName}"),
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
          if (request.isAppro == 1||request.isAppro == -1) ...[
            SizedBox(height: 8),
            Text("Approved by: ${request.approUser ?? 'N/A'}"),
            Text("Comment: ${request.approCmt ?? 'N/A'}"),
            Text("Time: ${request.approTime ?? 'N/A'}"),
          ],
          if (request.isAuth == 0 || request.isAuth == -1 ||
              (request.isAppro == 0 && (UserCredentials().AuthCreditLimit! > (double.tryParse(request.totalAmount) ?? 0))))
            _buildActionButtons(request),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PaymentRequest request) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (request.isAuth == 0 || request.isAuth == -1)
          ElevatedButton(
            onPressed: () async {
              bool? result = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AuthorizationConstructionDialog(
                    requestId: request.id,
                    refNumber: request.refNum.toString(),
                  );
                },
              );
              if (result == true) fetchRequests();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: request.isAuth == 0 ? Colors.orange : Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              request.isAuth == 0 ? "Authorize" : "Rejected",
              style: TextStyle(color: Colors.white),
            ),
          ),
        SizedBox(width: 8),
        if (request.isAppro == 0 &&
            (UserCredentials().AuthCreditLimit! > (double.tryParse(request.totalAmount) ?? 0)))
          ElevatedButton(
            onPressed: () async {
              bool? result = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ApproveConstructionDialog(
                    requestId: request.id,
                    refNumber: request.refNum.toString(),
                  );
                },
              );
              if (result == true) fetchRequests();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Approve",
              style: TextStyle(color: Colors.white),
            ),
          ),

        IconButton(
          icon: Icon(Icons.visibility, color: Colors.blue),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewConstructionRequestList(
                  requestId: request.id.toString(),
                  isNotApprove: false,
                  refNumber: request.refNum.toString(),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.pie_chart, color: Colors.purple),
          onPressed: () async {
            final data = await fetchEstimationRequestSummary(request.id);
            await showEstimationVsRequestDialog(context, data);

          },
        ),
        IconButton(
          icon: Icon(Icons.analytics_outlined, color: Colors.black),
              onPressed: () async {
        showDialog(
        context: context,
        builder: (context) => EstimationDetailsDialog(locationName: request.locationName.toString(),projectName: request.projectName.toString(),requestId: request.id,),
        );
          }
        )
      ],
    );
  }

  Color _getStatusColor(PaymentRequest request) {
    if (request.isAppro == 1) return Colors.green;
    if (request.isAppro == -1) return Colors.red;
    if (request.isAuth == 1) return Colors.blue;
    if (request.isAuth == -1) return Colors.orange;
    return Colors.grey;
  }

  String _getStatusText(PaymentRequest request) {
    if (request.isAppro == 1) return 'Approved';
    if (request.isAppro == -1) return 'Rejected';
    if (request.isAuth == 1) return 'Authorized';
    if (request.isAuth == -1) return 'Authorization Rejected';
    return 'Pending';
  }
}