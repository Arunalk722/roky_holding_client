class MaterialData {
  final int idtbl_material_list;
  final int work_list_id;
  final int cost_category_id;
  final String material_name;
  final String qty;
  final String uom;
  final String amount;
  final int is_edit_allow;
  final String created_date;
  final String created_by;
  final String change_date;
  final String change_by;
  final int is_active;
  MaterialData({
    required this.idtbl_material_list,
    required this.work_list_id,
    required this.cost_category_id,
    required this.material_name,
    required this.qty,
    required this.uom,
    required this.amount,
    required this.is_edit_allow,
    required this.created_date,
    required this.created_by,
    required this.change_date,
    required this.change_by,
    required this.is_active,
  });
  factory MaterialData.fromJson(Map<String, dynamic> json) {
    return MaterialData(
      idtbl_material_list: json['idtbl_material_list'] as int,
      work_list_id: json['work_list_id'] as int,
      cost_category_id: json['cost_category_id'] as int,
      material_name: json['material_name'] as String,
      qty: json['qty'] as String,
      uom: json['uom'] as String,
      amount: json['amount'] as String,
      is_edit_allow: json['is_edit_allow'] as int,
      created_date: json['created_date'] as String,
      created_by: json['created_by'] as String,
      change_date: json['change_date'] as String,
      change_by: json['change_by'] as String,
      is_active: json['is_active'] as int,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'idtbl_material_list': idtbl_material_list,
      'work_list_id': work_list_id,
      'cost_category_id': cost_category_id,
      'material_name': material_name,
      'qty': qty,
      'uom': uom,
      'amount': amount,
      'is_edit_allow': is_edit_allow,
      'created_date': created_date,
      'created_by': created_by,
      'change_date': change_date,
      'change_by': change_by,
      'is_active': is_active,
    };
  }
}