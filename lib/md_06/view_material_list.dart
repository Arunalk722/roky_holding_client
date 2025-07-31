import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/number_format.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/input_widget.dart';
import '../env/print_debug.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:roky_holding/env/platform_ind/csv_exporter.dart';

class ViewMaterialListPage extends StatefulWidget {
  final bool isEdit;
  const ViewMaterialListPage({super.key,required this.isEdit});

  @override
  ViewMaterialListPageState createState() =>
      ViewMaterialListPageState();
}

class ViewMaterialListPageState
    extends State<ViewMaterialListPage> {

  final _txtDropDownProject = TextEditingController();
  final _txtDropDownLocation = TextEditingController();
  bool isEditAlow=false;
  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dropDownWorkType();
      isEditAlow=widget.isEdit;
    });
  }

  String? selectedWorkType;
  List<String> workType = [];
  Future<void> _dropDownWorkType() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading');


      String reqUrl = '${APIHost().apiURL}/material_controller.php/MaterialWorkList';
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
        Navigator.pop(context);
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            workType = List<String>.from(
                (responseData['data'] ?? [])
                    .map((item) => item['work_name'].toString())
            );
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_material_list.dart');
      PD.pd(text: e.toString());
    }
  }


  String? selectedCategory;
  List<String> category = [];
  Future<void> _dropDownToCategory(String workName) async {
    category.clear();
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Category');

      String reqUrl = '${APIHost().apiURL}/material_controller.php/CostCategoryList';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"Authorization": APIToken().token,
          "work_name": workName}),
      );

      PD.pd(text: reqUrl);
      Navigator.pop(context);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            category = List<String>.from(
                (responseData['data'] ?? [])
                    .map((item) => item['cost_category'].toString())
            );
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_material_list.dart');
      PD.pd(text: e.toString());
    }
  }

  List<MaterialListItem> _activeMaterialList = [];

  Future<void> _loadworkTypeLocationEstimationList() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Loading');

      String reqUrl =
          '${APIHost().apiURL}/material_controller.php/ListCategoryWiseMaterial';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "work_name": selectedWorkType,
          "cost_category": selectedCategory
        }),
      );

      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          setState(() {
            _activeMaterialList = (responseData['data'] as List)
                .map((item) => MaterialListItem.fromJson(item))
                .toList();
          });
        } else {
          throw Exception(
              responseData['message'] ?? 'Error fetching materials');
        }
      } else {

        throw Exception("HTTP Error: ${response.statusCode}");
      }
    } catch (e,st) {

      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_material_list.dart');
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
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appname: 'Material Lists Info'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white60],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                ExpansionTile(title:const
               Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_alt_rounded,
                          color: Colors.deepPurple, size: 28),
                      const SizedBox(width: 10),
                      const Text(
                        "Filter Options",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                children: [
                  const SizedBox(height: 10),
                  CustomDropdown(
                    label: 'Work Type',
                    suggestions: workType,
                    icon: Icons.category_sharp,
                    controller: _txtDropDownProject,
                    onChanged: (value) {
                      selectedWorkType = value;
                      _dropDownToCategory(value.toString());
                    },
                  ),
                  const SizedBox(height: 10),
                  CustomDropdown(
                    label: 'Category',
                    suggestions: category,
                    icon: Icons.category_sharp,
                    controller: _txtDropDownLocation,
                    onChanged: (value) {
                      selectedCategory = value;

                    },
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        _loadworkTypeLocationEstimationList();

                      },
                      child: const Text("View Report"),
                    ),
                  ),],
                ),

                buildTable(),
              ],
            ),
          ),
        ),
      ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_activeMaterialList.isNotEmpty) {
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                ),
                builder: (context) {
                  return Wrap(
                    children: [
                      ListTile(
                          leading: Icon(Icons.file_download, color: Colors.blue),
                          title: Text('Export CSV'),
                          onTap: () {
                            Navigator.pop(context); // Close the sheet
                            exportToCSV(context ,_activeMaterialList);
                          },
                        ),
                      ListTile(
                        leading: Icon(Icons.print, color: Colors.green),
                        title: Text('Print PDF'),
                        onTap: () {
                           _exportAndPrintPdf();
                        },
                      ),
                    ],
                  );
                },
              );
            } else {
              OneBtnDialog.oneButtonDialog(
                context,
                title: 'No Data',
                message: 'No Data to export',
                btnName: 'Ok',
                icon: Icons.warning_rounded,
                iconColor: Colors.red,
                btnColor: Colors.black,
              );
            }
          },
          tooltip: 'Export Options',
          child: const Icon(FontAwesomeIcons.fileExport),)

    );
  }

  Widget buildDropdown(String label, List<String> items, String? selectedItem, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            value: selectedItem,
            onChanged: onChanged,
            hint: const Text("Select an option"),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              );
            }).toList(),
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black),
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
          ),
        ),
      ],
    );
  }

  Widget buildTable() {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final minTableWidth = 1024.0;

    // Group materials by work type and cost category
    final groupedMaterials = <String, Map<String, List<MaterialListItem>>>{};

    for (var material in _activeMaterialList) {
      final workTypeKey = material.workName;
      final categoryKey = material.costCategory;

      groupedMaterials.putIfAbsent(workTypeKey, () => {});
      groupedMaterials[workTypeKey]!.putIfAbsent(categoryKey, () => []);
      groupedMaterials[workTypeKey]![categoryKey]!.add(material);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: screenWidth < minTableWidth
                    ? minTableWidth
                    : screenWidth,
              ),
              child: Table(
                border: TableBorder.all(
                  color: Colors.grey[300]!,
                  width: 1,
                  borderRadius: BorderRadius.circular(12),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(3), // Material Description
                  1: FlexColumnWidth(1.5), // Quantity
                  2: FlexColumnWidth(2), // Unit Amount
                  3: FlexColumnWidth(2), // Created Date
                },
                children: [
                  // Table Header
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blue[600]),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text("Material Description",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text("Quantity",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text("Unit Amount",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text("Created Date",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ],
                  ),

                  // Grouped Rows
                  for (var workType in groupedMaterials.keys)
                    for (var category in groupedMaterials[workType]!.keys)
                      ...[
                        // Group Header Row
                        TableRow(
                          decoration: BoxDecoration(color: Colors.blue[50]),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                '$workType - $category',
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(),
                            const SizedBox(),
                            const SizedBox(),
                          ],
                        ),

                        // Item Rows
                        for (var material in groupedMaterials[workType]![category]!)
                          TableRow(
                            decoration: BoxDecoration(
                              color: groupedMaterials[workType]![category]!
                                  .indexOf(material) %
                                  2 ==
                                  0
                                  ? Colors.white
                                  : Colors.grey[50],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  material.materialName,
                                  style: TextStyle(
                                      color: Colors.grey[800], fontSize: 14),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  '${NumberStyles.qtyStyle(
                                      material.qty)} ${material.uom}',
                                  style: TextStyle(
                                      color: Colors.grey[800], fontSize: 14),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  NumberStyles.currencyStyle(material.amount),
                                  style: TextStyle(
                                      color: Colors.grey[800], fontSize: 14),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  '${material.createdBy}\n${material
                                      .createdDate}',
                                  style: TextStyle(
                                      color: Colors.grey[800], fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                      ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Future<void> exportToCSV(BuildContext context, List<MaterialListItem> materials) async {
    try {
      // Define headers for the CSV
      List<List<String>> rows = [
        [
          "#",
          "Work Name",
          "Cost Category",
          "Material Description",
          "Quantity",
          "UOM",
          "Unit Amount",
          "Created By",
          "Created Date"
        ],
      ];

      // Populate data rows
      for (var estimation in materials) {
        rows.add([
          estimation.idtblMaterialList,
          estimation.workName,
          estimation.costCategory,
          estimation.materialName,
          NumberStyles.qtyStyle(estimation.qty),
          NumberStyles.qtyStyle(estimation.uom),
          NumberStyles.currencyStyle(estimation.amount),
          estimation.createdBy,
          estimation.createdDate,
        ]);
      }

      await MobileCSVExporter.export(
        context: context,
        headersAndRows: rows,
        fileNamePrefix: 'material list $selectedWorkType $selectedCategory',
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("CSV exported successfully.")),
          );
        },
        onError: (e, st) {
          debugPrint('CSV Export Error: $e\n$st');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to export CSV.")),
          );
        },
      );
  } catch (e,st) {
  ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_project_wise_request_list.dart');
  PD.pd(text: e.toString());
  OneBtnDialog.oneButtonDialog(
  context,
  title: "Error",
  message: "Failed to export CSV: $e",
  btnName: 'OK',
  icon: Icons.error,
  iconColor: Colors.red,
  btnColor: Colors.black,
  );
}
}
  Future<pw.Document> generateEstimationPdf(List<MaterialListItem> estimationList,String projectName,String locationName,) async {
    final pdf = pw.Document();
    final printedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // Load Unicode Fonts
    final fontData = await rootBundle.load("assets/fonts/iskpota.ttf");
    final ttf = pw.Font.ttf(fontData);
    // final boldFontData = await rootBundle.load("assets/fonts/iskpotab.ttf");
    // final ttfB = pw.Font.ttf(boldFontData);

    // Load images (replace with actual asset paths)
    final footerLogo = pw.MemoryImage(
      (await rootBundle.load('assets/image/HBiz.jpg')).buffer.asUint8List(),
    );

    final headerLogo = pw.MemoryImage(
      (await rootBundle.load('assets/image/logo.png')).buffer.asUint8List(),
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
              pw.Container(
                width: 30,
                height: 30,
                child: pw.Image(footerLogo),
              ),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Software by Hela Software Solution',
                    style: pw.TextStyle(fontSize: 10, font: ttf, fontStyle: pw.FontStyle.italic),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Contact: +94 70 157 3582',
                    style: pw.TextStyle(fontSize: 9, font: ttf),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Website: www.helasoftsolution.com',
                    style: pw.TextStyle(fontSize: 9, font: ttf),
                  ),
                ],
              ),
            ],
          ),
        ),
        build: (pw.Context context) {
          // Calculate totals


          return [
            // Header with logo and title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  width: 80,
                  height: 80,
                  child: pw.Image(headerLogo),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Project Estimation Report',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, font: ttf),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Printed on: $printedDateTime',
                      style: pw.TextStyle(fontSize: 10, font: ttf, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Divider(),

            // Project and location info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Project: $projectName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: ttf)),
                pw.Text('Location: $locationName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: ttf)),
              ],
            ),
            pw.SizedBox(height: 20),

            // Estimation table
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey500),
              headerDecoration: pw.BoxDecoration(color: PdfColors.deepPurple),
              headerHeight: 30,
              cellHeight: 25,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, font: ttf),
              cellStyle: pw.TextStyle(fontSize: 10, font: ttf),
              cellAlignment: pw.Alignment.centerLeft,
              headers: [
                'Work',
                'Cost Category',
                'Material Name',
                'Qty',
                'Unit Cost (LKR)'
              ],
              data: estimationList.map((estimation) {
                return [
                  estimation.workName,
                  estimation.costCategory,
                  estimation.materialName,
                  estimation.qty,
                  NumberFormat('#,###.00', 'en_US').format(double.tryParse(estimation.amount))

                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            // Summary totals


            // Footer copyright
            pw.Center(
              child: pw.Text(
                '© ${DateTime.now().year} Hela Software Solution',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, font: ttf),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }


  Future<void> _exportAndPrintPdf() async {
    try {
      if (selectedWorkType == null || selectedCategory == null) {
        throw Exception("Please select project and location first");
      }

      if (_activeMaterialList.isEmpty) {
        throw Exception("No estimation data to export");
      }

      WaitDialog.showWaitDialog(context, message: 'Generating PDF');

      final pdf = await generateEstimationPdf(
        _activeMaterialList,
        selectedWorkType!,
        selectedCategory!,
      );

      WaitDialog.hideDialog(context);

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_material_list.dart');
      WaitDialog.hideDialog(context);
      OneBtnDialog.oneButtonDialog(
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
class MaterialListItem {
  final String uom;
  final String qty;
  final String amount;
  final bool isEditAllowed;
  final String idtblMaterialList;
  final String idtblMaterialCostCategory;
  final String workTypeId;
  final String costCategory;
  final String createdDate;
  final String createdBy;
  final String changeDate;
  final String changeBy;
  final bool isActive;
  final String workName;
  final String materialName;

  MaterialListItem({
    required this.uom,
    required this.qty,
    required this.amount,
    required this.isEditAllowed,
    required this.idtblMaterialList,
    required this.idtblMaterialCostCategory,
    required this.workTypeId,
    required this.costCategory,
    required this.createdDate,
    required this.createdBy,
    required this.changeDate,
    required this.changeBy,
    required this.isActive,
    required this.workName,
    required this.materialName,
  });

  factory MaterialListItem.fromJson(Map<String, dynamic> json) {
    return MaterialListItem(
      uom: json['uom'],
      qty: json['qty'].toString(),
      amount: json['amount'].toString(),
      isEditAllowed: json['is_edit_allow'] == 1,
      idtblMaterialList: json['idtbl_material_list'].toString(),
      idtblMaterialCostCategory: json['idtbl_material_cost_category'].toString(),
      workTypeId: json['work_type_id'].toString(),
      costCategory: json['cost_category'],
      createdDate: json['created_date'],
      createdBy: json['created_by'],
      changeDate: json['change_date'],
      changeBy: json['change_by'],
      isActive: json['is_active'] == 1,
      workName: json['work_name'],
      materialName: json['material_name'],
    );
  }
}


