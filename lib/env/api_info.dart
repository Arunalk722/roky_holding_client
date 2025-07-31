import 'package:url_launcher/url_launcher.dart';

class APIHost {
  //  final String apiURL = 'http://localhost:8002/RN/public/apis/controllers';
     final String apiURL = 'https://apps.api.rokyholdings.com/RN/public/apis/controllers';
  final String appVersion = '4.0.1';
}
class APIInfo{
  static String _apiVersion='';
  static void setAPI(String val){
    _apiVersion=val;
  }
  static String getAPI(){
    return _apiVersion;
  }
}
class APIToken {
  String? _token;
  APIToken._privateConstructor();
  static final APIToken _instance = APIToken._privateConstructor();

  factory APIToken() {
    return _instance;
  }
  //token
  set token(String? value) => _token = value;
  String? get token => _token;
}
Future<void> openWebPage() async {
  final Uri uri = Uri.parse('https://apps.rokyholdings.com/app_clear.html');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
  }
}


