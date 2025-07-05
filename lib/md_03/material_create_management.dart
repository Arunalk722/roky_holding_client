import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/user_data.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/custome_icon.dart';
import '../env/input_widget.dart';
import '../env/print_debug.dart';
import 'material_editing_dialog.dart';

class MaterialCreate extends StatefulWidget {
  const MaterialCreate({super.key});

  @override
  State<MaterialCreate> createState() => _MaterialCreateState();
}

class _MaterialCreateState extends State<MaterialCreate> {
//
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActiveWorkList();
    });
  }

  //work list
  final List<dynamic> _activeWorksList = [];
  List<dynamic> _activeWorkListMap = [];
  bool _isLoadingWorksList = false;
  String? _selectedValueWorkType;
  String? _selectedUnit;
  List<String> _dropdownWorkType = [];
  Future<void> _loadActiveWorkList() async {
    setState(() {
      _isLoadingWorksList = true;
    });
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading works');

      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        return;
      }

      String reqUrl =
          '${APIHost().apiURL}/material_controller.php/MaterialWorkList';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": token}),
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
        //  PD.pd(text: message);
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'material_create_management.dart');
      PD.pd(text: e.toString());
    } finally {
      setState(() {
        _isLoadingWorksList = false;
      });

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }


  //active cost list
  final List<dynamic> _activeCostList = [];
  List<dynamic> _activeCostListMap = [];
  bool _isLoadingCostList=false;
  String? _selectedValueCostCategory;
  List<String> _dropdownCostCategory = [];
  Future<void> _loadActiveCostList(String? workName) async {
    setState(() {
      _isLoadingCostList = true;
    });
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Category');

      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        return;
      }

      String reqUrl =
          '${APIHost().apiURL}/material_controller.php/CostCategoryList';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": token,
          "work_name":workName,
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
        //  PD.pd(text: message);
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'material_create_management.dart');
      PD.pd(text: e.toString());
    } finally {
      setState(() {
        _isLoadingCostList = false;
      });

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  final List<String> _dropDownSIUnit = [
    'Nos' , 'Mts','Ltr', 'Psum' , 'Cube' , 'Days' , 'LFeet', 'SqFt' , 'Kg','Km','Grm'];



  //list of materials
  final List<dynamic> _activeMaterialList = [];
  List<dynamic> _activeMaterialListMap = [];
  bool _isLoadingMaterials = false;
  String? _selectedMaterial;

  List<String> materialList = [];

  Future<void> _loadMaterials(String? workName,String? costCategory) async {
    setState(() {
      _isLoadingMaterials = true;
    });
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Material');

      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        return;
      }

      String reqUrl =
          '${APIHost().apiURL}/material_controller.php/ListCategoryWiseMaterial';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": token,
          "work_name":workName,
          "cost_category":costCategory
        }),
      );

      PD.pd(text: reqUrl);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _activeMaterialListMap = responseData['data'] ?? [];
            _activeMaterialList.clear();
            _activeMaterialList.addAll(_activeMaterialListMap);
             materialList=_activeMaterialListMap
                 .map<String>((item) => item['material_name'].toString())
                .toList();
           PD.pd(text: _activeMaterialListMap.toString());
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'material_create_management.dart');
      PD.pd(text: e.toString());
    } finally {
      setState(() {
        _isLoadingMaterials = false;
      });

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _deleteMaterial(BuildContext context, int materialId) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Deleting');
      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        PD.pd(text: "Authentication token is missing.");
        return;
      }
    String reqUrl='${APIHost().apiURL}/material_controller.php/DeleteMaterialById';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": token,
          "idtbl_material_list": materialId,
        }),
      );
      WaitDialog.hideDialog(context);
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 200) {
        OneBtnDialog.oneButtonDialog(context,
            title: "Successful",
            message: responseData['message'],
            btnName: 'Ok',
            icon: Icons.verified_outlined,
            iconColor: Colors.black,
            btnColor: Colors.green);
            _loadMaterials(_selectedValueWorkType.toString(), _selectedValueCostCategory.toString());
      } else {
        OneBtnDialog.oneButtonDialog(context,
            title: 'Error',
            message: responseData['message'] ?? 'Update failed',
            btnName: 'OK',
            icon: Icons.error,
            iconColor: Colors.red,
            btnColor: Colors.black);
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'material_create_management.dart');
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

  bool _allowUserToEdit=false;

  final _costTypeDropdownController = TextEditingController();
  final _costCategoryDropDownController = TextEditingController();

  final _txtUnit = TextEditingController();
  final TextEditingController _txtMaterialName = TextEditingController();
  final TextEditingController _txtMaterialCost= TextEditingController();
  final TextEditingController _txtQty= TextEditingController();
  void _clearText(){
    _allowUserToEdit=false;
    _txtMaterialCost.text='';
    _txtQty.text='';
    _txtMaterialName.text='';
    //_costCategoryDropDownController.text='';
   // _costTypeDropdownController.text='';
    setState(() {
    });
  }

  Future<void> createMaterials(BuildContext context) async {
    // Add BuildContext
    try {
      WaitDialog.showWaitDialog(context, message: 'Item Creating');
      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        PD.pd(text: "Authentication token is missing.");
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

      PD.pd(text: "Token: $token");
      String reqUrl = '${APIHost().apiURL}/material_controller.php/CreateMaterial';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "work_name": _selectedValueWorkType,
          "cost_category": _selectedValueCostCategory,
          "material_name":_txtMaterialName.text,
          "qty": _txtQty.text.replaceAll(',', ''),
          "amount": _txtMaterialCost.text.replaceAll(',', ''),
          "created_by": UserCredentials().UserName,
          "is_edit_allow": _allowUserToEdit==true?1:0,
          "uom" : _txtUnit.text
        }),
      );

      PD.pd(text: "Response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final int status = responseData['status'];

          if (status == 200) {
            PD.pd(text: responseData.toString());
            OneBtnDialog.oneButtonDialog(context,
                title: "Successful",
                message: responseData['message'],
                btnName: 'Ok',
                icon: Icons.verified_outlined,
                iconColor: Colors.black,
                btnColor: Colors.green);
            _clearText();
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
          ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'material_create_management.dart');
          PD.pd(
              text: "Error decoding JSON: $e, Body: ${response.body}"); // Debug
          ExceptionDialog.exceptionDialog(
            context,
            title: 'JSON Error',
            message: "Error decoding JSON response: $e",
            btnName: 'OK',
            icon: Icons.error,
            iconColor: Colors.red,
            btnColor: Colors.black,
          );
        }
      } else {
        WaitDialog.hideDialog(context);
        String errorMessage =
            'Material creating failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e,st) {
            ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'material_create_management.dart');
            errorMessage = response.body;
          }
        }
        PD.pd(text: errorMessage);
        ExceptionDialog.exceptionDialog(
          context,
          title: 'HTTP Error',
          message: errorMessage,
          btnName: 'OK',
          icon: Icons.error,
          iconColor: Colors.red,
          btnColor: Colors.black,
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'material_create_management.dart');
      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      WaitDialog.hideDialog(context);
      PD.pd(text: errorMessage);
      ExceptionDialog.exceptionDialog(
        context,
        title: 'General Error',
        message: errorMessage,
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
    }
    _loadMaterials(_selectedValueWorkType.toString(), _selectedValueCostCategory.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(appname: 'Material/Billing Items Management'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double a = constraints.maxWidth;
          bool isWideScreen = constraints.maxWidth > 740; // Check screen width
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: isWideScreen
                ? Row(
              // Two columns if screen is wide
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCreateLocationForm()),
                const SizedBox(width: 20), // Spacing between columns
                Expanded(child: _buildActiveLocationCostListCard()),
              ],
            )
                : Column(
              // Stack in a single column if screen is narrow
              children: [
                _buildCreateLocationForm(),
                const SizedBox(height: 20), // Spacing between sections
                _buildActiveLocationCostListCard(),
              ],
            ),
          );
        },
      ),
    );
  }
  Widget _buildCreateLocationForm() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: 400, // Keep max width limited
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Center(
                    child: Text(
                      'Create a Billing Items',
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
                      label: 'Main Category',
                      suggestions: _dropdownWorkType,
                      icon: Icons.category_sharp,
                      controller: _costTypeDropdownController,
                      onChanged: (value) {
                        _selectedValueWorkType = value;
                        _loadActiveCostList(value);
                        setState(() {

                        });
                      },
                    ),
                       CustomDropdown(
                            label: 'Select Sub/Cost Category',
                            suggestions: _dropdownCostCategory,
                            icon: Icons.celebration,
                            controller: _costCategoryDropDownController,
                            onChanged: (value) {
                              _selectedValueCostCategory = value;
                              PD.pd(text: _selectedValueWorkType.toString());

                              _loadMaterials(_selectedValueWorkType.toString(),
                                  _selectedValueCostCategory.toString());
                            },
                          ),
                    _buildMaterialSection(),



                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: buildNumberField(
                              _txtQty,
                              'Qty',
                              '1',
                              Icons.numbers,
                              true,
                              5
                          ),
                        ),
                        SizedBox(width: 10), // Space between fields
                        Expanded(flex: 4,
                            child: buildNumberField(
                              _txtMaterialCost,
                              'Billing Item Cost',
                              '1500',
                                LKRIcon(),
                              true,
                              10)
                        ),
                      ],
                    ),
                    Row(
                      children: [Expanded
                        (flex: 3,
                        child
                          : CustomDropdown(
                        label: 'Select Unit',
                        suggestions: _dropDownSIUnit,
                        icon: Icons.straighten,
                        controller: _txtUnit,
                        onChanged: (value) {
                          _selectedUnit = value;
                          PD.pd(text: _selectedUnit.toString());

                        },
                      ),),Expanded(flex: 5,child:  _buildCheckboxes(),)],
                    )
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
  Widget _buildCheckboxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Checkbox(
                value: _allowUserToEdit,
                onChanged: (bool? newValue) {
                  setState(() {
                    _allowUserToEdit = newValue ?? false;
                  });
                },
                activeColor: Colors.blueAccent,
              ),
              const Text('Allow User to edit price'),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {

          YNDialogCon.ynDialogMessage(
            context,
            messageBody: 'Confirm to create a new Material',
            messageTitle: 'Material Creating',
            icon: Icons.verified_outlined,
            iconColor: Colors.black,
            btnDone: 'YES',
            btnClose: 'NO',
          ).then((value) async {
            if (value == 1) {
               await createMaterials(context);
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
      child: const Text('Create Material'),
    );
  }
  Widget _buildActiveLocationCostListCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Active Billing Items",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildActiveMaterialList(),
          ],
        ),
      ),
    );
  }
  Widget _buildActiveMaterialList() {
    if (_isLoadingMaterials) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeMaterialListMap.isEmpty) {
      return const Center(
        child: Text('No active Billing Items found.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
      child: DataTable(
        border: TableBorder.all(width: 1, color: Colors.grey),
        columnSpacing: 12, // Adjust column spacing
        headingRowHeight: 40, // Header row height
        dataRowMinHeight: 35, // Minimum row height
        dataRowMaxHeight: 50, // Maximum row height
        columns: const [
          DataColumn(label: Text('Billing Name', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Main Category', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Amount LKR', style: TextStyle(fontWeight: FontWeight.bold))),
          //DataColumn(label: Text('Visibility', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Delete', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _activeMaterialListMap.map<DataRow>((material) {
          return DataRow(
            cells: [
              DataCell(Text(material['material_name'] ?? 'Unknown')),
              DataCell(Text(material['work_name'] ?? 'Unknown')),
              DataCell(Text('${material['qty']} ${material['uom'] ?? ''}')),
              DataCell(Text(NumberFormat('#,###.00', 'en_US').format(double.tryParse(material['amount']) ?? 0))),
              // DataCell(
              //   IconButton(
              //     icon: Icon(material['is_active'] == 1
              //         ? Icons.visibility
              //         : Icons.visibility_off_outlined),
              //     color: material['is_active'] == 1 ? Colors.blue : Colors.red,
              //     onPressed: () {
              //       PD.pd(text: "Toggled visibility for: ${material['material_name']}");
              //     },
              //   ),
              // ),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => MaterialUpdateDialog(
                        itemId: material['idtbl_material_list'],

                      ),
                    );

                  },
                ),

              ),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  onPressed: () {

                    YNDialogCon.ynDialogMessage(
                      context,
                      messageBody: 'Would you like to delete this material.this process cannot undo',
                      messageTitle: 'deleting material',
                      icon: Icons.verified_outlined,
                      iconColor: Colors.black,
                      btnDone: 'YES',
                      btnClose: 'NO',
                    ).then((value) async {
                      if (value == 1) {
                        await _deleteMaterial(
                            context,
                            material['idtbl_material_list']
                        );
                      }
                    });

                  },
                ),

              ),
            ],
          );
        }).toList(),
      ),
    );
  }
  Widget _buildMaterialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _selectedMaterial ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) {
            // Filter workTypes based on user input
            return materialList.where((word) =>
                word.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) {
            setState(() {
              _selectedMaterial = selection;
              _txtMaterialName.text = selection; // Update controller when an item is selected
              _loadActiveCostList(_selectedMaterial);
            });
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              maxLength: 45,
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'Cement',
                labelText: 'Items Creating',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _txtMaterialName.text = value;
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