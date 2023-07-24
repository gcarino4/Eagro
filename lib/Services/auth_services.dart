import 'dart:convert';

import 'package:flutterapp/Services/globals.dart';
import 'package:http/http.dart' as http;

class AuthServices {

  static Future<http.Response> register(
  String rsbsa, String fname,String lname,String phone, String email, String password) async {
    Map data = {
      "rsbsa": rsbsa,
      "fname": fname,
      "lname": lname,
      "phone": phone,
      "email": email,
      "password": password,
    };

    var body = json.encode(data);
    var url = Uri.parse(baseURL + 'auth/register');
    http.Response response = await http.post(
      url,
      headers: headers,
      body: body,
    );
    print(response.body);
    return response;
  }

  static Future<http.Response> login(String phone, String password) async {
    Map data = {
      "phone": phone,
      "password": password,
    };

    var body = json.encode(data);
    var url = Uri.parse(baseURL + 'auth/login');
    http.Response response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    print(response.body);
    return response;
  }
}
