import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bill.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create the 'customer' table
    await db.execute('''
      CREATE TABLE customer (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        address TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    // Create the 'bill' table
    // Error fetching and updating data from JSON: DatabaseException(NOT NULL constraint failed: bill.name (code 1299 SQLITE_CONSTRAINT_NOTNULL)) sql 'INSERT OR REPLACE INTO bill (id, customer_id, total_price, is_paid, created_at) VALUES (?, ?, ?, ?, ?)' args [bill1, cust1, 100, 0, 2024-12-15T12:00:00]
    await db.execute('''
      CREATE TABLE bill (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL, 
        customer_id TEXT NOT NULL,
        total_price INTEGER NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customer (id) ON DELETE CASCADE
      );
    ''');

    // Create the 'bill_item' table
    await db.execute('''
      CREATE TABLE bill_item (
        id TEXT PRIMARY KEY,
        bill_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        total_price INTEGER NOT NULL,
        FOREIGN KEY (bill_id) REFERENCES bill (id) ON DELETE CASCADE
      );
    ''');
  }

  // Insert a record into any table
  Future<int> _insertRecord(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> loadAndUpdateDatabase(String filePath) async {
    try {
      // Load the JSON file from assets
      String jsonString = await rootBundle.loadString(filePath);

      // Parse the JSON string into a Map
      Map<String, dynamic> jsonData = jsonDecode(jsonString);

      // Pass the parsed JSON data to fetchAndUpdateFromJson
      await DatabaseService().fetchAndUpdateFromJson(jsonData);
      print("Database updated successfully from JSON file.");
    } catch (e) {
      print("Error loading or updating database: $e");
    }
  }


Future<void> fetchAndUpdateFromJson(Map<String, dynamic> jsonData) async {
  final db = await database;

  try {
    // Start a transaction to ensure data consistency
    await db.transaction((txn) async {
      // Handle customers
      if (jsonData.containsKey('customers')) {
        for (var customer in jsonData['customers']) {
          await txn.insert(
            'customer',
            customer,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Handle bills
      if (jsonData.containsKey('bills')) {
        for (var bill in jsonData['bills']) {
          // Insert or update the bill
          await txn.insert(
            'bill',
            {
              'id': bill['id'],
              'name':bill['name'],
              'customer_id': bill['customer_id'],
              'total_price': bill['total_price'],
              'is_paid': bill['is_paid'],
              'created_at': bill['created_at'],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Handle bill items
          if (bill.containsKey('items')) {
            for (var item in bill['items']) {
              await txn.insert(
                'bill_item',
                {
                  'id': item['id'],
                  'bill_id': bill['id'],
                  'item_name': item['item_name'],
                  'quantity': item['quantity'],
                  'unit_price': item['unit_price'],
                  'total_price': item['total_price'],
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      }
    });
    print("Data successfully fetched and updated from JSON.");
  } catch (e) {
    print("Error fetching and updating data from JSON: $e");
  }
}

// Fetch bill details
  Future<Map<String, dynamic>> fetchBillDetails(String billId) async {
    final db = await database;
    final bill = await db.query('bill', where: 'id = ?', whereArgs: [billId]);
    final items =
        await db.query('bill_item', where: 'bill_id = ?', whereArgs: [billId]);

    if (bill.isNotEmpty) {
      final billData = bill.first;
      final itemList = items
          .map((e) => {
                'id': e['id'],
                'item_name': e['item_name'],
                'quantity': e['quantity'],
                'unit_price': e['unit_price'],
                'total_price': e['total_price']
              })
          .toList();

      return {
        'id': billData['id'],
        'name': billData['name'],
        'customer_id': billData['customer_id'],
        'total_price': billData['total_price'],
        'is_paid': billData['is_paid'],
        'created_at': billData['created_at'],
        'items': itemList,
      };
    }

    return {};
  }

  // Fetch customer details
  Future<Map<String, dynamic>> fetchCustomerDetails(String customerId) async {
    final db = await database;
    final customer =
        await db.query('customer', where: 'id = ?', whereArgs: [customerId]);

    if (customer.isNotEmpty) {
      final customerData = customer.first;
      return {
        'id': customerData['id'],
        'name': customerData['name'],
        'phone_number': customerData['phone_number'],
        'address': customerData['address'],
        'created_at': customerData['created_at'],
      };
    }

    return {};
  }


  // Insert a customer
  Future<int> insertCustomer(Map<String, dynamic> customer) =>
      _insertRecord('customer', customer);

  // Insert a bill
  Future<int> insertBill(Map<String, dynamic> bill) =>
      _insertRecord('bill', bill);

  // Insert a bill item
  Future<int> insertBillItem(Map<String, dynamic> billItem) =>
      _insertRecord('bill_item', billItem);

  // Insert multiple items for a bill
  Future<void> insertBillItems(
      String billId, List<Map<String, dynamic>> items) async {
    for (var item in items) {
      await insertBillItem({
        'id': item['id'],
        'bill_id': billId,
        'item_name': item['item_name'],
        'quantity': item['quantity'],
        'unit_price': item['unit_price'],
        'total_price': item['total_price'],
      });
    }
  }

  // Get all customers
  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;
    return await db.query('customer');
  }

  // Get all bills
  Future<List<Map<String, dynamic>>> getBills() async {
    final db = await database;
    return await db.query('bill');
  }
  Future<List<Map<String, dynamic>>> getCustomer(customerId) async {
    final db = await database;
    return await db.query('customer', where: 'id = ?', whereArgs: [customerId]);
  }

  Future<List<Map<String, dynamic>>> getBillsWithCustomerNames() async {
    final db = await database;
    try {
      // Query to join the bill and customer tables
      final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT
        bill.id AS bill_id,
        bill.customer_id,
        customer.name AS customer_name,
        bill.total_price,
        bill.is_paid,
        bill.created_at
      FROM bill
      INNER JOIN customer ON bill.customer_id = customer.id
    ''');
      return results;
    } catch (e) {
      print("Error fetching bills with customer names: $e");
      return [];
    }
  }


  // Get all items for a specific bill
  Future<List<Map<String, dynamic>>> getBillItems(String billId) async {
    final db = await database;
    return await db.query(
      'bill_item',
      where: 'bill_id = ?',
      whereArgs: [billId],
    );
  }

  // Get a bill with its items
  Future<Map<String, dynamic>> getBillWithItems(String billId) async {
    final db = await database;

    // Fetch bill details
    final bill = await db.query(
      'bill',
      where: 'id = ?',
      whereArgs: [billId],
    );

    if (bill.isEmpty) return {};

    // Fetch associated items
    final items = await getBillItems(billId);

    return {
      'bill': bill.first,
      'items': items,
    };
  }

  // Update a record in any table
  Future<int> _updateRecord(
      String table, Map<String, dynamic> data, String id) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update a bill
  Future<int> updateBill(Map<String, dynamic> bill, String id) =>
      _updateRecord('bill', bill, id);

  // Update a bill item
  Future<int> updateBillItem(Map<String, dynamic> billItem, String id) =>
      _updateRecord('bill_item', billItem, id);

  // Delete a record from any table
  Future<int> deleteRecord(String table, String id) async {
    final db = await database;
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a bill and its items
  Future<int> deleteBill(String billId) => deleteRecord('bill', billId);

  // Print database contents for debugging
  Future<void> printDatabaseContents() async {
    final db = await database;

    final tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");

    for (var table in tables) {
      final tableName = table['name'] as String;
      print("\n--- Table: $tableName ---");

      final schema = await db.rawQuery("PRAGMA table_info('$tableName')");
      print("Schema:");
      for (var column in schema) {
        print(
            "  ${column['name']} - ${column['type']} (${column['notnull'] == 1 ? 'NOT NULL' : 'NULL'})");
      }

      final contents = await db.rawQuery("SELECT * FROM '$tableName'");
      print("Contents:");
      for (var row in contents) {
        print("  $row");
      }
    }
  }

  // Delete the database file
  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bill.db');
    await deleteDatabase(path);
    print("Database deleted successfully.");
  }
}
