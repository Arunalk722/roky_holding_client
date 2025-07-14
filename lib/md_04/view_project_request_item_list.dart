import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pattern_formatter/numeric_formatter.dart';
import 'package:roky_holding/env/DialogBoxs.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/number_format.dart';
import 'package:roky_holding/env/print_debug.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/sp_format_data.dart';
import '../env/user_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'material_budgeted_cost.dart';

class ViewConstructionRequestList extends StatefulWidget {
  final String requestId;
  final String refNumber;
  final bool isNotApprove;
  const ViewConstructionRequestList(
      {super.key, required this.requestId, required this.isNotApprove,required this.refNumber});

  @override
  State<ViewConstructionRequestList> createState() =>
      _ViewConstructionRequestListState();
}

class _ViewConstructionRequestListState extends State<ViewConstructionRequestList> {
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

    String apiURL =
        '${APIHost().apiURL}/project_payment_controller.php/ListOfRequestById';
    PD.pd(text: apiURL);
    try {
      WaitDialog.showWaitDialog(context,
          message:
          'loading request number ${RequestNumber.formatNumber(val: int.tryParse(widget.requestId.toString())??0)}');
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          'tbl_user_payment_request_id': widget.requestId,
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
            getDataRequestMateriaList();
            isApproved = data.any((item) {
              return item['is_appro'] == 0 && item['is_auth'] == 0;
            });
            canDelete=data.any((item){
              return item['is_appro'] != 1 && item['is_auth'] != 1;
            });
            _isLoading = false;
            PD.pd(text: 'Edit ${isApproved.toString()}');
            PD.pd(text:'Can Delete ${canDelete.toString()}');
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_project_request_item_list.dart');
      WaitDialog.hideDialog(context);
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      PD.pd(text: e.toString());
    }
  }

  Future<void> getDataRequestMateriaList() async {
    String apiURL =
        '${APIHost().apiURL}/project_payment_controller.php/RequestedListOfItem';
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
          'request_id': widget.requestId
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_project_request_item_list.dart');
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

  List<ImagesList> _imagesLists = [];
  Future<void> viewImages(String refNum) async {
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
          'req_ref_number': refNum,
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
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_project_request_item_list.dart');
      if (!mounted) return; // Check again after the async operation
      WaitDialog.hideDialog(context);
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      PD.pd(text: e.toString());
    }
  }

  Future<Uint8List> generatePdf() async {


    await fetchRequestsById();
    final pdf = pw.Document();
    // Load custom fonts
    final fontData = await rootBundle.load("assets/fonts/iskpota.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load("assets/fonts/iskpotab.ttf");
    final ttfBold = pw.Font.ttf(boldFontData);
    // Create a theme with the custom fonts
    final theme = pw.ThemeData.withFont(
      base: ttf,
      bold: ttfBold,
    );

    pdf.addPage(

      pw.MultiPage(
        pageFormat: PdfPageFormat.a5,
        theme: theme,
        margin: const pw.EdgeInsets.all(12),
        maxPages: 100, // Set a reasonable max page limit
        build: (pw.Context context) {
          return [buildIouPdfPage(_requests, _requestedItems, ttf, ttfBold)];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget buildIouPdfPage(List<PaymentRequest> paymentRequests,List<RequestedItem> requestedItems,pw.Font normalFont,pw.Font boldFont) {

    // Group items by workType and costType and sum amounts
    final Map<String, double> categorySums = {};
    for (var item in requestedItems) {
      final amount = double.tryParse(item.actualAmount) ?? 0;
      final itemDis = double.tryParse(item.itemDisc) ?? 0;
      final categoryKey = '${item.workType} - ${item.costType}';
      categorySums.update(
        categoryKey,
            (value) => value + amount - itemDis,
        ifAbsent: () => amount - itemDis,
      );
    }


    // Convert to sorted list
    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return pw.Column(
      children: paymentRequests.map((request) {

        double _vat=double.tryParse(request.vat)??0;
        double _sscl=double.tryParse(request.sscl)??0;
        double _addDis=double.tryParse(request.addDisc)??0;
        double _billAmount=double.tryParse(request.totalAmount)??0;
        double _itemsDis=double.tryParse(request.itemsDis)??0;
        double _billSubTotal=_billAmount+_vat+_sscl-(_addDis+_itemsDis);


        PD.pd(text: '-------------------');


        PD.pd(text: _itemsDis.toString());
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 15),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('IOU',
                        style: pw.TextStyle(
                            fontSize: 14,
                            font: boldFont,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text('ROKY Holdings (Pvt) LTD',
                        style: pw.TextStyle(
                            fontSize: 10,
                            font: normalFont)),
                    pw.SizedBox(height: 8),
                  ],
                ),
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(3),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Text('IOU No:  ${IOUNumber.iouNumber(val: request.iouNumber.toString()) ?? '000000'}',
                        style: pw.TextStyle(fontSize: 8, font: normalFont)),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(3),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child:  pw.Text('Payment:  ${request.paymentType}',
                        style: pw.TextStyle(fontSize: 8, font: normalFont)),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(3),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child:   pw.Text('No: ${request.refNum ?? ''}',
                        style: pw.TextStyle(fontSize: 8, font: normalFont)),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(3),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Text('Paid Date: ${request.payedDate}',
                        style: pw.TextStyle(fontSize: 8, font: normalFont)),
                  ),
                ],
              ),

              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Project: ${request.projectName ?? ''}',
                        style: pw.TextStyle(fontSize: 8, font: normalFont)),
                    pw.Text('Location:  ${request.locationName ?? ''}',
                        style: pw.TextStyle(fontSize: 8, font: normalFont)),
                  ],
                ),
              ),

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
                        pw.Text('Payment Requested BY: ${request.createdBy ?? ''}',
                            style: pw.TextStyle(fontSize: 8, font: normalFont)),
                        pw.Text('Requested Date & time: ${request.createdTime ?? ''}',
                            style: pw.TextStyle(fontSize: 8, font: normalFont)),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Remarks: ${request.comment ?? ''}',
                          style: pw.TextStyle(fontSize: 8, font: normalFont),
                          softWrap: true,
                          maxLines: 3,
                          overflow: pw.TextOverflow.visible,
                        ),

                        pw.Text(
                          'Paid Account: ${request.ourAccountNumber ?? ''}',
                          style: pw.TextStyle(fontSize: 8, font: normalFont),
                          softWrap: true,
                          maxLines: 3,
                          overflow: pw.TextOverflow.visible,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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
                        pw.Text('Beneficiary Name: ${request.receiverName ?? ''}',
                            style: pw.TextStyle(fontSize: 8, font: normalFont)),
                        pw.Text('Mobile no: ${request.receiverMobile ?? ''}',
                            style: pw.TextStyle(fontSize: 8, font: normalFont)),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Requested Amount: ${NumberStyles.currencyStyle(request.requested.toString())}',
                            style: pw.TextStyle(fontSize: 8, font: normalFont)),
                        pw.Text('Paid Amount: ${NumberStyles.currencyStyle(request.totalActualAmount.toString())}',
                            style: pw.TextStyle(fontSize: 8, font: normalFont)),
                      ],
                    ),
                  ],
                ),
              ),

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
                        pw.Text('A/C holder Name: ${request.beneficiaryName ?? ''}',
                            style: pw.TextStyle(fontSize: 8, font: normalFont)),
                        pw.Text('Bank: ${request.bankName ?? ''}',
                            style: pw.TextStyle(fontSize: 8, font: normalFont)),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('A/C number: ${request.accountNumber ?? ''}',
                            style: pw.TextStyle(fontSize: 8, font: normalFont)),
                        pw.Text('Branch: ${request.bankBranch ?? ''}',
                            style: pw.TextStyle(fontSize: 8, font: normalFont)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 5),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildApprovalBox('${request.isAuth==-1?'Reject':'Authorized'} By', request.authUser, request.authTime, request.authCmt, normalFont, boldFont),
                  buildApprovalBox('${request.isAppro==-1?'Reject':'Approved'} By', request.approUser, request.approTime, request.approCmt, normalFont, boldFont),
                  buildApprovalBox('Paid By', request.pmtUser, request.pmtTime, request.pmtCmt, normalFont, boldFont),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Text('Category Summary',
                  style: pw.TextStyle(
                      fontSize: 10,
                      font: boldFont,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
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
                                  font: boldFont,
                                  fontWeight: pw.FontWeight.bold))
                      ),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text('Amount',
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  font: boldFont,
                                  fontWeight: pw.FontWeight.bold))
                      ),
                    ],
                  ),
                  ...sortedCategories.map((entry) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(entry.key,
                            style: pw.TextStyle(fontSize: 7, font: normalFont)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                          NumberStyles.currencyStyle(entry.value.toString()),
                          style: pw.TextStyle(fontSize: 7, font: normalFont),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  )),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('TOTAL',
                            style: pw.TextStyle(
                                fontSize: 8,
                                font: boldFont,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                          NumberStyles.currencyStyle(
                              request.totalAmount),
                          style: pw.TextStyle(
                              fontSize: 8,
                              font: boldFont,
                              fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  /* if(_addDis!=0)...[
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text('ADDITIONAL DISCOUNT',
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  font: boldFont,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text(
                            NumberStyles.currencyStyle(_addDis.toString()),
                            style: pw.TextStyle(
                                fontSize: 8,
                                font: boldFont,
                                fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if(_vat!=0)...[
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text('VAT',
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  font: boldFont,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text(
                            NumberStyles.currencyStyle(_vat.toString()),
                            style: pw.TextStyle(
                                fontSize: 8,
                                font: boldFont,
                                fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if(_sscl!=0)...[
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text('SSCL',
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  font: boldFont,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text(
                            NumberStyles.currencyStyle(_sscl.toString()),
                            style: pw.TextStyle(
                                fontSize: 8,
                                font: boldFont,
                                fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],*/

                  /*   pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text('SUB TOTAL',
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  font: boldFont,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text(
                            NumberStyles.currencyStyle(request.totalAmount),
                            style: pw.TextStyle(
                                fontSize: 8,
                                font: boldFont,
                                fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),*/

                ],
              ),

              // pw.SizedBox(height: 10),
              // pw.Text('Detailed Items',
              //     style: pw.TextStyle(
              //         fontSize: 10,
              //         font: boldFont,
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
              //                     font: boldFont,
              //                     fontWeight: pw.FontWeight.bold))
              //         ),
              //         pw.Padding(
              //             padding: const pw.EdgeInsets.all(3),
              //             child: pw.Text('Sub category',
              //                 style: pw.TextStyle(
              //                     fontSize: 7,
              //                     font: boldFont,
              //                     fontWeight: pw.FontWeight.bold))
              //         ),
              //         pw.Padding(
              //             padding: const pw.EdgeInsets.all(3),
              //             child: pw.Text('Amount',
              //                 style: pw.TextStyle(
              //                     fontSize: 7,
              //                     font: boldFont,
              //                     fontWeight: pw.FontWeight.bold))
              //         ),
              //       ],
              //     ),
              //     for (var item in requestedItems)
              //       pw.TableRow(
              //         children: [
              //           pw.Padding(
              //             padding: const pw.EdgeInsets.all(3),
              //             child: pw.Text(item.workType ?? '',
              //                 style: pw.TextStyle(fontSize: 7, font: normalFont)),
              //           ),
              //           pw.Padding(
              //             padding: const pw.EdgeInsets.all(3),
              //             child: pw.Text(item.costType ?? '',
              //                 style: pw.TextStyle(fontSize: 7, font: normalFont)),
              //           ),
              //           pw.Padding(
              //             padding: const pw.EdgeInsets.all(3),
              //             child: pw.Text(
              //               NumberStyles.currencyStyle(item.actualAmount.toString()),
              //               style: pw.TextStyle(fontSize: 7, font: normalFont),
              //               textAlign: pw.TextAlign.right,
              //             ),
              //           ),
              //         ],
              //       ),
              //   ],
              // ),

              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Printed By: ${UserCredentials().UserName}',
                      style: pw.TextStyle(fontSize: 8, font: normalFont)),
                  pw.Text('Printed Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(fontSize: 8, font: normalFont)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }



  pw.Widget buildApprovalBox(
      String title,
      String? name,
      String? date,
      String? remark,
      pw.Font normalFont,
      pw.Font boldFont,
      {String? account}) {
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
                    fontWeight: pw.FontWeight.bold
                )
            ),
            pw.Text('User: ${name ?? ''}',
                style: pw.TextStyle(fontSize: 6, font: normalFont)),
            pw.Text('Date & Time: ${date ?? ''}',
                style: pw.TextStyle(fontSize: 6, font: normalFont)),
            pw.Text('Remarks: ${remark ?? ''}',
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
      // Show loading dialog
      WaitDialog.showWaitDialog(context, message: 'Generating PDF...');


      // Generate the PDF
      final pdfBytes = await generatePdf();

      // Hide loading dialog
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
      appBar: MyAppBar(appname: 'View the Item List for Project Requests'),
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


    return ListView.builder(
      padding: EdgeInsets.all(10),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        double _vat=double.tryParse(request.vat)??0;
        double _sscl=double.tryParse(request.sscl)??0;
        double _addDis=double.tryParse(request.addDisc)??0;
        double _billAmount=double.tryParse(request.totalAmount)??0;
        double _itemsDis=double.tryParse(request.itemsDis)??0;
        double _billSubTotal=_billAmount+_vat+_sscl-(_addDis+_itemsDis);
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
                        "IOU Number: ${IOUNumber.iouNumber(val: request.iouNumber.toString())}| Request ${request.refNum}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Text("Project: ${request.projectName} ${request.paymentType}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Location: ${request.locationName}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Receiver: ${request.receiverName} |Type ${request.paymentType}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Mobile: ${request.receiverMobile}"),
                    Text("Date: ${request.requestDate}"),
                    Text("Comment: ${request.comment}"),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [


                        if (_itemsDis != 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Items Discount:", style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                "Rs.${NumberStyles.currencyStyle(_itemsDis.toString())}",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                          Divider(),
                        ],

                        if (_vat != 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("VAT:", style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                "Rs.${NumberStyles.currencyStyle(_vat.toString())}",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                          Divider(),
                        ],

                        if (_sscl != 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("SSCL:", style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                "Rs.${NumberStyles.currencyStyle(_sscl.toString())}",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                          Divider(),
                        ],

                        if (_addDis != 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Additional discount:", style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                "Rs.${NumberStyles.currencyStyle(_addDis.toString())}",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                          Divider(),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total Bill Value:", style: TextStyle(fontWeight: FontWeight.w500)),
                            Text(
                              "Rs.${NumberStyles.currencyStyle(request.totalAmount.toString())}",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
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
                    if (request.isAuth == 1||request.isAuth == -1) ...[
                      SizedBox(height: 10),
                      Text("${request.isAuth==-1?'Reject':'Authorized'} by: ${request.authUser ?? 'N/A'}"),
                      Text(
                          "Authorization Comment: ${request.authCmt ?? 'N/A'}"),
                      Text("Authorization Time: ${request.authTime ?? 'N/A'}"),
                    ],
                    if (request.isAppro == 1||request.isAppro == -1) ...[
                      SizedBox(height: 10),
                      Text("${request.isAppro==-1?'Reject':'Approved'} by: ${request.approUser ?? 'N/A'}"),
                      Text("Comment: ${request.approCmt ?? 'N/A'}"),
                      Text("Time: ${request.approTime ?? 'N/A'}"),
                    ],
                  ],
                ),
              ),
              // Add the Print and View Images Buttons at the top-right corner
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
                        PD.pd(text: request.totalActualAmount.toString());
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
    // Create base columns
    final List<DataColumn> columns = [
      const DataColumn(label: Text('Work Type')),
      const DataColumn(label: Text('Category')),
      const DataColumn(label: Text('Billed Name')),
      const DataColumn(label: Text('Qty')),
      const DataColumn(label: Text('Unit Amount(LKR)')),
      const DataColumn(label: Text('Total(LKR)')),
      const DataColumn(label: Text('Discount')),
    ];

    // Conditionally add Edit/Delete columns
    if (isApproved) {
      columns.add(const DataColumn(label: Text('Edit')));
    }
    if (canDelete) {
      columns.add(const DataColumn(label: Text('Delete')));
    }

    columns.add(const DataColumn(label: Text('Estimation'))); // Always show Estimation

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 20,
          columns: columns,
          rows: _requestedItems.map((item) {
            final List<DataCell> cells = [
              DataCell(Container(
                constraints: BoxConstraints(maxWidth: 150),
                child: Text(item.workType, overflow: TextOverflow.ellipsis),
              )),
              DataCell(Container(
                constraints: BoxConstraints(maxWidth: 150),
                child: Text(item.costType, overflow: TextOverflow.ellipsis),
              )),
              DataCell(Container(
                constraints: BoxConstraints(maxWidth: 150),
                child: Text(item.materialDescription, overflow: TextOverflow.ellipsis),
              )),
              DataCell(Container(
                width: 100,
                child: TextFormField(
                  inputFormatters: [ThousandsFormatter(allowFraction: true)],
                  enabled: isApproved,
                  initialValue: item.requestedQuantity,
                  onChanged: (value) {
                    item.newQuantity = double.tryParse(value.replaceAll(',', '')) ?? 0;
                  },
                ),
              )),
              DataCell(Container(
                width: 100,
                child: TextFormField(
                  inputFormatters: [ThousandsFormatter(allowFraction: true)],
                  enabled: isApproved,
                  initialValue: item.requestedAmount,
                  onChanged: (value) {
                    item.newAmount = double.tryParse(value.replaceAll(',', '')) ?? 0;
                  },
                ),
              )),
              DataCell(Container(
                width: 100,
                child: TextFormField(
                  inputFormatters: [ThousandsFormatter(allowFraction: true)],
                  enabled: isApproved,
                  initialValue: item.requestedTotalAmount,
                  onChanged: (value) {
                    item.newRequestedTotalAmount = double.tryParse(value.replaceAll(',', '')) ?? 0;
                  },
                ),
              )),
              DataCell(Container(
                width: 100,
                child: TextFormField(
                  inputFormatters: [ThousandsFormatter(allowFraction: true)],
                  enabled: isApproved,
                  initialValue: item.itemDisc,
                  onChanged: (value) {
                    item.newDisc = double.tryParse(value.replaceAll(',', '')) ?? 0;
                  },
                ),
              )),
            ];

            // Conditionally add Edit cell
            if (isApproved) {
              cells.add(DataCell(
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
                        messageBody: 'Confirm to Edit Item ${item.materialDescription} QTY :${item.newQuantity} and amount ${item.newAmount}',
                        messageTitle: 'Edit Price',
                        icon: Icons.edit,
                        iconColor: Colors.red,
                        btnDone: 'Update',
                        btnClose: 'No',
                      ).then((value) {
                        if (value == 1) {
                          changePriceAndQty(
                            context,
                            item.id,
                            item.requestId,
                            item.materialDescription,
                            item.newQuantity.toString(),
                            item.newAmount.toString(),
                            item.requestedAmount.toString(),
                            item.requestedQuantity.toString(),
                            item.materialId,
                            item.requestedTotalAmount.toString(),
                            item.newRequestedTotalAmount.toString(),
                            item.newDisc.toString(),
                          );
                        }
                      });
                    }
                  },
                ),
              ));
            }

            // Conditionally add Delete cell
            if (canDelete) {
              cells.add(DataCell(
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    YNDialogCon.ynDialogMessage(
                      context,
                      messageBody: 'Confirm to remove Item ${item.materialDescription} QTY :${item.requestedQuantity}',
                      messageTitle: 'Remove Items',
                      icon: Icons.delete_forever,
                      iconColor: Colors.red,
                      btnDone: 'Yes,Delete',
                      btnClose: 'No',
                    ).then((value) {
                      if (value == 1) {
                        removeRequestItem(context, item.id, item.materialDescription, item.requestId);
                      }
                    });
                  },
                ),
              ));
            }

            // Always show Estimation icon
            cells.add(DataCell(
              IconButton(
                tooltip: 'Show Pie Dialog',
                icon: Icon(Icons.pie_chart),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => MaterialEstimationDialog(
                      selectedProjectLocationName: item.locationName,
                      selectedProjectName: item.projectName,
                      materialName: item.materialName,
                      costCategory: item.costType,
                      workName: item.workType,
                    ),
                  );
                },
              ),
            ));

            return DataRow(cells: cells);
          }).toList(),
        ),
      ),
    );
  }

  Future<void> removeRequestItem( BuildContext context, int id, String name, int requestId) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Processing Request...');
      String apiURL='${APIHost().apiURL}/project_payment_controller.php/DeleteBilledItem';
      PD.pd(text: apiURL);
      final response = await http.post(
        Uri.parse(
            apiURL  ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "request_id": requestId,
          "idtbl_user_request_list": id,
          "isLog": 1,
          "BilledName": name,
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
                getDataRequestMateriaList();
              }
            });



          } else {
            showErrorDialog(context, responseData['message'] ?? 'Error');
          }
        } catch (e,st) {
          ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_project_request_item_list.dart');
          showErrorDialog(context, "Error decoding JSON response.");
        }
      } else {
        handleHttpError(context, response);
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_project_request_item_list.dart');
      handleGeneralError(context, e);
    }
  }
  Future<void> changePriceAndQty(BuildContext context,int id,int requestId,String billedName,String reqQty,String reqAmount,String oldPrice,String oldQty,int materialId,String oldTotal,String newTotal,String newDisc) async {
    try {

      WaitDialog.showWaitDialog(context, message: 'Change Price...');

      final response = await http.post(
        Uri.parse(
            '${APIHost().apiURL}/project_payment_controller.php/EditPriceAndQty'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "request_id": requestId,
          "idtbl_user_request_list": id,
          "material_name": billedName,
          "req_qty": reqQty.toString().replaceAll(',', ''),
          "req_amout": reqAmount.toString().replaceAll(',', ''),
          "old_price": oldPrice.toString().replaceAll(',', ''),
          "old_qty": oldQty.toString().replaceAll(',', ''),
          "old_total": oldTotal.toString().replaceAll(',', ''),
          "new_total": newTotal.toString().replaceAll(',', ''),
          "material_id": materialId.toString().replaceAll(',', ''),
          "item_disc": newDisc.toString().replaceAll(',', ''),
          "created_by": UserCredentials().UserName
        }),
      );

      WaitDialog.hideDialog(context);
      if (response.statusCode == 200) {
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
            getDataRequestMateriaList();
          } else {
            showErrorDialog(context, responseData['message'] ?? 'Error');
          }
        } catch (e,st) {
          ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_project_request_item_list.dart');
          showErrorDialog(context, "Error decoding JSON response.");
        }
      } else {
        handleHttpError(context, response);
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_project_request_item_list.dart');
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
    ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'view_project_request_item_list.dart');
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
  final String payedDate;
  final String receiverName;
  final String receiverMobile;
  final String requestDate;
  final String comment;
  final String totalAmount;
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
  final String? bankName; // New variable
  final String? iouNumber; // New variable
  final String? totalActualAmount; // New variable
  final String? requested;
  final int? pmtStatus; // New variable
  final String? pmtCmt; // New variable
  final String? pmtUser; // New variable
  final String? pmtTime; // New variable
  final String createdBy;
  final String createdTime;
  final String paymentRef;
  final String ourAccountNumber;
  final String? beneficiaryName;
  final String? addDiscount;
  final String vat;
  final String sscl;
  final String addDisc;
  final String itemsDis;

  PaymentRequest({
    required this.id,
    required  this.payedDate,
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
    required this.createdBy,
    required this.createdTime,
    required this.paymentRef,
    required this.addDiscount,
    required this.beneficiaryName,
    required this.bankBranch,
    required this.accountNumber,
    required this.requested,
    required this.sscl,
    required this.vat,
    required this.addDisc,
    required this.itemsDis,
    required this.authCmt,
    required this.authUser,
    required this.authTime,
    required this.approCmt,
    required this.approUser,
    required this.approTime,
    required this.refNum,
    required this.bankName,
    required this.iouNumber,
    required this.totalActualAmount,
    required this.pmtStatus,
    required this.pmtCmt,
    required this.pmtUser,
    required this.pmtTime,
    required this.ourAccountNumber,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      beneficiaryName: json['beneficiary_name']??'NA',
      payedDate: json['payed_date']??'NA',
      ourAccountNumber: json['our_account_number']??'NA',
      id: json['tbl_user_payment_request_id'],
      receiverName: json['receiver_name'],
      receiverMobile: json['receiver_mobile'],
      requestDate: json['request_date'],
      comment: json['cmt'],
      totalAmount: json['total_req_amount']??'0',
      isAuth: json['is_auth'],
      isAppro: json['is_appro'],
      requested: json['requested_amount'],
      addDiscount: json['addt_discount'],
      paymentType: json['payment_type'],
      bankBranch: json['bank_branch'],
      accountNumber: json['account_number'],
      authCmt: json['auth_cmt'],
      authUser: json['auth_user'],
      authTime: json['auth_time'],
      approCmt: json['appro_cmt'],
      approUser: json['appro_user'],
      approTime: json['appro_time'],
      refNum: json['req_ref_number'],
      locationName: json['location_name'],
      projectName: json['project_name'],
      bankName: json['bank_name'], // New variable
      iouNumber: json['iou_number'], // New variable
      totalActualAmount: json['total_req_amount'].toString()??'0', // New variable
      pmtStatus: json['pmt_status'], // New variable
      pmtCmt: json['pmt_cmt'], // New variable
      pmtUser: json['pmt_user'], // New variable
      pmtTime: json['pmt_time']??'NA', // New variable
      createdBy: json['created_by'],
      paymentRef: json['payment_ref']??"NA",
      createdTime: json['created_date'].toString(), // New vari
      sscl: json['sscl']??'0',
      vat: json['vat']??'0',
      addDisc: json['addt_discount']??'0',
      itemsDis: json['ItemsTotalDis']??'0',
    );
  }
}

class RequestedItem {
  int id;
  String projectName;
  String locationName;
  String materialName;
  int workId;
  int costId;
  int materialId;
  int estimationListId;
  int requestId;
  String materialDescription;
  String requestedQuantity;
  String requestedAmount;
  String actualAmount;
  String itemDisc;
  int isActive;
  int isVisible;
  int statusOfPayment;
  String createdDate;
  String createdBy;
  String? changeDate;
  String? changeBy;
  int isPost;
  String totalEstimateQty;
  String totalEstimateAmount;
  double? newQuantity;
  double? newAmount;
  double? newDisc;
  String workType;
  String costType;
  String requestedTotalAmount;
  double? newRequestedTotalAmount;
  RequestedItem(
      {required this.id,
        required this.projectName,
        required this.locationName,
        required this.materialName,
        required this.workId,
        required this.costId,
        required this.materialId,
        required this.estimationListId,
        required this.requestId,
        required this.materialDescription,
        required this.requestedQuantity,
        required this.requestedAmount,
        required this.actualAmount,
        required this.isActive,
        required this.isVisible,
        required this.statusOfPayment,
        required this.createdDate,
        required this.createdBy,
        required this.changeDate,
        required this.changeBy,
        required this.isPost,
        required this.totalEstimateQty,
        required this.totalEstimateAmount,
        required this.newAmount,
        required this.workType,
        required this.costType,
        required this.itemDisc,
        required this.requestedTotalAmount,
        required this.newRequestedTotalAmount,
        required this.newQuantity,
        required this.newDisc });

  factory RequestedItem.fromJson(Map<String, dynamic> json) {
    return RequestedItem(
        id: json['idtbl_user_request_list']??0,
        projectName: json['project_name']??'NA',
        locationName: json['location_name']??'NA',
        materialName: json['material_name']??'NA',
        workId: json['work_id'],
        costId: json['cost_id'],
        materialId: json['material_id'],
        estimationListId: json['estimation_list_Id'],
        requestId: json['request_id'],
        materialDescription: json['material_des'],
        requestedQuantity: json['req_qty'].toString(),
        requestedAmount: json['req_amout'].toString(),
        actualAmount: json['actual_amount'].toString(),
        isActive: json['is_active'],
        isVisible: json['is_visible'],
        statusOfPayment: json['status_of_payment'],
        createdDate: json['created_date'],
        createdBy: json['created_by'],
        changeDate: json['change_date'],
        changeBy: json['change_by'],
        isPost: json['is_post'],
        totalEstimateQty: json['total_estimate_qty'].toString(),
        totalEstimateAmount: json['total_estimate_amount'].toString(),
        costType: json['cost_category'].toString(),
        workType: json['work_name'].toString(),
        requestedTotalAmount:json['actual_amount'],
        itemDisc:json['item_disc'] ,
        newRequestedTotalAmount: 0,
        newAmount: 0,
        newQuantity: 0,
        newDisc: 0);
  }
}

class ImagesList {
  String emageUrl;
  ImagesList({
    required this.emageUrl,
  });
}