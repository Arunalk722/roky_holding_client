import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';

class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({super.key});

  @override
  _ResetPasswordFormState createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final TextEditingController _txtUserName = TextEditingController();
  final TextEditingController _txtEmail = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    } else if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex =
    RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  Widget buildTextField(
      TextEditingController controller, String label, String hint, IconData icon,
      {bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.deepPurple[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
      ),
      validator: isEmail ? _validateEmail : _validateUsername,
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _sendEmails();
    }
  }

  Future<void> _sendEmails() async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Sending reset request...');
      String reqUrl = '${APIHost().apiURL}/user_controller.php/ForgetPasswordReset';
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _txtEmail.text.toString(),
          "user_name": _txtUserName.text.toString(),
        }),
      );
      PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          OneBtnDialog.oneButtonDialog(
            context,
            title: 'Success',
            message: 'A temporary password has been sent to your email.',
            btnName: 'OK',
            icon: Icons.check_circle,
            iconColor: Colors.green,
            btnColor: Colors.black,
          );
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
        WaitDialog.hideDialog(context);
        OneBtnDialog.oneButtonDialog(
          context,
          title: 'Error',
          message: 'Failed to send reset request. Please try again.',
          btnName: 'OK',
          icon: Icons.error,
          iconColor: Colors.red,
          btnColor: Colors.black,
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'login.dart');
      PD.pd(text: e.toString());
      WaitDialog.hideDialog(context);
      OneBtnDialog.oneButtonDialog(
        context,
        title: 'Error',
        message: 'An unexpected error occurred. Please try again.',
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
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enter your details',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepPurple),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                buildTextField(_txtUserName, 'Username', 'Enter username',
                    Icons.person_outline),
                const SizedBox(height: 20),
                buildTextField(_txtEmail, 'Email', 'Enter email',
                    Icons.email_outlined,
                    isEmail: true),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.deepPurple,
                    elevation: 5,
                  ),
                  child: const Text('Submit',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 24),
                const Center(
                    child: Text(
                      "We will send a temporary password to your email",
                      style: TextStyle(color: Colors.grey),
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}