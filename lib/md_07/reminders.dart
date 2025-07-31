import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/app_bar.dart';
import 'dart:convert';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/user_data.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  RemindersScreenState createState() => RemindersScreenState();
}

class RemindersScreenState extends State<RemindersScreen> {
  List<dynamic> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReminders();
    });

  }

  Future<void> _loadReminders() async {
    try {
      setState(() => _isLoading = true);
      final response = await http.post(
        Uri.parse('${APIHost().apiURL}/reminders_controller.php/GetRemindersByUser'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Authorization": APIToken().token,"create_by":UserCredentials().UserName}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200) {
          setState(() => _reminders = data['data'] ?? []);
        } else {
          showErrorDialog(context, data['message'] ?? 'Failed to load reminders');
        }
      } else {
        handleHttpError(context, response);
      }
    } catch (e) {
      handleGeneralError(context, e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appname: 'Reminders'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddReminderDialog(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No reminders yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add one',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadReminders,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _reminders.length,
          itemBuilder: (context, index) {
            final reminder = _reminders[index];
            return _buildReminderCard(reminder);
          },
        ),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    final date = DateTime.parse(reminder['remind_date']);
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reminder['reminder_log'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditReminderDialog(context, reminder);
                    } else if (value == 'delete') {
                      _confirmDeleteReminder(context, reminder);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String reminderText = '';
    DateTime selectedDate = DateTime.now();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Reminder'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Reminder Text',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter reminder text' : null,
                    onChanged: (value) => reminderText = value,
                  ),
                  const SizedBox(height: 16),
                  DatePickerWidget(
                    label: 'Reminder Date',
                    initialDate: selectedDate,
                    onDateSelected: (date) => selectedDate = date,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  await _createReminder(
                    context,
                    reminderText,
                    selectedDate.toIso8601String(),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditReminderDialog(BuildContext context, Map<String, dynamic> reminder) {
    final formKey = GlobalKey<FormState>();
    String reminderText = reminder['reminder_log'];
    DateTime selectedDate = DateTime.parse(reminder['remind_date']);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Reminder'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: reminderText,
                    decoration: const InputDecoration(
                      labelText: 'Reminder Text',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter reminder text' : null,
                    onChanged: (value) => reminderText = value,
                  ),
                  const SizedBox(height: 16),
                  DatePickerWidget(
                    label: 'Reminder Date',
                    initialDate: selectedDate,
                    onDateSelected: (date) => selectedDate = date,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context);
                  await _updateReminder(
                    context,
                    reminder['idtbl_my_reminders'].toString(),
                    reminderText,
                    selectedDate.toIso8601String(),
                  );
                }
              },
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteReminder(BuildContext context, Map<String, dynamic> reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder['reminder_log']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            onPressed: () async {
              await _deleteReminder(context, reminder['idtbl_my_reminders'].toString());
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createReminder(BuildContext context, String text, String date) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Creating reminder...');
      final response = await http.post(
        Uri.parse('${APIHost().apiURL}/reminders_controller.php/CreateReminder'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "reminder_log": text,
          "remind_date": date,
          "create_by": UserCredentials().UserName,
        }),
      );

      WaitDialog.hideDialog(context);
      WaitDialog.hideDialog(context);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == 200) {
          OneBtnDialog.oneButtonDialog(
            context,
            title: "Success",
            message: responseData['message'],
            btnName: 'OK',
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            btnColor: Colors.blue[600]!,
          ).then((v){
            if(v==true){
              _loadReminders();
            }
          });

        } else {
          showErrorDialog(context, responseData['message'] ?? 'Failed to create reminder');
        }
      } else {
        handleHttpError(context, response);
      }
    } catch (e) {
      handleGeneralError(context, e);
    }
  }

  Future<void> _updateReminder(BuildContext context, String id, String text, String date) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Updating reminder...');

      final response = await http.post(
        Uri.parse('${APIHost().apiURL}/reminders_controller.php/UpdateReminder'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "idtbl_my_reminders": id,
          "reminder_log": text,
          "remind_date": date,
          "create_by": UserCredentials().UserName,
        }),
      );

      WaitDialog.hideDialog(context);
      WaitDialog.hideDialog(context);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == 200) {
          OneBtnDialog.oneButtonDialog(
            context,
            title: "Success",
            message: responseData['message'],
            btnName: 'OK',
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            btnColor: Colors.blue[600]!,
          ).then((v){
            if(v==true){
              _loadReminders();
            }
          });
        } else {
          showErrorDialog(context, responseData['message'] ?? 'Failed to update reminder');
        }
      } else {
        handleHttpError(context, response);
      }
    } catch (e) {
      handleGeneralError(context, e);
    }
  }

  Future<void> _deleteReminder(BuildContext context, String id) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Deleting reminder...');

      final response = await http.post(
        Uri.parse('${APIHost().apiURL}/reminders_controller.php/DeleteReminder'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "idtbl_my_reminders": id,
          "create_by": UserCredentials().UserName,
        }),
      );
      WaitDialog.hideDialog(context);
      WaitDialog.hideDialog(context);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == 200) {
          OneBtnDialog.oneButtonDialog(
            context,
            title: "Success",
            message: responseData['message'],
            btnName: 'OK',
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            btnColor: Colors.blue[600]!,
          ).then((v){
            if(v==true){
              _loadReminders();
            }
          });
        } else {
          showErrorDialog(context, responseData['message'] ?? 'Failed to delete reminder');
        }
      } else {
        handleHttpError(context, response);
      }
    } catch (e) {
      handleGeneralError(context, e);
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    OneBtnDialog.oneButtonDialog(
      context,
      title: "Error",
      message: message,
      btnName: 'OK',
      icon: Icons.error_outline,
      iconColor: Colors.red,
      btnColor: Colors.blue[600]!,
    );
  }

  void handleHttpError(BuildContext context, http.Response response) {
    showErrorDialog(
      context,
      'Server returned status code ${response.statusCode}: ${response.reasonPhrase}',
    );
  }

  void handleGeneralError(BuildContext context, dynamic error) {
    if (!mounted) return;

    OneBtnDialog.oneButtonDialog(
      context,
      title: "Error",
      message: error.toString(),
      btnName: 'OK',
      icon: Icons.error_outline,
      iconColor: Colors.red,
      btnColor: Colors.blue[600]!,
    );
  }
}



class DatePickerWidget extends StatelessWidget {
  final String label;
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const DatePickerWidget({
    Key? key,
    required this.label,
    required this.initialDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Colors.blue,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (date != null) {
              onDateSelected(date); // Just pass the selected date directly
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(initialDate),
                  style: TextStyle(color: Colors.grey[800]),
                ),
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}