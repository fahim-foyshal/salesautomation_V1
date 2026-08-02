import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
 // Import the ItemJournal model

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('products.db');
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
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        salePrice TEXT,
        stock TEXT,
        purchasePrice TEXT,
        category TEXT,
        subCategory TEXT,
        unit TEXT,
        details TEXT,
        onlineSell INTEGER,
        wholesaleSell INTEGER,
        stockAlert INTEGER,
        vatApplicable INTEGER,
        warranty INTEGER,
        discount INTEGER,
        images TEXT
      )
    ''');

    await db.execute(''' 
      CREATE TABLE item_journal (
        id TEXT PRIMARY KEY,
        item_id TEXT,
        date TEXT,
        warehouse_id TEXT,
        warehouse_to TEXT,
        pre_stock INTEGER,
        pre_price REAL,
        item_in INTEGER,
        item_ex INTEGER,
        item_price REAL,
        post_stock INTEGER,
        post_price REAL,
        final_price REAL,
        batch_no TEXT,
        tr_no TEXT,
        tr_id TEXT,
        tr_from TEXT,
        entry_at TEXT,
        entry_by TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE inventory_journal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id TEXT NOT NULL,
        item_in INTEGER DEFAULT 0,
        item_ex INTEGER DEFAULT 0,
        balance INTEGER NOT NULL,
        transaction_date TEXT NOT NULL,
        reference_id TEXT NOT NULL,
        transaction_reason TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        purchase_id TEXT PRIMARY KEY,
        supplier_id TEXT,
        purchase_date TEXT,
        received_by TEXT,
        payment_type TEXT
        delivery_charge REAL,
        discount_amount REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id TEXT,
        item_id TEXT,
        quantity INTEGER,
        unit_price REAL,
        total_price REAL

      )
    ''');
    await db.execute('''
  CREATE TABLE suppliers (
    supplier_id TEXT PRIMARY KEY,
    name TEXT,
    contact_details TEXT,
    type TEXT
  )
''');

    // 3. Invoice table
    //    Now includes 'invoice_type' so we can track "PAYABLE" vs. "RECEIVABLE".
    await db.execute('''
    CREATE TABLE Invoice (
      invoice_id TEXT PRIMARY KEY,
      party_id TEXT,
      invoice_type TEXT NOT NULL,  -- "PAYABLE" or "RECEIVABLE"
      invoice_date TEXT NOT NULL,
      due_date TEXT,
      invoice_amount REAL NOT NULL,
      status TEXT DEFAULT 'Open',
      FOREIGN KEY (party_id) REFERENCES Party(party_id)
    )
  ''');

    // 4. InvoiceItem table (remains similar; each line references the Invoice + Item)
    await db.execute('''
    CREATE TABLE InvoiceItem (
      inv_item_id TEXT PRIMARY KEY,
      invoice_id TEXT NOT NULL,
      item_id TEXT NOT NULL,
      quantity REAL NOT NULL,
      unit_price REAL NOT NULL,
      FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id),
      FOREIGN KEY (item_id) REFERENCES Item(item_id)
    )
  ''');

    // 5. Payment table
    //    Add 'payment_type' for "INCOMING" (receivable payments from customers)
    //    vs. "OUTGOING" (payable payments to suppliers).
    await db.execute('''
    CREATE TABLE Payment (
      payment_id TEXT PRIMARY KEY,
      party_id TEXT,
      payment_date TEXT NOT NULL,
      payment_method TEXT NOT NULL,
      payment_type TEXT NOT NULL,  -- "INCOMING" or "OUTGOING"
      payment_amount REAL NOT NULL,
      notes TEXT,
      FOREIGN KEY (party_id) REFERENCES Party(party_id)
    )
  ''');

    // 6. PaymentAllocation table
    //    Links each Payment to specific Invoices and amounts allocated.
    await db.execute('''
    CREATE TABLE PaymentAllocation (
      allocation_id TEXT PRIMARY KEY,
      payment_id TEXT NOT NULL,
      invoice_id TEXT NOT NULL,
      allocated_amount REAL NOT NULL,
      FOREIGN KEY (payment_id) REFERENCES Payment(payment_id),
      FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id)
    )
  ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS inventory_batches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item_id TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      remaining_quantity INTEGER NOT NULL,
      unit_cost REAL NOT NULL,
      purchase_date TEXT NOT NULL
    )
  ''');

  }
}
