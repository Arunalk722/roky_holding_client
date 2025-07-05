import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/user_data.dart';
import '../env/DialogBoxs.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';

class EstimationAuth{
  final int id;
  final int estimationReqId;
  final bool isAuth;
  final bool isApprove;
  EstimationAuth({
    required this.estimationReqId,
   required this.id,
   required this.isApprove,
   required this.isAuth
});
  factory EstimationAuth.fromJson(Map<String ,dynamic> json){
    return EstimationAuth(
      id: int.tryParse(json['idtbl_project_location_estimation_events'].toString())??0,
      estimationReqId: int.tryParse('estimation_req_id'.toString())??0,
      isAuth : bool.tryParse(json['is_auth'].toString())??false,
      isApprove : bool.tryParse(json['is_appr'].toString())??false,
    );
  }
}



class EstimationAuthorizedDialog extends StatefulWidget {
  final String id;
  final String estimationId;
  final String locationID;
  const EstimationAuthorizedDialog({super.key,required this.id,required this.estimationId,required this.locationID});

  @override
  EstimationAuthorizedDialogState createState() => EstimationAuthorizedDialogState();
}

class EstimationAuthorizedDialogState extends State<EstimationAuthorizedDialog> {
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
          logFile: 'estimation_authorized_dialog.dart'
      );

      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(
        "Authorizing Estimations",
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
              messageBody: 'Are you sure you want to Reject the estimation Authorized request number ${widget.id}?',
              messageTitle: 'Confirm Payment',
              icon: Icons.verified,
              iconColor: Colors.green,
              btnDone: 'Reject',
              btnClose: 'Cancel',
            );
            if (val == 1) {
              authorizedOrRejectRequest(context,estimationId,estimationReqId,-1);
            }

            //Navigator.pop(context);
          },
          child: const Text('Reject', style: TextStyle(color: CupertinoColors.systemRed),),
        ),
        CupertinoDialogAction(
          onPressed: () async {
            final val = await YNDialogCon.ynDialogMessage(
              context,
              messageBody: 'Are you sure you want to Authorized request number ${widget.id}?',
              messageTitle: 'Confirm Payment',
              icon: Icons.verified,
              iconColor: Colors.green,
              btnDone: 'Authorized',
              btnClose: 'Cancel',
            );
            if (val == 1) {
              authorizedOrRejectRequest(context,estimationId,estimationReqId,1);
            }

            //Navigator.pop(context);
          },
          isDefaultAction: true,
          child: const Text(
            'Authorized',
            style: TextStyle(color: CupertinoColors.activeGreen),
          ),
        ),
      ],
    );
  }

  Future<void> authorizedOrRejectRequest(BuildContext context, int estimationId, int estimationReqId, int isApproved) async {
    WaitDialog.showWaitDialog(context, message: 'Processing Request');
    try {
      String apiURL='${APIHost().apiURL}/estimation_controller.php/Authorized';
      PD.pd(text: apiURL);
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "estimation_id": estimationId,
          "estimation_req_id": estimationReqId,
          "is_auth":isApproved,
          "auth_by": UserCredentials().UserName,
          "auth_cmt": _txtComment.text,
          "location_id": widget.locationID,
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'estimation_authorized_dialog.dart');
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

class _Status {
  final String text;
  final Color color;

  _Status(this.text, this.color);
}
