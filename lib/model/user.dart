class User {
  final String username;  // Required
  final String password;  // Required
  final int? userId;
  final int? level;
  final String? fname;
  final String? address;
  final String? email;
  final String? mobile;
  final String? designation;
  final String? status;
  final int? groupFor;
  final int? dealerCode;
  final String? productGroup;
  final int? regionId;
  final int? zoneId;
  final int? areaId;
  final String? entryAt;
  final String? editAt;
  final String? lastLogin;
  final String? lastRecovery;
  final int? appLevel;
  final int? targetVisit;
  final int? geoLock;
  final int? geoLockMeter;
  final String? fgType;

  User({
    required this.username,
    required this.password,
    this.userId,
    this.level,
    this.fname,
    this.address,
    this.email,
    this.mobile,
    this.designation,
    this.status,
    this.groupFor,
    this.dealerCode,
    this.productGroup,
    this.regionId,
    this.zoneId,
    this.areaId,
    this.entryAt,
    this.editAt,
    this.lastLogin,
    this.lastRecovery,
    this.appLevel,
    this.targetVisit,
    this.geoLock,
    this.geoLockMeter,
    this.fgType,
  });

  // Convert User object to a map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'user_id': userId,
      'level': level,
      'fname': fname,
      'address': address,
      'email': email,
      'mobile': mobile,
      'designation': designation,
      'status': status,
      'group_for': groupFor,
      'dealer_code': dealerCode,
      'product_group': productGroup,
      'region_id': regionId,
      'zone_id': zoneId,
      'area_id': areaId,
      'entry_at': entryAt,
      'edit_at': editAt,
      'last_login': lastLogin,
      'last_recovery': lastRecovery,
      'app_level': appLevel,
      'target_visit': targetVisit,
      'geo_lock': geoLock,
      'geo_lock_meter': geoLockMeter,
      'fg_type': fgType,
    };
  }

  // Create a User object from a map (retrieved from a query)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'],
      password: map['password'],
      userId: map['user_id'],
      level: map['level'],
      fname: map['fname'],
      address: map['address'],
      email: map['email'],
      mobile: map['mobile'],
      designation: map['designation'],
      status: map['status'],
      groupFor: map['group_for'],
      dealerCode: map['dealer_code'],
      productGroup: map['product_group'],
      regionId: map['region_id'],
      zoneId: map['zone_id'],
      areaId: map['area_id'],
      entryAt: map['entry_at'],
      editAt: map['edit_at'],
      lastLogin: map['last_login'],
      lastRecovery: map['last_recovery'],
      appLevel: map['app_level'],
      targetVisit: map['target_visit'],
      geoLock: map['geo_lock'],
      geoLockMeter: map['geo_lock_meter'],
      fgType: map['fg_type'],
    );
  }
}
