import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/number_format.dart';
import 'package:roky_holding/env/user_data.dart';
import 'package:roky_holding/md_03/estimation_approve_dialog.dart';
import 'package:roky_holding/md_03/estimation_authorized_dialog.dart';
import 'package:roky_holding/md_04/view_ofz_request_list.dart';
import 'package:roky_holding/md_05/approve_ofz_request_dialog_box.dart';
import 'package:roky_holding/md_05/auth_ofz_request_dialog_box.dart';
import '../env/DialogBoxs.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';
import '../env/sp_format_data.dart';



class EstimationApprovingDialog extends StatefulWidget {
  final String id;
  final String estimationId;
  final String locationID;
  final double newAmount;
  const EstimationApprovingDialog({super.key,required this.newAmount ,required this.id,required this.estimationId,required this.locationID});

  @override
  EstimationApprovingDialogState createState() => EstimationApprovingDialogState();
}

class EstimationApprovingDialogState extends State<EstimationApprovingDialog> {
  List<EstimationAuth> _requests = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late  int estimationId=0;
  late int estimationReqId=0;

  final TextEditingController _txtComment = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchRequests();
    });
  }

  Future<void> fetchRequests() async {
    WaitDialog.showWaitDialog(context, message: 'Loading...');
    String apiURL = '${APIHost().apiURL}/estimation_controller.php/GetEventData';
    PD.pd(text: apiURL);
    try {
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "estimation_id": widget.estimationId,
          "estimation_req_id": widget.id,
        }),
      );

      PD.pd(text: apiURL);
      if (response.statusCode == 200) {
        Navigator.pop(context);
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          List<dynamic> data = responseData['data'];
          estimationReqId =int.tryParse(data[0]['estimation_req_id'].toString())??0;
          estimationId=int.tryParse(data[0]['estimation_id'].toString())??0;
          PD.pd(text: estimationReqId.toString());
        }
        else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Error loading requests';
            _isLoading = false;
          });
        }
      }
      else {
        Navigator.pop(context);
        setState(() {
          _errorMessage = 'HTTP Error: ${response.statusCode}';
        });
      }
    } catch (e, st) {
      Navigator.pop(context);
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'estimation_approve_dialog.dart'
      );

      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> approveOrRejectRequest(BuildContext context, int estimationId, int estimationReqId, int isApproved) async {
    WaitDialog.showWaitDialog(context, message: 'Processing Request');
    try {
      String apiURL='${APIHost().apiURL}/estimation_controller.php/Approved';
      PD.pd(text: apiURL);
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "estimation_id": estimationId,
          "estimation_req_id": estimationReqId,
          "is_appr":isApproved,
          "appr_by": UserCredentials().UserName,
          "appr_cmt": _txtComment.text,
          "location_id": widget.locationID,
          "new_amount": widget.newAmount,
        }),
      );
      WaitDialog.hideDialog(context);
      final responseData = jsonDecode(response.body);
      PD.pd(text: responseData.toString());
      if (response.statusCode == 200 && responseData['status'] == 200) {
        OneBtnDialog.oneButtonDialog(
          context,
          title: "Successful",
          message: '${responseData['message']}',
          btnName: 'Ok',
          icon: Icons.verified_outlined,
          iconColor: Colors.black,
          btnColor: Colors.green,
        ).then((value){
          if(value==true){
            Navigator.pop(context,true);
          }
        });
      } else {
        OneBtnDialog.oneButtonDialog(
          context,
          title: 'Error',
          message: '${responseData['message']}',
          btnName: 'OK',
          icon: Icons.error,
          iconColor: Colors.red,
          btnColor: Colors.black,
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'estimation_approve_dialog.dart');
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
  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(
        "Approve Estimations",
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            CupertinoTextField(
              controller: _txtComment,  // Use CupertinoTextField instead of TextField
              placeholder: 'Enter your comment here',
              maxLines: 3,  // Limit the height of the text field
              padding: EdgeInsets.all(8.0), // Padding for text field
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () async {
            final val = await YNDialogCon.ynDialogMessage(
              context,
              messageBody: 'Are you sure you want to Reject the estimation approving request ${widget.id}?',
              messageTitle: 'Confirm Payment',
              icon: Icons.verified,
              iconColor: Colors.green,
              btnDone: 'Reject',
              btnClose: 'Cancel',
            );
            if (val == 1) {
              approveOrRejectRequest(context,estimationId,estimationReqId,-1);
            }

            //Navigator.pop(context);
          },
          child: const Text('Reject', style: TextStyle(color: CupertinoColors.systemRed),),
        ),
        CupertinoDialogAction(
          onPressed: () async {
            final val = await YNDialogCon.ynDialogMessage(
              context,
              messageBody: 'Are you sure you want to Approve request number ${widget.id}?',
              messageTitle: 'Confirm Payment',
              icon: Icons.verified,
              iconColor: Colors.green,
              btnDone: 'Approve',
              btnClose: 'Cancel',
            );
            if (val == 1) {
                approveOrRejectRequest(context,estimationId,estimationReqId,1); // Pass comment to the API
            }

            //Navigator.pop(context);
          },
          isDefaultAction: true,
          child: const Text(
            'Approved',
            style: TextStyle(color: CupertinoColors.activeGreen),
          ),
        ),
      ],
    );
  }


}
