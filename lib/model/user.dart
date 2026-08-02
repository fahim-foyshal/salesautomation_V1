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
      username: map['username'] ?? '', // Provide default value for null
      password: map['password'] ?? '', // Provide default value for null
      userId: map['user_id'] != null ? int.tryParse(map['user_id'].toString()) : null, // Safely parse int
      level: map['level'] != null ? int.tryParse(map['level'].toString()) : null, // Safely parse int
      fname: map['fname'] ?? '', // Provide default value for null
      address: map['address'] ?? '', // Provide default value for null
      email: map['email'] ?? '', // Provide default value for null
      mobile: map['mobile'] ?? '', // Provide default value for null
      designation: map['designation'] ?? '', // Provide default value for null
      status: (map['status'] != null && map['status'].isNotEmpty) ? map['status'] : 'Active', // Default to 'Active'
      groupFor: map['group_for'] != null ? int.tryParse(map['group_for'].toString()) : null, // Safely parse int
      dealerCode: map['dealer_code'] != null ? int.tryParse(map['dealer_code'].toString()) : null, // Safely parse int
      productGroup: map['product_group'] ?? '', // Provide default value for null
      regionId: map['region_id'] != null ? int.tryParse(map['region_id'].toString()) : null, // Safely parse int
      zoneId: map['zone_id'] != null ? int.tryParse(map['zone_id'].toString()) : null, // Safely parse int
      areaId: map['area_id'] != null ? int.tryParse(map['area_id'].toString()) : null, // Safely parse int
      entryAt: map['entry_at'] ?? '', // Provide default value for null
      editAt: map['edit_at'] ?? '', // Provide default value for null
      lastLogin: map['last_login'] ?? '', // Provide default value for null
      lastRecovery: map['last_recovery'] ?? '', // Provide default value for null
      appLevel: map['app_level'] != null ? int.tryParse(map['app_level'].toString()) : null, // Safely parse int
      targetVisit: map['target_visit'] != null ? int.tryParse(map['target_visit'].toString()) : null, // Safely parse int
      geoLock: map['geo_lock'] != null ? int.tryParse(map['geo_lock'].toString()) : null, // Safely parse int
      geoLockMeter: map['geo_lock_meter'] != null ? int.tryParse(map['geo_lock_meter'].toString()) : null, // Safely parse int
      fgType: map['fg_type'] ?? '', // Provide default value for null
    );
  }




}