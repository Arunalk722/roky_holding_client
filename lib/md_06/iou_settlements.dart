import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/app_bar.dart';
import 'package:roky_holding/env/number_format.dart';
import 'package:roky_holding/env/sp_format_data.dart';
import 'package:roky_holding/env/user_data.dart';

import '../env/DialogBoxs.dart';
import '../env/custome_icon.dart';
import '../env/input_widget.dart';
import '../env/print_debug.dart';

class IOUSettlements extends StatefulWidget {
  const IOUSettlements({super.key});

  @override
  State<IOUSettlements> createState() => _IOUSettlementsState();
}

class _IOUSettlementsState extends State<IOUSettlements> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedRequestType = 0; // 0 - Office, 1 - Construction
  List<dynamic> _beneficiaryList = [];
  List<String> _beneficiaryNames = [];
  List<String> _selectedIOUNumbers = [];
  List<dynamic> _iouList = [];
  bool _isLoading = false;
  bool _loadTable=false;
  List<IOUSettData> _settlementList = [];
  final TextEditingController _beneficiaryController = TextEditingController();

  List<Map<String, dynamic>> _distributeSettlement(double amount) {
    List<Map<String, dynamic>> distribution = [];
    double remainingAmount = amount;

    for (var iouId in _selectedIOUNumbers) {
      if (remainingAmount <= 0) break;

      final iou = _iouList.firstWhere(
            (item) => item['idtbl_IOU_list'].toString() == iouId,
        orElse: () => null,
      );

      if (iou != null) {
        double iouAmount = double.tryParse(iou['amount'].toString()) ?? 0;
        double settledAmount = double.tryParse(iou['set_amount'].toString()) ?? 0;
        double availableAmount = iouAmount - settledAmount;

        if (availableAmount > 0) {
          double settleThisTime = 0;
          if (availableAmount >= remainingAmount) {
            settleThisTime = remainingAmount;
            remainingAmount = 0;
          } else {
            settleThisTime = availableAmount;
            remainingAmount -= availableAmount;
          }

          distribution.add({
            'iouId': iou['idtbl_IOU_list'],
            'iouNumber': IOUNumber.iouNumber(val: iou['idtbl_IOU_list'].toString()),
            'requestRef': iou['request_ref'],
            'originalAmount': iouAmount,
            'settledAmount': settleThisTime,
            'remainingAmount': iouAmount - (settledAmount + settleThisTime),
          });
        }
      }
    }

    return distribution;
  }
  void _settData() {
    if (_txtAmount.text.isEmpty || double.tryParse(_txtAmount.text.replaceAll(',', '')) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid settlement amount')),
      );
      return;
    }

    double settlementAmount = double.parse(_txtAmount.text.replaceAll(',', ''));
    double totalAvailableAmount = 0;

    // Calculate total available amount from selected IOUs
    for (var iouId in _selectedIOUNumbers) {
      final iou = _iouList.firstWhere(
            (item) => item['idtbl_IOU_list'].toString() == iouId,
        orElse: () => null,
      );

      if (iou != null) {
        double iouAmount = double.tryParse(iou['amount'].toString()) ?? 0;
        double settledAmount = double.tryParse(iou['set_amount'].toString()) ?? 0;
        totalAvailableAmount += (iouAmount - settledAmount);
      }
    }

    if (settlementAmount > totalAvailableAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settlement amount (${NumberStyles.currencyStyle(settlementAmount.toString())}) exceeds available amount (${NumberStyles.currencyStyle(totalAvailableAmount.toString())})'),
          ));
          return;
      }

          final distribution = _distributeSettlement(settlementAmount);

      // Update the IOU list with new settled amounts
      for (var dist in distribution) {
        final iouIndex = _iouList.indexWhere(
                (item) => item['idtbl_IOU_list'].toString() == dist['iouId'].toString()
        );

        if (iouIndex != -1) {
          double currentSettled = double.tryParse(_iouList[iouIndex]['set_amount'].toString()) ?? 0;
          _iouList[iouIndex]['set_amount'] = currentSettled + dist['settledAmount'];
        }
      }

      String iouArray = distribution.map((d) =>
      '${d['iouNumber']} (${NumberStyles.currencyStyle(d['settledAmount'].toString())})'
      ).join(', ');

      String requestRefs = distribution.map((d) => d['requestRef']).join(', ');

      final newSettlement = IOUSettData(
        id: DateTime.now().millisecondsSinceEpoch,
        iouArry: iouArray,
        requestRef: requestRefs,
        settDate: _txtDate.text,
        descr: _txtDes.text,
        remark: _txtRemark.text,
        amount: settlementAmount,
        isActive: true,
        createdDate: DateTime.now().toString(),
        createdBy: 'user',
        changeDate: '',
        changeBy: '',
        distribution: distribution, // Add this field to your IOUSettData class
      );

      setState(() {
        _settlementList.add(newSettlement);
        _txtDate.clear();
        _txtDes.clear();
        _txtRemark.clear();
        _txtAmount.clear();
        _tabController.animateTo(1);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settlement added successfully')),
      );
    }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBeneficiaries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBeneficiaries() async {
    setState(() {
      _isLoading = true;
    });

    try {


      String apiURL='${APIHost().apiURL}/iou_controller.php/ScanIOUs';
      PD.pd(text: apiURL);
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "Authorization": APIToken().token, // Add your auth token here
          "request_type": _selectedRequestType == 0 ? "office" : "constructions"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200) {
          setState(() {
            _beneficiaryList = data['data'] ?? [];
            _beneficiaryNames = _beneficiaryList.map<String>((item) => item['beneficiary_name'].toString()).toList();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Error loading beneficiaries')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadIOUNumbers(String beneficiaryName) async {
    setState(() {
      _isLoading = true;
      _iouList.clear();
      _selectedIOUNumbers.clear();
    });
    PD.pd(text: beneficiaryName);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8002/RN/public/apis/controllers/iou_controller.php/ListIOUNumber'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "request_type": _selectedRequestType == 0 ? "office" : "constructions",
          "beneficiary_name": beneficiaryName
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        PD.pd(text:data.toString());
        if (data['status'] == 200) {
          setState(() {
            _iouList = data['data'] ?? [];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'No IOU numbers found')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading IOU numbers: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildRequestTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTypeRadioButton(0, 'Office'),
          const SizedBox(width: 20),
          _buildTypeRadioButton(1, 'Construction'),
        ],
      ),
    );
  }

  Widget _buildTypeRadioButton(int index, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedRequestType == index,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedRequestType = index;
            _loadBeneficiaries();
          });
        }
      },
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: _selectedRequestType == index ? Colors.white : Colors.black,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildBeneficiarySearch() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _beneficiaryNames.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _beneficiaryController.text = selection;
        final selectedBeneficiary = _beneficiaryList.firstWhere(
              (item) => item['beneficiary_name'] == selection,
          orElse: () => null,
        );
        if (selectedBeneficiary != null) {
          _loadIOUNumbers(_beneficiaryController.text);
        }
      },
      fieldViewBuilder: (
          BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted,
          ) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Search Beneficiary',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[100],
            suffixIcon: textEditingController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                textEditingController.clear();
                setState(() {
                  _iouList.clear();
                  _selectedIOUNumbers.clear();
                });
              },
            )
                : null,
          ),
          onChanged: (value) {
            setState(() {});
          },
        );
      },
      optionsViewBuilder: (
          BuildContext context,
          AutocompleteOnSelected<String> onSelected,
          Iterable<String> options,
          ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return InkWell(
                    onTap: () {
                      onSelected(option);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        option,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIOUMultiSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select IOU Numbers',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Select IOU Numbers'),
                          items: _iouList.map((iou) {
                            return DropdownMenuItem<String>(
                              value: iou['idtbl_IOU_list'].toString(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ref: ${iou['request_ref']} IOU:${IOUNumber.iouNumber(val: iou['idtbl_IOU_list'].toString())}'),
                                  Text('Amount: LKR ${NumberStyles.currencyStyle(iou['amount'].toString())} Set: LKR ${NumberStyles.currencyStyle(iou['set_amount'].toString())}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null && !_selectedIOUNumbers.contains(newValue)) {
                              setState(() {
                                _selectedIOUNumbers.add(newValue);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedIOUNumbers.isNotEmpty)
                Column(
                  children: _selectedIOUNumbers.map((iouId) {
                    final iou = _iouList.firstWhere(
                          (item) => item['idtbl_IOU_list'].toString() == iouId,
                      orElse: () => null,
                    );
                    if (iou == null) return const SizedBox.shrink();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('IOU:${IOUNumber.iouNumber(val: iou['idtbl_IOU_list'].toString())}'),
                                  Text('Ref: ${iou['request_ref']}'),
                                  Text('Amount: LKR ${NumberStyles.currencyStyle(iou['amount'].toString())}',
                                      style: const TextStyle(fontSize: 12)),
                                  Text('Amount: LKR ${NumberStyles.currencyStyle(iou['set_amount'].toString())}',
                                      style: const TextStyle(fontSize: 12)),
                                  Text('Date: ${iou['request_date']}',
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                setState(() {
                                  _selectedIOUNumbers.remove(iouId);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        if (_selectedIOUNumbers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Selected Amount:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'LKR ${NumberStyles.currencyStyle(_calculateTotalAmount().toString())}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _calculateTotalAmount() {
    double total = 0;
    for (var iouId in _selectedIOUNumbers) {
      final iou = _iouList.firstWhere(
            (item) => item['idtbl_IOU_list'].toString() == iouId,
        orElse: () => null,
      );
      if (iou != null) {
        total += double.tryParse(iou['amount'].toString()) ?? 0;
      }
    }
    return total.toStringAsFixed(2);
  }

  // Declare these at the class level
  final TextEditingController _txtAmount = TextEditingController();
  final TextEditingController _txtDes = TextEditingController();
  final TextEditingController _txtDate = TextEditingController();
  final TextEditingController _txtRemark = TextEditingController();


// Inside your stateful widget
  Widget _buildSettlementForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Settlement Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _txtDate,
              decoration: InputDecoration(
                labelText: '',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                  _txtDate.text = formattedDate;
                }
              },
            ),
            SizedBox(height: 16,),
            buildTextField(_txtDes, 'References/Description', 'Description', Icons.room_preferences, true, 100),
            TextFormField(
              controller: _txtRemark,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            buildNumberField(_txtAmount, 'Settlement Amount', '2000', LKRIcon(), true, 20),

            ElevatedButton(
              onPressed: () {
                _settData();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Submit Settlement'),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSelection(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              // Desktop layout
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Column(
                        children: [
                          _buildRequestTypeSelector(),
                          _buildBeneficiarySearch(),
                          const SizedBox(height: 16),
                          _buildIOUMultiSelect(),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: _buildSettlementForm(),
                  ),
                ],
              );
            } else {
              // Mobile layout
              return Column(
                children: [
                  _buildRequestTypeSelector(),
                  _buildBeneficiarySearch(),
                  const SizedBox(height: 16),
                  _buildIOUMultiSelect(),
                  const SizedBox(height: 16),
                  _buildSettlementForm(),
                ],
              );
            }
          },
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appname: 'IOU Settlements'),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Selection'),
              Tab(text: 'Data Form'),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSelection(context),
                Center( // Center content vertically and horizontally
                  child: SingleChildScrollView( // Enable vertical scrolling for overflow
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActiveListOfRequest(_settlementList),
                        SizedBox(height: 20,),
                        ElevatedButton(onPressed: (){_submitSettlementsToServer();}, child: Text('save'))
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )

        ],
      ),
    );
  }


  Widget _buildActiveListOfRequest(List<IOUSettData> iouList) {
    if (_loadTable) {
      return const Center(child: CircularProgressIndicator());
    }

    if (iouList.isEmpty) {
      return const Center(
        child: Text(
          'No IOU Settlement data found.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      );
    }

    // Create a list of all settlement items
    List<Map<String, dynamic>> allSettlements = [];
    int rowIndex = 1;

    for (var settlement in iouList) {
      for (var dist in settlement.distribution) {
        allSettlements.add({
          'rowIndex': rowIndex++,
          'iouNumber': dist['iouNumber'],
          'requestRef': dist['requestRef'],
          'settDate': settlement.settDate,
          'descr': settlement.descr,
          'remark': settlement.remark,
          'amount': dist['settledAmount'],
          'originalSettlement': settlement,
        });
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            border: TableBorder.all(width: 1, color: Colors.grey.withOpacity(0.2)),
            columnSpacing: 12,
            dataRowMinHeight: 50,
            dataRowMaxHeight: 60,
            headingRowHeight: 50,
            columns: [
              _buildDataColumn('#'),
              _buildDataColumn('IOU Number'),
              _buildDataColumn('Request Ref'),
              _buildDataColumn('Settlement Date'),
              _buildDataColumn('Description'),
              _buildDataColumn('Remark'),
              _buildDataColumn('Amount (LKR)'),
              _buildDataColumn('Actions'),
            ],
            rows: allSettlements.map((settlement) {
              return DataRow(
                cells: [
                  _buildDataCell(settlement['rowIndex'].toString()),
                  _buildDataCell(settlement['iouNumber']),
                  _buildDataCell(settlement['requestRef']),
                  _buildDataCell(settlement['settDate']),
                  _buildDataCell(settlement['descr']),
                  _buildDataCell(settlement['remark']),
                  _buildDataCell(NumberStyles.currencyStyle(settlement['amount'].toString())),
                  DataCell(
                    Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          _showDeleteConfirmation(context, settlement['originalSettlement']);
                        },
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),

    );
  }
  void _showDeleteConfirmation(BuildContext context, IOUSettData settlement) {
    YNDialogCon.ynDialogMessage(
      context,
      messageBody: 'Confirm to remove this settlement?',
      messageTitle: 'Remove Settlement',
      icon: Icons.delete_forever,
      iconColor: Colors.red,
      btnDone: 'Yes, Delete',
      btnClose: 'No',
    ).then((value) {
      if (value == 1) {
        setState(() {
          // First, reverse the settlement amounts in the IOU list
          for (var dist in settlement.distribution) {
            final iouIndex = _iouList.indexWhere(
                    (item) => item['idtbl_IOU_list'].toString() == dist['iouId'].toString()
            );

            if (iouIndex != -1) {
              double currentSettled = double.tryParse(_iouList[iouIndex]['set_amount'].toString()) ?? 0;
              _iouList[iouIndex]['set_amount'] = currentSettled - dist['settledAmount'];
            }
          }

          // Then remove the settlement
          _settlementList.remove(settlement);
        });
      }
    });
  }
  DataColumn _buildDataColumn(String title) {
    return DataColumn(
      label: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
  DataCell _buildDataCell(String value) {
    return DataCell(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Future<void> _submitSettlementsToServer() async {
    setState(() {
      _isLoading = true;
    });

    WaitDialog.showWaitDialog(context, message: 'settlements recording');

    try {
      final settlementsToSend = _settlementList.map((settlement) {
        return {
          'settlement_id': settlement.id,
          'settlement_date': settlement.settDate,
          'description': settlement.descr,
          'remarks': settlement.remark,
          'total_amount': settlement.amount,
          'created_by':UserCredentials().UserName,

          'distribution': settlement.distribution.map((dist) {
            return {
              'iou_arr': dist['iouId'],
              'iou_number': dist['iouNumber'],
              'request_ref': dist['requestRef'],
              'settled_amount': dist['settledAmount'],
            };
          }).toList(),
        };
      }).toList();

      final response = await http.post(
        Uri.parse('${APIHost().apiURL}/iou_controller.php/IOUSettlement'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "Authorization": APIToken().token,
          'created_by':UserCredentials().UserName,
          'req_type':_selectedRequestType == 0 ? "office" : "constructions",
          "settlements": settlementsToSend,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        final data = jsonDecode(response.body);
        PD.pd(text: data.toString());
        if (data['status'] == 200) {

          OneBtnDialog.oneButtonDialog(context, title: 'Process done', message: '${data['message']} process number :${data['process_id']}', btnName: 'Ok', icon:Icons.verified, iconColor: Colors.green, btnColor: Colors.green);

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Error saving settlements')),
          );
        }
      }
      else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    }
    catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

}
class IOUSettData {
  final int id;
  final String iouArry;
  final String requestRef;
  final String settDate;
  final String descr;
  final String remark;
  final double amount;
  final bool isActive;
  final String createdDate;
  final String createdBy;
  final String changeDate;
  final String changeBy;
  final List<Map<String, dynamic>> distribution;

  IOUSettData({
    required this.id,
    required this.iouArry,
    required this.requestRef,
    required this.settDate,
    required this.descr,
    required this.remark,
    required this.amount,
    required this.isActive,
    required this.createdDate,
    required this.createdBy,
    required this.changeDate,
    required this.changeBy,
    this.distribution = const [],
  });

}