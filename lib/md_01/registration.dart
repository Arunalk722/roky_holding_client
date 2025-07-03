import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:roky_holding/env/input_widget.dart';
import 'package:roky_holding/md_01/login.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';
import 'package:http/http.dart' as http;

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _txtUserName = TextEditingController();
  final TextEditingController _txtEmail = TextEditingController();
  final TextEditingController _txtPassword = TextEditingController();
  final TextEditingController _txtConfirmPassword = TextEditingController();
  final TextEditingController _txtPhone = TextEditingController();
  final TextEditingController _txtDisplayName = TextEditingController();
  bool isValidEmail(String email) {
    final RegExp emailRegExp = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");
    return emailRegExp.hasMatch(email);
  }

  Future<void> _createUser(BuildContext context) async {
    try {
      WaitDialog.showWaitDialog(context, message: 'Creating user...');
      final response = await http.post(
        Uri.parse('${APIHost().apiURL}/user_controller.php/create'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _txtUserName.text,
          "password": _txtPassword.text,
          "email": _txtEmail.text,
          "phoneNumber": _txtPhone.text,
          "display_name": _txtDisplayName.text
        }),
      );

      PD.pd(text: "Response: ${response.statusCode} - ${response.body}");
      WaitDialog.hideDialog(context);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String message = responseData['message'];
        final int status = responseData['status'];

        if (status == 200) {
          PD.pd(text: "User created successfully: $message");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User has been created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          PD.pd(text: "User creation failed: $message");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration Failed: $message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      else {
        WaitDialog.hideDialog(context);
        String errorMessage = 'Registration failed with status code ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e,st) {
            ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'login.dart');
            errorMessage = response.body;
          }
        }

        PD.pd(text: errorMessage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'login.dart');
      WaitDialog.hideDialog(context);
      String errorMessage = 'An error occurred: $e';

      if (e is FormatException) {
        errorMessage = 'Invalid JSON response.';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        // Use a Column for the main layout
        children: [
          Expanded(
            // Use Expanded to fill available space for the form
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  width: 400,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset( 'assets/image/logo.png',
                          height: 80,
                          errorBuilder: (context, object, stackTrace) {
                            print('Image load failed: $object, Stack trace: $stackTrace');  // Print the error to the console
                            return const Icon(Icons.error); // Show an error icon
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Register",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        buildTextField(_txtDisplayName, 'Display Name',
                            'Enter your Display name', Icons.person, true, 45),
                        buildTextField(_txtUserName, 'User Name',
                            'Enter your user name', Icons.person, true, 20),
                        buildTextField(_txtEmail, 'Email',
                            'Enter your email', Icons.email, true, 45),
                        buildTextField(_txtPhone, 'Phone Number',
                            '077XXXXXXX', Icons.phone, true, 10),
                        buildPwdTextField(_txtPassword, 'Password',
                            'Enter your password', Icons.password_rounded, true, 20),
                        buildPwdTextField(_txtConfirmPassword, 'Confirm Password',
                            'Confirm your password', Icons.password_rounded, true, 20),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {if (_txtUserName.text.length < 5) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User name must be at least 5 characters long.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else if (!isValidEmail(_txtEmail.text)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid email address.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else if (_txtPhone.text.length < 10) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Phone number must be at least 10 digits.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else if (_txtPassword.text != _txtConfirmPassword.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Passwords do not match.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else if (_txtPassword.text.length < 5) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password must be at least 5 characters long.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            _createUser(context);
                          }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 100,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text(
                            "Register",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginApp()));
                          },
                          child: const Text(
                            "Already have an account? Login",
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Footer Image
          SizedBox(
            height: 40,
            width: 40,
            child: Image.asset(
              'assets/image/HBiz.jpg',
              fit: BoxFit.cover, // or other BoxFit values
            ),
          )
        ],
      ),
      backgroundColor: Colors.grey[200],
    );
  }
}
