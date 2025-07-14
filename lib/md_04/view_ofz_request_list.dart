import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:roky_holding/env/DialogBoxs.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/print_debug.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/number_format.dart';
import '../env/sp_format_data.dart';
import '../env/user_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewOfzRequestList extends StatefulWidget {
  final String requestId;
  final isNotApprove;
  final String refNumber;
  const ViewOfzRequestList(
      {super.key, required this.requestId, required this.isNotApprove,required this.refNumber});

  @override
  State<ViewOfzRequestList> createState() =>
      _ViewOfzRequestListState();
}

class _ViewOfzRequestListState extends State<ViewOfzRequestList> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<PaymentRequest> _requests = [];
  List<RequestedItem> _requestedItems = [];

  bool _isLoading = true;
  String _errorMessage = '';
  bool isNotToApprove = true;
  bool isApproved = false;
  bool canDelete = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchRequestsById();
    });
  }

  Future<void> fetchRequestsById() async {
    _requests.clear();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    String reqUrl =
        '${APIHost().apiURL}/ofz_payment_controller.php/ListOfRequestById';
    PD.pd(text: reqUrl);
    try {
      WaitDialog.showWaitDialog(context,
          message:
          'loading request number ${RequestNumber.formatNumber(val: int.tryParse(widget.requestId.toString())??0)}');
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          'idtbl_ofz_request': widget.requestId.toString(),
          "req_ref_number":widget.refNumber.toString()
        }),
      );

      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          List<dynamic> data = responseData['data'];
          setState(() {
            _requests =
                data.map((json) => PaymentRequest.fromJson(json)).toList();
            getDataRequestMaterialList();
            isApproved = data.any((item) {
              return item['is_appro'] == 0 && item['is_auth'] == 0;
            });
            canDelete=data.any((item){
              return item['is_appro'] != 1 && item['is_auth'] != 1;
            });
            _isLoading = false;
            // PD.pd(text: isApproved.toString());
          });
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Error loading requests';
            _isLoading = false;
          });
        }
      } else {
        WaitDialog.hideDialog(context);
        setState(() {
          _errorMessage = 'HTTP Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_ofz_request_list.dart');
      WaitDialog.hideDialog(context);
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      PD.pd(text: e.toString());
    }
  }

  Future<void> getDataRequestMaterialList() async {
    String apiURL =
        '${APIHost().apiURL}/ofz_payment_controller.php/RequestedListOfItem';
    PD.pd(text: apiURL);
    try {
      WaitDialog.showWaitDialog(context,
          message:
          'loading material list');
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          'ofz_request_id': widget.requestId,
          "req_ref_number":widget.refNumber
        }),
      );

      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          List<dynamic> data = responseData['data'];
          setState(() {
            _requestedItems =
                data.map((json) => RequestedItem.fromJson(json)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Error loading requests';
            _isLoading = false;
          });
        }
      } else {
        WaitDialog.hideDialog(context);
        setState(() {
          _errorMessage = 'HTTP Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_ofz_request_list.dart');
      WaitDialog.hideDialog(context);
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      PD.pd(text: e.toString());
    }
  }

  List<ImagesList> _imagesLists = [];
  Future<void> viewImages(String refnum) async {
    if (!mounted) return; // Check if the widget is still mounted

    setState(() {
      _isLoading = true;
      _errorMessage = '';
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
          'req_ref_number': refnum,
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

          // Show the images dialog only if there are images
          if (_imagesLists.isNotEmpty && mounted) {
            _showImagesDialog(_scaffoldKey.currentContext!);
          } else {
            ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
              SnackBar(
                content: Text('No images found for this request.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Error loading images';
            _isLoading = false;
          });
        }
      } else {
        WaitDialog.hideDialog(context);
        setState(() {
          _errorMessage = 'HTTP Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_ofz_request_list.dart');
      if (!mounted) return; // Check again after the async operation
      WaitDialog.hideDialog(context);
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      PD.pd(text: e.toString());
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    String apiURL =
        '${APIHost().apiURL}/project_payment_controller.php/ImageDeleteFromUrl';
    PD.pd(text: apiURL);
    try {
      WaitDialog.showWaitDialog(context,
          message:
          'loading material list');
      final response = await http.delete(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          'image_url': imageUrl
        }),
      );
      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          OneBtnDialog.oneButtonDialog(context, title: 'Image Removed', message: responseData['message'], btnName: 'Ok', icon: Icons.verified, iconColor: Colors.green, btnColor: Colors.black);
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Error loading requests';
            _isLoading = false;
          });
        }
      } else {
        WaitDialog.hideDialog(context);
        setState(() {
          _errorMessage = 'HTTP Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_project_request_item_list.dart');
      WaitDialog.hideDialog(context);
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      PD.pd(text: e.toString());
    }
  }

  Future<Uint8List> generatePdf(List<PaymentRequest> paymentRequests, List<RequestedItem> requestedItems) async {
    final pdf = pw.Document();
    final firstRequest = paymentRequests.first;

    // Load fonts
    final fontData = await rootBundle.load("assets/fonts/iskpota.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load("assets/fonts/iskpotab.ttf");
    final ttfBold = pw.Font.ttf(boldFontData);

    // Create theme with custom fonts
    final theme = pw.ThemeData.withFont(
      base: ttf,
      bold: ttfBold,
    );

    // Group items by main category and subcategory for summary
    final Map<String, Map<String, double>> categoryTotals = {};
    for (var item in requestedItems) {
      final amount = double.tryParse(item.totalAmount.toString()) ?? 0;
      if (!categoryTotals.containsKey(item.mainCategory)) {
        categoryTotals[item.mainCategory] = {};
      }
      categoryTotals[item.mainCategory]!.update(
        item.subCategory,
            (value) => value + amount,
        ifAbsent: () => amount,
      );
    }

    // Calculate grand total

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a5,
        theme: theme,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return [
            // Header Section (keep existing)
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('IOU',
                      style: pw.TextStyle(
                          fontSize: 14,
                          font: ttfBold,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text('ROKY Holdings (Pvt) LTD',
                      style: pw.TextStyle(fontSize: 10, font: ttf)),
                  pw.SizedBox(height: 8),
                ],
              ),
            ),

            // IOU Number and Date (keep existing)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(3),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Text(
                      'IOU No: ${IOUNumber.iouNumber(val: firstRequest.iouNumber.toString()) ?? '000000'}',
                      style: pw.TextStyle(fontSize: 8, font: ttf)),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(3),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child:  pw.Text('Payment:  ${firstRequest.paymentType}',
                      style: pw.TextStyle(fontSize: 8, font: ttf)),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(3),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child:   pw.Text('No: ${firstRequest.refNum ?? ''}',
                      style: pw.TextStyle(fontSize: 8, font: ttf)),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(3),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Text('Paid Date: ${firstRequest.requestDate}',
                      style: pw.TextStyle(fontSize: 8, font: ttf)),
                ),
              ],
            ),

            // Request Details (keep existing)
            pw.SizedBox(height: 5),
            pw.Container(
              padding: const pw.EdgeInsets.all(3),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          'Payment Requested BY: ${firstRequest.createdBy ?? ''}',
                          style: pw.TextStyle(fontSize: 8, font: ttf)),
                      pw.Text(
                          'Requested Date & time: ${firstRequest.createTime ?? ''}',
                          style: pw.TextStyle(fontSize: 8, font: ttf)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Remarks: ${firstRequest.comment ?? ''}',
                          style: pw.TextStyle(fontSize: 8, font: ttf)),
                      pw.Text('Paid Account: ${firstRequest.ourAccountNumber ?? ''}',
                          style: pw.TextStyle(fontSize: 8, font: ttf)),
                    ],
                  ),
                ],
              ),
            ),

            // Beneficiary Details (keep existing)
            pw.SizedBox(height: 5),
            pw.Container(
              padding: const pw.EdgeInsets.all(3),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          'Beneficiary Name: ${firstRequest.receiverName ?? firstRequest.receiverName ?? ''}',
                          style: pw.TextStyle(fontSize: 8, font: ttf)),
                      pw.Text('Mobile no: ${firstRequest.receiverMobile ?? ''}',
                          style: pw.TextStyle(fontSize: 8, font: ttf)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          'Paid Amount: ${NumberStyles.currencyStyle((firstRequest.totalAmount+firstRequest.vat+firstRequest.sscl-firstRequest.addDis).toString())}',
                          style: pw.TextStyle(fontSize: 8, font: ttf)),
                    ],
                  ),
                ],
              ),
            ),

            // Payment Method Details (keep existing)
            pw.SizedBox(height: 5),
            pw.Container(
              padding: const pw.EdgeInsets.all(3),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          'A/C holder Name: ${firstRequest.beneficiaryName ?? ''}',
                          style: pw.TextStyle(fontSize: 8, font: ttf)),
                      pw.Text('Bank: ${firstRequest.bankName ?? ''}',
                          style: pw.TextStyle(fontSize: 8, font: ttf)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('A/C number: ${firstRequest.accountNumber ?? ''}',
                          style: pw.TextStyle(fontSize: 8, font: ttf)),
                      pw.Text('Branch: ${firstRequest.bankBranch ?? ''}',
                          style: pw.TextStyle(fontSize: 8, font: ttf)),
                    ],
                  ),
                ],
              ),
            ),

            // Approval Boxes (keep existing)
            pw.SizedBox(height: 5),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                buildApprovalBox(
                    'Authorized By',
                    firstRequest.authUser,
                    firstRequest.authTime,
                    firstRequest.authCmt,
                    ttf,
                    ttfBold),
                buildApprovalBox(
                    'Approved By',
                    firstRequest.approUser,
                    firstRequest.approTime,
                    firstRequest.approCmt,
                    ttf,
                    ttfBold),
                buildApprovalBox(
                    'Paid By',
                    firstRequest.pmtUser,
                    firstRequest.pmtTime,
                    firstRequest.pmtCmt,
                    ttf,
                    ttfBold),
              ],
            ),

            // Category Summary Section
            pw.SizedBox(height: 10),
            pw.Text('Category Summary',
                style: pw.TextStyle(
                    fontSize: 10,
                    font: ttfBold,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('Category',
                            style: pw.TextStyle(
                                fontSize: 8,
                                font: ttfBold,
                                fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('Amount',
                            style: pw.TextStyle(
                                fontSize: 8,
                                font: ttfBold,
                                fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                // Add grouped category items
                for (var mainCategory in categoryTotals.keys)
                  for (var subCategory in categoryTotals[mainCategory]!.keys)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text('$mainCategory - $subCategory',
                              style: pw.TextStyle(fontSize: 7, font: ttf)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text(
                            NumberStyles.currencyStyle(categoryTotals[mainCategory]![subCategory]!.toString()),
                            style: pw.TextStyle(fontSize: 7, font: ttf),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                // Grand Total row
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('GRAND TOTAL',
                          style: pw.TextStyle(
                              fontSize: 8,
                              font: ttfBold,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(
                        NumberStyles.currencyStyle(((firstRequest.totalAmount+firstRequest.vat+firstRequest.sscl-firstRequest.addDis).toString()).toString()),
                        style: pw.TextStyle(
                            fontSize: 8,
                            font: ttfBold,
                            fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Detailed Items Table (keep existing)
            // pw.SizedBox(height: 10),
            // pw.Text('Detailed Items',
            //     style: pw.TextStyle(
            //         fontSize: 10,
            //         font: ttfBold,
            //         fontWeight: pw.FontWeight.bold)),
            // pw.SizedBox(height: 5),
            // pw.Table(
            //   border: pw.TableBorder.all(),
            //   children: [
            //     pw.TableRow(
            //       decoration: pw.BoxDecoration(color: PdfColors.grey300),
            //       children: [
            //         pw.Padding(
            //             padding: const pw.EdgeInsets.all(3),
            //             child: pw.Text('Main category',
            //                 style: pw.TextStyle(
            //                     fontSize: 7,
            //                     font: ttfBold,
            //                     fontWeight: pw.FontWeight.bold))),
            //         pw.Padding(
            //             padding: const pw.EdgeInsets.all(3),
            //             child: pw.Text('Sub category',
            //                 style: pw.TextStyle(
            //                     fontSize: 7,
            //                     font: ttfBold,
            //                     fontWeight: pw.FontWeight.bold))),
            //         pw.Padding(
            //             padding: const pw.EdgeInsets.all(3),
            //             child: pw.Text('Amount',
            //                 style: pw.TextStyle(
            //                     fontSize: 7,
            //                     font: ttfBold,
            //                     fontWeight: pw.FontWeight.bold))),
            //       ],
            //     ),
            //     for (var item in requestedItems)
            //       pw.TableRow(
            //         children: [
            //           pw.Padding(
            //             padding: const pw.EdgeInsets.all(3),
            //             child: pw.Text(item.mainCategory ?? '',
            //                 style: pw.TextStyle(fontSize: 7, font: ttf)),
            //           ),
            //           pw.Padding(
            //             padding: const pw.EdgeInsets.all(3),
            //             child: pw.Text(item.subCategory ?? '',
            //                 style: pw.TextStyle(fontSize: 7, font: ttf)),
            //           ),
            //           pw.Padding(
            //             padding: const pw.EdgeInsets.all(3),
            //             child: pw.Text(
            //               NumberStyles.currencyStyle(item.totalAmount.toString()),
            //               style: pw.TextStyle(fontSize: 7, font: ttf),
            //               textAlign: pw.TextAlign.right,
            //             ),
            //           ),
            //         ],
            //       ),
            //   ],
            // ),

            // Footer (keep existing)
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Printed By: ${UserCredentials().UserName}',
                    style: pw.TextStyle(fontSize: 8, font: ttf)),
                pw.Text(
                    'Printed Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 8, font: ttf)),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget buildApprovalBox(
      String title,
      String? name,
      String? date,
      String? remark,
      pw.Font normalFont,
      pw.Font boldFont, {
        String? account}) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.all(2),
        padding: const pw.EdgeInsets.all(3),
        decoration: pw.BoxDecoration(border: pw.Border.all()),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 7,
                    font: boldFont,
                    fontWeight: pw.FontWeight.bold)),
            pw.Text('User: ${name ?? 'N/A'}',
                style: pw.TextStyle(fontSize: 6, font: normalFont)),
            pw.Text('Date & Time: ${date ?? 'N/A'}',
                style: pw.TextStyle(fontSize: 6, font: normalFont)),
            pw.Text('Remarks: ${remark ?? 'N/A'}',
                style: pw.TextStyle(fontSize: 6, font: normalFont)),
            if (account != null)
              pw.Text('Account: $account',
                  style: pw.TextStyle(fontSize: 6, font: normalFont)),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAndPrintPdf() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Generating PDF...');

      // Fetch data if needed
      await fetchRequestsById();

      // Generate PDF
      final pdfBytes = await generatePdf(_requests, _requestedItems);

      WaitDialog.hideDialog(context);

      // Print the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      WaitDialog.hideDialog(context);
      ExceptionDialog.exceptionDialog(
        context,
        title: 'Print Error',
        message: 'Failed to generate PDF: ${e.toString()}',
        btnName: 'OK',
        icon: Icons.error,
        iconColor: Colors.red,
        btnColor: Colors.black,
      );
      PD.pd(text: 'Print error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.sizeOf(context).width;
    return Scaffold(
      key: _scaffoldKey,
      appBar: MyAppBar(appname: 'Details of Billed Items for Office Requests'),
      body: Container(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
            ? Center(child: Text(_errorMessage))
            : Column(
          children: [
            Expanded(
              child: _buildInfoList(_requests, screenWidth),
            ),
            Expanded(
              child: _buildRequestedItemsTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoList(List<PaymentRequest> requests, double screenWidth) {
    double buttonWidth = screenWidth < 600 ? 120 : 180;
    return ListView.builder(
      padding: EdgeInsets.all(10),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          elevation: 5,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "IOU Number: ${IOUNumber.iouNumber(val: request.iouNumber.toString())}|Request Number: ${request.refNum.toString()}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Text("Receiver: ${request.receiverName}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Mobile: ${request.receiverMobile}"),
                    Text("Date: ${request.requestDate}"),
                    Text("Comment: ${request.comment}"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Bill Amount:", style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          "Rs.${NumberStyles.currencyStyle(request.totalAmount.toString())}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    Divider(),
                    if (request.itemDis != 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Items Discount:", style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            "Rs.${NumberStyles.currencyStyle(request.itemDis.toString())}",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      Divider(),
                    ],

                    if (request.vat != 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("VAT:", style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            "Rs.${NumberStyles.currencyStyle(request.vat.toString())}",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      Divider(),
                    ],

                    if (request.sscl != 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("SSCL:", style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            "Rs.${NumberStyles.currencyStyle(request.sscl.toString())}",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      Divider(),
                    ],

                    if (request.addDis != 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Additional discount:", style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            "Rs.${NumberStyles.currencyStyle(request.addDis.toString())}",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      Divider(),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Sub Amount:", style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          "Rs.${NumberStyles.currencyStyle((request.totalAmount+request.vat+request.sscl-request.addDis).toString())}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    if (request.paymentType == "Bank Transfer") ...[
                      SizedBox(height: 10),
                      Text("Beneficiary Name: ${request.beneficiaryName ?? 'N/A'}"),
                      Text("Bank Name: ${request.bankName ?? 'N/A'}"),
                      Text("Bank Branch: ${request.bankBranch ?? 'N/A'}"),
                      Text("Account Number: ${request.accountNumber ?? 'N/A'}"),
                    ],
                    if (request.isAuth == 1) ...[
                      SizedBox(height: 10),
                      Text("Authorized by: ${request.authUser ?? 'N/A'}"),
                      Text(
                          "Authorization Comment: ${request.authCmt ?? 'N/A'}"),
                      Text("Authorization Time: ${request.authTime ?? 'N/A'}"),
                    ],
                    if (request.isAppro == 1) ...[
                      SizedBox(height: 10),
                      Text("Approved by: ${request.approUser ?? 'N/A'}"),
                      Text("Approval Comment: ${request.approCmt ?? 'N/A'}"),
                      Text("Approval Time: ${request.approTime ?? 'N/A'}"),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    // View Images Button
                    IconButton(
                      icon: Icon(Icons.image, color: Colors.blue),
                      onPressed: () {
                        viewImages(request.refNum.toString()).then((_) {
                          if (_imagesLists.isNotEmpty && mounted) {
                            _showImagesDialog(_scaffoldKey.currentContext!); // Use the GlobalKey's context
                          } else {
                            ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                              SnackBar(
                                content: Text('No images found for this request.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        });
                      },
                    ),
                    // Print Button
                    IconButton(
                      icon: Icon(Icons.print, color: Colors.blue),
                      onPressed: () {

                        _exportAndPrintPdf();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void _showImagesDialog(BuildContext context) {
    if (!mounted) return;
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
                          // Download button
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.8),
                              child: Icon(Icons.download, color: Colors.green),
                            ),
                          ),
                          // Delete button
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () async {
                                int a= await YNDialogCon.ynDialogMessage(context, messageBody: 'Are you sure you want to delete this image?', messageTitle: 'Delete Image', icon: Icons.delete, iconColor: Colors.red, btnDone: 'Yes', btnClose: 'No');
                                if(a==1){
                                  final removedImage = _imagesLists[index];

                                  PD.pd(text: 'Deleting image: ${removedImage.emageUrl}');
                                  deleteImage(removedImage.emageUrl);
                                  setState(() {
                                    _imagesLists.removeAt(index);
                                  });

                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Image deleted"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }else{

                                }

                              },
                              child: CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.8),
                                radius: 14,
                                child: Icon(Icons.close, size: 18, color: Colors.red),
                              ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),  child: Text('Close'),)
            ],
          ),
        );
      },
    );
  }
  Widget _buildRequestedItemsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Main Category')),
            DataColumn(label: Text('Sub Category')),
            DataColumn(label: Text('Billed Name')),
            DataColumn(label: Text('List Description')),
            DataColumn(label: Text('Qty')),
            DataColumn(label: Text('Unit Amount')),
            DataColumn(label: Text('Total Amount')),
            DataColumn(label: Text('Edit')),
            DataColumn(label: Text('Delete')),
          ],
          rows: _requestedItems.map((item) {
            String formattedTotal = NumberFormat('#,###.00', 'en_US').format(item.totalAmount);
            PD.pd(text: formattedTotal.toString());
            return DataRow(
              cells: [
                DataCell(Text(item.mainCategory)),
                DataCell(Text(item.subCategory.toString())),
                DataCell(Text(item.itemName)),
                DataCell(Text(item.description)),
                DataCell(
                  TextFormField(
                    enabled: isApproved,
                    initialValue: item.sumQuantity.toString(),
                    onChanged: (value) {
                      item.newQuantity = double.tryParse(value) ?? 0;
                    },
                  ),
                ),
                DataCell(
                  TextFormField(
                    enabled: isApproved,
                    initialValue: item.unitAmount.toString(),
                    onChanged: (value) {
                      item.newAmount = double.tryParse(value) ?? 0;
                    },
                  ),
                ),
                DataCell(Text(formattedTotal)),
                DataCell(
                  Visibility(
                    visible: isApproved,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.save, color: Colors.green),
                          onPressed: () {
                            if (item.newAmount! <= 0 || item.newQuantity! <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please Change Amount and price before edit.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              YNDialogCon.ynDialogMessage(
                                context,
                                messageBody: 'Confirm to Edit Item ${item.description} QTY :${item.newQuantity} and amount ${item.newAmount}',
                                messageTitle: 'Edit Price',
                                icon: Icons.edit,
                                iconColor: Colors.red,
                                btnDone: 'Update',
                                btnClose: 'No',
                              ).then((value) {
                                if (value == 1) {
                                  changePriceAndQty(
                                    context,
                                    item.requestListId,
                                    item.requestId,
                                    item.description,
                                    item.newQuantity.toString(),
                                    item.newAmount.toString(),
                                    item.unitAmount.toString(),
                                    item.sumQuantity.toString(),
                                  );
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Visibility(
                    visible: canDelete,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            YNDialogCon.ynDialogMessage(
                              context,
                              messageBody: 'Confirm to remove Item ${item.description} QTY :${item.sumQuantity}',
                              messageTitle: 'Remove Items',
                              icon: Icons.delete_forever,
                              iconColor: Colors.red,
                              btnDone: 'Yes,Delete',
                              btnClose: 'No',
                            ).then((value) {
                              if (value == 1) {
                                removeRequestItem(context, item.requestListId, item.description, item.requestId);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> removeRequestItem( BuildContext context, int id, String name, int requestId) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Processing Request...');
      String apiURL ='${APIHost().apiURL}/ofz_payment_controller.php/RemoveItemFormList';
      PD.pd(text: apiURL);
      final response = await http.post(
        Uri.parse(apiURL
            ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "request_id": requestId,
          "idtbl_ofz_request_list": id,
          "isLog": 1,
          "list_des": name,
          "created_by": UserCredentials().UserName
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
            ).then((value) {
              PD.pd(text: value.toString());
              if (value == true) {
                getDataRequestMaterialList();
              }
            });



          } else {
            showErrorDialog(context, responseData['message'] ?? 'Error');
          }
        } catch (e,st) {
          ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_ofz_request_list.dart');
          showErrorDialog(context, "Error decoding JSON response.");
        }
      } else {
        handleHttpError(context, response);
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_ofz_request_list.dart');
      handleGeneralError(context, e);
    }
  }
  Future<void> changePriceAndQty(BuildContext context,int id,int requestId,String billedName,String reqQty,String reqAmount,String oldPrice,String oldQty) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Changing the price');
      String apiURL = '${APIHost().apiURL}/ofz_payment_controller.php/EditPriceAndQty';
      PD.pd(text: apiURL);
      final response = await http.post(Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "idtbl_ofz_request_list": id,
          "ofz_request_id": requestId,
          "list_des": billedName,
          "new_qty": reqQty,
          "new_amout": reqAmount,
          "old_price": oldPrice,
          "old_qty": oldQty,
          "change_by": UserCredentials().UserName
        }),
      );
      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          PD.pd(text: responseData.toString());
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
            getDataRequestMaterialList();
          } else {
            showErrorDialog(context, responseData['message'] ?? 'Error');
          }
        } catch (e,st) {
          ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_ofz_request_list.dart');
          showErrorDialog(context, "Error decoding JSON response.");
        }
      } else {
        handleHttpError(context, response);
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_ofz_request_list.dart');
      handleGeneralError(context, e);
    }
  }
}

void handleHttpError(BuildContext context, http.Response response) {
  String errorMessage =
      'Request failed with status code ${response.statusCode}';
  try {
    final errorData = jsonDecode(response.body);
    errorMessage = errorData['message'] ?? errorMessage;
  } catch (e,st) {
    ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_ofz_request_list.dart');
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

class PaymentRequest {
  final int id;
  final String receiverName;
  final String receiverMobile;
  final String requestDate;
  final String comment;
  final double totalAmount;
  final int isAuth;
  final int isAppro;
  final String paymentType;
  final String? bankBranch;
  final String? accountNumber;
  final String? authCmt;
  final String? authUser;
  final String? authTime;
  final String? approCmt;
  final String? approUser;
  final String? approTime;
  final String? refNum;
  final String? projectName;
  final String? locationName;
  final String? bankName;
  final String? iouNumber;
  final String ourAccountNumber;
  final double? totalActualAmount;
  final int? pmtStatus;
  final String? pmtCmt;
  final String? pmtUser;
  final String? pmtTime;
  final String? createdBy;
  final String? createTime;
  final String? beneficiaryName;
  final double vat;
  final double sscl;
  final double addDis;
  final double itemDis;
  PaymentRequest({
    required this.id,
    required this.ourAccountNumber,
    required this.receiverName,
    required this.receiverMobile,
    required this.requestDate,
    required this.comment,
    required this.totalAmount,
    required this.isAuth,
    required this.isAppro,
    required this.paymentType,
    required this.projectName,
    required this.locationName,
    required this.vat,
    required this.addDis,
    required this.sscl,
    required this.itemDis,
    this.beneficiaryName,
    this.bankBranch,
    this.accountNumber,
    this.authCmt,
    this.authUser,
    this.authTime,
    this.approCmt,
    this.approUser,
    this.approTime,
    this.refNum,
    this.bankName,
    this.iouNumber,
    this.totalActualAmount,
    this.pmtStatus,
    this.pmtCmt,
    this.pmtUser,
    this.pmtTime,
    this.createdBy,
    this.createTime
  });

  // Factory constructor to parse JSON into PaymentRequest
  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
        ourAccountNumber: json['our_account_number']??'NA',
        id: json['idtbl_ofz_request'] ?? 0,
        beneficiaryName: json['beneficiary_name']??'NA',
        receiverName: json['receiver_name'] ?? '',
        receiverMobile: json['receiver_mobile'] ?? '',
        requestDate: json['request_date'] ?? '',
        comment: json['cmt'] ?? '',
        totalAmount: double.tryParse(json['total']) ?? 0,
        isAuth: json['is_auth'] ?? 0,
        isAppro: json['is_appro'] ?? 0,
        paymentType: json['payment_type'] ?? '',
        projectName: json['project_name'] ?? '',
        locationName: json['location_name'] ?? '',
        bankBranch: json['bank_branch'] ?? '',
        accountNumber: json['account_number'] ?? '',
        authCmt: json['auth_cmt'] ?? '',
        authUser: json['auth_user'] ?? '',
        authTime: json['auth_time'] ?? '',
        approCmt: json['appro_cmt'] ?? '',
        approUser: json['appro_user'] ?? '',
        approTime: json['appro_time'] ?? '',
        refNum: json['req_ref_number'] ?? '',
        bankName: json['bank_name'] ?? '',
        iouNumber: json['iou_number'] ?? '',
        totalActualAmount: json['sumamount']??0,
        pmtStatus: json['pmt_status'] ?? 0,
        pmtCmt: json['pmt_cmt'] ?? '',
        pmtUser: json['pmt_user'] ?? '',
        pmtTime: json['pmt_time'] ?? '',
        createdBy: json['created_by']??'',
        createTime: json['created_date']??'',
        vat: double.tryParse(json['vat'])??0,
        sscl: double.tryParse(json['sscl'])??0,
        addDis: double.tryParse(json['add_dis'])??0,
      itemDis: double.tryParse(json['itemDisc'])??0,
    );
  }
}

class RequestedItem {
  int requestId;
  String requestRefNumber;
  int requestListId;
  String mainCategory;
  String subCategory;
  String itemName;
  String reference;
  String description;
  String unitOfMeasure;
  String? sumQuantity;
  String? unitAmount;
  double? totalAmount;
  double? newQuantity;
  double? newAmount;

  RequestedItem({
    required this.requestId,
    required this.requestRefNumber,
    required this.requestListId,
    required this.mainCategory,
    required this.subCategory,
    required this.itemName,
    required this.reference,
    required this.description,
    required this.unitOfMeasure,
    required this.sumQuantity,
    required this.unitAmount,
    required this.totalAmount,
    this.newQuantity,
    this.newAmount,
  });

  factory RequestedItem.fromJson(Map<String, dynamic> json) {
    return RequestedItem(
      requestId: json['idtbl_ofz_request'],
      requestRefNumber: json['req_ref_number'],
      requestListId: json['idtbl_ofz_request_list'],
      itemName: json['item_name']??'NA',
      mainCategory: json['main_name'],
      subCategory: json['sub_name'],
      reference: json['ref'],
      description: json['list_des'],
      unitOfMeasure: json['uom'],
      sumQuantity: json['qty'],
      totalAmount: double.tryParse(json['total_amout']),
      unitAmount: json['amout'],
      newQuantity: 0.0,
      newAmount: 0.0,
    );
  }
}

class ImagesList {
  String emageUrl;

  ImagesList({
    required this.emageUrl,
  });
}