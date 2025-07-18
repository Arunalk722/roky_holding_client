import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/status_icons.dart';
import 'package:roky_holding/md_05/ofz_pay_point_dialog.dart';
import 'package:roky_holding/md_05/project_pay_point_dialog.dart';
import 'package:roky_holding/md_04/view_project_request_item_list.dart';
import '../env/app_logs_to.dart';
import '../env/number_format.dart';
import '../env/print_debug.dart';
import '../env/sp_format_data.dart';
import '../md_04/view_ofz_request_list.dart';

class PaymentRequest {
  final String? id;
  final String? projectId;
  final String? locationId;
  final String? estimationId;
  final String? bankId;
  final String? statusId;
  final String? paymentMethodId;
  final String? bankBranch;
  final String? bankName;
  final String? accountNumber;
  final String? beneficiaryName;
  final String? receiverMobile;
  final String? requestDate;
  final String? receiverName;
  final String? comment;
  final String? isActive;
  final String? createdDate;
  final String? createdBy;
  final String? isAuth;
  final String? authCmt;
  final String? authUser;
  final String? authTime;
  final String? isAppro;
  final String? approCmt;
  final String? approUser;
  final String? approTime;
  final String isPaid;
  final String paymentStatus;
  final String? paymentComment;
  final String? paymentUser;
  final String? paymentTime;
  final String? isVisible;
  final String? changeDate;
  final String? changeBy;
  final String? isPost;
  final String? referenceNumber;
  final String? paymentType;
  final String? totalRequestedAmount;
  final String? totalActualAmount;
  final String? reqType;
  final String? projectName;
  final String? locationName;
  final String vat;
  final String sscl;
  final String addDisc;
  final String itemsDis;
  PaymentRequest({
    required this.id,
    required this.projectId,
    required this.locationId,
    required this.estimationId,
    required this.bankId,
    required this.statusId,
    required this.paymentMethodId,
    required this.bankName,
    this.bankBranch,
    this.accountNumber,
    required this.beneficiaryName,
    required this.receiverMobile,
    required this.requestDate,
    required this.receiverName,
    required this.comment,
    required this.isActive,
    required this.createdDate,
    required this.createdBy,
    required this.isAuth,
    required this.projectName,
    required this.locationName,
    required this.sscl,
    required this.vat,
    required this.addDisc,
    required this.itemsDis,
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
    required this.changeDate,
    required this.changeBy,
    required this.isPost,
    required this.referenceNumber,
    required this.paymentType,
    required this.totalRequestedAmount,
    required this.totalActualAmount,
    required this.reqType
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      projectName: json['project_name']??'NA',
      locationName: json['location_name']??'NA',
      id: json['tbl_user_payment_request_id'].toString(),
      projectId: json['project_id'].toString(),
      bankName: json['bank_name']??'NA',
      locationId: json['location_id'].toString(),
      estimationId: json['estimation_id'].toString(),
      bankId: json['bank_id'].toString(),
      statusId: json['status_id'].toString(),
      paymentMethodId: json['paymeth_id'].toString(),
      bankBranch: json['bank_branch'].toString(),
      accountNumber: json['account_number'].toString(),
      beneficiaryName: json['beneficiary_name'].toString(),
      receiverMobile: json['receiver_mobile'].toString(),
      requestDate: json['request_date'].toString(),
      receiverName: json['receiver_name'].toString(),
      comment: json['cmt'].toString(),
      isActive: json['is_active'].toString(),
      createdDate: json['created_date'].toString(),
      createdBy: json['created_by'].toString(),
      isAuth: json['is_auth'].toString(),
      authCmt: json['auth_cmt'].toString(),
      authUser: json['auth_user'].toString(),
      authTime: json['auth_time'],
      isAppro: json['is_appro'].toString(),
      approCmt: json['appro_cmt'].toString(),
      approUser: json['appro_user'].toString(),
      approTime: json['appro_time'].toString(),
      isPaid: json['is_paid'].toString(),
      paymentStatus: json['pmt_status'].toString(),
      paymentComment: json['pmt_cmt'].toString(),
      paymentUser: json['pmt_user'].toString(),
      paymentTime: json['pmt_time'].toString(),
      isVisible: json['is_visible'].toString(),
      changeDate: json['change_date'].toString(),
      changeBy: json['change_by'].toString(),
      isPost: json['is_post'].toString(),
      referenceNumber: json['req_ref_number'].toString(),
      paymentType: json['payment_type'].toString(),
      totalRequestedAmount: json['requested_amount'].toString(),
      totalActualAmount: json['total_actual_amount'].toString(),
      reqType: 'CONS',
      sscl: json['sscl']??'0',
      vat: json['vat']??'0',
      addDisc: json['addt_discount']??'0',
      itemsDis: json['itemDiscount']??'0',
    );
  }

  // Add a factory constructor for OfzPaymentRequest
  factory PaymentRequest.fromOfzJson(Map<String, dynamic> json) {
    return PaymentRequest(
      projectName: json['project_name']??'NA',
      locationName: json['location_name']??'NA',
      id: json['idtbl_ofz_request'].toString(),
      projectId: '0',
      locationId: '0',
      estimationId: '0',
      bankName: json['bank_name']??'NA',
      bankId: json['bank_id'].toString(),
      statusId: json['status_id'].toString(),
      paymentMethodId: json['paymeth_id'].toString(),
      bankBranch: json['bank_branch'].toString(),
      accountNumber: json['account_number'].toString(),
      beneficiaryName: json['beneficiary_name'].toString(),
      receiverMobile: json['receiver_mobile'].toString(),
      requestDate: json['request_date'].toString(),
      receiverName: json['receiver_name'].toString(),
      comment: json['cmt'].toString(),
      isActive: json['is_active'].toString(),
      createdDate: json['created_date'].toString(),
      createdBy: json['created_by'].toString(),
      isAuth: json['is_auth'].toString(),
      authCmt: json['auth_cmt'].toString(),
      authUser: json['auth_user'].toString(),
      authTime: json['auth_time'].toString(),
      isAppro: json['is_appro'].toString(),
      approCmt: json['appro_cmt'].toString(),
      approUser: json['appro_user'].toString(),
      approTime: json['appro_time'].toString(),
      isPaid: json['is_paid'].toString(),
      paymentStatus: json['pmt_status'].toString(),
      paymentComment: json['pmt_cmt'].toString(),
      paymentUser: json['pmt_user'].toString(),
      paymentTime: json['pmt_time'].toString(),
      isVisible: json['is_visible'].toString(),
      changeDate: json['change_date'].toString(),
      changeBy: json['change_by'].toString(),
      isPost: json['is_post'].toString(),
      referenceNumber: json['req_ref_number'].toString(),
      paymentType: json['paymeth_id'] == 0 ? "Cash":json['paymeth_id']== 1?'Cheque': "Bank Transfer",
      totalRequestedAmount: json['total_amout'].toString(),
      totalActualAmount: json['total_amout'].toString(),
      reqType: 'OFZ',
      sscl: json['sscl']??'0',
      vat: json['vat']??'0',
      addDisc: json['add_dis']??'0',
      itemsDis: json['ItemsTotalDisfrom']??'0',
    );
  }
}

class RequestPaymentProcess extends StatefulWidget {
  const RequestPaymentProcess({super.key});

  @override
  RequestPaymentProcessState createState() => RequestPaymentProcessState();
}

class RequestPaymentProcessState extends State<RequestPaymentProcess> {
  List<PaymentRequest> _requests = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //methoord
      fetchData();
    });
  }

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch data from both APIs
      final requests1 = await fetchRequests();
      final requests2 = await fetchRequestsOfzPayment();

      // Combine the data
      setState(() {
        _requests = [...requests1, ...requests2];
        _isLoading = false;
      });
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'payment_process_all.dart');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<List<PaymentRequest>> fetchRequests() async {
    String apiURL = '${APIHost().apiURL}/project_payment_controller.php/ViewNotPayedRequests';
    PD.pd(text: apiURL);
    final response = await http.post(
      Uri.parse(apiURL),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"Authorization": APIToken().token}),
    );
    PD.pd(text: apiURL);
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      PD.pd(text: responseData.toString());
      if (responseData['status'] == 200) {
        List<dynamic> data = responseData['data'];
        return data.map((json) => PaymentRequest.fromJson(json)).toList();
      } else {
        throw Exception(responseData['message'] ?? 'Error loading requests');
      }
    } else {
      throw Exception('HTTP Error: ${response.statusCode}');
    }
  }

  Future<List<PaymentRequest>> fetchRequestsOfzPayment() async {
    String apiURL = '${APIHost().apiURL}/ofz_payment_controller.php/ViewNotPayedRequests';
    PD.pd(text: apiURL);
    final response = await http.post(
      Uri.parse(apiURL),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"Authorization": APIToken().token}),
    );
     if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      PD.pd(text: responseData.toString());
      if (responseData['status'] == 200) {
        List<dynamic> data = responseData['data'];
        return data.map((json) => PaymentRequest.fromOfzJson(json)).toList();
      } else {
        throw Exception(responseData['message'] ?? 'Error loading requests');
      }
    } else {
      throw Exception('HTTP Error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<PaymentRequest>> categorizedRequests = {
      "Cash": [],
      "Bank Transfer": [],
      "Cheque": [],
    };

    // Categorize requests based on payment type
    for (var request in _requests) {
      categorizedRequests[request.paymentType]?.add(request);
    }

    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: MyAppBar(appname: 'Payment Views-Account Update'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
          : DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              labelColor: Colors.black,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: "Cash 💰"),
                Tab(text: "Bank Transfer 🏦"),
                Tab(text: "Cheque 📝"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildRequestList(categorizedRequests["Cash"] ?? [], screenWidth),
                  _buildRequestList(categorizedRequests["Bank Transfer"] ?? [], screenWidth),
                  _buildRequestList(categorizedRequests["Cheque"] ?? [], screenWidth),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildRequestList(List<PaymentRequest> requests, double screenWidth) {
    if (requests.isEmpty) {
      return Center(
        child: Text(
          "No requests available",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }

    double buttonWidth = screenWidth < 600 ? 120 : 180;

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];

        double _billAmount=double.tryParse(request.totalActualAmount.toString())??0;
        double _vat=double.tryParse(request.vat)??0;
        double _sscl=double.tryParse(request.sscl)??0;
        double _addDis=double.tryParse(request.addDisc)??0;
        double _itemsDis=double.tryParse(request.itemsDis)??0;
        double _billSubTotal=_billAmount+_vat+_sscl-(_addDis+_itemsDis);
        return Card(
          elevation: 10,
          margin: EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          shadowColor: Colors.grey.withOpacity(0.5),
          child: GestureDetector(
            onLongPress: () {
              request.reqType=='OFZ'?Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewOfzRequestList(
                    requestId: request.id.toString(),
                    isNotApprove: true,
                    refNumber: request.referenceNumber.toString(),
                  ),
                ),
              ):
              Navigator.push(
              context,
              MaterialPageRoute(
              builder: (context) => ViewConstructionRequestList(
              requestId: request.id.toString(),
              isNotApprove: true,
                refNumber: request.referenceNumber.toString(),
              ),
              ),
              );
            },
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              collapsedBackgroundColor: Colors.blue.shade50,
              backgroundColor: Colors.blue.shade100,
              iconColor: Colors.black,
              title: 
              Row(
                children: [Expanded(child: Text(
                  "Reference: ${request.referenceNumber.toString()}",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.blue.shade800),
                ),),
                Expanded(child: StatusIcon(statusId: int.tryParse(request.statusId.toString())??0))],
              ),
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if(request.projectName!='NA')...[
                        _infoText("Project", request.projectName.toString(), Colors.black),
                        _infoText("Location", request.locationName.toString(), Colors.black),
                      ],
                      _infoText("Request Number", RequestNumber.formatNumber(val: int.tryParse(request.id.toString()) ?? 0), Colors.black),
                      _infoText("Receiver", request.receiverName.toString(), Colors.black),
                      _infoText("Mobile", request.receiverMobile.toString(), Colors.grey.shade700),
                      _infoText("Date", request.requestDate.toString(), Colors.grey.shade700),
                      _infoText("Comment", request.comment.toString(), Colors.grey.shade700),
                      _infoText(
                        "Total Amount",
                        "Rs.${NumberStyles.currencyStyle(request.totalRequestedAmount.toString())}",
                        Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      _infoText(
                        "Payable",
                        "Rs.${NumberStyles.currencyStyle(_billSubTotal.toString())}",
                        Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      if (request.paymentType == "Bank Transfer") ...[
                        SizedBox(height: 8),
                        _infoText("Beneficiary", request.beneficiaryName.toString(), Colors.grey.shade700),
                        _infoText("Account Number", request.accountNumber.toString(), Colors.black),
                        _infoText("Bank Name", request.bankName.toString(), Colors.black),
                        _infoText("Bank Branch", request.bankBranch.toString(), Colors.black),

                      ],
                      if (request.isAuth.toString() == '1') ...[
                        SizedBox(height: 8),
                        _infoText("Authorized by", request.authUser ?? 'N/A', Colors.blue.shade700),
                        _infoText("Auth Comment", request.authCmt ?? 'N/A', Colors.blue.shade700),
                        _infoText("Auth Time", request.authTime ?? 'N/A', Colors.blue.shade700),
                      ],
                      if (request.isAppro.toString() == '1') ...[
                        SizedBox(height: 8),
                        _infoText("Approved by", request.approUser.toString(), Colors.green.shade700),
                        _infoText("Approval Comment", request.approCmt.toString(), Colors.green.shade700),
                        _infoText("Approval Time", request.approTime.toString(), Colors.green.shade700),
                      ],
                      if (request.isPaid.toString() == '0')
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              request.reqType=='OFZ'?
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return OfzPayPointDialog(requestId: request.id.toString(),refNumber: request.referenceNumber.toString(),);
                                },
                              ):showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return PayPointDialog(requestId: request.id.toString(),refnumber: request.referenceNumber.toString(),);
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              fixedSize: Size(buttonWidth, 45),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            
                            child: Text(request.reqType=='OFZ'?"Pay Ofz":'Pay Project', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        SizedBox(height: 10,),
                        Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            request.reqType=='OFZ'?Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewOfzRequestList(
                                  requestId: request.id.toString(),
                                  isNotApprove: true,
                                  refNumber: request.referenceNumber.toString(),
                                ),
                              ),
                            ):
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewConstructionRequestList(
                                  requestId: request.id.toString(),
                                  isNotApprove: true,
                                  refNumber: request.referenceNumber.toString(),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            fixedSize: Size(buttonWidth, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('View', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _infoText(String label, String value, Color color, {FontWeight fontWeight = FontWeight.normal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(fontSize: 16, fontWeight: fontWeight, color: color),
            ),
          ],
        ),
      ),
    );
  }

}