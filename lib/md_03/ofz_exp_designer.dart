import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/user_data.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';

class OfzExpAndTaskDesigner extends StatefulWidget {
  const OfzExpAndTaskDesigner({super.key});

  @override
  State<OfzExpAndTaskDesigner> createState() => OfzExpAndTaskDesignerState();
}

class OfzExpAndTaskDesignerState extends State<OfzExpAndTaskDesigner> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _txtMainCategoryType = TextEditingController();
  final TextEditingController _txtSubCategoryType = TextEditingController();
  final TextEditingController _txtItemName= TextEditingController();

  Future<void> _createMainCategory() async {
    // Add BuildContext
    try {

      String reqUrl = '${APIHost().apiURL}/ofz_payment_controller.php/InsertMainCategory';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "main_name": _txtMainCategoryType.text
        }),
      );

      PD.pd(text: "Response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final int status = responseData['status'];
          _loadActiveMainCategory();
          if (status == 200) {
            PD.pd(text: responseData.toString());
            OneBtnDialog.oneButtonDialog(context,
                title: "Successful",
                message: responseData['message'],
                btnName: 'Ok',
                icon: Icons.verified_outlined,
                iconColor: Colors.black,
                btnColor: Colors.green);
            _loadActiveSubCategory(_txtMainCategoryType.text);
            itemList.clear();
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
          ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'ofz_exp_designer.dart');
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

        String errorMessage =
            'Material creating failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e,st) {
            ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'ofz_exp_designer.dart');
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'ofz_exp_designer.dart');

      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
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
  }
  Future<void> _createSubCategory() async {
    // Add BuildContext
    try {
      String reqUrl = '${APIHost().apiURL}/ofz_payment_controller.php/InsertSubCategory';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "main_name": _txtMainCategoryType.text,
          "sub_name": _txtSubCategoryType.text
        }),
      );
      
      PD.pd(text: "Response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final int status = responseData['status'];

          if (status == 200) {
            _loadItemList();
            itemList.clear();
            PD.pd(text: responseData.toString());
            OneBtnDialog.oneButtonDialog(context,
                title: "Successful",
                message: responseData['message'],
                btnName: 'Ok',
                icon: Icons.verified_outlined,
                iconColor: Colors.black,
                btnColor: Colors.green);
            _loadActiveSubCategory(_selectedMainCategoryType);
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
          ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'ofz_exp_designer.dart');
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

        String errorMessage =
            'Material creating failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e,st) {
            ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'ofz_exp_designer.dart');
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'ofz_exp_designer.dart');

      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
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
  }
  Future<void> _createdItem() async {
    // Add BuildContext
    try {

      String reqUrl = '${APIHost().apiURL}/ofz_payment_controller.php/InsertMaterialItem';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "main_name": _selectedMainCategoryType,
          "sub_name": _txtSubCategoryType.text,
          "item_name":_txtItemName.text,
          "created_by":UserCredentials().UserName
        }),
      );
      
      PD.pd(text: "Response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
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
            _loadActiveSubCategory(_selectedMainCategoryType);
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
          ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'ofz_exp_designer.dart');
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

        String errorMessage =
            'Material creating failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e,st) {
            ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'ofz_exp_designer.dart');
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'ofz_exp_designer.dart');

      String errorMessage = 'An error occurred: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
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
  }
  
  bool _isLoadingMainCategory = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //methoord
      _loadActiveMainCategory();
    });

  }
  List<dynamic> _activeMainCategoryListMap = [];
  String? _selectedMainCategoryType;
  List<String> mainCategory = [];
  Future<void> _loadActiveMainCategory() async {
    setState(() {
      _isLoadingMainCategory = true;
    });
    try {
      String reqUrl = '${APIHost().apiURL}/ofz_payment_controller.php/GetMainCategory';
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
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            _activeMainCategoryListMap = responseData['data'] ?? [];
            mainCategory = _activeMainCategoryListMap
                .map<String>((item) => item['main_name'].toString())
                .toList();
          });
        } else {
          final String message = responseData['message'] ?? 'Error';
        }
      } else {

      }
    } finally {
      setState(() {
        _isLoadingMainCategory = false;
      });
    }
  }



  List<dynamic> _activeSubCategoryListMap = [];
  String? _selectedValueSubCategory;
  List<String> subCategories = [];
  Future<void> _loadActiveSubCategory(String? mainName) async {
    subCategories.clear();
    try {
      
      String reqUrl ='${APIHost().apiURL}/ofz_payment_controller.php/GetSubCategory';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "main_name": mainName,
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            _activeSubCategoryListMap = responseData['data'] ?? [];
            subCategories = _activeSubCategoryListMap
                .map<String>((item) => item['sub_name'].toString())
                .toList();
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
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'ofz_exp_designer.dart');
      PD.pd(text: e.toString());
    }
  }



  List<dynamic> _activeItemListMap = [];
  String? _selectedValueItemList;
  List<String> itemList = [];
  Future<void> _loadItemList() async {
    itemList.clear();
    try {

      String reqUrl ='${APIHost().apiURL}/ofz_payment_controller.php/GetMaterialItem';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "main_name": _selectedMainCategoryType,
          "sub_name": _selectedValueSubCategory,
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            _activeItemListMap = responseData['data'] ?? [];
            itemList = _activeItemListMap
                .map<String>((item) => item['item_name'].toString())
                .toList();
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
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'ofz_exp_designer.dart');
      PD.pd(text: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appname: 'Office Expense & Task Designer'),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Manage Office Request Items',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildWorkTypeSection(),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildCategorySection(),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [Expanded(child:  _buildItemSection())],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildWorkTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Main Category',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 10),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _selectedMainCategoryType ?? ''),
          optionsBuilder: (textEditingValue) {
            final input = textEditingValue.text.toLowerCase();
            return mainCategory.where(
                  (word) => word.toLowerCase().contains(input),
            );
          },
          onSelected: (selection) {
            setState(() {
              _selectedMainCategoryType = selection;
              _txtMainCategoryType.text = selection;
              _loadActiveSubCategory(_selectedMainCategoryType);
            });
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              maxLength: 45,
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Work Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _txtMainCategoryType.text = value;
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
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: () {
              if (_txtMainCategoryType.text.length > 1) {
                if (!mainCategory.contains(_txtMainCategoryType.text)) {
                  YNDialogCon.ynDialogMessage(
                    context,
                    messageBody: 'Confirm to create Main Category ${_txtMainCategoryType.text}',
                    messageTitle: 'Work Type Creating',
                    icon: Icons.verified_outlined,
                    iconColor: Colors.black,
                    btnDone: 'YES',
                    btnClose: 'NO',
                  ).then((value) async {
                    if (value == 1) {
                      await _createMainCategory();
                    }
                  });
                } else {
                  _loadActiveSubCategory(_txtMainCategoryType.text);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
              shadowColor: Colors.green.shade700,
            ),
            child: const Text(
              'Create Main Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Sub Category',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 10),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _selectedValueSubCategory ?? ''),
          optionsBuilder: (textEditingValue) {
            final input = textEditingValue.text.toLowerCase();
            return subCategories.where(
                  (category) => category.toLowerCase().contains(input),
            );
          },
          onSelected: (selection) {
            setState(() {
              _selectedValueSubCategory = selection;
              _txtSubCategoryType.text = selection;
              _loadItemList();
            });
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              maxLength: 45,
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Cost Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _txtSubCategoryType.text = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a cost category';
                }
                return null;
              },
            );
          },
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: () {
              if (_selectedMainCategoryType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a Main Category first.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (_txtSubCategoryType.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a Sub Category.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                if (!subCategories.contains(_txtSubCategoryType.text)) {
                  YNDialogCon.ynDialogMessage(
                    context,
                    messageBody: 'Confirm to create Sub Category ${_txtSubCategoryType.text} under Main Category Type $_selectedMainCategoryType',
                    messageTitle: 'Cost Category Creating',
                    icon: Icons.verified_outlined,
                    iconColor: Colors.black,
                    btnDone: 'YES',
                    btnClose: 'NO',
                  ).then((value) async {
                    if (value == 1) {
                      await _createSubCategory();
                    }
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sub Category already exists'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
              shadowColor: Colors.green.shade700,
            ),
            child: const Text(
              'Create Sub Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildItemSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Selection',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 10),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _selectedValueItemList ?? ''),
          optionsBuilder: (textEditingValue) {
            final input = textEditingValue.text.toLowerCase();
            return itemList.where(
                  (category) => category.toLowerCase().contains(input),
            );
          },
          onSelected: (selection) {
            setState(() {
              _selectedValueItemList = selection;
              _txtItemName.text = selection;
            });
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              maxLength: 45,
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Item List',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _txtItemName.text = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a Item';
                }
                return null;
              },
            );
          },
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: () {
              print(_txtItemName.text);

              if (_selectedMainCategoryType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a Main Category first.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (_txtSubCategoryType.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please Select a Sub Category.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              else if (_txtItemName.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a Item Name.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }else {
                if (!itemList.contains(_txtSubCategoryType.text)) {
                  YNDialogCon.ynDialogMessage(
                    context,
                    messageBody: 'Confirm to create Items sub Category ${_txtSubCategoryType.text} under Main Category Type $_selectedMainCategoryType',
                    messageTitle: 'Cost Category Creating',
                    icon: Icons.verified_outlined,
                    iconColor: Colors.black,
                    btnDone: 'YES',
                    btnClose: 'NO',
                  ).then((value) async {
                    if (value == 1) {
                      await _createdItem();
                    }
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item already exists'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
              shadowColor: Colors.green.shade700,
            ),
            child: const Text(
              'Create Item',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
