import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/app_versions.dart';
import 'package:roky_holding/md_01/registration.dart';
import 'package:roky_holding/md_01/reset_password.dart';
import 'package:roky_holding/md_02/home_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../env/DialogBoxs.dart';
import '../env/app_logs_to.dart';
import '../env/input_widget.dart';
import '../env/print_debug.dart';
import '../env/user_data.dart';

class LoginApp extends StatefulWidget {
  const LoginApp({super.key});

  @override
  State<LoginApp> createState() => _LoginAppState();
}

class _LoginAppState extends State<LoginApp> {
  final TextEditingController _userName = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    super.setState(() {
      _userName.text = 'admin';
      _password.text = '123Admin@@';
    });
  }

  Future<void> clearSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }



  Future<void> loginSystem() async {
    WaitDialog.showWaitDialog(context, message: 'Login');

    try {
      final response = await http.post(
        Uri.parse('${APIHost().apiURL}/login_controller.php/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _userName.text,
          "password": _password.text
        }),
      );
      if (response.statusCode == 200) {
        WaitDialog.hideDialog(context);
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        final int status = responseData['status'];
        if (status == 200) {
          UserCredentials().setUserData(
              responseData['user_name'],
              responseData['email'],
              responseData['phone'],
              responseData['idtbl_users'],
              responseData['req_pw_change']
          );
          APIToken().token = responseData['token'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token']);
          await prefs.setString('user_name', responseData['user_name']);
          await prefs.setString('email', responseData['email']);
          await prefs.setString('phone', responseData['phone']);
          await prefs.setInt('idtbl_users', responseData['idtbl_users']??0);
          await prefs.setInt('req_pw_change', responseData['req_pw_change']??0);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful! Redirecting...'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(isAdvance: responseData['is_advance_mode']==1?true:false)),
          );
        } else {
          final String message = responseData['message'] ?? 'Login failed';
          PD.pd(text: message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to login: $message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      else {

        String errorMessage = 'Login failed with status code ${response.statusCode}';
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
      String errorMessage = 'An error occurred during login: $e';
      if (e is FormatException) {
        errorMessage = 'Invalid JSON response';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your connection.';
      }
      PD.pd(text: errorMessage);
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Padding(
              // Added padding inside the container
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Added Image at the top
                  Image.asset(
                    'assets/image/logo.png',
                    scale: 1,
                    height: 80,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "WELCOME TO THE",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const Text(
                    "ROKY HOLDINGS",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildTextField(_userName, 'User Name',
                      'Enter your user name', Icons.person, true, 20),
                  buildPwdTextField(_password, 'Password',
                      'Your password', Icons.password_rounded, true, 20),
                  ElevatedButton(
                    onPressed: () {
                      if(APIInfo.getAPI()==APIHost().appVersion)
                      {
                        loginSystem();
                      }
                      else{
                        if(kIsWeb)
                        {
                          clearSharedPreferences();
                          openWebPage();
                        }
                        else{
                          OneBtnDialog.oneButtonDialog(
                            context,
                            title: 'Invalid App Version',
                            message: 'For security reasons, we have restricted logins from invalid app versions. If you see this error, try the following:\n\n1. If you are trying to log in using a web browser, clear your cache.\n2. Use private browsing mode.\n\nIf the issue persists, please contact support.',
                            btnName: 'Ok',
                            icon: Icons.restart_alt,
                            iconColor: Colors.red,
                            btnColor: Colors.black,
                          );
                        }
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
                      "Login",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    // Changed to TextButton for "Need help?"
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>  ResetPasswordForm()));
                    },

                    child: const Text(
                      "Trouble to login?",
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                  TextButton(
                    // Changed to TextButton for "Need help?"
                    onPressed: () {

                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegistrationPage()));
                    },

                    child: const Text(
                      "Create new Account",
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                  AppVersionTile(),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[200], // Changed background color
    );
  }
}

