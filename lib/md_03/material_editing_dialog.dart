import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';
import '../env/user_data.dart';

class MaterialUpdateDialog extends StatefulWidget {
  final int itemId;

  const MaterialUpdateDialog({
    super.key,
    required this.itemId,
  });

  @override
  _MaterialUpdateDialogState createState() => _MaterialUpdateDialogState();
}

class _MaterialUpdateDialogState extends State<MaterialUpdateDialog> {
  final TextEditingController _txtQtyController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  late bool isEditAllows;
  late String materialName;

  Future<void> _loadMaterialInfo() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'loading');
      String reqUrl =
          '${APIHost().apiURL}/material_controller.php/GetMateriaInfoById';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token,
          'idtbl_material_list':widget.itemId},),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        Navigator.pop(context);
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            List<dynamic> activeMaterial = responseData['data'] ?? [];
            var material = activeMaterial.isNotEmpty ? activeMaterial[0] : null;
            if (material != null) {
              materialName = material['material_name']?.toString() ?? "No Name";
              _txtQtyController.text = material['qty']?.toString() ?? "0";
              _amountController.text = (double.tryParse(material['amount']?.toString() ?? "0") ?? 0).toStringAsFixed(2);
              isEditAllows = material['is_edit_allow'] == 1;
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
      }
      else {
        Navigator.pop(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'material_editing_dialog.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    materialName = ""; // Initialize to avoid null issues
    isEditAllows = false; // Initialize default state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //methoord
      _loadMaterialInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(
        materialName,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildTextField(
              controller: _txtQtyController,
              label: 'Quantity',
              icon: CupertinoIcons.cube_box,
              hintText: 'Enter quantity',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _amountController,
              label: 'Amount',
              icon: CupertinoIcons.money_dollar_circle,
              hintText: 'Enter amount',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(CupertinoIcons.checkmark_seal, color: CupertinoColors.activeGreen),
                    SizedBox(width: 8),
                    Text('User can edit price'),
                  ],
                ),
                CupertinoSwitch(
                  value: isEditAllows,
                  onChanged: (bool value) {
                    setState(() {
                      isEditAllows = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: () {
            final double updatedQty = double.tryParse(_txtQtyController.text) ?? 0.0;
            final double updatedAmount = double.tryParse(_amountController.text) ?? 0.0;

            changePrice(context, widget.itemId, updatedQty, updatedAmount, isEditAllows);

            Navigator.pop(context);
          },
          isDefaultAction: true,
          child: const Text(
            'Save',
            style: TextStyle(color: CupertinoColors.activeGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
  }) {
    return CupertinoTextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Icon(icon, color: CupertinoColors.activeBlue),
      ),
      placeholder: hintText,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      style: const TextStyle(fontSize: 16),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
    );
  }

  @override
  void dispose() {
    _txtQtyController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> changePrice(BuildContext context, int materialId, double qty, double amount, bool isEditAllows) async {
    WaitDialog.showWaitDialog(context, message: 'Updating Price');

    try {
      String? token = APIToken().token;

      if (token == null || token.isEmpty) {
        PD.pd(text: "Authentication token is missing.");
        WaitDialog.hideDialog(context);
        return;
      }
      String reqUrl ='${APIHost().apiURL}/material_controller.php/EditPrice';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": token,
          "idtbl_material_list": materialId,
          "qty": qty,
          "amount": amount,
          "is_edit_allow": isEditAllows == true ? 1 : 0,
          "change_by": UserCredentials().UserName,
        }),
      );

      WaitDialog.hideDialog(context);

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 200) {
        OneBtnDialog.oneButtonDialog(
          context,
          title: "Successful",
          message: responseData['message'],
          btnName: 'Ok',
          icon: Icons.verified_outlined,
          iconColor: Colors.black,
          btnColor: Colors.green,
        );
      } else {
        OneBtnDialog.oneButtonDialog(
          context,
          title: 'Error',
          message: responseData['message'] ?? 'Update failed',
          btnName: 'OK',
          icon: Icons.error,
          iconColor: Colors.red,
          btnColor: Colors.black,
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'material_editing_dialog.dart');
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
