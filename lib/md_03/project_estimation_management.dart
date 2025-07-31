import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/number_format.dart';
import 'package:roky_holding/md_06/view_location_estimation.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/custome_icon.dart';
import '../env/input_widget.dart';
import '../env/print_debug.dart';
import '../env/user_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ConstructionEstimationCreate extends StatefulWidget {
  const ConstructionEstimationCreate({super.key});

  @override
  State<ConstructionEstimationCreate> createState() =>
      _ConstructionEstimationCreateState();
}

class _ConstructionEstimationCreateState
    extends State<ConstructionEstimationCreate> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dropDownToProject();
    });
  }

  //loading estimation
  List<dynamic> _activeEstimationList = [];
  bool _isEstimationLoad = false;
  Future<void> _loadProjectsLocationEstimationList() async {
    _activeEstimationList.clear();
    setState(() => _isEstimationLoad = true);

    try {
      WaitDialog.showWaitDialog(context, message: 'Loading estimations');
      String? token = APIToken().token;
      String reqUrl =
          '${APIHost().apiURL}/estimation_controller.php/GetEstimations';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": token,
          "project_name": _selectedProjectName.toString(),
          "location_name": _selectedProjectLocationName.toString(),
          "show_only_estimated":'0'
        }),
      );

      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            _activeEstimationList = List.from(responseData['data'] ?? []);
          });
        } else {
          throw Exception(
              responseData['message'] ?? 'Error fetching estimations');
        }
      } else {
        WaitDialog.hideDialog(context);
        throw Exception("HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_estimation_management.dart');
      WaitDialog.hideDialog(context);
      PD.pd(text: e.toString());
      OneBtnDialog.oneButtonDialog(
        context,
        title: 'Error',
        message: e.toString(),
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
    } finally {
      setState(() => _isEstimationLoad = false);
    }
  }

  //project list dropdown
  List<dynamic> _activeProjectDropDownMap = [];
  bool _isProjectsDropDown = false;
  Future<void> _dropDownToProject() async {
    setState(() {
      _isProjectsDropDown = true;
    });
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading project');

      String reqUrl = '${APIHost().apiURL}/project_controller.php/listAll';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token}),
      );
      PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
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
      } else {
        WaitDialog.hideDialog(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_estimation_management.dart');
      WaitDialog.hideDialog(context);
      PD.pd(text: e.toString());
    } finally {
      setState(() {
        _isProjectsDropDown = false;
      });
    }
  }

  //project location list dropdown
  String? _selectedProjectName;
  List<String> _dropdownProjects = [];
  List<dynamic> _activeProjectLocationDropDownMap = [];
  bool _isProjectLocationDropDown = false;
  Future<void> _dropDownToProjectLocation(String project) async {
    _activeEstimationList.clear();
    setState(() {
      _isProjectLocationDropDown = true;
    });
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading location');
      String reqUrl =
          '${APIHost().apiURL}/location_controller.php/ListProjectActiveLocation';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(
            {"Authorization": APIToken().token, "project_name": project}),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
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
        WaitDialog.hideDialog(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_estimation_management.dart');
      WaitDialog.hideDialog(context);
      PD.pd(text: e.toString());
    } finally {
      setState(() {
        _isProjectLocationDropDown = false;
      });
    }
  }

  String? _selectedProjectLocationName;
  List<String> _dropdownProjectLocation = [];

  //work list
  final List<dynamic> _activeWorksList = [];
  List<dynamic> _activeWorkListMap = [];
  bool _isLoadingWorksList = false;
  String? _selectedValueWorkType;
  List<String> _dropdownWorkType = [];
  Future<void> _loadActiveWorkList() async {
    setState(() {
      _isLoadingWorksList = true;
    });
    try {
      _dropdownCostCategory.clear();
      _dropdownMaterial.clear();
      WaitDialog.showWaitDialog(context, message: 'Loading works');
      String reqUrl =
          '${APIHost().apiURL}/material_controller.php/MaterialWorkList';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token}),
      );
      PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
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
        WaitDialog.hideDialog(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_estimation_management.dart');
      WaitDialog.hideDialog(context);
      PD.pd(text: e.toString());
    } finally {
      setState(() {
        _isLoadingWorksList = false;
      });
    }
  }

  //cost category
  String? _selectedValueCostCategory;
  List<String> _dropdownCostCategory = [];
  final List<dynamic> _activeCostList = [];
  List<dynamic> _activeCostListMap = [];
  bool _isLoadingCostList = false;
  Future<void> _loadActiveCostList(String? workName) async {
    setState(() {
      _isLoadingCostList = true;
    });
    try {
      _dropdownMaterial.clear();
      WaitDialog.showWaitDialog(context, message: 'Loading Category');
      String reqUrl =
          '${APIHost().apiURL}/material_controller.php/CostCategoryList';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "work_name": workName,
        }),
      );

      PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
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
        WaitDialog.hideDialog(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_estimation_management.dart');
      WaitDialog.hideDialog(context);
      PD.pd(text: e.toString());
    } finally {
      setState(() {
        _isLoadingCostList = false;
      });
    }
  }

  String? _selectedValueMaterial;
  List<String> _dropdownMaterial = [];
  final List<dynamic> _activeMaterialList = [];
  List<dynamic> _activeMaterialListMap = [];
  bool _isLoadingMaterialList = false;
  Future<void> _loadActiveMaterialList(String? workName, String? costCategory) async {
    setState(() {
      _isLoadingMaterialList = true;
    });
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Items');

      String reqUrl =
          '${APIHost().apiURL}/material_controller.php/ListCategoryWiseMaterial';
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "work_name": workName,
          "cost_category": costCategory
        }),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _activeMaterialListMap = responseData['data'] ?? [];
            _dropdownMaterial = _activeMaterialListMap
                .map<String>((item) => item['material_name'].toString())
                .toList();
          });
          //PD.pd(text: _dropdownMaterial.toString());
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
        WaitDialog.hideDialog(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_estimation_management.dart');
      WaitDialog.hideDialog(context);
      PD.pd(text: e.toString());
    } finally {
      setState(() {
        _isLoadingMaterialList = false;
      });
    }
  }

  //Text field controllers and validation

  final _txtProjectDropdown = TextEditingController();
  final _txtProjectLocationDropdown = TextEditingController();
  final _txtMaterialDropDown = TextEditingController();
  final _txtCostTypeDropdown = TextEditingController();
  final _txtCostCategoryDropDown = TextEditingController();
  final _txtQty = TextEditingController();
  final _txtEstimationAmount = TextEditingController();
  final _txtDescriptions = TextEditingController();

  Future<pw.Document> generateEstimationPdf( List<dynamic> estimationList, String projectName, String locationName, ) async {
    final pdf = pw.Document();

    final printedDateTime =
    DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final footerLogo = pw.MemoryImage(
      (await rootBundle.load('assets/image/HBiz.jpg')).buffer.asUint8List(),
    );

    final headerLogo = pw.MemoryImage(
      (await rootBundle.load('assets/image/logo.png')).buffer.asUint8List(),
    );
    final pageTheme = pw.PageTheme(
      margin: pw.EdgeInsets.all(32),

    );

    pdf.addPage(
      pw.MultiPage(
        footer: (pw.Context context) => pw.Container(
          alignment: pw.Alignment.centerLeft,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              // Left side: Logo
              pw.Container(
                width: 60,
                height: 60,
                child: pw.Image(footerLogo),
              ),

              pw.SizedBox(width: 10), // spacing between logo and text

              // Right side: Column with text lines
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Software by Hela Software Solution',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Contact: +94 70 157 3582',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Website: www.helasoftsolution.com',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),




        pageTheme: pageTheme,
        build: (pw.Context context) {
          return [
            // Top header row with logo and title
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Left-aligned HBiz logo
                pw.Container(
                  width: 80,
                  height: 80,
                  child: pw.Image(headerLogo),
                ),
                // Report title and date on the right
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Project Estimation Report',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.deepPurple900,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Printed on: $printedDateTime',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            pw.Divider(),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Project: $projectName',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Location: $locationName',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey500),
              headerDecoration: pw.BoxDecoration(color: PdfColors.deepPurple),
              headerHeight: 30,
              cellHeight: 25,
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              headers: [
                'Main Category',
                'Sub Category',
                'Item',
                'Qty',
                'Amount (LKR)',
                'Actual Cost (LKR)',
                'Unit Cost (LKR)'
              ],
              data: estimationList.map((estimation) {
                double estimateAmount =
                    double.tryParse(estimation['ItemEstimateAmount'].toString()) ??
                        0;
                double actualCost =
                    double.tryParse(estimation['actual_cost'].toString()) ?? 0;
                double actualUnitAmount =
                    double.tryParse(estimation['actual_unit_amount'].toString()) ??
                        0;

                return [
                  estimation['work_name'],
                  estimation['cost_category'],
                  estimation['material_description'],
                  estimation['estimate_qty'].toString(),
                  NumberFormat('#,###.00', 'en_US').format(estimateAmount),
                  NumberFormat('#,###.00', 'en_US').format(actualCost),
                  NumberFormat('#,###.00', 'en_US').format(actualUnitAmount),
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Budgeted Cost (LKR):',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  NumberFormat('#,###.00', 'en_US').format(
                    estimationList.fold(0.0, (sum, item) =>
                    sum +
                        (double.tryParse(item['ItemEstimateAmount'].toString()) ??
                            0)),
                  ),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),

            pw.SizedBox(height: 10),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Actual Cost (LKR):',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  NumberFormat('#,###.00', 'en_US').format(
                    estimationList.fold(0.0, (sum, item) =>
                    sum +
                        (double.tryParse(item['actual_cost'].toString()) ?? 0)),
                  ),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),

            pw.SizedBox(height: 40),

            pw.SizedBox(height: 10),

            pw.Center(
              child: pw.Text(
                '© ${DateTime.now().year} Hela Software Solution',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }


  Future<void> _exportAndPrintPdf(List<dynamic> estimationList) async {
    final pdf = await generateEstimationPdf(
        estimationList,
        _selectedProjectName.toString(),
        _selectedProjectLocationName.toString());
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? _materialId = '-1';
  String? _price = '-1';
  String? _qty = '-1';
  String? _unit = '-1';
  double amount = 0;

  void _updateAmount() {
    double inputAmount= double.tryParse(_txtEstimationAmount.text.replaceAll(',', ''))??0.0;
    if (inputAmount == 0 || _txtEstimationAmount.text.isEmpty) {
      try {
        double qty = double.tryParse(_txtQty.text) ?? 0;
        double price = double.tryParse(_price.toString().replaceAll(',', '')) ?? 0;
        setState(() {
          amount = qty * price;
        });
        _txtEstimationAmount.text = NumberStyles.currencyStyle(_price.toString());
      } catch (e,st) {
        ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_estimation_management.dart');
      }
    } else {}
  }

  Future<void> _loadMaterialInfo( String? workName, String? costCategory, String? materialName) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'loading..');

      String reqUrl =
          '${APIHost().apiURL}/material_controller.php/GetmaterialInfo';
      PD.pd(text: reqUrl);

      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken()
              .token, // Keeping Authorization in the body as per your request
          "work_name": workName,
          "cost_category": costCategory,
          "material_name": materialName,
        }),
      );
      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          if (responseData['data'] is List && responseData['data'].isNotEmpty) {
            final materialData = responseData['data'][0];
            setState(() {
              _materialId = materialData['idtbl_material_list'].toString();
              _qty = materialData['qty'];
              _price = materialData['amount'];
              _unit = materialData['uom'];
              _txtEstimationAmount.text='';
              _txtQty.text='';
              _txtDescriptions.text = materialData['material_name'];
            });
           /* ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Material ID: $_materialId'),
                  backgroundColor: Colors.green),
            );*/
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('No material data found.'),
                  backgroundColor: Colors.red),
            );
          }
        } else {
          final String message = responseData['message'] ?? 'Unknown Error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      } else {
        WaitDialog.hideDialog(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('HTTP Error: ${response.statusCode}'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_estimation_management.dart');
      WaitDialog.hideDialog(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoadingMaterialList = false;
      });
    }
  }

  Future<void> createEstimationList() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading');
      String reqUrl =
          '${APIHost().apiURL}/estimation_controller.php/CreateEstimationList';
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
          "material_Id": _materialId,
          "is_active": '1',
          "created_by": UserCredentials().UserName,
          "estimate_amount": _txtEstimationAmount.text.replaceAll(',', ''),
          "estimation_gap": "0",
          "estimate_qty": _txtQty.text.replaceAll(',', ''),
          "material_description": _txtDescriptions.text,
          "cost_category": _selectedValueCostCategory.toString(),
          "work_name": _selectedValueWorkType.toString(),
          "material_name": _txtMaterialDropDown.text,
          'uom':_unit
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final int status = responseData['status'];
          if (status == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                  Text(responseData['message'] ?? 'Estimation Created'),
                  backgroundColor: Colors.green),
            );
            PD.pd(text: responseData.toString());
            _loadProjectsLocationEstimationList();
            clearData();
          } else {
            final String message = responseData['message'] ?? 'Error';
            OneBtnDialog.oneButtonDialog(context, title: 'Bad Request', message: message, btnName: 'Ok', icon: Icons.error, iconColor: Colors.red, btnColor: Colors.black);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          }
        } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_estimation_management.dart');
          String errorMessage =
              "Error decoding JSON: $e, Body: ${response.body}";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } else {
        Navigator.pop(context);
        String errorMessage =
            'Estimation creation failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_estimation_management.dart');
            errorMessage = response.body;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_estimation_management.dart');
      Navigator.pop(context);
      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
    }
  }

  Future<void> createNewEstimationId() async {
    try {
      // Show loading message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Creating Estimation...'),
            duration: Duration(seconds: 2)),
      );

      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        // If token is missing, show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Authentication token is missing."),
              backgroundColor: Colors.red),
        );
        return;
      }

      String reqUrl =
          '${APIHost().apiURL}/estimation_controller.php/CreateEstimation';
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
          "is_active": '1',
          "created_by": UserCredentials().UserName,
        }),
      );
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final int status = responseData['status'];
          if (status == 200) {
            // Success message
            PD.pd(text: responseData.toString());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                  Text(responseData['message'] ?? 'Estimation Created'),
                  backgroundColor: Colors.green),
            );
          } else if (status == 409) {
            // Scanning message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                    responseData['message'] ?? 'Scanning',
                    style: TextStyle(color: Colors.black),
                  ),
                  backgroundColor: Colors.yellow),
            );
            _loadProjectsLocationEstimationList();
          } else {
            final String message = responseData['message'] ?? 'Error';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          }
        } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_estimation_management.dart');
          String errorMessage =
              "Error decoding JSON: $e, Body: ${response.body}";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } else {
        String errorMessage =
            'Estimation creation failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_estimation_management.dart');
            errorMessage = response.body;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'project_estimation_management.dart');
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

  void clearData() {
    _materialId = '';
    _price = '';
    _qty = '';
    _unit = '';
    amount = 0;
    _txtDescriptions.text = "";
    _txtEstimationAmount.text = '';
    _txtQty.text = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(appname: 'Construction Estimation Management'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 600; // Check screen width

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: isWideScreen
                ? Row(
              // Two columns if screen is wide
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCreateEstimationForm()),
                const SizedBox(width: 20), // Spacing between columns
                Expanded(child: _buildActiveEstimationListCard()),
              ],
            )
                : Column(
              // Stack in a single column if screen is narrow
              children: [
                _buildCreateEstimationForm(),
                const SizedBox(height: 20), // Spacing between sections
                _buildActiveEstimationListCard(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Stack(
        children: [
          // First Floating Action Button
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: () async {
                if (_activeEstimationList.isNotEmpty) {
                  await _exportAndPrintPdf(_activeEstimationList);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No estimation data to print.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              tooltip: 'Print Estimation List',
              child: const Icon(Icons.print),
            ),
          ),
          // Second Floating Action Button
          Positioned(
            bottom: 16.0,
            right: 96.0, // Adjust the right position to prevent overlap
            child: FloatingActionButton(
              onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context)=>ViewLocationWiseEstimationPage(isEdit: true)));
              },
              tooltip: 'Edit Estimation',
              child: const Icon(Icons.edit),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCreateEstimationForm() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: 400, // Keep max width limited
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Center(
                    child: Text(
                      'Estimation Management',
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
                const SizedBox(height: 10),
                Wrap(
                  spacing: 20,
                  runSpacing: 15,
                  children: [
                    CustomDropdown(
                      label: 'Select Project',
                      suggestions: _dropdownProjects,
                      icon: Icons.category_sharp,
                      controller: _txtProjectDropdown,
                      onChanged: (value) {
                        _selectedProjectName = value;
                        _dropDownToProjectLocation(value.toString());
                      },
                    ),
                    CustomDropdown(
                      label: 'Select Location',
                      suggestions: _dropdownProjectLocation,
                      icon: Icons.location_city,
                      controller: _txtProjectLocationDropdown,
                      onChanged: (value) {
                        _selectedProjectLocationName = value;
                        createNewEstimationId();
                        _loadActiveWorkList();
                      },
                    ),
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
                    CustomDropdown(
                      label: 'Select Sub/Cost Category',
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
                    _buildMaterialSection(),
                    buildTextField(_txtDescriptions, 'Descriptions', 'Cement',
                        Icons.description, true, 45),
                    Visibility(
                        visible: _price == '-1' ? false:_price == '' ? false : true,
                        child: Column(
                          children: <Widget>[
                            buildDetailRow('Material ID', _materialId),
                            buildDetailRow('Price', NumberStyles.currencyStyle(_price.toString())),
                            buildDetailRow('Qty', '$_qty $_unit'),
                          ],
                        )),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: buildNumberField(
                            _txtQty,
                            'Estimate Qty',
                            '1',
                            Icons.numbers,
                            true,
                            5,
                          ),
                        ),

                        SizedBox(width: 10), // Space between fields
                        Expanded(
                            flex: 5,
                            child: buildNumberField(
                                _txtEstimationAmount,
                                'Unit Cost',
                                '1500',
                                LKRIcon(),
                                true,
                                10,)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        _updateAmount();
        if (_formKey.currentState!.validate()) {
          YNDialogCon.ynDialogMessage(
            context,
            messageBody: 'Confirm to adding items estimation',
            messageTitle: 'estimations making',
            icon: Icons.verified_outlined,
            iconColor: Colors.black,
            btnDone: 'YES',
            btnClose: 'NO',
          ).then((value) async {
            if (value == 1) {
              await createEstimationList();
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
      child: const Text('Create estimation'),
    );
  }

  Widget _buildActiveEstimationListCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Active Project Estimation",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildActiveProjectsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveProjectsList() {
    if (_isEstimationLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeEstimationList.isEmpty) {
      return const Center(
        child: Text(
          'No active estimation found.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      );
    }
    Map<int, dynamic> groupedEstimations = {};
    for (var estimation in _activeEstimationList) {
      int materialId = estimation['material_Id'];
      if (groupedEstimations.containsKey(materialId)) {
        groupedEstimations[materialId]['estimate_qty'] +=
            double.tryParse(estimation['estimate_qty'].toString()) ?? 0;
        groupedEstimations[materialId]['ItemEstimateAmount'] +=
            double.tryParse(estimation['ItemEstimateAmount'].toString()) ?? 0;
        groupedEstimations[materialId]['actual_cost'] +=
            double.tryParse(estimation['actual_cost'].toString()) ?? 0;
        groupedEstimations[materialId]['actual_unit_amount'] ?? 0;
      } else {
        groupedEstimations[materialId] = {
          'work_name': estimation['work_name'],
          'cost_category': estimation['cost_category'],
          'material_description': estimation['material_description'],
          'estimate_qty':
          double.tryParse(estimation['estimate_qty'].toString()) ?? 0,
          'ItemEstimateAmount':
          double.tryParse(estimation['ItemEstimateAmount'].toString()) ?? 0,
          'actual_cost':
          double.tryParse(estimation['actual_cost'].toString()) ?? 0,
          'actual_unit_amount':
          double.tryParse(estimation['actual_unit_amount'].toString()) ?? 0,
        };
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 600),
        child: DataTable(
          border: TableBorder.all(width: 1, color: Colors.grey),
          columnSpacing: 5,
          dataRowMinHeight: 30,
          dataRowMaxHeight: 40,
          headingRowHeight: 35,
          columns: [
            _buildDataColumn('Main Category'),
            _buildDataColumn('Sub Category'),
            _buildDataColumn('Item'),
            _buildDataColumn('Qty'),
            _buildDataColumn('Amount (LKR)'),
            _buildDataColumn('Actual Cost (LKR)'),
            _buildDataColumn('Unit Cost (LKR)'),
          ],
          rows: groupedEstimations.values.map((estimation) {
            return DataRow(cells: [
              _buildDataCell(estimation['work_name']),
              _buildDataCell(estimation['cost_category'].toString()),
              _buildDataCell(estimation['material_description']),
              _buildDataCell(estimation['estimate_qty'].toString()),
              _buildDataCell(NumberFormat('#,###.00', 'en_US')
                  .format(estimation['ItemEstimateAmount'])),
              _buildDataCell(NumberFormat('#,###.00', 'en_US')
                  .format(estimation['actual_cost'])),
              _buildDataCell(NumberFormat('#,###.00', 'en_US')
                  .format(estimation['actual_unit_amount'])),
            ]);
          }).toList(),
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

  DataCell _buildDataCell(String value) {
    return DataCell(
      Text(
        value,
        style: TextStyle(fontSize: 12),
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
            return _dropdownMaterial.where((word) => word
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) {
            setState(() {
              _selectedValueMaterial = selection;
              _txtMaterialDropDown.text =
                  selection; // Update controller when an item is selected
              _loadMaterialInfo(
                  _selectedValueWorkType.toString(),
                  _selectedValueCostCategory.toString(),
                  _selectedValueMaterial.toString());
            });
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              maxLength: 45,
              decoration: const InputDecoration(
                hintText: 'Cement',
                labelText: 'Estimation Item/Billed Name',
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
                  return 'Please select a work type';
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
