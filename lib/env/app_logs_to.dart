import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/print_debug.dart';
import 'package:roky_holding/env/user_data.dart';
import 'api_info.dart';

class ExceptionLogger {
  static Future<void> logToError({
    required String message,
    required String errorLog,
    required String logFile,
  }) async {
      try {
        String reqUrl = '${APIHost().apiURL}/app_log.php/AppLog';  // Your API endpoint
        PD.pd(text: reqUrl);
        final response = await http.post(
          Uri.parse(reqUrl),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({"Authorization": APIToken().token,
            "mg":message,
            "logFile":logFile,
            "errorLog":errorLog,
            "userName":UserCredentials().UserName??"UNKNOWN"}),
        );
        PD.pd(text: reqUrl);
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['status'] == 200) {
          } else {
            final String message = responseData['message'] ?? 'Error';
            PD.pd(text: message);
          }
        } else {
          PD.pd(text: "HTTP Error: ${response.statusCode}");
        }
      } catch (e) {

        PD.pd(text: e.toString());
      }
  }
}
