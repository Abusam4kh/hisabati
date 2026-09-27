import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'hasabati.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE customers(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL DEFAULT '',
            address TEXT NOT NULL DEFAULT '',
            note TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE entries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            currency TEXT NOT NULL DEFAULT 'YER',
            description TEXT NOT NULL DEFAULT '',
            date TEXT NOT NULL,
            FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
          )
        ''');
      },
    );
    return _db!;
  }

  Future<List<Customer>> customers({String query = ''}) async {
    final db = await database;
    final rows = await db.query(
      'customers',
      where: query.trim().isEmpty ? null : 'name LIKE ? OR phone LIKE ?',
      whereArgs: query.trim().isEmpty
          ? null
          : ['%${query.trim()}%', '%${query.trim()}%'],
      orderBy: 'id DESC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return db.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return db.update('customers', customer.toMap(),
        where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    await db.delete('entries', where: 'customer_id = ?', whereArgs: [id]);
    return db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Entry>> entriesForCustomer(int customerId) async {
    final db = await database;
    final rows = await db.query(
      'entries',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Entry.fromMap).toList();
  }

  Future<int> insertEntry(Entry entry) async {
    final db = await database;
    return db.insert('entries', entry.toMap());
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> balanceByCurrency(int customerId) async {
    final rows = await entriesForCustomer(customerId);
    final result = <String, double>{};
    for (final e in rows) {
      final sign = e.type == EntryType.credit ? 1 : -1;
      result[e.currency] = (result[e.currency] ?? 0) + sign * e.amount;
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> customerBalances() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT c.id, c.name, c.phone,
        COALESCE(SUM(CASE WHEN e.type='credit' THEN e.amount ELSE -e.amount END), 0) AS balance,
        COALESCE(MAX(e.currency), 'YER') AS currency
      FROM customers c
      LEFT JOIN entries e ON e.customer_id = c.id
      GROUP BY c.id
      ORDER BY c.name COLLATE NOCASE
    ''');
    return rows;
  }

  Future<List<Entry>> allEntries() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT * FROM entries ORDER BY date DESC, id DESC');
    return rows.map(Entry.fromMap).toList();
  }
}
