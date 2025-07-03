class UserCredentials {
  String? _userName;
  int? _userId;
  String? _email;
  String? _phone;
  int? _reqPwChange;
  double? _authCreditLimit;
  UserCredentials._privateConstructor();
  static final UserCredentials _instance = UserCredentials._privateConstructor();
  factory UserCredentials() {
    return _instance;
  }
  String? get UserName => _userName;
  int? get UserId => _userId;
  String? get Email =>_email;
  String? get PhoneNumber =>_phone;
  int? get Req_pw_change =>_reqPwChange;
  double? get AuthCreditLimit => _authCreditLimit;
  set UserName(String? value) => _userName = value;
  set UserId(int? value) => _userId = value;
  set PhoneNumber(String? value) => _phone = value;
  set Email(String? value) => _email = value;
  set Req_pw_change(int? value) => _reqPwChange = value;
  set AuthCreditLimit(double? value) => _authCreditLimit=value;
  void setUserData(String? name,String? email,String? phoneNumber, int? id,int? redPwdChange) {
    _userName = name;
    _userId = id;
    _email=email;
    _phone=phoneNumber;
    _reqPwChange=redPwdChange;
  }
}