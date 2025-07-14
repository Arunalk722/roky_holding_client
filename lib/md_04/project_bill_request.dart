import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roky_holding/env/DialogBoxs.dart';
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/custome_icon.dart';
import 'package:roky_holding/env/number_format.dart';
import 'package:roky_holding/env/sp_format_data.dart';
import 'package:roky_holding/env/user_data.dart';
import '../env/app_logs_to.dart';
import '../env/input_widget.dart';
import '../env/print_debug.dart';
import 'package:http_parser/http_parser.dart';


class ProjectBillRequest extends StatefulWidget {
  const ProjectBillRequest({super.key});

  @override
  State<ProjectBillRequest> createState() => _ProjectBillRequestState();
}

class _ProjectBillRequestState extends State<ProjectBillRequest>{

  final GlobalKey<FormState> _requestFormKey = GlobalKey<FormState>();
  late bool _btnVisible=true;
  int _selectedPaymentType = 0; // 0 - Cash, 1 - Cheque, 2 - Bank Transfer
  late String _requestDate;
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
      PD.pd(text: apiURL);
      var uri = Uri.parse(
          apiURL );

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
            btnColor: Colors.green).then((value) async {
          if (value == true) {
           // await _postToApproveRequest();
          }
        });
      }else if (response.statusCode == 200 && decodedResponse['status'] == 400) {
        Navigator.pop(context);
        OneBtnDialog.oneButtonDialog(context, title: 'Limit Issue', message: decodedResponse['message'], btnName: 'Ok', icon: Icons.image_not_supported_rounded, iconColor: Colors.red, btnColor: Colors.red);

      } else {
        Navigator.pop(context);
        OneBtnDialog.oneButtonDialog(context, title: 'Image Upload Error', message: 'Upload failed: ${decodedResponse['message'] ?? 'Unexpected response format.'}', btnName: 'Retry', icon: Icons.error, iconColor: Colors.red, btnColor: Colors.red);

      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_request.dart');
      Navigator.pop(context);
      ExceptionDialog.exceptionDialog(context, title: 'Image Upload Error', message: 'Exception: $e', btnName: 'Retry', icon: Icons.error, iconColor: Colors.red, btnColor: Colors.red);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dropDownToProject();
      _loadBank();
      _loadTemplateList();
    });
  }

  void _clearFields() {
    _txtReceiverName.clear();
    _txtReceiverMobile.clear();
    _txtChequeWriter.clear();
    _txtBranch.clear();
    _txtAccountNumber.clear();
    _txtBeneficiaryName.clear();
    _txtBiller.clear();
  }

  //loading request material
  List<dynamic> _activeRequestList = [];

  String? _selectedValueReceiver;
  List<String> _dropdownReceiver = [];
  List<dynamic> _activeReceiverListMap = [];


  Future<void> _loadTemplateList() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'templates');
      String reqUrl =
          '${APIHost().apiURL}/payment_temp_controller.php/LoadTemplateList';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({
          "Authorization": APIToken().token,
          "created_by":UserCredentials().UserName
        }),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        Navigator.pop(context);
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            _activeReceiverListMap = responseData['data'] ?? [];
            _dropdownReceiver = _activeReceiverListMap
                .map<String>((item) => item['rec_name'].toString())
                .toList();
          });

        }
        else {
          Navigator.pop(context);
          final String message = responseData['message'] ?? 'Error';
          PD.pd(text: message);
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
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_request.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    }
  }

  Future<void> _loadTemplateData() async {
    try {
     // WaitDialog.showWaitDialog(context, message: 'Loading material list...');
      String reqUrl = '${APIHost().apiURL}/payment_temp_controller.php/SelectTemplate';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "rec_name":_txtReceiverName.text,
          "created_by":UserCredentials().UserName
        }),
      );
      PD.pd(text: reqUrl.toString());
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          PD.pd(text: responseData.toString());
          if (responseData['data'] is List && responseData['data'].isNotEmpty) {
            final tempData = responseData['data'][0];
            setState(() {
                _selectedPaymentType=tempData['req_type']??'0';
                _txtBeneficiaryName.text=tempData['benf_name']??'NA';
                _txtReceiverMobile.text=tempData['rec_mob']??'NA';

                if(_selectedPaymentType==2){
                  _selectedValueBank=tempData['bank_name']??'NA';
                  _txtBankName.text=tempData['bank_name']??'NA';
                  _txtAccountNumber.text=tempData['acc_no']??'NA';
                  _txtBranch.text=tempData['branch']??'NA';
                }

            });
          } else {
            clearText();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No payment template data found.'), backgroundColor: Colors.red),
            );
          }
        } else {
          clearText();
          final String message = responseData['message'] ?? 'Unknown Error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      } else {
        clearText();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HTTP Error: ${response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      clearText();
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_request.dart');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e'), backgroundColor: Colors.red),
      );
    }
  }

  //project list dropdown
  List<dynamic> _activeProjectDropDownMap = [];
  String? _selectedProjectName;
  List<String> _dropdownProjects = [];
  Future<void> _dropDownToProject() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading project');
      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        return;
      }
      String reqUrl = '${APIHost().apiURL}/project_controller.php/ProjectByDate';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": token}),
      );
      PD.pd(text: reqUrl);
      WaitDialog.hideDialog(context);
      if (response.statusCode == 200) {

        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _activeProjectDropDownMap = responseData['data'] ?? [];
            _dropdownProjects = _activeProjectDropDownMap
                .map<String>((item) => item['project_name'].toString())
                .toList();
          });
        } else {
          final String message = responseData['message'] ?? 'Error';
          PD.pd(text: message);
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
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_request.dart');
      PD.pd(text: e.toString());
    }

  }




  //project location list dropdown
  List<dynamic> _activeProjectLocationDropDownMap = [];
  String? _selectedProjectLocationName;
  List<String> _dropdownProjectLocation = [];
  Future<void> _dropDownToProjectLocation(String project) async {
    _activeRequestList.clear();

    try {
      WaitDialog.showWaitDialog(context, message: 'Loading location');
      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        return;
      }
      String reqUrl = '${APIHost().apiURL}/location_controller.php/ListProjectActiveLocation';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": token,
          "project_name": project}),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _activeProjectLocationDropDownMap = responseData['data'] ?? [];
            _dropdownProjectLocation = _activeProjectLocationDropDownMap
                .map<String>((item) => item['location_name'].toString())
                .toList();
          });
        } else {
          final String message = responseData['message'] ?? 'Error';
          PD.pd(text: message);
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
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_request.dart');
      PD.pd(text: e.toString());
    } finally {

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

    }

  }


  Future<void> getProjectSummary(String projectName, String location) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'loading');
      String apiURL = '${APIHost().apiURL}/project_controller.php/GetProjectSummary';
      PD.pd(text: apiURL);
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          'project_name': projectName,
          "location_name": location,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          final dataList = responseData['data'];
          if (dataList is List && dataList.isNotEmpty) {
            final summary = dataList[0] as Map<String, dynamic>;
            showProjectSummaryDialog(context, summary);
          } else {
            PD.pd(text: 'No data returned.');
          }
        } else {
          PD.pd(text: responseData['message'] ?? 'Unknown error');
          setState(() {});
        }
      } else {
        Navigator.pop(context);
        PD.pd(text: 'Server error: ${response.statusCode}');
        setState(() {});
      }
    } catch (e, st) {
      Navigator.pop(context);
      ExceptionLogger.logToError(message: e.toString(), errorLog: st.toString(), logFile: 'project_bill_request.dart');
      PD.pd(text: 'EstimationDetailsDialog Error: $e');
      setState(() {});
    }
  }


  //list on banks
  String? _selectedValueBank;
  List<String> _dropdownBank = [];
  List<dynamic> _activeBankMap = [];
  Future<void> _loadBank() async {
    try {
      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        return;
      }

      String reqUrl =
          '${APIHost().apiURL}/bank_controller.php/GetBankList';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": token,
        }),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _activeBankMap = responseData['data'] ?? [];
            _dropdownBank = _activeBankMap
                .map<String>((item) => item['bank_name'].toString())
                .toList();
          });
        } else {
          final String message = responseData['message'] ?? 'Error';
          PD.pd(text: message);
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
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_request.dart');
      PD.pd(text: e.toString());
    } finally {
    }
  }


  //Text field controllers and validation



  final _txtReceiverName = TextEditingController();
  final _txtReceiverMobile =TextEditingController();
  final _txtChequeWriter = TextEditingController();
  final _txtComment = TextEditingController();
  final _txtBankName = TextEditingController();
  final _txtBeneficiaryName = TextEditingController();
  final _txtAccountNumber = TextEditingController();
  final _txtBranch = TextEditingController();
  final _txtBiller = TextEditingController();
  final _txtRequestId= TextEditingController();
  final _txtProjectDropdown = TextEditingController();
  final _txtProjectLocationDropdown =TextEditingController();
  final _txtRequestedAmount =TextEditingController();

  int requestId=0;
  Future<void> createNewRequest() async {
    try {
      // Show loading message
      WaitDialog.showWaitDialog(context, message: 'Creating');
      String reqUrl = '${APIHost().apiURL}/project_payment_controller.php/InsertPaymentRequest';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "location_name": _selectedProjectLocationName.toString(),
          "project_name": _selectedProjectName.toString(),
          "bank_name":_selectedPaymentType==2?_selectedValueBank.toString():"NO" ,
          "cmt": _txtComment.text,
          "bank_branch": _txtBranch.text,
          "account_number": _txtAccountNumber.text,
          "beneficiary_name": _txtBeneficiaryName.text,
          "created_by": UserCredentials().UserName,
          "is_active":0,
          "payment_meth":_selectedPaymentType,
          "receiver_mobile":_txtReceiverMobile.text,
          "request_date":_requestDate,
          "receiver_name":_txtReceiverName.text,
          "requested_amount":_txtRequestedAmount.text.replaceAll(',', '')
        }),
      );
      if (response.statusCode == 200) {
          Navigator.pop(context);
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          PD.pd(text: responseData.toString());
          final int status = responseData['status'];
          if (status == 200) {
            requestId = int.tryParse(responseData['tbl_user_payment_request_id'].toString()) ?? 0;
            _txtRequestId.text=RequestNumber.formatNumber(val: requestId);
            _btnVisible=false;
            YNDialogCon.ynDialogMessage(context, messageTitle: 'Request Creating successful', messageBody: '${responseData['message']} would you like to upload bill', icon: Icons.verified, iconColor: Colors.green, btnDone: 'Upload',btnClose: 'Later').then((value) async {
              if (value == 1) {
                if(kIsWeb){
                  await startFilePicker(int.tryParse(requestId.toString()) ?? 0,RequestNumber.refNumberCon(val: _txtRequestId.text.toString()));
                }
                else{
                  WaitDialog.hideDialog(context);
                //  await _postToApproveRequest();
                }
              }else{
                WaitDialog.hideDialog(context);
              //  await _postToApproveRequest();
              }
            });
          } else {
            final String message = responseData['message'] ?? 'Error';
            OneBtnDialog.oneButtonDialog(context, title: 'Error', message: message, btnName: 'Ok', icon: Icons.sms_failed, iconColor: Colors.red, btnColor: Colors.red);
          }

      }
      else {
        Navigator.pop(context);
        String errorMessage = 'Request creation failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          }catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_request.dart');
            errorMessage = response.body;
          }
        }
        OneBtnDialog.oneButtonDialog(context, title: 'Error', message: errorMessage, btnName: 'Ok', icon: Icons.sms_failed, iconColor: Colors.red, btnColor: Colors.red);
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_request.dart');
      Navigator.pop(context);
      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      ExceptionDialog.exceptionDialog(context, title: 'Error', message: errorMessage, btnName: 'Ok', icon: Icons.sms_failed, iconColor: Colors.red, btnColor: Colors.red);
    }
  }

  Future<void> _postToApproveRequests() async {

   /* try {

      WaitDialog.showWaitDialog(context, message: 'posting');
      String url = '${APIHost().apiURL}/project_payment_controller.php/PostToApprove';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "request_id":_txtRequestId.text,
          "req_ref_number":RequestNumber.refNumberCon(val: _txtRequestId.text),
          "bank_name":_selectedPaymentType==2?_txtBankName.text:'NO',
          "is_active":"1",
          'post_user':UserCredentials().UserName,
          "is_post":"0",
        }),
      );

      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final int status = responseData['status'];

          if (status == 200) {
            // Success message
            WaitDialog.hideDialog(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message'] ?? 'Bill Created'), backgroundColor: Colors.green),
            );
            OneBtnDialog.oneButtonDialog(context, title: 'Request Submitted', message: responseData['message'], btnName: 'Ok', icon: Icons.verified, iconColor: Colors.green, btnColor: Colors.black);


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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_request.dart');
          String errorMessage = "Error decoding JSON: $e, Body: ${response.body}";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
      else {
        WaitDialog.hideDialog(context);
        String errorMessage = 'Request creation failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          }catch (e,st) {
            ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_request.dart');
            errorMessage = response.body;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_request.dart');
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
    }*/
  }

  Future<void> createPaymentTemplate() async {
    try {
      String reqUrl = '${APIHost().apiURL}/payment_temp_controller.php/RegisterPaymentTemplate';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "req_type":_selectedPaymentType,
          "bank_name":_selectedPaymentType==2?_selectedValueBank.toString():"NO" ,
          "rec_name":_txtReceiverName.text,
          "rec_mob":_txtReceiverMobile.text,
          "branch": _txtBranch.text,
          "benf_name": _txtBeneficiaryName.text,
          "acc_no": _txtAccountNumber.text,
          "created_by": UserCredentials().UserName,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        final int status = responseData['status'];
        if (status == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(responseData['message']), backgroundColor: Colors.red),
          );
        }
      }
      else {
         String errorMessage = 'Payment Template creation failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          }catch (e,st) {
            ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_request.dart');
            errorMessage = response.body;
          }
        }

      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_bill_request.dart');
    }
  }

  Future<void> deleteProfile(String recName) async {
    try {
      PD.pd(text: recName);
      WaitDialog.showWaitDialog(context, message: 'Deleting');
      String reqUrl = '${APIHost().apiURL}/payment_temp_controller.php/DeleteProfile';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "created_by": UserCredentials().UserName,
          "rec_name":recName
        }),
      );
      if (response.statusCode == 200) {
        Navigator.pop(context);
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        final int status = responseData['status'];
        if (status == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green),
          );
          clearText();
        } else {
          final String message = responseData['message'] ?? 'Error';
          OneBtnDialog.oneButtonDialog(context, title: 'Error', message: message, btnName: 'Ok', icon: Icons.sms_failed, iconColor: Colors.red, btnColor: Colors.red);
        }

      }
      else {
        Navigator.pop(context);
        String errorMessage = 'Request creation failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          }catch (e,st) {
            ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_request.dart');
            errorMessage = response.body;
          }
        }
        OneBtnDialog.oneButtonDialog(context, title: 'Error', message: errorMessage, btnName: 'Ok', icon: Icons.sms_failed, iconColor: Colors.red, btnColor: Colors.red);
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_request.dart');
      Navigator.pop(context);
      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      ExceptionDialog.exceptionDialog(context, title: 'Error', message: errorMessage, btnName: 'Ok', icon: Icons.sms_failed, iconColor: Colors.red, btnColor: Colors.red);
    }
  }

  void clearText(){
    _loadTemplateList();
    setState(() {
      _txtBeneficiaryName.text='';
      _txtReceiverMobile.text='';
      _selectedValueBank='NO';
      if(_selectedPaymentType==2){
        _txtBankName.text='';
        _txtAccountNumber.text='';
        _txtBranch.text='';
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appname: 'Submit Project Bill Request'),
      body: Center(
        child:  _requestForms(),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        PD.pd(text: requestId.toString());
        await startFilePicker(int.tryParse(requestId.toString()) ?? 0,RequestNumber.refNumberCon(val: _txtRequestId.text.toString()));
       // await _postToApproveRequest();
      },backgroundColor: Colors.green,
        tooltip: 'Upload Image',
        child: Icon(Icons.image),
      ),
    );
  }
  Widget _requestForms() {
    double screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Center( // Center the form on the screen
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600), // Set max width for larger screens
            child: Form(
              key: _requestFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: Center(
                      child: Text(
                        'Request Form',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  _buildFormFields(screenWidth),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildFormFields(double screenWidth) {
    return screenWidth < 600
        ? Column(children: _getFormFields())
        : Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _getFormFields(),
            ),
          ),
        ),
      ],
    );
  }
  List<Widget> _getFormFields() {
    return [
      const Text('Select Payment Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      Row(
        children: [
          _buildRadioButton(0, 'Cash'),
          _buildRadioButton(1, 'Cheque'),
          _buildRadioButton(2, 'Bank Transfer'),
        ],
      ),
     // buildTextField(_txtRequestId, 'Request ID', 'Request ID', Icons.request_quote, true, 45),
      const SizedBox(height: 20),
      CustomDropdown(
        label: 'Select Projects',
        suggestions: _dropdownProjects,
        icon: Icons.category_sharp,
        controller: _txtProjectDropdown,
        onChanged: (value) {
          _selectedProjectName = value;
          _dropDownToProjectLocation(value.toString());
        },
      ),
      const SizedBox(height: 20),
      CustomDropdown(
        label: 'Select Location',
        suggestions: _dropdownProjectLocation,
        icon: Icons.location_city,
        controller: _txtProjectLocationDropdown,
        onChanged: (value) {
          _selectedProjectLocationName = value;
          getProjectSummary(_txtProjectDropdown.text,_txtProjectLocationDropdown.text);
        },
      ),
      const SizedBox(height: 20),
      _buildReceiverSection(),
      const SizedBox(height: 10),
      buildTextField(_txtBeneficiaryName, 'Beneficiary Name', 'Enter beneficiary name', Icons.person, true, 45),
      const SizedBox(height: 10),
      buildTextField(_txtReceiverMobile, 'Receiver Mobile', 'Enter receiver mobile', Icons.phone, true, 10),
      const SizedBox(height: 10),
      buildTextField(_txtComment, 'Request Comment', 'Enter your comment', Icons.comment, true, 200),
      const SizedBox(height: 10),
      buildNumberField(_txtRequestedAmount, 'Request Amount', 'Enter expected amount', LKRIcon(), true, 10),
      Column(
        children: [
          DatePickerWidget(
            label: 'Expected date',
            onDateSelected: (selectedDate) {
              setState(() {
                _requestDate = selectedDate;
              });
              PD.pd(text: _requestDate);
            },
          ),
        ],
      ),
      const SizedBox(height: 20),
      if (_selectedPaymentType == 2)
        CustomDropdown(
          label: 'Select Bank',
          suggestions: _dropdownBank,
          icon: FontAwesomeIcons.bank,
          controller: _txtBankName,
          onChanged: (value) {
            _selectedValueBank = value;
          },
        ),
      if (_selectedPaymentType == 2) // Bank Transfer - Show Bank details
        Column(
          children: [
            const SizedBox(height: 10),
            buildTextField(_txtBranch, 'Branch', 'Enter branch', Icons.location_on, true, 45),
            const SizedBox(height: 10),
            buildTextField(_txtAccountNumber, 'Account Number', 'Enter account number', Icons.account_balance, true, 45),
          ],
        ),
      Center(
        child:
        Visibility(visible: _btnVisible,
        child: _buildRequestCreating(),
        )
      )
    ];
  }
  Widget _buildRadioButton(int index, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio(
          value: index,
          groupValue: _selectedPaymentType,
          onChanged: (value) {
            setState(() {
              _selectedPaymentType = value as int;

              // Reset fields when switching payment type
              _clearFields();

              if (_selectedPaymentType != 2) {
                _txtBankName.text = _dropdownBank.first; // Auto-select first bank
              }
            });
          },
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
  Widget _buildRequestCreating() {
    return ElevatedButton(
      onPressed: () {
        if(_txtReceiverName.text.isEmpty){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please select receiver name'),
                backgroundColor: Colors.red),
          );
        }
        else{
          if (_requestFormKey.currentState!.validate()) {
            YNDialogCon.ynDialogMessage(
              context,
              messageBody: 'Would you confirm to create new payment request',
              messageTitle: 'payment request',
              icon: Icons.verified_outlined,
              iconColor: Colors.black,
              btnDone: 'YES',
              btnClose: 'NO',
            ).then((value) async {
              if (value == 1) {
                await  createPaymentTemplate();
                await createNewRequest();
              }
            });
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // Background color
        foregroundColor: Colors.white, // Text color
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500, // Font weight
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5, // Elevation
        shadowColor: Colors.black26, // Shadow color
      ),
      child: const Text('Create Request'),
    );
  }
  Widget _buildReceiverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _selectedValueReceiver ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) {
            return _dropdownReceiver.where((word) =>
                word.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) {
            setState(() {
              _selectedValueReceiver = selection;
              _txtReceiverName.text = selection;
              _loadTemplateData();
            });
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  onSelected(option);
                                  setState(() {
                                    _selectedValueReceiver = option;
                                    _txtReceiverName.text = option;
                                    _loadTemplateData();
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(option, style: const TextStyle(fontSize: 14)),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                int a = await YNDialogCon.ynDialogMessage(
                                  context,
                                  messageBody: 'Remove selected payment profile',
                                  messageTitle: 'Remove Confirmation',
                                  icon: Icons.remove,
                                  iconColor: Colors.red,
                                  btnDone: 'Yes',
                                  btnClose: 'No',
                                );
                                if (a == 1) {
                                  deleteProfile(option);
                                }
                              },

                              child: const Icon(Icons.delete, size: 18, color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              maxLength: 45,
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Receiver',
                labelText: 'Receiver Selection',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_drop_down),
                      onPressed: () {
                        focusNode.requestFocus();
                      },
                    ),
                    if (textEditingController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedValueReceiver = '';
                            _txtReceiverName.clear();
                            textEditingController.clear();
                          });
                        },
                      ),
                  ],
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _txtReceiverName.text = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter receiver';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }




}
void showProjectSummaryDialog(BuildContext context, Map<String, dynamic> data) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 12,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics_outlined, color: Colors.deepPurple, size: 26),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Project Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Divider(color: Colors.deepPurple.shade100),

                  const SizedBox(height: 8),

                  SummaryRow(
                    icon: Icons.work_outline,
                    label: 'Project',
                    value: data['project_name'] ?? '-',
                  ),
                  SummaryRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: data['location_name'] ?? '-',
                  ),
                  SummaryRow(
                    icon: Icons.calculate_outlined,
                    label: 'Estimated',
                    value: 'Rs. ${NumberStyles.currencyStyle(data['total_estimation_amount'])}',
                  ),
                  SummaryRow(
                    icon: Icons.receipt_long_outlined,
                    label: 'Spent',
                    value: 'Rs. ${NumberStyles.currencyStyle(data['total_actual_amount'])}',
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      label: const Text('Close', style: TextStyle(fontSize: 14)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const SummaryRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurpleAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

