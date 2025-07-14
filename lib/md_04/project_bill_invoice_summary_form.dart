import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pattern_formatter/numeric_formatter.dart';
import 'package:roky_holding/env/number_format.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';
import '../env/user_data.dart';

class InvoiceSummaryDialog extends StatefulWidget {
  final String refId;
  final String refNumber;

  const InvoiceSummaryDialog({
    super.key,
    required this.refNumber,
    required this.refId,
  });

  @override
  InvoiceSummaryDialogState createState() => InvoiceSummaryDialogState();
}

class InvoiceSummaryDialogState extends State<InvoiceSummaryDialog> {
  final TextEditingController _txtTotalAmount = TextEditingController();
  final TextEditingController _txtVAT = TextEditingController();
  final TextEditingController _txtSSCL = TextEditingController();
  final TextEditingController _txtAdditionalDiscount = TextEditingController();
  final TextEditingController _txtItemsDiscount  = TextEditingController();
  final TextEditingController _txtItemsTotal  = TextEditingController();
  final TextEditingController _txtFinalAmount = TextEditingController();



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _txtItemsTotal.addListener(_calculateFinalAmount);
      _txtVAT.addListener(_calculateFinalAmount);
      _txtSSCL.addListener(_calculateFinalAmount);
      _txtAdditionalDiscount.addListener(_calculateFinalAmount);
      _txtItemsDiscount.addListener(_calculateFinalAmount);
    });

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration.zero, _loadInvoiceDetails);
    });
  }

  void _calculateFinalAmount() {
    try {
      double itemsTotal = double.tryParse(_txtItemsTotal.text.replaceAll(',', '')) ?? 0;
      double vat = double.tryParse(_txtVAT.text.replaceAll(',', '')) ?? 0;
      double sscl = double.tryParse(_txtSSCL.text.replaceAll(',', '')) ?? 0;
      double discount = double.tryParse(_txtAdditionalDiscount.text.replaceAll(',', '')) ?? 0;
      double itemDis = double.tryParse(_txtItemsDiscount.text.replaceAll(',', '')) ?? 0;
      double totalTaxes= itemsTotal+vat + sscl;
      double totalDis=discount+itemDis;
      double finalAmount = totalTaxes - totalDis;
      setState(() {
        _txtFinalAmount.text = NumberStyles.currencyStyle(finalAmount.toStringAsFixed(2).toString());
      });
    } catch (e) {
      PD.pd(text: "Error calculating final amount: $e");
    }
  }

  Future<void> _loadInvoiceDetails() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading invoice details');
      String apiURL = '${APIHost().apiURL}/project_payment_controller.php/GetBillSum';
      PD.pd(text: apiURL);
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          'request_id': widget.refId,
          "req_ref_number": widget.refNumber,
        }),
      );

      PD.pd(text: apiURL);

      if (response.statusCode == 200) {
        Navigator.pop(context);
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());

        if (responseData['status'] == 200) {
          setState(() {
            List<dynamic> invoiceData = responseData['data'] ?? [];
            var invoice = invoiceData.isNotEmpty ? invoiceData[0] : null;

            if (invoice != null) {
              _txtTotalAmount.text = NumberStyles.currencyStyle(invoice['requested_amount'].toString());
              _txtVAT.text = NumberStyles.currencyStyle(invoice['vat'].toString());
              _txtSSCL.text = NumberStyles.currencyStyle(invoice['sscl'].toString());
              _txtAdditionalDiscount.text =NumberStyles.currencyStyle(invoice['addt_discount'].toString());
              _txtItemsDiscount.text =NumberStyles.currencyStyle(invoice['total_items_disc'].toString());
              _txtItemsTotal.text =NumberStyles.currencyStyle(invoice['total_items_amount'].toString());
              
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
          logFile: 'project_bill_invoice_summary_form.dart'
      );
      Navigator.pop(context);
      PD.pd(text: e.toString());
    }
  }

/*  @override
  void dispose() {
    _txtTotalAmount.dispose();
    _txtVAT.dispose();
    _txtSSCL.dispose();
    _txtAdditionalDiscount.dispose();
    _txtFinalAmount.dispose();
    _txtTotalAmount.dispose();
    _txtItemsTotal.dispose();
    super.dispose();
  }*/

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(
        "Invoice Summary Form",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildAmountField("Total Bill Amount", _txtTotalAmount),
            _buildAmountField("VAT Amount", _txtVAT),
            _buildAmountField("SSCL Amount", _txtSSCL),
            _buildAmountField("Additional Discount", _txtAdditionalDiscount),
            _buildAmountField("Items Total", _txtItemsTotal, isEnabled: false),
            _buildAmountField("Items Discount", _txtItemsDiscount, isEnabled: false),
            _buildAmountField("Final Amount", _txtFinalAmount, isEnabled: false),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: CupertinoColors.systemRed)),
        ),
        CupertinoDialogAction(
          onPressed: () async {
            if (_validateInputs()) {
              final val = await YNDialogCon.ynDialogMessage(
                context,
                messageBody: 'Are you sure you want to save this invoice?',
                messageTitle: 'Confirm Invoice',
                icon: Icons.verified,
                iconColor: Colors.green,
                btnDone: 'Save',
                btnClose: 'Cancel',
              );
              if (val == 1) {
                _saveInvoice(context);
              }
            }
          },
          isDefaultAction: true,
          child: const Text('Save', style: TextStyle(color: CupertinoColors.activeGreen)),
        ),
      ],
    );
  }

  Widget _buildAmountField(String label, TextEditingController controller, {bool isEnabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: CupertinoTextField(
              inputFormatters: [
                ThousandsFormatter(allowFraction: true)
              ],
              controller: controller,
              placeholder: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              enabled: isEnabled,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isEnabled?Colors.white:Colors.grey,
                border: Border.all(color: CupertinoColors.systemGrey),
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateInputs() {
    if (_txtTotalAmount.text.isEmpty || double.tryParse(_txtTotalAmount.text.replaceAll(',', '')) == null) {
      OneBtnDialog.oneButtonDialog(
        context,
        title: 'Error',
        message: 'Please enter a valid total amount',
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
      return false;
    }

    // Validate other numeric fields
    final numericFields = [
      {'controller': _txtVAT, 'name': 'VAT'},
      {'controller': _txtSSCL, 'name': 'SSCL'},
      {'controller': _txtAdditionalDiscount, 'name': 'Additional Discount'},
    ];

    for (var field in numericFields) {
      final controller = field['controller'] as TextEditingController;
      final fieldName = field['name'] as String;

      if (controller.text.isNotEmpty && double.tryParse(controller.text.replaceAll(',', '')) == null) {
        OneBtnDialog.oneButtonDialog(
          context,
          title: 'Error',
          message: 'Please enter a valid $fieldName amount',
          btnName: 'OK',
          icon: Icons.error,
          iconColor: Colors.red,
          btnColor: Colors.black,
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _saveInvoice(BuildContext context) async {
    WaitDialog.showWaitDialog(context, message: 'Saving Invoice');
    try {
      String apiURL='${APIHost().apiURL}/project_payment_controller.php/UpdateInvoiceSum';
      PD.pd(text: apiURL);
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "tbl_user_payment_request_id": widget.refId,
          "req_ref_number": widget.refNumber,
          "requested_amount": double.parse(_txtTotalAmount.text.replaceAll(',', '')),
          "vat": double.tryParse(_txtVAT.text.replaceAll(',', '')) ?? 0,
          "sscl": double.tryParse(_txtSSCL.text.replaceAll(',', '')) ?? 0,
          "addt_discount": double.tryParse(_txtAdditionalDiscount.text.replaceAll(',', '')) ?? 0,
          "change_by": UserCredentials().UserName,
        }),
      );
      WaitDialog.hideDialog(context);
      final responseData = jsonDecode(response.body);
      PD.pd(text: responseData.toString());

      if (response.statusCode == 200 && responseData['status'] == 200) {
        OneBtnDialog.oneButtonDialog(
          context,
          title: "Success",
          message: 'Invoice ${widget.refNumber} saved successfully',
          btnName: 'Ok',
          icon: Icons.check_circle,
          iconColor: Colors.green,
          btnColor: Colors.black,
        ).then((value) {
          if (value == true) {
            Navigator.pop(context, true);
          }
        });
      } else {
        OneBtnDialog.oneButtonDialog(
          context,
          title: 'Error',
          message: responseData['message'] ?? 'Failed to save invoice',
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
          logFile: 'project_bill_invoice_summary_form.dart'
      );
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