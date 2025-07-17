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

class OfzPayPointDialog extends StatefulWidget {
  final String requestId;
  final String refNumber;

  const OfzPayPointDialog({
    super.key,
    required this.refNumber,
    required this.requestId,
  });

  @override
  OfzPayPointDialogState createState() => OfzPayPointDialogState();
}

class OfzPayPointDialogState extends State<OfzPayPointDialog> {
  late String refNum;
  final TextEditingController _txtComment= TextEditingController();
  final TextEditingController _txtAmount= TextEditingController();
  final TextEditingController _txtPaymentRef= TextEditingController();
  final TextEditingController _txtBankName= TextEditingController();
  final TextEditingController _txtAccNum= TextEditingController();


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
    int? maxLength,
    int? maxLengthEnforced,
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
          maxLength: maxLength,
          maxLengthEnforcement: maxLengthEnforced != null
              ? MaxLengthEnforcement.enforced
              : MaxLengthEnforcement.none,
          inputFormatters: [
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ],
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey),
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
        if (maxLength != null)
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
      String apiURL = '${APIHost().apiURL}/ofz_payment_controller.php/ListOfRequestById';
      PD.pd(text: apiURL);
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          'idtbl_ofz_request': widget.requestId,
          "req_ref_number": widget.refNumber
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
              if (request['is_paid'] != 0) {
                OneBtnDialog.oneButtonDialog(context,
                    title: 'Payment proceed',
                    message: 'This payment request has already been processed',
                    btnName: 'Ok',
                    icon: Icons.info,
                    iconColor: Colors.red,
                    btnColor: Colors.blue
                ).then((v) {
                  if (v == true) {
                    Navigator.pop(context);
                  }
                });
              } else {
               // isPayed = request['is_paid'] == 1;
                _txtComment.text = request['pmt_cmt'] == 'na' ? '' : request['pmt_cmt'];
                refNum = request['req_ref_number'] ?? '';

                double total=double.tryParse(request['total'])??0;
                double vat=double.tryParse(request['vat'])??0;
                double sscl=double.tryParse(request['sscl'])??0;
                double addDis=double.tryParse(request['add_dis'])??0;
                double itemDis=double.tryParse(request['itemDisc'])??0;
                double payble=total+vat+sscl-addDis-itemDis;
                _txtAmount.text = NumberStyles.currencyStyle(payble.toString());
                _paymethId = request['paymeth_id'] ?? 0;
                _paymentType = request['payment_type'] ?? '';
                _txtPaymentRef.text = request['payment_ref'] ?? '';
                _txtBankName.text = request['bank_name'] ?? 'NO';
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
          logFile: 'ofz_pay_point_dialog.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    }
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
                .where((name) => name.isNotEmpty)
                .toList();

            if (_dropdownBank.isEmpty) {
              _dropdownBank = ['No banks available'];
            } else {
              _dropdownBank.insert(0, 'NO');
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
          logFile: 'ofz_pay_point_dialog.dart');
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
      PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            _activeAccNumMap = responseData['data'] ?? [];
            _dropdownAccNum = _activeAccNumMap
                .map<String>((item) => item['account_number']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList();

            if (_dropdownAccNum.isEmpty) {
              _dropdownAccNum = ['No Account available'];
            } else {
              _dropdownAccNum.insert(0, 'NO');
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
          logFile: 'ofz_pay_point_dialog.dart');
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
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _paymethId = 0;
    _paymentType = '';
    _activeBankMap = [];
    _dropdownBank = [];
    _activeAccNumMap = [];
    _dropdownAccNum = [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBank();
      _loadAccounts();
      _loadRequestInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
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
                if (_paymethId == 1) ...[
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
                  await _paymentReject( context, int.tryParse(widget.requestId.toString()) ?? 0, _txtComment.text, _txtPaymentRef.text, );
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
                if (_txtAccNum.text=='NO') {
                  OneBtnDialog.oneButtonDialog(
                    context,
                    title: 'Validation Error',
                    message: 'Please select payed Account',
                    btnName: 'OK',
                    icon: Icons.error,
                    iconColor: Colors.red,
                    btnColor: Colors.black,
                  );
                  return;
                }
                PD.pd(text: _paymethId.toString());
                if (_paymethId == 1 && _txtBankName.text=='NO') {
                  OneBtnDialog.oneButtonDialog(
                    context,
                    title: 'Validation Error',
                    message: 'Please select bank name',
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
                  await paymentApprove(
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
        ),
      ),
    );
  }

  Future<void> paymentApprove(BuildContext context, int requestId, int isPaid, String comment, String paymentRef) async {
    WaitDialog.showWaitDialog(context, message: 'Processing Request');
    try {

      String reqUrl='${APIHost().apiURL}/ofz_payment_controller.php/PaymentApprove';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "idtbl_ofz_request": requestId,
          "is_paid": isPaid,
          "pmt_status": isPaid,
          "pmt_cmt": comment,
          "pmt_user": UserCredentials().UserName,
          "ref_number": refNum,
          "amount": _txtAmount.text.replaceAll(',', ''),
          "paymeth_id": _paymethId,
          "payment_ref": paymentRef,
          "payed_date": _selectedDate.toIso8601String(),
          "bank_name": _txtBankName.text,
          "account_number": _txtAccNum.text,
          ...(_paymethId == 1 ? {"bank_name": _txtBankName.text} : {}),
        }),
      );

      WaitDialog.hideDialog(context);
      final responseData = jsonDecode(response.body);
      PD.pd(text: responseData.toString());

      if (response.statusCode == 200 && responseData['status'] == 200) {
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
          Navigator.pop(context, true);
        }
      } else {
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
          logFile: 'ofz_pay_point_dialog.dart');
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
      String apiURL ='${APIHost().apiURL}/ofz_payment_controller.php/PaymentReject';
      PD.pd(text: apiURL);
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "idtbl_ofz_request": requestId,
          "pmt_cmt": comment,
          "pmt_user": UserCredentials().UserName,
          "ref_number": refNum,
        }),
      );

      WaitDialog.hideDialog(context);
      final responseData = jsonDecode(response.body);
      PD.pd(text: responseData.toString());

      if (response.statusCode == 200 && responseData['status'] == 200) {
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
          Navigator.pop(context, true);
        }
      } else {
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
          logFile: 'ofz_pay_point_dialog.dart');
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
    super.key,
    required this.label,
    required this.suggestions,
    required this.icon,
    required this.controller,
    this.onChanged,
  });

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