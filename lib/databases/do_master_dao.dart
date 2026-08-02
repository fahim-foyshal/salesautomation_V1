import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../model/do_master.dart'; // Assuming you have the DoMaster model defined.
import 'database_helper.dart';

class DoMasterDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Insert a DoMaster record into the database
  Future<int> insertDoMaster(DoMaster doMaster) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'do_master',
      doMaster.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert a DoMaster record using a transaction
  Future<int> insertDoMasterWithTransaction(Transaction txn, DoMaster doMaster) async {
    return await txn.insert(
      'do_master',
      doMaster.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all DoMaster records from the database
  Future<List<DoMaster>> getAllDoMasters() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'do_master',
      orderBy: 'do_offline_id DESC', // Replace 'doNo' with the column you want to order by
    );
    return List.generate(maps.length, (i) {
      return DoMaster.fromMap(maps[i]);
    });
  }



  // Get a DoMaster record by do_offline_id
  Future<DoMaster?> getDoMasterById(int doOfflineId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'do_master',
      where: 'do_offline_id = ?',
      whereArgs: [doOfflineId],
    );
    if (maps.isNotEmpty) {
      return DoMaster.fromMap(maps.first);
    }
    return null;
  }

  // Get a DoMaster record by do_no
  Future<DoMaster?> getDoMasterByDoNo(String doNo) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'do_master',
      where: 'do_no = ?',
      whereArgs: [doNo],
    );
    if (maps.isNotEmpty) {
      return DoMaster.fromMap(maps.first);
    }
    return null;
  }

  // Update a DoMaster record
  Future<int> updateDoMaster(DoMaster doMaster) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'do_master',
      doMaster.toMap(),
      where: 'do_offline_id = ?',
      whereArgs: [doMaster.doOfflineId],
    );
  }

  // Delete a DoMaster record by do_offline_id
  Future<int> deleteDoMaster(int doOfflineId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'do_master',
      where: 'do_offline_id = ?',
      whereArgs: [doOfflineId],
    );
  }

  // Update sent status of a DoMaster record
  Future<int> updateSentStatus(int doOfflineId, String sentStatus) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'do_master',
      {'sent_status': sentStatus},
      where: 'do_offline_id = ?',
      whereArgs: [doOfflineId],
    );
  }
  // Get a list of DoMaster records by status
  Future<List<DoMaster>> getDoMastersByStatus(String status) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'do_master',
      where: 'status = ?',
      whereArgs: [status],
    );

    return List.generate(maps.length, (i) {
      return DoMaster.fromMap(maps[i]);
    });
  }


  // Search DoMaster records between two dates, optionally filtering by status
  Future<List<DoMaster>> searchDoMastersBetweenDatesAndStatus(
      DateTime startDate, DateTime endDate, {String? status}) async {
    final db = await _databaseHelper.database;

    // Format the dates as strings for comparison
    String startDateString = DateFormat('yyyy-MM-dd HH:mm:ss').format(startDate);
    String endDateString = DateFormat('yyyy-MM-dd HH:mm:ss').format(endDate);

    // Build the query with optional status filter
    String query = 'SELECT * FROM do_master WHERE do_date BETWEEN ? AND ?';
    List<dynamic> whereArgs = [startDateString, endDateString];

    // If status is provided, add it to the query
    if (status != null) {
      query += ' AND status = ?';
      whereArgs.add(status);
    }

    // Execute the query
    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);

    return List.generate(maps.length, (i) {
      return DoMaster.fromMap(maps[i]);
    });
  }

  // Update location data when order is confirmed
  Future<int> updateLocationData(int doOfflineId, String endLatitude, String endLongitude) async {
    final db = await _databaseHelper.database;
    
    // Update the database
    int result = await db.update(
      'do_master',
      {
        'end_latitude': endLatitude,
        'end_longitude': endLongitude,
      },
      where: 'do_offline_id = ?',
      whereArgs: [doOfflineId],
    );
    
    // Also update the DoMaster object if it's passed to updateDoMaster later
    DoMaster? doMaster = await getDoMasterById(doOfflineId);
    if (doMaster != null) {
      doMaster.endLatitude = endLatitude;
      doMaster.endLongitude = endLongitude;
    }
    
    return result;
  }
}
