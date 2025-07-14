import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/custome_icon.dart';
import 'package:roky_holding/env/sp_format_data.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/input_widget.dart';
import '../env/number_format.dart';
import '../env/print_debug.dart';
import '../env/user_data.dart';

class OfficePaymentRequest extends StatefulWidget {
  const OfficePaymentRequest({super.key});
  @override
  State<OfficePaymentRequest> createState() => _OfficePaymentRequestState();
}

class _OfficePaymentRequestState extends State<OfficePaymentRequest> with SingleTickerProviderStateMixin {

  final GlobalKey<FormState> _requestFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _materialSelectionKey = GlobalKey<FormState>();
  String _requestDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  int _selectedPaymentType = 0; // 0 - Cash, 1 - Cheque, 2 - Bank Transfer
  late TabController _tabController;

  final List<String> _dropDownSIUnit = [
    'Nos' ,'Km', 'Mts','Ltr', 'Psum' , 'Cube' , 'Days' ,   'LFeet',  'SqFt' , 'Kg'];
  String? _selectedUnit;

  bool isProjectRelated=false;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this ,length: 3);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  bool _isUserRequestLoad = false;
  Future<void> _loadUserRequestMaterialList() async {
    _activeRequestList.clear();
    setState(() {
      _isUserRequestLoad = true;
    });
    try {

      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        return;
      }
      String reqUrl =
          '${APIHost().apiURL}/ofz_payment_controller.php/RequestMaterialListOnRequestId';
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": token,
          "ofz_request_id":_txtRequestId.text
        }),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        try {
          final responseData =
          jsonDecode(response.body) as Map<String, dynamic>;

          // Check the status and process the response data
          if (responseData['status'] == 200) {
            // Extract data from the response
            setState(() {
              _activeRequestList = List.from(responseData['data'] ?? []);
            });
            PD.pd(text: responseData.toString());
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
        } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
          PD.pd(text: e.toString());
        }
      } else {
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
      PD.pd(text: e.toString());
    } finally {
      setState(() {
        _isUserRequestLoad = false;
      });
    }
  }

  String? _selectedValueReceiver;
  List<String> _dropdownReceiver = [];
  List<dynamic> _activeReceiverListMap = [];


  Future<void> _loadTemplateList() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'templates');
      String reqUrl =
          '${APIHost().apiURL}/payment_temp_controller.php/LoadTemplateList';
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
      clearText();
      // WaitDialog.showWaitDialog(context, message: 'Loading material list...');
      String reqUrl = '${APIHost().apiURL}/payment_temp_controller.php/SelectTemplate';
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
              _selectedPaymentType = tempData['req_type']?.toInt() ?? 0;
              _txtBeneficiaryName.text=tempData['benf_name']??'NA';
              _txtReceiverMobile.text=tempData['rec_mob']??'NA';

              if(_selectedPaymentType==2){
                _txtBankName.text=tempData['bank_name']??'NA';
                _selectedValueBank=tempData['bank_name']??'NA';
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
      clearText();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void clearText(){
    _loadTemplateList();
    setState(() {
      _txtItemDisc.text='';
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
  Future<void> createPaymentTemplate() async {
    try {
      String url = '${APIHost().apiURL}/payment_temp_controller.php/RegisterPaymentTemplate';
      final response = await http.post(
        Uri.parse(url),
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
          clearText();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green),
          );
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

  //cost category
  String? _selectedOfzMainCategoryItem;
  List<String> _dropdownOfzMainCategory = [];
  List<dynamic> _activeOfzMainCategoryListMap = [];
  Future<void> _loadOfzMainCategoryList() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Main Category');
      String reqUrl =
          '${APIHost().apiURL}/ofz_payment_controller.php/GetMainCategory';
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token,
        }),
      );

      PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _activeOfzMainCategoryListMap = responseData['data'] ?? [];
            _dropdownOfzMainCategory = _activeOfzMainCategoryListMap
                .map<String>((item) => item['main_name'].toString())
                .toList();
            if (_dropdownOfzMainCategory.isNotEmpty) {
              _selectedOfzMainCategoryItem = _dropdownOfzMainCategory.first;
              _txtMainCategoryDropDown.text = _selectedOfzMainCategoryItem!;
              _loadOfzSubCategoryList(_selectedOfzMainCategoryItem);
            }
          });
        }
        else {
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
      PD.pd(text: e.toString());
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }


  String? _selectedOfzSubCategoryItem;
  List<String> _dropdownOfzSubCategory = [];
  List<dynamic> _activeOfzSubCategoryListMap = [];
  Future<void> _loadOfzSubCategoryList(String? mainCategory) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Sub Category');
      String reqUrl = '${APIHost().apiURL}/ofz_payment_controller.php/GetSubCategory';
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "main_name": mainCategory,
        }),
      );

      PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            Navigator.pop(context);
            _activeOfzSubCategoryListMap = responseData['data'] ?? [];
            _dropdownOfzSubCategory = _activeOfzSubCategoryListMap
                .map<String>((item) => item['sub_name'].toString())
                .toList();
            // Clear the sub-category selection when loading new sub-categories
            _selectedOfzSubCategoryItem = null;
            // Also clear the item selection
            _selectedOfzItem = null;
            _dropdownOfzItem = [];
          });
        } else {
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
        Navigator.pop(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(), errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    }
  }


  String? _selectedOfzItem;
  List<String> _dropdownOfzItem = [];
  List<dynamic> _activeOfzItemListMap = [];
  Future<void> _loadOfzItemList(String? mainCategory, String? subName) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Items');
      String reqUrl = '${APIHost().apiURL}/ofz_payment_controller.php/GetMaterialItem';
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "main_name": _selectedOfzMainCategoryItem, // Use the stored value
          "sub_name": subName,
        }),
      );

      PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            Navigator.pop(context);
            _activeOfzItemListMap = responseData['data'] ?? [];
            _dropdownOfzItem = _activeOfzItemListMap
                .map<String>((item) => item['item_name'].toString())
                .toList();
            // Clear the item selection when loading new items
            _selectedOfzItem = null;
            _txtMaterialDropDown.clear();
          });
        } else {
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
        Navigator.pop(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(), errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    }
  }


  //list on banks

  String? _selectedValueBank;
  List<String> _dropdownBank = [];
  List<dynamic> _activeBankMap = [];
  Future<void> _loadBank() async {
    try {

      String reqUrl =
          '${APIHost().apiURL}/bank_controller.php/GetBankList';
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token,
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
            if (_dropdownBank.isNotEmpty) {
              _selectedValueBank = _dropdownBank.first;
              _txtBankName.text = _selectedValueBank!;
            }
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
      PD.pd(text: e.toString());
    } finally {
    }
  }


  //project related
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
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading location');
      String reqUrl = '${APIHost().apiURL}/location_controller.php/ListProjectActiveLocation';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token,
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

  //Text field controllers and validation
  final _txtUnit = TextEditingController();
  final _txtReceiverName = TextEditingController();
  final _txtReceiverMobile =TextEditingController();
  final _txtChequeWriter = TextEditingController();
  final _txtMaterialDropDown = TextEditingController();
  final _txtSubCategoryDropDown = TextEditingController();
  final _txtMainCategoryDropDown = TextEditingController();
  final _txtQty = TextEditingController();
  final _txtCostAmount = TextEditingController();
  final _txtUnitCost = TextEditingController();
  final _txtItemRef = TextEditingController();
  final _txtItemDes = TextEditingController();
  final _txtComment = TextEditingController();
  final _txtBankName = TextEditingController();
  final _txtBeneficiaryName = TextEditingController();
  final _txtAccountNumber = TextEditingController();
  final _txtBranch = TextEditingController();
  final _txtBiller = TextEditingController();
  final _txtRequestId= TextEditingController();
  final _txtVat = TextEditingController();
  final _txtSSCL = TextEditingController();
  final _txtAddiDis = TextEditingController();
  final _txtItemDisc = TextEditingController();
  final _txtProjectDropdown = TextEditingController();
  final _txtProjectLocationDropdown =TextEditingController();


  double amount=0;



  int touchedIndex = -1;



  int requestId=0;
  Future<void> createNewOfzRequest() async {
    try {
      if (_selectedPaymentType == 2 && (_selectedValueBank == null || _selectedValueBank!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a bank'), backgroundColor: Colors.red),
        );
        return;
      }
      WaitDialog.showWaitDialog(context, message: 'Creating');
      String url = '${APIHost().apiURL}/ofz_payment_controller.php/CreateOfzPaymentRequest';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "bank_name":_selectedPaymentType==2?_selectedValueBank.toString():"NO" ,
          "payment_meth":_selectedPaymentType,
          "bank_branch": _selectedPaymentType==2?_txtBranch.text:"NO",
          "account_number": _selectedPaymentType==2?_txtAccountNumber.text:'No',
          "beneficiary_name": _txtBeneficiaryName.text,
          "receiver_mobile":_txtReceiverMobile.text,
          "request_date":_requestDate,
          "receiver_name":_txtReceiverName.text,
          "cmt": _txtComment.text,
          "vat": _txtVat.text.isEmpty?'0':_txtVat.text.replaceAll(',', ''),
          "sscl": _txtSSCL.text.isEmpty?'0':_txtSSCL.text.replaceAll(',', ''),
          "add_dis": _txtAddiDis.text.isEmpty?'0':_txtAddiDis.text.replaceAll(',', ''),
          "is_active":0,
          "created_by": UserCredentials().UserName,
        }),
      );
      if (response.statusCode == 200) {
        Navigator.pop(context);
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        final int status = responseData['status'];
        if (status == 200) {
          OneBtnDialog.oneButtonDialog(context, title: 'Request Created', message: responseData['message'], btnName: 'OK', icon: Icons.verified, iconColor: Colors.green, btnColor: Colors.green);
          requestId = int.tryParse(responseData['tbl_ofz_request_id'].toString()) ?? 0;
          _txtRequestId.text=RequestNumber.formatNumber(val: requestId);
          _tabController.index=1;
          _loadOfzMainCategoryList();
        } else {
          final String message = responseData['message'] ?? 'Error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
      else {
        Navigator.pop(context);
        String errorMessage = 'Request Creating failed ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
            errorMessage = response.body;
          }
        }
        OneBtnDialog.oneButtonDialog(context, title: 'Request Creating failed', message: errorMessage, btnName: 'Ok', icon: Icons.error_outline_sharp, iconColor: Colors.red, btnColor: Colors.red);
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
      Navigator.pop(context);
      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      ExceptionDialog.exceptionDialog(context, title: 'Error in Creating', message: errorMessage, btnName: 'Ok', icon: Icons.error, iconColor: Colors.red, btnColor: Colors.red);
    }
  }
  Future<void> _addItemsToRequest() async {
    try {
      if (_selectedOfzMainCategoryItem == null || _selectedOfzMainCategoryItem!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a main category'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_selectedOfzSubCategoryItem == null || _selectedOfzSubCategoryItem!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a sub category'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_txtMaterialDropDown.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an item'), backgroundColor: Colors.red),
        );
        return;
      }
      WaitDialog.showWaitDialog(context, message: 'Items Adding');
      String url = '${APIHost().apiURL}/ofz_payment_controller.php/InsertRequestList';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "ofz_request_id":_txtRequestId.text,
          "main_name":_selectedOfzMainCategoryItem,
          "sub_name":_selectedOfzSubCategoryItem,
          "item_name":_txtMaterialDropDown.text,
          "req_ref_number":"-1",
          "ref":_txtItemRef.text,
          "list_des":_txtItemDes.text,
          "qty":_txtQty.text.replaceAll(',', ''),
          "amout":_txtUnitCost.text.replaceAll(',', ''),
          "total_amout":_txtCostAmount.text.replaceAll(',', ''),
          "created_by":UserCredentials().UserName,
          'uom':_txtUnit.text,
          'item_dis':_txtItemDisc.text.isEmpty?'0':_txtItemDisc.text.replaceAll(',', ''),
          'is_project':isProjectRelated?1:0,
          'project':_selectedProjectName,
          'project_location':_selectedProjectLocationName
        }),
      );
      if (response.statusCode == 200) {
        Navigator.pop(context);
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        final int status = responseData['status'];
        if (status == 200) {
          OneBtnDialog.oneButtonDialog(context, title: 'Item Insert Successful', message: responseData['message'] , btnName: 'Ok', icon: Icons.verified, iconColor: Colors.green, btnColor:  Colors.green);
          clearData();
          _loadUserRequestMaterialList();
        } else {
          OneBtnDialog.oneButtonDialog(context, title: 'Error Billing', message: responseData['message'] , btnName: 'Ok', icon: Icons.error, iconColor: Colors.red, btnColor:  Colors.green);
        }
      }
      else {
        Navigator.pop(context);
        OneBtnDialog.oneButtonDialog(context, title: 'Item Insert Failed', message:'Estimation creation failed with status code ${response.statusCode}'  , btnName: 'Ok', icon: Icons.error, iconColor: Colors.green, btnColor:  Colors.green);

      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
      Navigator.pop(context);
      ExceptionDialog.exceptionDialog(context, title: 'Error', message: e.toString(), btnName: 'Ok', icon: Icons.error, iconColor: Colors.red, btnColor: Colors.red);
    }
  }
  Future<void> _postRequest() async {
    try {

      WaitDialog.showWaitDialog(context, message: 'posting');
      String url = '${APIHost().apiURL}/ofz_payment_controller.php/PostToApprove';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "request_id":_txtRequestId.text,
          "req_ref_number":RequestNumber.refNumberOfz(val: _txtRequestId.text),
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
            // Success message
            WaitDialog.hideDialog(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green),
            );
            OneBtnDialog.oneButtonDialog(context, title: 'Request Submitted', message: responseData['message'], btnName: 'Ok', icon: Icons.verified, iconColor: Colors.green, btnColor: Colors.black);
            _loadUserRequestMaterialList();
            clearData();
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
            errorMessage = response.body;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
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


  void clearData(){

    amount=0;
    _txtCostAmount.text='';
    _txtUnitCost.text='';
    _txtQty.text='';
    _txtItemRef.text='';
    _txtItemDes.text='';
    _txtItemDisc.text='';
    _selectedProjectLocationName='';
    _selectedProjectName='';
    _txtProjectDropdown.text='';
    _txtProjectLocationDropdown.text='';
    setState(() {
      isProjectRelated=false;
    });
  }

  // void _totalCost(){
  //   double qty = double.tryParse(_txtQty.text)??0;
  //   double unitCost = double.tryParse(_txtUnitCost.text.replaceAll(',', ''))??0;
  //   double totalCost =qty*unitCost;
  //   _txtCostAmount.text=totalCost.toString();
  // }

  void _totalCost() {



    double totalAmount = double.tryParse(_txtCostAmount.text.replaceAll(',', '')) ?? 0;
    double unitCost = double.tryParse(_txtUnitCost.text.replaceAll(',', '')) ?? 0;
    double qty = double.tryParse(_txtQty.text.replaceAll(',', '')) ?? 0;
    double expectedAmount = qty * unitCost;

    if (totalAmount == 0) {
      amount = expectedAmount;
      _txtCostAmount.text = NumberStyles.currencyStyle(amount.toString());
    } else {
      if ((totalAmount - expectedAmount).abs() > 0.01) {
        showTopNotification(
          context,
          'Entered Total Amount (${_txtCostAmount.text}) does not match Unit Cost x Qty (${NumberStyles.currencyStyle(expectedAmount.toString())})',
        );
      }
    }


  }


  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.sizeOf(context).width;
    double h= MediaQuery.sizeOf(context).height;
    return Scaffold(
      appBar: ControllerWithAppBar(appname: 'Office Payment Request Form', tabController:  _tabController),
      body: TabBarView(
        controller: _tabController,
        children: [
          _requestForms(),
          _materialSelection(),
          _buildListOfRequest(w,h),

        ],
      ),
    );
  }
  Widget _requestForms() {
    double screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: screenWidth < 600 ? screenWidth * 0.9 : 600, // Responsive max width
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
                  leading: Container(
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormFields(screenWidth),
                    )],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }



  //request stat form
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
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey[100],
            child: Column(
              children: [
                const Center(
                  child: Icon(Icons.add_box_outlined, size: 50, color: Colors.blue),
                ),
              ],
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
      const SizedBox(height: 10),
      _buildReceiverSection(),
      const SizedBox(height: 10),
      buildTextField(_txtBeneficiaryName, 'Beneficiary Name', 'Enter beneficiary name', Icons.person, true, 45),
      const SizedBox(height: 10),
      buildTextField(_txtReceiverMobile, 'Receiver Mobile', 'Enter receiver mobile', Icons.phone, true, 10),
      const SizedBox(height: 10),
      buildTextField(_txtComment, 'Request Comment', 'Enter your comment', Icons.comment, true, 45),
      _buildTax(context),
      Column(
        children: [
          DatePickerWidget(
            label: 'Select Date',
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
          icon: Icons.food_bank,
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
        child:  _buildRequestCreating(),
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
                await createPaymentTemplate();
                await createNewOfzRequest();
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


  Widget _buildTax(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile layout (1 column)
          return Column(
            children: [
              buildNumberField(_txtVat, 'VAT', 'Total VAT', LKRIcon(), true, 20),
              SizedBox(height: 10),
              buildNumberField(_txtSSCL, 'SSCL', 'Total SSCL', LKRIcon(), true, 20),
              SizedBox(height: 10),
              buildNumberField(_txtAddiDis, 'Additional discount', 'Total Discount', LKRIcon(), true, 20),
            ],
          );
        } else {
          // Web/tablet layout (2 columns and 1 full width)
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child:  buildNumberField(_txtVat, 'VAT', 'Total VAT', LKRIcon(), true, 20),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: buildNumberField(_txtSSCL, 'SSCL', 'Total SSCL', LKRIcon(), true, 20),
                  ),
                ],
              ),
              SizedBox(height: 10),
              buildNumberField(_txtAddiDis, 'Additional discount', 'Total Discount', LKRIcon(), true, 20),
            ],
          );
        }
      },
    );
  }





  //material selection
  Widget _materialSelection() {
    double screenWidth = MediaQuery.of(context).size.width;
    Widget buildFormFields() {
      return Column(
        children: [
          buildTextFieldReadOnly(
            _txtRequestId,
            'Requested Ref Number',
            '',
            Icons.numbers,
            true,
            10,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: isProjectRelated,
                onChanged: (value) {
                  setState(() {
                    isProjectRelated = value ?? false;
                    _selectedProjectLocationName='';
                    _selectedProjectName='';
                    _txtProjectDropdown.text='';
                    _txtProjectLocationDropdown.text='';
                    _dropDownToProject();
                  });
                },
              ),
              const Text('Project Related'),
            ],
          ),
          Row(
            children:
            [
              Expanded(
                flex: 7,
                child:
                CustomDropdown(
                  label: 'Select Main category',
                  suggestions: _dropdownOfzMainCategory,
                  icon: Icons.celebration,
                  controller: _txtMainCategoryDropDown,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedOfzMainCategoryItem = value;
                    });
                    _loadOfzSubCategoryList(value); // Pass the value directly
                  },
                ),),
              Expanded(
                flex: 7,
                child:
                CustomDropdown(
                  label: 'Select Sub',
                  suggestions: _dropdownOfzSubCategory,
                  icon: Icons.celebration,
                  controller: _txtSubCategoryDropDown,
                  onChanged: (value) {
                    _selectedOfzSubCategoryItem = value;
                    _loadOfzItemList(_txtMaterialDropDown.text,
                        value.toString());
                    if(value.toString().toLowerCase()=='fuel'){
                      _txtUnit.text='Ltr';

                    }else if(value.toString().toLowerCase()=='service & maintenance'){
                      _txtUnit.text='Km';

                    }else{
                      _txtUnit.text='Nos';
                    }
                  },
                ),),
             ],
          ),
          const SizedBox(height: 10),

          Row(
           children: [
             Expanded(flex: 6,
                 child:  _buildMaterialSection()),
             Expanded(
               flex: 3,
               child:
               Container(
                 padding: EdgeInsets.only(bottom: 10),
                 child: CustomDropdown(
                   label: 'Select Unit',
                   suggestions: _dropDownSIUnit,
                   icon: Icons.straighten,
                   controller: _txtUnit,
                   onChanged: (value) {
                     _selectedUnit = value;
                     PD.pd(text: _selectedUnit.toString());
                   },
                 ),
               ),
             )
           ],
         ),
          const SizedBox(height: 10),
          buildTextField(_txtItemDes, 'Descriptions', _selectedOfzMainCategoryItem=='Vehicle'?'Petrol':_selectedOfzMainCategoryItem=='Food'?'Lunch/Dinner':"Books", Icons.description, true, 45),


          Visibility(visible: isProjectRelated,child: _buildProjectDropDown(),),

          const SizedBox(height: 10),
          buildTextField(_txtItemRef, 'Note/Invoice', _selectedOfzMainCategoryItem=='Vehicle'?'Traveling':'Invoice Number', Icons.description, true, 45),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: buildNumberField(
                  _txtQty,
                  'Request Qty',
                  '1',
                  Icons.numbers,
                  true,
                  10,
                ),
              ),
              SizedBox(width: 8), // Reduced space between fields
              Expanded(
                flex: 5,
                child: buildNumberWithReadOption(
                  _txtUnitCost,
                  'Unit Cost',
                  '1500',
                  LKRIcon(), false,
                  15,
                ),
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                flex: 5,
                child:
                buildNumberWithReadOption(
                  _txtCostAmount,
                  'Total Cost',
                  '1500',
                  LKRIcon(),
                  false,
                  15,
                ),
              ),
              SizedBox(width: 8), // Reduced space between fields
              Expanded(
                flex: 5,
                child:
                buildNumberWithReadOption(
                  _txtItemDisc,
                  'Item Discount',
                  '1500',
                  LKRIcon(),
                  false,
                  15,
                ),
              ),
            ],
          ),

          _buildSubmitButton(),
          const SizedBox(height: 16),
        ],
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          width: screenWidth * 0.9,
          child: Form(
            key: _materialSelectionKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Center(
                    child: Text(
                      'Billing Item Insert',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  leading: Container(
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.token, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(height: 10),
                screenWidth < 720
                    ? Column(
                  children: [
                    buildFormFields(),
                    Container(
                      padding: EdgeInsets.all(12),
                      height: 300,
                      child: SizedBox(),
                    ),
                  ],
                )
                    : Row(
                  children: [
                    // Left side: Form fields
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: buildFormFields(), // Use the common form for larger screens
                      ),
                    ),
                    // Right side: Pie chart
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          height: 300, // Adjusted height for the pie chart
                          child: SizedBox(), // Pie chart on the right for desktop
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _selectedOfzItem ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) {
            // Filter workTypes based on user input
            return _dropdownOfzItem.where((word) =>
                word.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) {
            setState(() {
              _selectedOfzItem = selection;
              _txtMaterialDropDown.text = selection;
            });
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              maxLength: 45,
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: '',
                labelText: 'Item List',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _txtMaterialDropDown.text = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Item List';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }
  //submit button material adding
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {

        PD.pd(text:'Project $_selectedProjectName');
        PD.pd(text:'Location $_selectedProjectLocationName');

        PD.pd(text: requestId.toString());
        _totalCost();
        if (_materialSelectionKey.currentState!.validate()) {
          YNDialogCon.ynDialogMessage(
            context,
            messageBody: 'Confirm to adding items on the list',
            messageTitle: 'billing',
            icon: Icons.verified_outlined,
            iconColor: Colors.black,
            btnDone: 'YES',
            btnClose: 'NO',
          ).then((value) async {
            if (value == 1) {

              await _addItemsToRequest();
            }
          });
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
      child: const Text('Add Items To Bill'),
    );
  }

  //list of material
  Widget _buildListOfRequest(double w,double h) {
    return Container(
      height: w*1,
      width: w*1,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Ensures full width
          children: [
            const Text(
              "Request Item List",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, // Center the title
            ),
            const SizedBox(height: 10),
            Expanded( // Takes remaining space
                child: Center(
                  child: _buildActiveListOfRequest(),
                ),
            ),
            const SizedBox(height: 20),
            if (_activeRequestList.isNotEmpty) _buildCloseButton(), // Better than Visibility
          ],
        ),
      ),
    );
  }

  Widget _buildActiveListOfRequest() {
    if (_isUserRequestLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeRequestList.isEmpty) {
      return const Center(
        child: Text(
          'No Billed Items found.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      );
    }

    final verticalController = ScrollController();
    final horizontalController = ScrollController();

    return LayoutBuilder(
      builder: (context, constraints) {
        const double fixedWidth = 1024;
        double tableHeight = constraints.maxHeight - 50;

        return Scrollbar(
          controller: horizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          thickness: 12,
          radius: const Radius.circular(10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: horizontalController,
            child:
            SizedBox(
              width: fixedWidth, // Fixed width here
              height: tableHeight,
              child: Scrollbar(
                controller: verticalController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 12,
                radius: const Radius.circular(10),
                child: ListView(
                  controller: verticalController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DataTable(
                        border: TableBorder.all(width: 1, color: Colors.grey),
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        dataRowMinHeight: 30,
                        dataRowMaxHeight: 40,
                        headingRowHeight: 35,
                        columns: [
                          _buildDataColumn('Main Category'),
                          _buildDataColumn('Sub Category'),
                          _buildDataColumn('List Name'),
                          _buildDataColumn('Description'),
                          _buildDataColumn('Ref'),
                          _buildDataColumn('Qty'),
                          _buildDataColumn('Unit amount(LKR)'),
                          _buildDataColumn('Total amount(LKR)'),
                          _buildDataColumn('Actions'),
                        ],
                        rows: _activeRequestList.map((requestList) {
                          double total = double.tryParse(requestList['total_amout']) ?? 0;
                          double unitAmount = double.tryParse(requestList['amout']) ?? 0;

                          String formattedTotal = NumberFormat('#,###.00', 'en_US').format(total);
                          String formattedUnitAmount = NumberFormat('#,###.00', 'en_US').format(unitAmount);

                          return DataRow(
                            cells: [
                              _buildDataCell(requestList['main_name'].toString()),
                              _buildDataCell(requestList['sub_name'].toString()),
                              _buildDataCell(requestList['item_name'].toString()),
                              _buildDataCell(requestList['list_des'].toString()),
                              _buildDataCell(requestList['ref'].toString()),
                              _buildDataCell('${requestList['qty']} ${requestList['uom']}'),
                              _buildDataCell(formattedUnitAmount),
                              _buildDataCell(formattedTotal),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                                  onPressed: () => _confirmDeleteItem(requestList),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
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
  Widget _buildProjectDropDown() {
    return Card(
      color: Colors.lightBlueAccent,
        child: Column(
          children: [
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
            const SizedBox(height: 10),
            CustomDropdown(
                    label: 'Select Location',
                    suggestions: _dropdownProjectLocation,
                    icon: Icons.location_city,
                    controller: _txtProjectLocationDropdown,
                    onChanged: (value) {
                      _selectedProjectLocationName = value;
                    },
                  ),
          ],
        ),
    );
  }


// Helper method for delete confirmation
  void _confirmDeleteItem(Map<String, dynamic> requestList) {
    YNDialogCon.ynDialogMessage(
      context,
      messageBody: 'Confirm to remove Item ${requestList['list_des']} QTY: ${requestList['qty']}',
      messageTitle: 'Remove Items',
      icon: Icons.delete_forever,
      iconColor: Colors.red,
      btnDone: 'Yes,Delete',
      btnClose: 'No',
    ).then((value) {
      if (value == 1) {
        removeRequestItem(
          context,
          requestList['idtbl_ofz_request_list'].toString(),
          requestList['list_des'],
        );
      }
    });
  }
  DataColumn _buildDataColumn(String title) {
    return DataColumn(
      label: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
  //pie chart for visualize
  DataCell _buildDataCell(String value) {
    return DataCell(
      Text(
        value,
        style: TextStyle(fontSize: 12),
      ),
    );
  }
  //table for price and qty
  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
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
  //remove listed items
  Future<void> removeRequestItem(BuildContext context, String id,String name) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Remove Item...');
      final response = await http.post(
        Uri.parse('${APIHost().apiURL}/ofz_payment_controller.php/RemoveItemFormList'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "idtbl_ofz_request_list": id,
          "request_id":requestId,
          "isLog":0,
          'list_des':name,
          "created_by":UserCredentials().UserName
        }),
      );
      WaitDialog.hideDialog(context);
      _loadUserRequestMaterialList();
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          if (responseData['status'] == 200) {
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
            showErrorDialog(context, responseData['message'] ?? 'Error');
          }
        } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
          showErrorDialog(context, "Error decoding JSON response.");
        }
      } else {
        handleHttpError(context, response);
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
      handleGeneralError(context, e);
    }
  }
  void handleHttpError(BuildContext context, http.Response response) {
    String errorMessage = 'Request failed with status code ${response.statusCode}';
    try {
      final errorData = jsonDecode(response.body);
      errorMessage = errorData['message'] ?? errorMessage;
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'office_payment_request_form.dart');
    }
    showErrorDialog(context, errorMessage);
  }
  void handleGeneralError(BuildContext context, dynamic e) {
    String errorMessage = (e is SocketException)
        ? 'Network error. Please check your connection.'
        : 'An error occurred: $e';
    showErrorDialog(context, errorMessage);
  }
  void showErrorDialog(BuildContext context, String message) {
    ExceptionDialog.exceptionDialog(
      context,
      title: 'Error',
      message: message,
      btnName: 'OK',
      icon: Icons.error,
      iconColor: Colors.red,
      btnColor: Colors.black,
    );
  }
  Widget _buildCloseButton() {
    return ElevatedButton(
      onPressed: () {

        YNDialogCon.ynDialogMessage(
          context,
          messageBody: 'Confirm to Post a Approval',
          messageTitle: 'closing',
          icon: Icons.verified_outlined,
          iconColor: Colors.black,
          btnDone: 'YES',
          btnClose: 'NO',
        ).then((value) async {
          if (value == 1) {
            await _postRequest();
          }
        });

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
      child: const Text('Post To Proceed'),
    );
  }
}

