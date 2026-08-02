import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// Import the ItemJournal model

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('secondarysales.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
  CREATE TABLE ss_user (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    password TEXT NOT NULL,
    level INTEGER DEFAULT NULL,
    fname TEXT DEFAULT NULL,
    address TEXT DEFAULT NULL,
    email TEXT DEFAULT NULL,
    mobile TEXT DEFAULT NULL,
    designation TEXT DEFAULT NULL,
    status TEXT CHECK(status IN ('Active', 'Inactive')) DEFAULT 'Active',
    group_for INTEGER DEFAULT NULL,
    dealer_code INTEGER DEFAULT NULL,
    product_group TEXT DEFAULT NULL,
    region_id INTEGER DEFAULT NULL,
    zone_id INTEGER DEFAULT NULL,
    area_id INTEGER DEFAULT NULL,
    entry_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    edit_at TIMESTAMP DEFAULT NULL,
    last_login TEXT DEFAULT NULL,
    last_recovery TEXT DEFAULT NULL,
    app_level INTEGER DEFAULT NULL,
    target_visit INTEGER DEFAULT NULL,
    geo_lock INTEGER DEFAULT 0,
    geo_lock_meter INTEGER DEFAULT NULL,
    fg_type TEXT DEFAULT NULL
  );
''');

    await db.execute('''
  CREATE TABLE routes (
  route_id INTEGER ,
  route_name TEXT NOT NULL                     
);
''');
    await db.execute('''
  CREATE TABLE shops (
  dealer_code INTEGER ,
  shop_name TEXT NOT NULL  ,   
  route_id TEXT NOT NULL,
  latitude TEXT NOT NULL,
  longitude TEXT NOT NULL
);
''');

    await db.execute('''
      CREATE TABLE category (
        id INTEGER PRIMARY KEY,
        category_name TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE sub_category (
        id INTEGER PRIMARY KEY,
        subcategory_name TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE item (
        item_id TEXT PRIMARY KEY,
        finish_goods_code TEXT NOT NULL,
        item_name TEXT NOT NULL,
        unit_name TEXT NOT NULL,
        t_price TEXT NOT NULL,
        pack_size TEXT NOT NULL,
        nsp_per TEXT NOT NULL,
        category_id TEXT NOT NULL,
        subcategory_id TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE do_master (
        do_offline_id INTEGER PRIMARY KEY AUTOINCREMENT,
        do_no TEXT,
        shop_id TEXT NOT NULL,
        do_date TEXT NOT NULL,
        status TEXT NOT NULL,
        sent_status TEXT NOT NULL DEFAULT 'pending',  -- Added sent_status column
        trade_offer_applied NOT NULL,
        start_latitude TEXT,
        start_longitude TEXT,
        combo_id TEXT,
        end_latitude TEXT,
        end_longitude TEXT,
        note TEXT,
        type TEXT
      );
    ''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS item_details (
  do_details_id INTEGER PRIMARY KEY AUTOINCREMENT,  
  do_master_id TEXT,               
  item_id TEXT NOT NULL,           
  finish_goods_code TEXT,          
  item_name TEXT,                  
  unit_name TEXT,                  
  t_price TEXT,                    
  pack_size TEXT,                  
  nsp_per TEXT,                    
  nsp_org TEXT,                    
  nsp_extra TEXT,                                      
  category_id TEXT,                
  subcategory_id TEXT,             
  offer TEXT DEFAULT '',           
  qty TEXT DEFAULT '',             
  amt TEXT DEFAULT '', 
  gift_id TEXT,            
  FOREIGN KEY (item_id) REFERENCES items(item_id)  
);
    ''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS trade_offer (
  id INTEGER PRIMARY KEY,
  year TEXT NOT NULL,
  mon TEXT NOT NULL,
  offer_name TEXT NOT NULL,
  item_list TEXT NOT NULL,
  min_taka TEXT NOT NULL,
  max_taka TEXT NOT NULL,
  gift_item_id TEXT NOT NULL,
  git_qty TEXT NOT NULL,
  gift_item_name TEXT NOT NULL,
  status TEXT CHECK(status IN ('Active', 'Inactive')) DEFAULT 'Active',
  combo_id INTEGER NOT NULL,

  entry_by TEXT DEFAULT '',
  entry_at TEXT DEFAULT ''
);
    ''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS trade_offer_percentage (
  id INTEGER PRIMARY KEY,
  year TEXT NOT NULL,
  mon TEXT NOT NULL,
  offer_name TEXT NOT NULL,
  item_list TEXT NOT NULL,
  min_taka TEXT NOT NULL,
  max_taka TEXT NOT NULL,
  percentage TEXT NOT NULL,
  status TEXT CHECK(status IN ('Active', 'Inactive')) DEFAULT 'Active',
  combo_id INTEGER NOT NULL,
  entry_by TEXT DEFAULT '',
  entry_at TEXT DEFAULT ''
);
    ''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS trade_offer_percentage_extra (
  id INTEGER PRIMARY KEY,
  year TEXT NOT NULL,
  mon TEXT NOT NULL,
  offer_name TEXT NOT NULL,
  item_list TEXT NOT NULL,
  min_taka TEXT NOT NULL,
  max_taka TEXT NOT NULL,
  percentage TEXT NOT NULL,
  status TEXT CHECK(status IN ('Active', 'Inactive')) DEFAULT 'Active',
  combo_id INTEGER NOT NULL,
  entry_by TEXT DEFAULT '',
  entry_at TEXT DEFAULT ''
);
    ''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS trade_item_offer (
  id INTEGER PRIMARY KEY,
  year TEXT NOT NULL,
  mon TEXT NOT NULL,
  offer_name TEXT NOT NULL,
  item_list TEXT NOT NULL,
  min_qty TEXT NOT NULL,
  max_qty TEXT NOT NULL,
  gift_item_id TEXT NOT NULL,
  git_qty TEXT NOT NULL,
  gift_item_name TEXT NOT NULL,
  combo_id INTEGER NOT NULL,
  status TEXT CHECK(status IN ('Active', 'Inactive')) DEFAULT 'Active',
  entry_by TEXT DEFAULT '',
  entry_at TEXT DEFAULT ''
);
    ''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS trade_offer_comission (
  id INTEGER PRIMARY KEY,
  year TEXT NOT NULL,
  mon TEXT NOT NULL,
  offer_name TEXT NOT NULL,
  item_group TEXT NOT NULL,
  item_list TEXT NOT NULL,
  min_qty TEXT NOT NULL,
  max_qty TEXT NOT NULL,
  combo_id INTEGER NOT NULL,
  free_qty TEXT NOT NULL,
  trade_com_per TEXT NOT NULL
);
    ''');

    await db.execute('''
  CREATE TABLE combos (
  id INTEGER ,
  name TEXT NOT NULL,
  status INTEGER DEFAULT 0

);
''');
  }
}
