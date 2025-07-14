import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/number_format.dart';
import 'package:roky_holding/env/sp_format_data.dart';
import 'package:roky_holding/md_04/project_bill_invoice_summary_form.dart';
import 'package:roky_holding/md_04/view_ofz_request_list.dart';
import 'package:url_launcher/url_launcher.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/custome_icon.dart';
import '../env/input_widget.dart';
import '../env/print_debug.dart';
import '../env/user_data.dart';
import 'office_payment_request_form.dart';

class DataEntryForm extends StatefulWidget {
  const DataEntryForm({super.key});

  @override
  State<DataEntryForm> createState() => _DataEntryFormState();
}

class _DataEntryFormState extends State<DataEntryForm> with SingleTickerProviderStateMixin {

  final GlobalKey<FormState> _requestFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _materialSelectionKey = GlobalKey<FormState>();

  int _selectedPaymentType = 0; // 0 - Cash, 1 - Cheque, 2 - Bank Transfer
  late TabController _tabController;

  bool _isLoading = true;
  List<ImagesList> _imagesLists = [];
  Future<void> viewImages() async {
    if (!mounted) return; // Check if the widget is still mounted

    setState(() {
      _isLoading = true;
      _imagesLists.clear(); // Clear previous images
    });

    String apiURL = '${APIHost().apiURL}/project_payment_controller.php/ViewImage';
    PD.pd(text: apiURL);
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading request images...');
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          'req_ref_number': RequestNumber.refNumberCon(val: _txtRequestId.text),
        }),
      );

      if (!mounted) return; // Check again after the async operation

      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          List<dynamic> data = responseData['data']; // Array of image URLs
          setState(() {
            _imagesLists = data.map((url) => ImagesList(emageUrl: url)).toList();
            _isLoading = false;
          });

          if (_imagesLists.isNotEmpty && mounted) {
            _showImagesDialog(_materialSelectionKey.currentContext!);
          } else {
            ScaffoldMessenger.of(_materialSelectionKey.currentContext!).showSnackBar(
              SnackBar(
                content: Text('No images found for this request.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          setState(() {
            //_errorMessage = responseData['message'] ?? 'Error loading images';
            _isLoading = false;
          });
        }
      } else {
        WaitDialog.hideDialog(context);
        setState(() {
         // _errorMessage = 'HTTP Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
      if (!mounted) return; // Check again after the async operation
      WaitDialog.hideDialog(context);
      setState(() {
       // _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      PD.pd(text: e.toString());
    }
  }
  void _showImagesDialog(BuildContext context) {
    if (!mounted) return; // Ensure the widget is still mounted

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Download Images',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _imagesLists.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "No images available.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Adjust grid count based on UI
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: _imagesLists.length,
                itemBuilder: (context, index) {
                  final imageUrl = _imagesLists[index].emageUrl;
                  return GestureDetector(
                    onTap: () async {
                      if (await canLaunch(imageUrl)) {
                        await launch(imageUrl);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not open $imageUrl'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.8),
                              child: Icon(Icons.download, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this ,length: 3);
    _qty='';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBank();
    });
  }

  Future<void> fetchRequestsById(int requestId) async {
    try {
      String apiURL =
          '${APIHost().apiURL}/project_payment_controller.php/ListOfRequestById';
      PD.pd(text: apiURL);
      String requestIdNumber = RequestNumber.formatNumber(
          val: int.tryParse(requestId.toString()) ?? 0);
      PD.pd(text: requestIdNumber);
      WaitDialog.showWaitDialog(context,
          message: 'Loading request number $requestIdNumber');


      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          'tbl_user_payment_request_id': requestId,
          "req_ref_number": RequestNumber.refNumberCon(val: requestIdNumber)
        }),
      );

      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          List<dynamic> data = responseData['data'] ?? [];
          if (data.isEmpty) {
            clearFullData();
            scaffoldMg('No request data found for the given Request ID.');
            return;
          }

          if (data[0]['is_auth'] == 1) {
            scaffoldMg(
                'This request has already been authorized and cannot be edited.');
            clearFullData();
          } else if (data[0]['is_appro'] == 1) {
            scaffoldMg(
                'This request has already been approved and cannot be edited.');
            clearFullData();
          } else if (data[0]['is_paid'] == 1) {
            scaffoldMg(
                'Payment has already been made for this request and cannot be edited.');
            clearFullData();
          } else if (data[0]['is_enable'] == 0) {
            scaffoldMg('This request is currently disabled and cannot be edited.');
            clearFullData();
          } else {

            _txtTotalBillAmount.text = (data[0]['total_req_amount'] != null)
                ? double.tryParse(data[0]['total_req_amount'].toString())
                ?.toString() ??
                '0.00'
                : '0.00';

            setState(() {
              scaffoldMgOk('request ${data[0]['req_ref_number']} is valid and can have items added');
              _txtReceiverName.text = data[0]['receiver_name'] ?? '';
              _txtBeneficiaryName.text = data[0]['beneficiary_name'] ?? '';
              _txtReceiverMobile.text = data[0]['receiver_mobile'] ?? '';
              _txtComment.text = data[0]['cmt'] ?? '';
              _txtProjectLocation.text = data[0]['location_name'] ?? '';
              _txtProject.text = data[0]['project_name'] ?? '';
              _selectedPaymentType = data[0]['paymeth_id'];
              _txtRequestId.text = RequestNumber.formatNumber(
                  val: data[0]['tbl_user_payment_request_id']);
              _txtTotalBillAmount.text = (data[0]['requested_amount'] != null)
                  ? double.tryParse(data[0]['requested_amount'].toString())
                  ?.toString() ??
                  '0.00'
                  :'0.00';
              if (_dropdownBank.isEmpty) {
                _dropdownBank = ["Select Bank"];
              }

              String bankFromApi = data[0]['bank_name']?.toString() ?? '';
              if (_dropdownBank.contains(bankFromApi)) {
                _txtAccountNumber.text = data[0]['account_number'] ?? '';
                _txtBranch.text = data[0]['bank_branch'] ?? '';
                _selectedValueBank = bankFromApi;
                _txtBankName.text = bankFromApi;
              } else {
                _selectedValueBank = null;
                _txtBankName.text = '';
              }
            });

            _loadActiveWorkList();
            _loadUserRequestMaterialList();
          }
        } else {
          scaffoldMg(responseData['message'] ?? 'Failed to load request data.');
        }
      } else {
        WaitDialog.hideDialog(context);
        scaffoldMg('HTTP Error: ${response.statusCode}');
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
      WaitDialog.hideDialog(context);
      PD.pd(text: e.toString());
      scaffoldMg('An error occurred while fetching the request data.');
    }
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

  List<dynamic> _activeRequestList = [];
  bool _isUserRequestLoad = false;
  Future<void> _loadUserRequestMaterialList() async {
    setState(() {
      _isUserRequestLoad = true;
    });
    _activeRequestList.clear();
    try {
      WaitDialog.showWaitDialog(context, message: 'loading list material');
      String reqUrl =
          '${APIHost().apiURL}/project_payment_controller.php/RequestMaterialListOnRequestId';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token,
          "request_id":_txtRequestId.text
        }),
      );

      PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        Navigator.pop(context);
        try {
          final responseData =
          jsonDecode(response.body) as Map<String, dynamic>;
          if (responseData['status'] == 200) {
            setState(() {
              _activeRequestList = List.from(responseData['data'] ?? []);
            });
            setState(() {
              _isUserRequestLoad = false;
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
          PD.pd(text: e.toString());
        }
      }
      else {
        Navigator.pop(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    }
  }

  void scaffoldMg(String mg){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
  void scaffoldMgOk(String mg){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mg),
        backgroundColor: Colors.green,
      ),
    );
  }







  //work list
  List<dynamic> _activeWorkListMap = [];
  String? _selectedValueWorkType;
  List<String> _dropdownWorkType = [];
  Future<void> _loadActiveWorkList() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading works');

      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        return;
      }

      String reqUrl =
          '${APIHost().apiURL}/project_payment_controller.php/WorkCategoryTypeSelection';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": token,
          "location_name":_txtProjectLocation.text,
          "project_name":_txtProject.text
        }),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _activeWorkListMap = responseData['data'] ?? [];
            _dropdownWorkType = _activeWorkListMap
                .map<String>((item) => item['work_name'].toString())
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
      PD.pd(text: e.toString());
    } finally {

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }


  //cost category
  String? _selectedValueCostCategory;
  List<String> _dropdownCostCategory = [];
  List<dynamic> _activeCostListMap = [];
  Future<void> _loadActiveCostList(String? workName) async {

    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Category');



      String reqUrl =
          '${APIHost().apiURL}/project_payment_controller.php/CostCategorySelectionByEstimationAndWorkId';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token,
          "work_name":workName,
          "location_name":_txtProjectLocation.text,
          "project_name":_txtProject.text,
        }),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _activeCostListMap = responseData['data'] ?? [];
            _dropdownCostCategory = _activeCostListMap
                .map<String>((item) => item['cost_category'].toString())
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
      PD.pd(text: e.toString());
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }


  String? _selectedValueMaterial;
  List<String> _dropdownMaterial = [];
  List<dynamic> _activeMaterialListMap = [];
  Future<void> _loadActiveMaterialList(String? workName,String? costCategory) async {

    try {
      WaitDialog.showWaitDialog(context, message: 'Loading material list');

      String reqUrl =
          '${APIHost().apiURL}/project_payment_controller.php/ListProjectRegisterdMaterial';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({
          "Authorization": APIToken().token,
          "location_name":_txtProjectLocation.text,
          "project_name":_txtProject.text,
          "work_name":workName,
          "cost_category":costCategory,
        }),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        Navigator.pop(context);
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            _activeMaterialListMap = responseData['data'] ?? [];
            _dropdownMaterial = _activeMaterialListMap
                .map<String>((item) => item['material_name'].toString())
                .toList();
          });
          //PD.pd(text: _dropdownMaterial.toString());
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
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
      PD.pd(text: reqUrl);
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
      PD.pd(text: e.toString());
    } finally {
    }
  }


  //Text field controllers and validation

  final _txtTotalAmount = TextEditingController();
  final _txtRequestNumber = TextEditingController();
  final _txtTotalBillAmount = TextEditingController();
  final _txtReceiverName = TextEditingController();
  final _txtReceiverMobile =TextEditingController();
  final _txtChequeWriter = TextEditingController();
  final _txtMaterialDropDown = TextEditingController();
  final _txtCostTypeDropdown = TextEditingController();
  final _txtCostCategoryDropDown = TextEditingController();
  final _txtQty = TextEditingController();
  final _txtUnitCost = TextEditingController();
  final _txtDescriptions = TextEditingController();
  final _txtComment = TextEditingController();
  final _txtBankName = TextEditingController();
  final _txtBeneficiaryName = TextEditingController();
  final _txtAccountNumber = TextEditingController();
  final _txtBranch = TextEditingController();
  final _txtBiller = TextEditingController();
  final _txtRequestId= TextEditingController();
  final _txtProject = TextEditingController();
  final _txtProjectLocation =TextEditingController();
  final _txtItemTotalDiscount = TextEditingController();



  String? _materialId;
  String? _price;
  String? _qty;

  double _amount=0;

  Future<void> _updateAmount() async {
    double totalAmount = double.tryParse(_txtTotalAmount.text.replaceAll(',', '')) ?? 0;
    double unitCost = double.tryParse(_txtUnitCost.text.replaceAll(',', '')) ?? 0;
    double qty = double.tryParse(_txtQty.text.replaceAll(',', '')) ?? 0;
    double expectedAmount = qty * unitCost;
    if(_txtItemTotalDiscount.text.isEmpty){
      _txtItemTotalDiscount.text='0';
    }
    if (totalAmount == 0) {
      _amount = expectedAmount;
      _txtTotalAmount.text = NumberStyles.currencyStyle(_amount.toString());
    } else {
      if ((totalAmount - expectedAmount).abs() > 0.01) {
        showTopNotification(context, 'Entered Total Amount (${_txtTotalAmount.text}) does not match Unit Cost x Qty (${NumberStyles.currencyStyle(expectedAmount.toString())})');
      }
    }
  }
  Future<void> _loadMaterialInfo(String? workName, String? costCategory, String? materialName) async {
    try {
      // Show loading message via SnackBar
     WaitDialog.showWaitDialog(context, message: 'Loading material list...');
      String reqUrl = '${APIHost().apiURL}/material_controller.php/GetmaterialInfo';
     PD.pd(text: reqUrl);

      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token, // Keeping Authorization in the body as per your request
          "work_name": workName,
          "cost_category": costCategory,
          "material_name": materialName,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          if (responseData['data'] is List && responseData['data'].isNotEmpty) {
            final materialData = responseData['data'][0];
            setState(() {
              _materialId = materialData['idtbl_material_list'].toString();
              _qty = materialData['qty'];
              _price = NumberStyles.currencyStyle(materialData['amount']);
              _txtDescriptions.text = materialData['material_name'];
            });
            _loadMaterialEstimationCost(workName,costCategory,materialName);

          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No material data found.'), backgroundColor: Colors.red),
            );
          }
        } else {
          final String message = responseData['message'] ?? 'Unknown Error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HTTP Error: ${response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e'), backgroundColor: Colors.red),
      );
    } finally {
    }
  }

  int touchedIndex = -1;

  double _requestedTotalAmount=0;
  double _totalEstimateAmount=0;
  double _totalEstimateQty=0;
  double _totalRqQty=0;
  double _itemDiscounts=0;
  bool _isPriceEditAllow=false;

  Future<void> _loadMaterialEstimationCost(String? workName, String? costCategory, String? materialName) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading request data');
      String reqUrl = '${APIHost().apiURL}/project_payment_controller.php/EstimateMaterialCost';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "location_name": _txtProjectLocation.text,
          "project_name": _txtProject.text,
          "work_name": workName,
          "cost_category": costCategory,
          "material_name": materialName,
        }),
      );
    PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        Navigator.pop(context);
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          if (responseData['estimateData'] is List && responseData['estimateData'].isNotEmpty) {
            final estimationData = responseData['estimateData'][0];
            if (responseData['requestdData'] is List &&
                responseData['requestdData'].isNotEmpty &&
                responseData['requestdData'][0] is List &&
                responseData['requestdData'][0].isNotEmpty) {
              final requestData = responseData['requestdData'][0][0];
              setState(() {
                _requestedTotalAmount = num.tryParse(requestData['request_amount'].toString())?.toDouble() ?? 0.0;
                _totalEstimateAmount = num.tryParse(estimationData['total_estimate_amount'].toString())?.toDouble() ?? 0.0;
                _totalEstimateQty = num.tryParse(estimationData['total_estimate_qty'].toString())?.toDouble() ?? 0.0;
                _totalRqQty = num.tryParse(requestData['requested_qty'].toString())?.toDouble() ?? 0.0;
                _itemDiscounts= num.tryParse(requestData['item_disc'].toString())?.toDouble() ?? 0.0;
                int? isEdit = int.tryParse(estimationData['is_edit_allow'].toString());
                _isPriceEditAllow = (isEdit == 0);
              });
              _txtQty.text="";
              _txtUnitCost.text="";
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No request data found.'), backgroundColor: Colors.red),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No material data found.'), backgroundColor: Colors.red),
            );
          }
        } else {
          final String message = responseData['message'] ?? 'Unknown Error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
      else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HTTP Error: ${response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e'), backgroundColor: Colors.red),
      );
    }
  }

  int requestId=0;

  Future<void> _addMaterialToList() async {
    try {
      // Show loading message
      WaitDialog.showWaitDialog(context, message: 'loading');
      String reqUrl = '${APIHost().apiURL}/project_payment_controller.php/AddBilledItem';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "request_id":_txtRequestId.text,
          "project_name":_txtProject.text,
          "location_name":_txtProjectLocation.text,
          "material_name":_selectedValueMaterial,
          "work_name":_selectedValueWorkType,
          "cost_category":_selectedValueCostCategory,
          "material_des":_txtDescriptions.text,
          "item_disc":_txtItemTotalDiscount.text.replaceAll(',', ''),
          "req_qty":_txtQty.text.replaceAll(',', ''),
          "req_amout":_txtUnitCost.text.replaceAll(',', ''),
          "actual_amount":_txtTotalAmount.text.replaceAll(',', ''),
          "created_by":UserCredentials().UserName,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final int status = responseData['status'];
          if (status == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message'] ?? 'Billed item insertion successful'), backgroundColor: Colors.green),
            );
            _loadUserRequestMaterialList();
            clearBillItemData();
          } else if (status == 409) {
            // Scanning message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message'] ?? 'error',style: TextStyle(color: Colors.black),), backgroundColor: Colors.yellow),
            );
          } else {
            final String message = responseData['message'] ?? 'Error';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          }
        } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
          String errorMessage = "Error decoding JSON: $e, Body: ${response.body}";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
      else {
        Navigator.pop(context);
        String errorMessage = 'billing failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
            errorMessage = response.body;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
      Navigator.pop(context);
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
  Future<void> _postRequest() async {
    try {

      WaitDialog.showWaitDialog(context, message: 'posting');
      String reqUrl = '${APIHost().apiURL}/project_payment_controller.php/PostToApprove';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "request_id":_txtRequestId.text,
          "req_ref_number":RequestNumber.refNumberCon(val: _txtRequestId.text),
          "bank_name":_selectedPaymentType==2?_txtBankName.text:'NO',
          "is_active":"1",
          "post_user":UserCredentials().UserName,
          "is_post":"1",
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
              SnackBar(content: Text(responseData['message'] ?? 'Post to Approved'), backgroundColor: Colors.green),
            );
            OneBtnDialog.oneButtonDialog(context, title: 'Request Submitted', message: responseData['message'], btnName: 'Ok', icon: Icons.verified, iconColor: Colors.green, btnColor: Colors.black);
            //_loadUserRequestMaterialList();
            clearBillItemData();
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
          String errorMessage = "Error decoding JSON: $e, Body: ${response.body}";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
      else {
        WaitDialog.hideDialog(context);
        String errorMessage = 'IOU Sending failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
            errorMessage = response.body;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
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



  void clearBillItemData(){
    _materialId='';
    _price='';
    _qty='';
    _amount=0;
    _txtUnitCost.text='';
    _txtQty.text='';
    _txtDescriptions.text='';
    _txtTotalAmount.text='';
    _txtItemTotalDiscount.text='';
  }


  void clearFullData(){

    setState(() {
      _txtProject.text='';
      _txtProjectLocation.text='';
      _txtTotalBillAmount.text='';
      _txtRequestId.text='';
      _txtReceiverName.text='';
      _txtBeneficiaryName.text='';
      _txtReceiverMobile.text='';
      _txtComment.text='';
      _txtBankName.text='';
      _txtAccountNumber.text='';
      _dropdownWorkType.clear();
      _activeWorkListMap.clear();
      _dropdownCostCategory.clear();
      _activeCostListMap.clear();
      _txtMaterialDropDown.text='';
      _activeMaterialListMap.clear();
      _dropdownMaterial.clear();
      _activeMaterialListMap.clear();
      _txtTotalAmount.text='';
      _materialId='';
      _price='';
      _qty='';
      _amount=0;
      _txtUnitCost.text='';
      _txtQty.text='';
      _txtDescriptions.text='';
      _txtBranch.text='';
      _txtAccountNumber.text='';
      _txtBankName.text='';
      _activeRequestList.clear();
      _txtRequestNumber.text='';
    });

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ControllerWithAppBar(appname: 'Project Payment Request Form(Data entry Form)', tabController:  _tabController),
      body: TabBarView(
        controller: _tabController,
        children: [
          _requestForms(),
          _materialSelection(),
          _buildListOfRequest(),
        ],
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
                    subtitle: _buildScanBar(),
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

  Widget _buildScanBar() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: buildTextField(
                _txtRequestNumber,
                'Request Number',
                'CON-000001',
                Icons.confirmation_number_outlined,
                true,
                10,
              ),
            ),
            Container(
              padding: EdgeInsets.only(bottom: 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  int id = int.tryParse(_txtRequestNumber.text)??0;
                  PD.pd(text: _txtRequestId.text);
                  fetchRequestsById(id);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(Icons.qr_code_scanner, color: Colors.white),
                label: Text(
                  "Scan",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }


// Request form
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
          SizedBox(width: 10,),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () {
              // To show the dialog for a new invoice:
              showDialog(
                context: context,
                builder: (context) => InvoiceSummaryDialog(
                  refNumber:RequestNumber.refNumberCon(val: _txtRequestId.text),
                  refId:  _txtRequestId.text,// Your invoice number
                ),
              ).then((saved) {
                if (saved == true) {
                  // Invoice was saved successfully
                  // Refresh your data or update UI as needed
                }
              });


            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Bill summery'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      buildTextFieldReadOnly(_txtProject, 'Project Name', 'From Project Name', Icons.construction_rounded, true, 45),
      const SizedBox(height: 20),
      buildTextFieldReadOnly(_txtProjectLocation, 'Location Name', 'From Location Name', Icons.store, true, 45),
      const SizedBox(height: 20),
      buildNumberWithReadOption(
        _txtTotalBillAmount,
        'Bill Total',
        '25000',
        Icons.attach_money,
        true,
        10,
      ),
      const SizedBox(height: 20),
      buildTextFieldReadOnly(_txtReceiverName, 'Receiver Name', 'Enter receiver name', Icons.person, true, 45),
      const SizedBox(height: 10),
      buildTextFieldReadOnly(_txtBeneficiaryName, 'Beneficiary Name', 'Enter beneficiary name', Icons.person, true, 45),
      const SizedBox(height: 10),
      buildTextFieldReadOnly(_txtReceiverMobile, 'Receiver Mobile', 'Enter receiver mobile', Icons.phone, true, 10),
      const SizedBox(height: 10),
      buildTextFieldReadOnly(_txtComment, 'Request Comment', 'Enter your comment', Icons.comment, true, 200),

      const SizedBox(height: 20),
      if (_selectedPaymentType == 2)
        CustomDropdown(
          label: 'Select Bank',
          suggestions: _dropdownBank,
          icon: FontAwesomeIcons.bank,
          controller: _txtBankName,
          onChanged: (value) {
            setState(() {
              _selectedValueBank = value;
              _txtBankName.text = value!;
              _loadActiveWorkList();
            });
          },
        ),
      if (_selectedPaymentType == 2) // Bank Transfer - Show Bank details
        Column(
          children: [
            const SizedBox(height: 10),
            buildTextFieldReadOnly(_txtBranch, 'Branch', 'Enter branch', Icons.location_on, true, 45),
            const SizedBox(height: 10),
            buildTextFieldReadOnly(_txtAccountNumber, 'Account Number', 'Enter account number', Icons.account_balance, true, 45),
          ],
        ),
      //   Center(
      //   child:  _buildRequestCreating(),
      // )
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
          CustomDropdown(
            label: 'Work Type',
            suggestions: _dropdownWorkType,
            icon: Icons.category_sharp,
            controller: _txtCostTypeDropdown,
            onChanged: (value) {
              _selectedValueWorkType = value;
              _loadActiveCostList(value);
            },
          ),
          const SizedBox(height: 10),
          CustomDropdown(
            label: 'Select Cost Category',
            suggestions: _dropdownCostCategory,
            icon: Icons.celebration,
            controller: _txtCostCategoryDropDown,
            onChanged: (value) {
              _selectedValueCostCategory = value;
              PD.pd(text: _selectedValueWorkType.toString());
              _loadActiveMaterialList(
                  _selectedValueWorkType.toString(),
                  value.toString());
            },
          ),
          const SizedBox(height: 10),
          _buildMaterialSection(),
          const SizedBox(height: 10),
          buildTextField(_txtDescriptions, 'Descriptions', 'Cement', Icons.description, true, 45),
          Visibility(
              visible: _qty==''?false:true,
              child: _buildMaterialInfoTable()
          ),
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
                  5,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 5,
                child:
                buildNumberWithReadOption(
                  _txtUnitCost,
                  'Unit Amount',
                  '1500',
                  LKRIcon(),
                  _isPriceEditAllow,
                  10,
                ),
              ),
            ],

          ),
          Row(
            children: [
              Expanded(child: buildNumberWithReadOption(
              _txtTotalAmount,
              'Total Amount',
              '1500',
              LKRIcon(),
              _isPriceEditAllow,
              10,
            ),),
              SizedBox(width: 8,),
              Expanded(child:
            buildNumberWithReadOption(
              _txtItemTotalDiscount,
              'Total Discount',
              '200',
              LKRIcon(),
              false,
              10,
            ),)],
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
                      'Item Selection',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: IconButton(
                        onPressed: () {
                          viewImages();
                        },
                        icon: const Icon(Icons.download_rounded, color: Colors.blueAccent),
                        tooltip: 'Download Request Bill',),
                  ),
                ),

                const SizedBox(height: 10),
                screenWidth < 900
                    ? Column(
                  children: [
                    buildFormFields(),
                    Container(
                      padding: EdgeInsets.all(12),
                      height: 300,
                      child: _buildPieChart(),
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
                          child: _buildPieChart(), // Pie chart on the right for desktop
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
          initialValue: TextEditingValue(text: _selectedValueMaterial ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) {
            // Filter workTypes based on user input
            return _dropdownMaterial.where((word) =>
                word.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) {
            setState(() {
              _selectedValueMaterial = selection;
              _txtMaterialDropDown.text = selection; // Update controller when an item is selected
              _loadMaterialInfo(_selectedValueWorkType.toString(),_selectedValueCostCategory.toString(),_selectedValueMaterial.toString());
            });
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              maxLength: 45,
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'Cement',
                labelText: 'Select Items',
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
                  return 'Please material';
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
        PD.pd(text: _qty.toString());
        _updateAmount();
        if (_selectedValueWorkType == null ||
            _selectedValueCostCategory == null ||
            _selectedValueMaterial == null ||
            _txtQty.text.isEmpty ||
            _txtItemTotalDiscount.text.isEmpty ||
            _txtUnitCost.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please fill all required fields'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (_materialSelectionKey.currentState!.validate()) {
          YNDialogCon.ynDialogMessage(
            context,
            messageBody: 'Confirm adding items to the bill list?',
            messageTitle: 'Add Items to Bill',
            icon: Icons.verified_outlined,
            iconColor: Colors.black,
            btnDone: 'YES',
            btnClose: 'NO',
          ).then((value) async {
            if (value == 1) {

              await _addMaterialToList();
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
      child: const Text('Add Items to Bill'),
    );
  }

  //list of material
  Widget _buildListOfRequest() {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Request Item List",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildActiveListOfRequest(),
                  const SizedBox(height: 20),
                  Visibility(
                    visible: _activeRequestList.isNotEmpty,
                    child: _buildCloseButton(),
                  ),
                ],
              ),
            ),
          ),
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
          'No Item List found.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6, // Limit height
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            border: TableBorder.all(width: 1, color: Colors.grey),
            columnSpacing: 5,
            dataRowMinHeight: 30,
            dataRowMaxHeight: 40,
            headingRowHeight: 35,
            columns: [
              _buildDataColumn('#'),
              _buildDataColumn('Main Category'),
              _buildDataColumn('Items'),
              _buildDataColumn('Qty'),
              _buildDataColumn('Unit Amount(LKR)'),
              _buildDataColumn('Dis(LKR)'),
              _buildDataColumn('Total Amount(LKR)'),
              _buildDataColumn('Actions'),
            ],
            rows: _activeRequestList.asMap().entries.map((entry) {
              int index = entry.key + 1; // For 1-based row numbering
              var requestList = entry.value;
              double qty = double.tryParse(requestList['req_qty']) ?? 0;
              double itemDis = double.tryParse(requestList['item_disc']) ?? 0;
              double unitAmount = double.tryParse(requestList['actual_amount']) ?? 0;
              double reqAmount = double.tryParse(requestList['req_amout']) ?? 0;
              double total = 1 * unitAmount-itemDis;
              return DataRow(cells: [
                _buildDataCell(index.toString()), // Row number
                _buildDataCell(requestList['work_name'].toString()),
                _buildDataCell(requestList['material_des']),
                _buildDataCell('${NumberStyles.qtyStyle(qty.toString())} ${requestList['uom']}'),
                _buildDataCell(NumberStyles.currencyStyle(reqAmount.toString())),
                _buildDataCell('$itemDis'),
                _buildDataCell(NumberStyles.currencyStyle(total.toString())),
                DataCell(
                    Center(
                      child: IconButton(
                        icon: Icon(Icons.delete_forever_rounded, color: Colors.red),
                        onPressed: () {
                          YNDialogCon.ynDialogMessage(context,
                              messageBody: 'Confirm to remove Item ${requestList['material_des']} QTY :${requestList['req_qty']}',
                              messageTitle: 'Remove Items',
                              icon: Icons.delete_forever,
                              iconColor: Colors.red,
                              btnDone: 'Yes,Delete',
                              btnClose: 'No').then((value) {
                            if (value == 1) {
                              removeRequestItem(context, requestList['idtbl_user_request_list'].toString(), requestList['material_des']);
                            }
                          });
                        },
                      ),
                    )
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
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
  Widget _buildPieChart() {
    if (_totalEstimateAmount <= 0) return SizedBox();
    double usedAmount = _requestedTotalAmount-_itemDiscounts;
    double remainingAmount = (_totalEstimateAmount - usedAmount).clamp(0, _totalEstimateAmount);
    double exceededAmount = (usedAmount > _totalEstimateAmount) ? (usedAmount - _totalEstimateAmount) : 0;

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // **Pie Chart**
          SizedBox(
            width: 150, // Adjust width
            height: 150, // Adjust height
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions || pieTouchResponse?.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 0,
                centerSpaceRadius: 10, // Small center space
                sections: [
                  // **Used Amount (Requested)**
                  PieChartSectionData(
                    color: Colors.blue, // Fill used portion in blue
                    value: (exceededAmount > 0) ? _totalEstimateAmount : usedAmount,
                    title: '${_getPercentage((exceededAmount > 0) ? _totalEstimateAmount : usedAmount, _totalEstimateAmount)}%',
                    radius: touchedIndex == 0 ? 60.0 : 55.0,
                    titleStyle: TextStyle(
                      fontSize: touchedIndex == 0 ? 14.0 : 12.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // **Exceeded Amount (If Used > Estimated)**
                  if (exceededAmount > 0)
                    PieChartSectionData(
                      color: Colors.red, // Show excess amount in red
                      value: exceededAmount,
                      title: '${_getPercentage(exceededAmount, _totalEstimateAmount)}%',
                      radius: touchedIndex == 1 ? 60.0 : 55.0,
                      titleStyle: TextStyle(
                        fontSize: touchedIndex == 1 ? 14.0 : 12.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  // **Remaining Amount**
                  if (exceededAmount == 0 && remainingAmount > 0) // Only show remaining if > 0 and no excess
                    PieChartSectionData(
                      color: Colors.grey.shade400, // Remaining portion in grey
                      value: remainingAmount,
                      title: '${_getPercentage(remainingAmount, _totalEstimateAmount)}%',
                      radius: touchedIndex == 2 ? 60.0 : 55.0,
                      titleStyle: TextStyle(
                        fontSize: touchedIndex == 2 ? 14.0 : 12.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8), // Space between pie chart and legend

          // **Legend (Now in row format: Estimated | Used | Balance)**
          Column(
            children: [
              _buildLegendItem(Colors.green, "Estimated", _totalEstimateAmount, _totalEstimateAmount),
              _buildLegendItem(Colors.blue, "Used", usedAmount, _totalEstimateAmount),
              _buildLegendItem(
                exceededAmount > 0 ? Colors.red : Colors.grey.shade400,
                exceededAmount > 0 ? "Exceeded" : "Balance",
                exceededAmount > 0 ? exceededAmount : remainingAmount,
                _totalEstimateAmount,
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildLegendItem(Color color, String label, double value, double total) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4), // Space
        Flexible( // Fix: Use Flexible to prevent overflow
          child: Text(
            '$label: ${NumberFormat('#,###.00', 'en_US').format(double.tryParse(value.toString()) ?? 0)} LKR (${_getPercentage(value, total)}%)',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500), // Smaller legend text
            overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
          ),
        ),
      ],
    );
  }
  String _getPercentage(double value, double total) {
    if (total == 0) return "0"; // Avoid division by zero
    return (value / total * 100).toStringAsFixed(1);
  }

  //table for price and qty
  Widget _hadersOnMaterialInfoTable(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(2, 2),)
          ]
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
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
  Widget _buildMaterialInfoTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First Column: Blue
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade100, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _hadersOnMaterialInfoTable("Material Info"),
                      Visibility(
                          visible: false,
                          child: buildDetailRow('Material ID', _materialId.toString())),
                      buildDetailRow('Price', _price.toString()),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),

              // Second Column: Green
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade100, Colors.green.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _hadersOnMaterialInfoTable("Estimation Info"),
                      Visibility(
                          visible: true,
                          child: buildDetailRow('Qty', _totalEstimateQty.toString())),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),

              // Third Column: Orange
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade100, Colors.orange.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _hadersOnMaterialInfoTable("Request"),
                      Visibility(
                          visible: true,
                          child: buildDetailRow('Qty', _totalRqQty.toString())),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  //remove listed items
  Future<void> removeRequestItem(BuildContext context, String id,String name) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Processing Request...');
      String? token = APIToken().token;

      if (token == null || token.isEmpty) {
        ExceptionDialog.exceptionDialog(
          context,
          title: 'Authentication Error',
          message: "Authentication token is missing.",
          btnName: 'OK',
          icon: Icons.error,
          iconColor: Colors.red,
          btnColor: Colors.black,
        );
        return;
      }

      String reqUrl='${APIHost().apiURL}/project_payment_controller.php/DeleteBilledItem';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Authorization": token,
          "request_id":requestId,
          "idtbl_user_request_list": id,
          "isLog":0,
          "BilledName":name,
          "created_by":UserCredentials().UserName
        }),
      );

      WaitDialog.hideDialog(context);
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
            ).then((v){
              if(v==true){
                _loadUserRequestMaterialList();
              }
            });

          } else {
            showErrorDialog(context, responseData['message'] ?? 'Error');
          }
        } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
          showErrorDialog(context, "Error decoding JSON response.");
        }
      } else {
        handleHttpError(context, response);
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
      handleGeneralError(context, e);
    }
  }
  void handleHttpError(BuildContext context, http.Response response) {
    String errorMessage = 'Request failed with status code ${response.statusCode}';
    try {
      final errorData = jsonDecode(response.body);
      errorMessage = errorData['message'] ?? errorMessage;
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_bill_data_entry_form.dart');
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
