import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:image_picker/image_picker.dart';
import 'second_page.dart';
import 'home_screen.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:signature/signature.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;

  static Database? _db;

  Future<Database?> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDb();
    return _db;
  }

  DatabaseHelper.internal();

  Future<Database> initDb() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'registration.db');

    return await openDatabase(dbPath, version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
  CREATE TABLE registration (
    id INTEGER PRIMARY KEY,
    rsbsa TEXT,
    fname TEXT,
    lname TEXT,
    birthdate TEXT,
    email TEXT,
    phone TEXT(11),
    password TEXT NULL,
    image TEXT,
    created_at TEXT
  )
''');
        });
  }
  Future<Database> initProfileDb() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, 'ProfileData.db');

    return await openDatabase(dbPath, version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
        CREATE TABLE profile_data (
          U_RSBSA TEXT PRIMARY KEY,
          U_FIRSTNAME TEXT,
          U_MIDDLENAME TEXT,
          U_LASTNAME TEXT,
          U_FULLNAME TEXT,
          U_BDAY TEXT,
          U_PROVINCE TEXT,
          U_CITY TEXT,
          U_BARANGAY TEXT
        )
      ''');
        });
  }

  Future<int> insertRegistration(Map<String, dynamic> registration) async {
    registration['created_at'] = DateTime.now().toString();
    final db = await this.db;
    return await db!.insert('registration', registration);
  }


  Future<List<Map<String, dynamic>>> getAllRegistrations() async {
    final db = await this.db;
    return await db!.query('registration', columns: [
      'id',
      'rsbsa',
      'fname',
      'lname',
      'birthdate',
      'email',
      'phone',
      'password',
      'image',
      'created_at',
    ]);

  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Existing fields
  String _rsbsa = '';
  String _fname = '';
  String _lname = '';
  String? _email;
  String _password = '';
  String _phone = '';
  TextEditingController _dateController = TextEditingController();
  File? _imageFile;

  List<Offset> _points = [];
  _SignaturePainter? _signaturePainter;
  bool _isDrawing = false;
  final GlobalKey _canvasKey = GlobalKey();
  bool _showSignatureCanvas = false;
  // // New fields
  // String _address = '';
  // String _gender = '';
  // String _placeOfBirth = '';
  // String _civilStatus = '';
  // String _tinNo = '';
  // String _educationalAttainment = '';
  // String _degreesCourse = '';
  //
  // String _spouse = '';
  // TextEditingController _spouseBirthdate = TextEditingController();
  // String _spouseContactNumber = '';
  // String _occupation = '';
  // String _spouseEducationalAttainment = '';
  // DateTime? _dateRegistered;
  late Database _database;
  late DatabaseHelper _databaseHelper;

  Future<void> _selectImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper(); // Initialize the DatabaseHelper instance
    initializeDatabase();
  }


  void navigateToNextPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }


  Future<void> initializeDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'registration.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
  CREATE TABLE registration (
    id INTEGER PRIMARY KEY,
    rsbsa TEXT,
    fname TEXT,
    lname TEXT,
    birthdate TEXT,
    email TEXT,
    phone TEXT(11),
    password TEXT NULL,
    image TEXT,
    created_at TEXT
  )
''');
// address TEXT,
//     date_registered TEXT,
//     gender TEXT,
//     place_of_birth TEXT,
//     civil_status TEXT,
//     tin_no TEXT,
//     educational_attainment TEXT,
//     degrees_course TEXT,
//     spouse TEXT,
//     spouse_birthdate TEXT,
//     spouse_contact_number TEXT,
//     occupation TEXT,
//     spouse_educational_attainment TEXT
      },
    );
  }

  void _drawSignature(Offset offset) {
    setState(() {
      _points = List.from(_points)..add(offset);
    });
  }
  void _addPoint(Offset offset) {
    setState(() {
      _points = List.from(_points)..add(offset);
    });
  }
  void _clearPoints() {
    setState(() {
      _points.clear();
    });
  }


  Future<int> insertRegistration(Map<String, dynamic> registration) async {
    return await _database.insert('registration', registration,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllRegistrations() async {
    return await _database.query('registration');
  }

  void createAccountPressed(BuildContext context) async {

    navigateToNextPage(context);
    // Validate user input
    if (_rsbsa.isEmpty ||
        _fname.isEmpty ||
        _lname.isEmpty ||
        _password.isEmpty ||
        _phone.isEmpty) {
      // Show an error message or perform some validation handling
      return;
    }

    // Insert registration details into the database
    Map<String, dynamic> registration = {
      'rsbsa': _rsbsa,
      'fname': _fname,
      'lname': _lname,
      'birthdate': _dateController.text,
      'email': _email,
      'phone': _phone,
      if (_password.isNotEmpty) 'password': _password,
      'image': _imageFile?.path != null ? _imageFile!.path : '',
      // 'address': _address,
      // 'date_registered': _dateRegistered?.toString(),
      // 'gender': _gender,
      // 'place_of_birth': _placeOfBirth,
      // 'civil_status': _civilStatus,
      // 'tin_no': _tinNo,
      // 'educational_attainment': _educationalAttainment,
      // 'degrees_course': _degreesCourse,
      // 'spouse': _spouse,
      // 'spouse_birthdate': _spouseBirthdate?.text,
      // 'spouse_contact_number': _spouseContactNumber,
      // 'occupation': _occupation,
      // 'spouse_educational_attainment': _spouseEducationalAttainment,
    };

    await _databaseHelper.insertRegistration(registration);

    // Save registrations to a CSV file
    final registrations = await getAllRegistrations();
    final profileDb = await _databaseHelper.initProfileDb();
    for (var registration in registrations) {
      Map<String, dynamic> profileData = {
        'U_RSBSA': registration['rsbsa'],
        'U_FIRSTNAME': registration['fname'],
        'U_MIDDLENAME': '',
        'U_LASTNAME': registration['lname'],
        'U_FULLNAME': registration['lname'] + ', ' + registration['fname'],
        'U_BDAY': registration['birthdate'],
        'U_PROVINCE': '',
        'U_CITY': '',
        'U_BARANGAY': '',
      };
      await profileDb.insert('profile_data', profileData,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final csvData = [
      [
        'ID',
        'RSBSA',
        'First Name',
        'Last Name',
        'Birthdate',
        'Email',
        'Phone',
        'Password',
        'Image Path',
        'Created At',
      ],
      // 'Address',
      //         'Date Registered',
      //         'Gender',
      //         'Place of Birth',
      //         'Civil Status',
      //         'TIN No.',
      //         'Educational Attainment',
      //         'Degrees/Course',
      //         'Spouse',
      //         'Spouse Birthdate',
      //         'Spouse Contact Number',
      //         'Occupation',
      //         'Spouse Educational Attainment',
      ...registrations.map((registration) => [
        registration['id'],
        registration['rsbsa'],
        registration['fname'],
        registration['lname'],
        registration['birthdate'],
        registration['email'],
        registration['phone'],
        registration['password'],
        registration['image'],
        registration['created_at'],
        // registration['address'],
        // registration['date_registered'],
        // registration['gender'],
        // registration['place_of_birth'],
        // registration['civil_status'],
        // registration['tin_no'],
        // registration['educational_attainment'],
        // registration['degrees_course'],
        // registration['spouse'],
        // registration['spouse_birthdate'],
        // registration['spouse_contact_number'],
        // registration['occupation'],
        // registration['spouse_educational_attainment'],
      ]),
    ];
    final csvFile = const ListToCsvConverter().convert(csvData);

    // Get the application documents directory
    final appDir = await getApplicationDocumentsDirectory();

    // Specify the file path using the application documents directory
    final filePath = '${appDir.path}/registrations.csv';

    final outputFile = File(filePath);
    await outputFile.writeAsString(csvFile);
    print(outputFile.path);

    // Navigate to HomeScreen after successful registration
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );

    // Print the registration details to the console
    print(registration);
  }



  @override

  Widget build(BuildContext context) {

    Widget _buildSignatureCanvas() {
      return SizedBox(
          height: 300.0, // Set a fixed height for the Column
          child: Column(
          children: [
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                RenderBox renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
                Offset offset = renderBox.globalToLocal(details.globalPosition);
                setState(() {
                  _isDrawing = true;
                  _points = List.from(_points)..add(offset);
                });
              },
              onPanUpdate: (details) {
                if (_isDrawing) {
                  RenderBox renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
                  Offset offset = renderBox.globalToLocal(details.globalPosition);
                  setState(() {
                    _points = List.from(_points)..add(offset);
                  });
                }
              },
              onPanEnd: (details) {
                setState(() {
                  _isDrawing = false;
                });
              },
              child: CustomPaint(
                key: _canvasKey,
                painter: _SignaturePainter(points: _points),
                child: Container(
                  width: double.infinity,
                  height: 200.0,
                ),
              ),
            ),
          ),
            ElevatedButton(
              onPressed: _clearPoints,
              child: Text('Clear'),
            ),
          ],
          ),
      );
    }

    Widget _buildImagePicker() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Image',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 8.0),
          GestureDetector(
            onTap: _selectImage,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.lightBlue.withOpacity(.1),
                borderRadius: BorderRadius.circular(15.0),
              ),
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.image),
                  SizedBox(width: 8.0),
                  Text(
                    _imageFile != null
                        ? 'Image selected'
                        : 'Tap to select an image',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: _imageFile != null ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(
          color: Colors.lightGreen,
        ),
        title: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 50, 0),
            child: Image.asset(
              'assets/logo.png',
              height: 36,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 30.0),
              Text(
                'To start your journey with us, please take a moment to verify your RSBSA Number with your personal information',
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 15.0,
                  color: Colors.grey,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30.0),
                  Text(
                    'RSBSA Number',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'xx-xxxxxxx-xxx',
                      filled: true,
                      fillColor: Colors.lightBlue.withOpacity(.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                    onChanged: (value) {
                      _rsbsa = value;
                    },
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'First Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.lightBlue.withOpacity(.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                          ),
                          onChanged: (value) {
                            _fname = value;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.lightBlue.withOpacity(.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                          ),
                          onChanged: (value) {
                            _lname = value;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birthdate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'dd/mm/yyyy',
                      filled: true,
                      fillColor: Colors.lightBlue.withOpacity(.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                    controller: _dateController,
                    onTap: () async {
                      final DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (selectedDate != null) {
                        String formattedDate =
                        DateFormat('MM/dd/yyyy').format(selectedDate);
                        _dateController.text = formattedDate;
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email (Optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                    onChanged: (value) {
                      _email = value;
                    },
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cellphone Number',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  TextField(
                    decoration: InputDecoration(
                      hintText: '09xxxxxxxxx',
                      filled: true,
                      fillColor: Colors.lightBlue.withOpacity(.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                    onChanged: (value) {
                      _phone = value;
                    },
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                    onChanged: (value) {
                      _password = value;
                    },
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              _buildImagePicker(), // Add the image picker widget
              SizedBox(height: 15.0),
              SizedBox(
                width: double.infinity,
                height: 50.0,
                child: ElevatedButton(

                  onPressed: () {
                    setState(() {
                      _showSignatureCanvas = !_showSignatureCanvas;
                    });
                  },
                  child: Text(
                    _showSignatureCanvas ? 'Close Signature' : 'Signature',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: _showSignatureCanvas,
                child: _buildSignatureCanvas(),
              ),

              SizedBox(height: 20.0),
              SizedBox(
                width: double.infinity,
                height: 50.0,
                child: ElevatedButton(
                  onPressed: () {
                    createAccountPressed(context); // Pass the BuildContext
                  },
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
              ),

            ],

          ),
        ),
      ),

    );

  }
}




