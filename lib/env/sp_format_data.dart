
class RequestNumber{
  static String formatNumber({required int val}){
    return val.toString().padLeft(6,'0');
  }
  static String refNumberCon({required String val}){
    return 'CON-${val.toString()}';
  }
  static String refNumberOfz({required String val}){
    return 'OFZ-${val.toString()}';
  }
}
class IOUNumber{
  static String iouNumber({required String val}){
    return val.toString().padLeft(7,'0');
  }
}