import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _registrations = [];
  List<Map<String, dynamic>> _filteredRegistrations = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> loadRegistrations() async {
    final Database database = await openDatabase('registration.db');
    final List<Map<String, dynamic>> registrations =
    await database.query('registration');

    setState(() {
      _registrations = registrations;
      _filteredRegistrations = registrations;
    });
  }

  Future<void> loadProfileData() async {
    final Database database = await openDatabase('ProfileData.db');
    final List<Map<String, dynamic>> profileData = await database.query('profile_data');

    // You can use the loaded profile data as needed
    // For example, store it in a List or process it further.
  }

  Future<void> createAndInsertProfileData() async {
    final String apiUrl = 'http://farmer.e-agro.ph/api_rsbsa_list.php'; // Replace with your API URL

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      final Database database = await openDatabase(
        join(await getDatabasesPath(), 'ProfileData.db'),
        version: 1,
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
        },
      );

      for (final item in data) {
        await database.insert(
          'profile_data',
          {
            'U_RSBSA': item['U_RSBSA'],
            'U_FIRSTNAME': item['U_FIRSTNAME'],
            'U_MIDDLENAME': item['U_MIDDLENAME'],
            'U_LASTNAME': item['U_LASTNAME'],
            'U_FULLNAME': item['U_FULLNAME'],
            'U_BDAY': item['U_BDAY'],
            'U_PROVINCE': item['U_PROVINCE'],
            'U_CITY': item['U_CITY'],
            'U_BARANGAY': item['U_BARANGAY'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace, // Use ConflictAlgorithm.replace to update existing data
        );
      }

      // After inserting data, load the registrations again to reflect the changes.
      await loadRegistrations();
    } else {
      print('Failed to fetch data from API. Status Code: ${response.statusCode}');
    }
  }


  void filterRegistrations(String query) {
    final List<Map<String, dynamic>> filteredList = _registrations
        .where((registration) =>
        '${registration['fname']} ${registration['lname']}'
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    setState(() {
      _filteredRegistrations = filteredList;
    });
  }

  Widget _buildRegistrationCard(BuildContext context, Map<String, dynamic> registration) {
    final String? imagePath = registration['image'];
    final File? imageFile = imagePath != null ? File(imagePath) : null;
    final bool imageExists = imageFile != null && imageFile.existsSync(); // Check if the file exists

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              registration: registration,
              imageFile: imageExists ? imageFile : null, // Use the imageFile only if it exists
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: ListTile(
          leading: CircleAvatar(
            // Check if the image exists before using FileImage
            backgroundImage: imageExists ? FileImage(imageFile!) : null,
          ),
          title: Text(
            '${registration['fname']} ${registration['lname']}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RSBSA Number: ${registration['rsbsa']}'),
              Text('Birthdate: ${registration['birthdate']}'),
              Text('Phone: ${registration['phone']}'),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              deleteRegistration(registration['id']);
            },
          ),
        ),
      ),
    );
  }


  Future<void> deleteRegistration(int id) async {
    final Database database = await openDatabase('registration.db');
    await database.delete('registration', where: 'id = ?', whereArgs: [id]);
    await loadRegistrations();
  }

  Future<void> downloadRegistrations() async {
    final response = await http.get(Uri.parse('http://farmer.e-agro.ph/api2.php'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      final Database database = await openDatabase(
        join(await getDatabasesPath(), 'registration.db'),
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
          CREATE TABLE registration (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rsbsa TEXT,
            fname TEXT,
            lname TEXT,
            birthdate TEXT,
            email TEXT,
            phone TEXT,
            password TEXT,
            image TEXT,
            created_at TEXT
          )
        ''');
        },
      );

      await database.transaction((txn) async {
        // Insert data into the 'registration' table
        for (final item in data) {
          final Map<String, dynamic> registration = {
            'rsbsa': item['rsbsa'],
            'fname': item['fname'],
            'lname': item['lname'],
            'birthdate': item['dob'], // Map 'dob' to 'birthdate'
            'email': item['email'],
            'phone': item['phone'],
            if (item['password'] != null) 'password': item['password'],
            'image': item['image'],
            'created_at': item['created_at'],
          };
          await txn.insert('registration', registration);
        }
      });

      await loadRegistrations();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_registrations == null) {
      // Handle the case when _registrations is null (before initialization)
      return Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterRegistrations,
              decoration: const InputDecoration(
                labelText: 'Search by name',
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _filteredRegistrations.length,
              itemBuilder: (context, index) {
                final registration = _filteredRegistrations[index];
                return _buildRegistrationCard(context, registration); // Pass 'context' here
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {

                  },
                  child: Text('Upload'),
                ),
                ElevatedButton(
                  onPressed: () {
                    downloadRegistrations(); // Call the download function
                  },
                  child: Text('Download'),
                ),
                ElevatedButton(
                  onPressed: () {
                    createAndInsertProfileData(); // Call the function
                  },
                  child: Text('Insert Profile'), // Button text
                ),
                ElevatedButton(
                  onPressed: () {
                    loadRegistrations(); // Call the function
                  },
                  child: Text('Refresh'), // Button text
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> registration;
  final File? imageFile;

  const ProfileScreen({
    Key? key,
    required this.registration,
    this.imageFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // Add 'BuildContext context' parameter here
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: imageFile != null ? FileImage(imageFile!) : null,
              radius: 60,
            ),
            const SizedBox(height: 16),
            Text(
              '${registration['fname']} ${registration['lname']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Phone Number: ${registration['phone']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text('RSBSA Number: ${registration['rsbsa']}'),
            // Add more information as needed
          ],
        ),
      ),
    );
  }
}

