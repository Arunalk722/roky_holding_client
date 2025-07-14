import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roky_holding/env/DialogBoxs.dart';
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/number_format.dart';
import 'package:roky_holding/env/sp_format_data.dart';
import 'package:roky_holding/env/user_data.dart';
import 'package:roky_holding/md_04/view_project_request_item_list.dart';
import 'package:roky_holding/md_04/view_ofz_request_list.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';
import '../env/status_icons.dart';
import 'project_request_disable.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http_parser/http_parser.dart';
import 'ofz_request_disable.dart';

class PaymentRequest {
  final String? id;
  final String? projectId;
  final String? locationId;
  final String? estimationId;
  final String? bankId;
  final String? statusId;
  final String? paymentMethodId;
  final String? bankBranch;
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
  final double totalRequestedAmount;
  final String? totalActualAmount;
  final String? reqType;
  final String iouNumber;
  final String logType;
  final double vat;
  final double sscl;
  final double addDis;
  PaymentRequest({
    required this.id,
    required this.projectId,
    required this.locationId,
    required this.estimationId,
    required this.bankId,
    required this.statusId,
    required this.paymentMethodId,
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
    required this.reqType,
    required this.iouNumber,
    required this.logType,
    required this.vat,
    required this.sscl,
    required this.addDis,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
        id: json['tbl_user_payment_request_id'].toString(),
        projectId: json['project_id'].toString(),
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
        totalRequestedAmount:double.tryParse( json['total_req_amount'])??0,
        totalActualAmount: json['total_actual_amount'].toString(),
        reqType: 'CONS',
        iouNumber: json['iou_number'].toString(),
        logType: json['event_type'],
        vat: double.tryParse(json['vat'])??0.0,
        sscl: double.tryParse(json['sscl'])??0.0,
        addDis: double.tryParse(json['addt_discount'])??0.0,
    );
  }

  // Add a factory constructor for OfzPaymentRequest
  factory PaymentRequest.fromOfzJson(Map<String, dynamic> json) {
    return PaymentRequest(
        id: json['idtbl_ofz_request'].toString(),
        projectId: '0',
        locationId: '0',
        estimationId: '0',
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
        totalRequestedAmount: double.tryParse(json['total'])??0,
        totalActualAmount: json['total'].toString(),
        reqType: 'OFZ',
        iouNumber: json['iou_number'].toString(),
        logType: json['event_type'],
        vat: double.tryParse(json['vat'])??0,
        sscl: double.tryParse(json['sscl'])??0,
        addDis: double.tryParse(json['add_dis'])??0,
    );
  }
}

class ViewUserRequestList extends StatefulWidget {
  const ViewUserRequestList({super.key});
  @override
  ViewUserRequestListState createState() => ViewUserRequestListState();
}

class ViewUserRequestListState extends State<ViewUserRequestList> {
  String? _startDate;
  String? _endDate;

  Map<int, Uint8List?> selectedImages = {};
  Future<Uint8List?> pickImage() async {
    FilePickerResult? result =
    await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      return result.files.first.bytes;
    }
    return null;
  }
  Future<void> startFilePicker(int requestId,String endPoint) async {
    final pickedBytes = await pickImage();
    if (pickedBytes != null) {
      setState(() {
        selectedImages[requestId] = pickedBytes;
      });
      await _uploadImage(endPoint, requestId);
    }
  }
  Future<void> _uploadImage(String endPoint, int requestId) async {
    if (selectedImages[requestId] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select an image first.'),
            backgroundColor: Colors.red),
      );
      return;
    }


    try {
      WaitDialog.showWaitDialog(context, message: 'Uploading image...');
      String apiURL="${APIHost().apiURL}/project_payment_controller.php/ImageUpload";
      var uri = Uri.parse(
          apiURL);
      PD.pd(text: apiURL);
      var request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        selectedImages[requestId]!,
        filename: 'image.png',
        contentType: MediaType('image', 'png'),
      ));
      request.fields['Authorization'] = APIToken().token!;
      request.fields['EndPoint'] = endPoint;
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var decodedResponse = json.decode(responseBody);

      if (response.statusCode == 200 && decodedResponse['status'] == 200) {
        Navigator.pop(context);
        OneBtnDialog.oneButtonDialog(context, title: 'Image Upload',
            message: 'Image uploaded successfully!',
            btnName: 'Ok',
            icon: Icons.done,
            iconColor: Colors.green,
            btnColor: Colors.green);
      }else if (response.statusCode == 200 && decodedResponse['status'] == 400) {
        Navigator.pop(context);
        OneBtnDialog.oneButtonDialog(context, title: 'Limit Issue', message: decodedResponse['message'], btnName: 'Ok', icon: Icons.image_not_supported_rounded, iconColor: Colors.red, btnColor: Colors.red);
      {
      }
      } else {
        Navigator.pop(context);
        OneBtnDialog.oneButtonDialog(context, title: 'Image Upload Error', message: 'Upload failed: ${decodedResponse['message'] ?? 'Unexpected response format.'}', btnName: 'Retry', icon: Icons.error, iconColor: Colors.red, btnColor: Colors.red);

      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_user_own_request_list.dart');
      Navigator.pop(context);
      ExceptionDialog.exceptionDialog(context, title: 'Image Upload Error', message: 'Exception: $e', btnName: 'Retry', icon: Icons.error, iconColor: Colors.red, btnColor: Colors.red);
    }
  }

  Future<pw.Document> generatePdf(List<PaymentRequest> requests) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('Payment Requests Report')),
              pw.SizedBox(height: 20),
              for (var request in requests)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('IOU: ${IOUNumber.iouNumber(val: request.iouNumber)}'),
                    pw.Text('Receiver: ${request.receiverName}'),
                    pw.Text(
                        'Amount: Rs.${NumberStyles.currencyStyle(request.totalRequestedAmount.toString())} VAT ${NumberStyles.currencyStyle(request.vat.toString())}: SSCL ${NumberStyles.currencyStyle(request.sscl.toString())} Add Dis ${NumberStyles.currencyStyle(request.addDis.toString())}'),
                    if (request.paymentType == "Bank Transfer") ...[
                      pw.Text('Bank Branch: ${request.bankBranch ?? 'N/A'}'),
                      pw.Text(
                          'Account Number: ${request.accountNumber ?? 'N/A'}'),
                    ],
                    if (request.isAuth == 1)
                      pw.Text('${request.isAuth==-1?'Reject':'Authorized'} by: ${request.authUser ?? 'N/A'}'),
                    if (request.isAppro == 1)
                      pw.Text('${request.isAppro==-1?'Reject':'Approved'} by: ${request.approUser ?? 'N/A'}'),
                    pw.Divider(),
                  ],
                ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  Future<void> _exportAndPrintPdf(List<PaymentRequest> requests) async {
    final pdf = await generatePdf(requests);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  List<PaymentRequest> _requests = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //methoord
      final now = DateTime.now();

      final dateFormat = DateFormat('yyyy-MM-dd');

      _startDate = dateFormat.format(DateTime(now.year, now.month, 1));
     _endDate = dateFormat.format(now);

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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_user_own_request_list.dart');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  Future<List<PaymentRequest>> fetchRequests() async {
    String apiURL = '${APIHost().apiURL}/project_payment_controller.php/ViewUserRequest';
    PD.pd(text: apiURL);
    final response = await http.post(
      Uri.parse(apiURL),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"Authorization": APIToken().token,
        'created_by': UserCredentials().UserName,
        "start_date":_startDate.toString(),
        "end_date":_endDate.toString()}),
    );

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
    String apiURL = '${APIHost().apiURL}/ofz_payment_controller.php/ViewUserRequest';
    PD.pd(text: apiURL);
    final response = await http.post(
      Uri.parse(apiURL),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"Authorization": APIToken().token,
        'created_by': UserCredentials().UserName,
        "start_date":_startDate.toString(),
        "end_date":_endDate.toString()}),
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
    for (var request in _requests) {
      categorizedRequests[request.paymentType]?.add(request);
    }

    return Scaffold(
      appBar: MyAppBar(appname: 'View Request List'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
          child:
          Text(_errorMessage, style: TextStyle(color: Colors.red)))
          : DefaultTabController(
        length: 3,
        child: Column(
          children: [

            ExpansionTile(
              title:Center(
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
                SizedBox(height: 10,),
                Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: 'From Date',
                      value: _startDate,
                      onDateSelected: (date) {
                        setState(() => _startDate = date);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePicker(
                      label: 'To Date',
                      value: _endDate,
                      onDateSelected: (date) {
                        setState(() => _endDate = date);
                      },
                    ),
                  ),
                ],
              ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: (){fetchData();},
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Apply Filter'),
                ),],
            ),
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
                  _buildRequestList(
                      categorizedRequests["Cash"] ?? []),
                  _buildRequestList(
                      categorizedRequests["Bank Transfer"] ?? []),
                  _buildRequestList(
                      categorizedRequests["Cheque"] ?? []),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _exportAndPrintPdf(_requests),
        tooltip: 'Export PDF',
        child: const Icon(Icons.picture_as_pdf),
      ),
    );
  }

  Widget _buildRequestList(List<PaymentRequest> requests) {
    if (requests.isEmpty) {
      return Center(
        child: Text(
          "No requests available",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final isWideScreen = MediaQuery.of(context).size.width > 600;
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: InkWell(
            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => request.reqType == 'OFZ'
                      ? ViewOfzRequestList(
                    requestId: request.id.toString(),
                    isNotApprove: true,
                    refNumber: request.referenceNumber.toString(),
                  )
                      : ViewConstructionRequestList(
                    requestId: request.id.toString(),
                    isNotApprove: true,
                    refNumber: request.referenceNumber.toString(),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              collapsedBackgroundColor: Colors.white,
              backgroundColor: Colors.blue.shade50,
              iconColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Reference: ${request.referenceNumber}",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isWideScreen ? 20 : 16,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  StatusIcon(statusId: int.tryParse(request.statusId.toString()) ?? 0),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IOU Section
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt, color: Colors.blue, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              "IOU: ${IOUNumber.iouNumber(val: request.iouNumber)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Detail Rows
                      _buildDetailRow(
                        icon: Icons.person,
                        label: "Receiver",
                        value: request.receiverName.toString(),
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        icon: Icons.attach_money,
                        label: "Amount",
                        value:
                        "Amount: Rs.${NumberStyles.currencyStyle(request.totalRequestedAmount.toString())}\nVAT ${NumberStyles.currencyStyle(request.vat.toString())}:\nSSCL ${NumberStyles.currencyStyle(request.sscl.toString())}\nAdd Dis ${NumberStyles.currencyStyle(request.addDis.toString())}",
                        valueColor: Colors.green,
                      ),

                      if (request.paymentType == "Bank Transfer") ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.account_balance,
                          label: "Bank Branch",
                          value: request.bankBranch ?? 'N/A',
                        ),
                        _buildDetailRow(
                          icon: Icons.numbers,
                          label: "Account Number",
                          value: request.accountNumber ?? 'N/A',
                        ),
                      ],

                      if (request.isAuth == 1) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.verified_user,
                          label: "Authorized by",
                          value: request.authUser ?? 'N/A',
                        ),
                      ],
                      if (request.isAppro == 1) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.thumb_up,
                          label: "Approved by",
                          value: request.approUser ?? 'N/A',
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Responsive Buttons
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              if (kIsWeb)
                                FilledButton.icon(
                                  icon: const Icon(Icons.image),
                                  label: const Text("Pick Image"),
                                  onPressed: () => startFilePicker(
                                    int.tryParse(request.id.toString()) ?? 0,
                                    request.referenceNumber.toString(),
                                  ),
                                ),
                              FilledButton.icon(
                                icon: const Icon(Icons.playlist_add_check_circle),
                                label: const Text("View Bill Items"),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => request.reqType == 'OFZ'
                                        ? ViewOfzRequestList(
                                      requestId: request.id.toString(),
                                      isNotApprove: true,
                                      refNumber: request.referenceNumber.toString(),
                                    )
                                        : ViewConstructionRequestList(
                                      requestId: request.id.toString(),
                                      isNotApprove: true,
                                      refNumber: request.referenceNumber.toString(),
                                    ),
                                  ),
                                ),
                              ),
                              if (request.isAuth != '1' && request.isAppro != '1')
                                FilledButton.icon(
                                  icon: const Icon(Icons.delete_forever_rounded),
                                  label: const Text("Delete"),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.redAccent.shade200,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return request.reqType == 'OFZ'
                                            ? DisablingOfzRequestDialog(
                                          requestId: request.id.toString(),
                                          refNumber: request.referenceNumber.toString(),
                                        )
                                            : DisablingRequestDialog(
                                          requestId: request.id.toString(),
                                          refNumber: request.referenceNumber.toString(),
                                        );
                                      },
                                    );
                                  },
                                ),
                              if (request.referenceNumber == '-1')
                                FilledButton.icon(
                                  icon: const Icon(Icons.approval),
                                  label: const Text("Send To Approval"),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.grey.shade700,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  onPressed: () {
                                    _postRequest(request.id.toString());
                                  },
                                ),
                            ],
                          );
                        },
                      ),
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
  Widget _buildDatePicker({
    required String label,
    required String? value,
    required Function(String) onDateSelected,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, size: 20),
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              onDateSelected(DateFormat('yyyy-MM-dd').format(date));
            }
          },
        ),
      ),
      controller: TextEditingController(text: value),
      readOnly: true,
    );
  }
  Widget _buildDetailRow({ required IconData icon, required String label, required String value, Color? valueColor,}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: valueColor ?? Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  Future<void> _postRequest(String reqId) async {
    try {
      String idString = RequestNumber.formatNumber(val: int.tryParse(reqId)??0);
      WaitDialog.showWaitDialog(context, message: 'posting');
      String url = '${APIHost().apiURL}/ofz_payment_controller.php/PostToApprove';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "request_id":reqId,
          "req_ref_number":RequestNumber.refNumberOfz(val: idString),
          "is_active":"1",
          "is_post":"1",
          "is_visible":'1'
        }),
      );
      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          PD.pd(text: responseData.toString());
          final int status = responseData['status'];
          if (status == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green),
            );
          } else if (status == 409) {
            // Scanning message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message'] ?? 'Scanning',style: TextStyle(color: Colors.black),), backgroundColor: Colors.yellow),
            );
          } else {
            final String message = responseData['message'] ?? 'Error';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          }
        } catch (e,st) {
          ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_user_own_request_list.dart');
          String errorMessage = "Error decoding JSON: $e, Body: ${response.body}";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
      else {
        WaitDialog.hideDialog(context);
        String errorMessage = 'Estimation creation failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e,st) {
            ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_user_own_request_list.dart');
            errorMessage = response.body;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_user_own_request_list.dart');
      WaitDialog.hideDialog(context);
      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

}
