import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;

  static late Database _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database;
    }

    _database = await initDatabase();
    return _database;
  }

  DatabaseHelper.internal();

  Future<Database> initDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, 'registration.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE registration(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      rsbsa TEXT,
      fname TEXT,
      lname TEXT,
      birthdate TEXT,
      email TEXT,
      phone TEXT,
      password TEXT,
      image TEXT
    )
    ''');
  }

  Future<int> insertRegistration(Map<String, dynamic> registration) async {
    final Database db = await database;
    return await db.insert('registration', registration);
  }

// Add more methods for database operations as needed (e.g., update, delete, query)
}
