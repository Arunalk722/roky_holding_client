import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/number_format.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';
import '../env/user_data.dart';

class PayPointDialog extends StatefulWidget {
  final String requestId;
  final String refnumber;

  const PayPointDialog({
    super.key,
    required this.refnumber,
    required this.requestId,
  });

  @override
  PayPointDialogState createState() => PayPointDialogState();
}

class PayPointDialogState extends State<PayPointDialog> {

  late String refNum;
  late TextEditingController _txtComment;
  late TextEditingController _txtAmount;
  late TextEditingController _txtPaymentRef;
  late TextEditingController _txtBankName;
  late TextEditingController _txtAccNum;
  late DateTime _selectedDate;
  late int _paymethId;
  late String _paymentType;

  // Reusable labeled text field widget
  Widget _labeledTextField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    bool readOnly = false,
    Widget? suffix,
    int? maxLines = 1,
    TextInputType? keyboardType,
    int? maxLength, // Add this parameter to specify max character limit
    int? maxLengthEnforced, // Optional: if you want to enforce the limit visually
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          readOnly: readOnly,
          maxLines: maxLines,
          padding: const EdgeInsets.all(8.0),
          suffix: suffix,
          keyboardType: keyboardType,
          maxLength: maxLength, // Set the maximum character limit
          maxLengthEnforcement: maxLengthEnforced != null
              ? MaxLengthEnforcement.enforced
              : MaxLengthEnforcement.none,
          inputFormatters: [
            if (maxLength != null)
              LengthLimitingTextInputFormatter(maxLength), // Enforces the limit
            // You can add other formatters here if needed
          ],
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey),
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
        if (maxLength != null) // Show character count if maxLength is provided
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${controller.text.length}/$maxLength',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
      ],
    );
  }
  Widget _datePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: CupertinoTextField(
              placeholder: 'Select payment date',
              controller: TextEditingController(
                  text: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              maxLines: 1,
              padding: const EdgeInsets.all(8.0),
              suffix: const Icon(CupertinoIcons.calendar),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey),
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Future<void> _loadRequestInfo() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'loading');
      String apiURL = '${APIHost().apiURL}/project_payment_controller.php/ListOfRequestById';
      PD.pd(text: apiURL);
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          'tbl_user_payment_request_id': widget.requestId,
          "req_ref_number": widget.refnumber
        }),
      );

      PD.pd(text: apiURL);
      if (response.statusCode == 200) {
        Navigator.pop(context);
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            List<dynamic> requestData = responseData['data'] ?? [];
            var request = requestData.isNotEmpty ? requestData[0] : null;
            if (request != null) {
              if(request['is_paid']!=0){
                OneBtnDialog.oneButtonDialog(context, title: 'Payment proceed', message: 'This payment request has already been processed', btnName: 'Ok', icon: Icons.info, iconColor: Colors.red, btnColor: Colors.blue).then((v){
                  if(v=true){
                    Navigator.pop(context);
                  }
                });
              }
              else{

                _txtComment.text = request['pmt_cmt'] == 'na' ? '' : request['pmt_cmt'];
                refNum = request['req_ref_number']??'';
                _txtAmount.text = NumberStyles.currencyStyle(request['total_req_amount']??'0');
                _paymethId = request['paymeth_id'];
                _paymentType = request['payment_type']??'';
                _txtPaymentRef.text = request['payment_ref']??'';
                _txtBankName.text=request['bank_name']??'NO';
              }
            }
          });
        } else {
          final String message = responseData['message'] ?? 'Error';
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
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'pay_point_dialog.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _txtComment = TextEditingController();
    _txtAmount = TextEditingController();
    _txtPaymentRef = TextEditingController();
    _txtBankName = TextEditingController();
    _selectedDate = DateTime.now();
    _txtAccNum = TextEditingController();
    _paymethId = 0;
    _paymentType = '';
    _activeBankMap = [];
    _dropdownBank =  [];
    _activeAccNumMap = [];
    _dropdownAccNum =  [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBank();
      _loadAccounts();
      _loadRequestInfo();
    });
  }
  List<String> _dropdownBank = [];
  List<dynamic> _activeBankMap = [];


  Future<void> _loadBank() async {
    try {
      String reqUrl = '${APIHost().apiURL}/bank_controller.php/GetBankList';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Authorization": APIToken().token}),
      );



      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _activeBankMap = responseData['data'] ?? [];
            _dropdownBank = _activeBankMap
                .map<String>((item) => item['bank_name']?.toString() ?? '')
                .where((name) => name.isNotEmpty) // Filter out empty names
                .toList();

            // Add a default empty option if needed
            if (_dropdownBank.isEmpty) {
              _dropdownBank = ['No banks available'];
            }else {
              _dropdownBank.insert(0, 'NO'); // Add default first item
            }
          });
        } else {
          final String message = responseData['message'] ?? 'Error loading banks';
          PD.pd(text: message);
          // Show error to user if needed
        }
      } else {
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_pay_point_dialog.dart'
      );
      PD.pd(text: e.toString());
    }
  }

  List<String> _dropdownAccNum = [];
  List<dynamic> _activeAccNumMap = [];
  Future<void> _loadAccounts() async {
    try {
      String reqUrl = '${APIHost().apiURL}/bank_controller.php/ListAccount';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Authorization": APIToken().token}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            _activeAccNumMap = responseData['data'] ?? [];
            _dropdownAccNum = _activeAccNumMap
                .map<String>((item) => item['account_number']?.toString() ?? '')
                .where((name) => name.isNotEmpty) // Filter out empty names
                .toList();

            // Add a default empty option if needed
            if (_dropdownAccNum.isEmpty) {
              _dropdownAccNum = ['No Account available'];
            }else {
              _dropdownAccNum.insert(0, 'NO'); // Add default first item
            }
          });
        } else {
          final String message = responseData['message'] ?? 'Error loading banks';
          PD.pd(text: message);
        }
      } else {
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_pay_point_dialog.dart'
      );
      PD.pd(text: e.toString());
    }
  }



  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getCommentLabel() {
    switch (_paymethId) {
      case 0: // Cash
        return 'Notes';
      case 1: // Cheque
        return 'Cheque Number';
      case 2: // Bank Transfer
        return 'Transaction Reference';
      default:
        return 'Payment Details';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false, // Prevent closing on back button
        child: GestureDetector(
        behavior: HitTestBehavior.opaque, // This prevents taps from passing through
        onTap: () {}, // Empty onTap handler to absorb taps
        child: CupertinoAlertDialog(
          title: Row(
            children: [
              IconButton(
                onPressed: (){
                  Navigator.pop(context);
                },
                icon: Icon(Icons.close, color: CupertinoColors.destructiveRed),
              ),
              Expanded(
                child: Text(
                  "Payment Process $_paymentType",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
          child: Column(
            children: [
              _labeledTextField(
                label: 'Amount',
                controller: _txtAmount,
                placeholder: 'Enter amount',
                readOnly: true,
                keyboardType: TextInputType.number,
              ),
              _labeledTextField(
                maxLength: 45,
                label: _getCommentLabel(),
                controller: _txtPaymentRef,
                placeholder: 'Enter ${_getCommentLabel().toLowerCase()}',
              ),
              if (_paymethId == 1) ...[
                Material(
                  color: Colors.transparent,
                  child: CustomDropdown(
                    label: 'Select Bank',
                    suggestions: _dropdownBank,
                    icon: FontAwesomeIcons.bank,
                    controller: _txtBankName,
                    onChanged: (value) {
                      if (value != null && value != 'Select a bank') {
                        setState(() {
                          _txtBankName.text = value;
                        });
                      }
                    },
                  ),
                ),
              ],
              Material(
                color: Colors.transparent,
                child: CustomDropdown(
                  label: 'Select Account',
                  suggestions: _dropdownAccNum,
                  icon: Icons.account_balance_wallet,
                  controller: _txtAccNum,
                  onChanged: (value) {
                    if (value != null && value != 'Select a Account') {
                      setState(() {
                        _txtAccNum.text = value;
                      });
                    }
                  },
                ),
              ),
              if(_paymethId==1)...[
                _datePickerField()
              ],
              _labeledTextField(
                maxLength: 45,
                label: 'Comments',
                controller: _txtComment,
                placeholder: 'Enter additional comments (optional)',
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () async {
              final val = await YNDialogCon.ynDialogMessage(
                context,
                messageBody: 'Are you sure you want to reject request number ${refNum}?',
                messageTitle: 'Confirm Rejection',
                icon: Icons.cancel,
                iconColor: Colors.red,
                btnDone: 'Reject',
                btnClose: 'Cancel',
              );

              if (val == 1) {
                await _paymentReject(
                context,
                  int.tryParse(widget.requestId.toString()) ?? 0,
                _txtComment.text,
                _txtPaymentRef.text,
                );
              }
            },
            isDestructiveAction: true,
            child: const Text('Reject'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              if (_txtPaymentRef.text.isEmpty) {
                OneBtnDialog.oneButtonDialog(
                  context,
                  title: 'Validation Error',
                  message: 'Please enter ${_getCommentLabel().toLowerCase()}',
                  btnName: 'OK',
                  icon: Icons.error,
                  iconColor: Colors.red,
                  btnColor: Colors.black,
                );
                return;
              }

              if (_paymethId == 2 && _txtBankName.text=='NO') {
                OneBtnDialog.oneButtonDialog(
                  context,
                  title: 'Validation Error',
                  message: 'Please enter bank name',
                  btnName: 'OK',
                  icon: Icons.error,
                  iconColor: Colors.red,
                  btnColor: Colors.black,
                );
                return;
              }

              if (_paymethId == 1 && _txtBankName.text=='NO') {
                OneBtnDialog.oneButtonDialog(
                  context,
                  title: 'Validation Error',
                  message: 'Please enter bank name',
                  btnName: 'OK',
                  icon: Icons.error,
                  iconColor: Colors.red,
                  btnColor: Colors.black,
                );
                return;
              }
              final val = await YNDialogCon.ynDialogMessage(
                context,
                messageBody: 'Are you sure you want to Confirm Payment request number ${refNum}?',
                messageTitle: 'Confirm Payment',
                icon: Icons.verified,
                iconColor: Colors.green,
                btnDone: 'Approved',
                btnClose: 'Cancel',
              );
              if (val == 1) {
                await _paymentApprove(
                  context,
                  int.tryParse(widget.requestId.toString()) ?? 0,
                  1,
                  _txtComment.text,
                  _txtPaymentRef.text,
                );
              }

            },
            isDefaultAction: true,
            child: const Text(
              'Pay',
              style: TextStyle(color: CupertinoColors.activeGreen),
            ),
          ),
        ],
      ),)
    );
  }

  Future<void> _paymentApprove(BuildContext context, int requestId, int isPaid, String comment, String paymentRef) async {
    WaitDialog.showWaitDialog(context, message: 'Processing Request');
    try {

      String reqUrl='${APIHost().apiURL}/project_payment_controller.php/PaymentApprove';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "tbl_user_payment_request_id": requestId,
          "is_paid": isPaid,
          "pmt_status": isPaid,
          "pmt_cmt": comment,
          "pmt_user": UserCredentials().UserName,
          "ref_number": refNum,
          "amount": _txtAmount.text.replaceAll(',', ''),
          "paymeth_id": _paymethId,
          "payment_ref": paymentRef,
          "payed_date": _selectedDate.toIso8601String(),
          "bank_name":_txtBankName.text,
          "account_number":_txtAccNum.text,
          ...(_paymethId == 2 ? {"bank_name": _txtBankName.text} : {}),
        }),
      );

      WaitDialog.hideDialog(context);
      final responseData = jsonDecode(response.body);
      PD.pd(text: responseData.toString());

      if (response.statusCode == 200 && responseData['status'] == 200) {
        // Show success and close only if user confirms
        bool? shouldClose = await OneBtnDialog.oneButtonDialog(
          context,
          title: "Successful",
          message: responseData['message'],
          btnName: 'Ok',
          icon: Icons.verified_outlined,
          iconColor: Colors.black,
          btnColor: Colors.green,
        );

        if (shouldClose == true) {
          Navigator.pop(context, true); // Close with success status
        }
      } else {
        // Show error but don't close
        await OneBtnDialog.oneButtonDialog(
          context,
          title: 'Error',
          message: responseData['message'] ?? 'Request processing failed',
          btnName: 'OK',
          icon: Icons.error,
          iconColor: Colors.red,
          btnColor: Colors.black,
        );
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'pay_point_dialog.dart');
      WaitDialog.hideDialog(context);
      ExceptionDialog.exceptionDialog(
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
  Future<void> _paymentReject(BuildContext context, int requestId, String comment, String paymentRef) async {
    WaitDialog.showWaitDialog(context, message: 'Processing Request');
    try {

      String apiURL='${APIHost().apiURL}/project_payment_controller.php/PaymentReject';
      PD.pd(text: apiURL);
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "tbl_user_payment_request_id": requestId,
          "pmt_cmt": comment,
          "pmt_user": UserCredentials().UserName,
          "ref_number": refNum,
        }),
      );
      WaitDialog.hideDialog(context);
      final responseData = jsonDecode(response.body);
      PD.pd(text: responseData.toString());

      if (response.statusCode == 200 && responseData['status'] == 200) {
        // Show success and close only if user confirms
        bool? shouldClose = await OneBtnDialog.oneButtonDialog(
          context,
          title: "Successful",
          message: responseData['message'],
          btnName: 'Ok',
          icon: Icons.verified_outlined,
          iconColor: Colors.black,
          btnColor: Colors.green,
        );

        if (shouldClose == true) {
          Navigator.pop(context, true); // Close with success status
        }
      } else {
        // Show error but don't close
        await OneBtnDialog.oneButtonDialog(
          context,
          title: 'Error',
          message: responseData['message'] ?? 'Request processing failed',
          btnName: 'OK',
          icon: Icons.error,
          iconColor: Colors.red,
          btnColor: Colors.black,
        );
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'pay_point_dialog.dart');
      WaitDialog.hideDialog(context);
      ExceptionDialog.exceptionDialog(
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

class CustomDropdown extends StatelessWidget {
  final String label;
  final List<String> suggestions;
  final IconData icon;
  final TextEditingController controller;
  final Function(String?)? onChanged;

  const CustomDropdown({
    Key? key,
    required this.label,
    required this.suggestions,
    required this.icon,
    required this.controller,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.0),
                borderSide: BorderSide(color: CupertinoColors.systemGrey),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
            isExpanded: true,
            value: controller.text.isEmpty ? null : controller.text,
            hint: Text('Select $label'),
            icon: Icon(icon),
            items: suggestions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}