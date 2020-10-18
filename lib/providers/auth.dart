import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart'; // or even flutter/widgets.dart will work. For ChangeNotifier
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiryDate;
  String _userId;
  Timer _authTimer;
  var _didTokenExipre = false;

  bool get isAuth {
    return token != null;
  }

  bool get didTokenExpire {
    return _didTokenExipre;
  }

  String get token {
    if (_expiryDate != null &&
        _expiryDate.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  String get userId {
    return _userId;
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    final url =
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyBkKT7enfL-2YrJuZCtjizwXN8RmMQWL24';
    // get this url from email sign up section - firebase auth API
    // Replace the [API_KEY] with the firebase project key from project settings in the firebase db

    try {
      final response = await http.post(
        url,
        body: json.encode(
          // keys in this map are from firebase auth API, under sign up with email/password
          {
            'email': email,
            'password': password,
            'returnSecureToken': true,
          },
        ),
      );
      // We need to check for and throw error manually because even though firebase gives an error, it isn't a normal error thrown by get/post requests with status codes in 400s.
      // This one has a 200 status code. Only, its response has an 'error' key in its body. (An unsual error throw).
      // This can be inferred from seeing the response body of an error case. Thankfully, we can derive intuition as to how to handle the error from the error response body as well.

      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }
      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expiryDate = DateTime.now()
          .add(Duration(seconds: int.parse(responseData['expiresIn'])));

      // Once the user logs in, begin timer which expires with the token
      _didTokenExipre = false;
      _autoLogout();

      // Shared preferences time!!
      // This is some async code. Make sure the func is async. Here it already is.
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'userId': _userId,
        'expiryDate': _expiryDate.toIso8601String(),
      }
          // json.encode converts the map to a representation wrapped in "", so essentially a string.
          );
      prefs.setString('userData', userData);

      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> signUp(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> loginUser(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  Future<bool> tryAutoLogin() async {
    // The user is currently logged out
    // He/she wants to open the app again if the token hasn't expired yet
    // This function tells if that's possible or not.
    // If possible, makes arramgements for it

    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      // Check if userData is stored on the device.
      return false; // No user data stored on device. Auto Login not possible
    }
    final extractedUserData =
        json.decode(prefs.getString('userData')) as Map<String, Object>;
    final expiryDate = DateTime.parse(extractedUserData['expiryDate']);

    if (expiryDate.isBefore(DateTime.now())) {
      // Token expired. Auto Login not possible
      return false;
    }

    _token = extractedUserData['token'];
    _userId = extractedUserData['userId'];
    _expiryDate = expiryDate;
    notifyListeners();
    _autoLogout();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    if (_authTimer != null) {
      // If user chooses to log out, cancel the timer.
      _authTimer.cancel();
      _authTimer = null;
    }
    notifyListeners();

    // Time to clear data stored on device.
    // If not, everytime someone logs out, they are logged right back in
    final prefs = await SharedPreferences.getInstance();
    // prefs.remove('userData'); // To remove only part of the data, if multiple things are being stored on the disk
    prefs.clear(); // Purges the disk of all data. Here both statements same onli.
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer.cancel();
    }
    final timeToExpiry = _expiryDate.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(
      Duration(seconds: timeToExpiry),
      () {
        _didTokenExipre = true;
        logout();
      },
    );
  }
}
