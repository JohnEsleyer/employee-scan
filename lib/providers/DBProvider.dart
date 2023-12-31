import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

import '../user_defined_functions.dart';

class DatabaseProvider extends ChangeNotifier {
  final Database db;

  DatabaseProvider(this.db);

  Future<void> insertAttendance(
      int employee_id,
      int office_id,
      String time_in_am,
      String time_out_am,
      String time_in_pm,
      String time_out_pm) async {
    await db.insert('attendance', {
      'employee_id': employee_id,
      'office_id': office_id,
      'time_in_am': time_in_am,
      'time_out_am': time_out_am,
      'time_in_pm': time_in_pm,
      'time_out_pm': time_out_pm,
      'sync': 0,
    });
  }

  Future<void> clearAllAttendance() async {
    await db.delete('attendance');
  }

  Future<void> clearAllSyncAttendance() async {
    await db.delete('attendance', where: 'sync = ?', whereArgs: [1]);
  }

  Future<void> updateTimeOutAM(int employee_id, String newTimeOut) async {
    final whereArgs = [employee_id];
    final updates = {'time_out_am': newTimeOut};

    await db.update('attendance', updates,
        where: 'employee_id = ?', whereArgs: whereArgs);
  }

  Future<void> updateTimeInPM(int employee_id, String newTimeOut) async {
    final whereArgs = [employee_id];
    final updates = {'time_in_pm': newTimeOut};

    await db.update('attendance', updates,
        where: 'employee_id = ?', whereArgs: whereArgs);
  }

  Future<void> updateTimeOutPM(int employee_id, String newTimeOut) async {
    final whereArgs = [employee_id];
    final updates = {'time_out_pm': newTimeOut};

    await db.update('attendance', updates,
        where: 'employee_id = ?', whereArgs: whereArgs);
  }

  Future<void> updateSync(int employee_id, int new_sync) async {
    final whereArgs = [employee_id];
    final updates = {'sync': new_sync};

    await db.update('attendance', updates,
        where: 'employee_id = ?', whereArgs: whereArgs);
  }

  Future<bool> isAttendanceRecordExists(int employee_id) async {
    final results = await db.query('attendance',
        where: 'employee_id = ?', whereArgs: [employee_id]);

    return results.isNotEmpty;
  }

  Future<Map<String, dynamic>> getAttendanceByEmployeeId(
      int employee_id) async {
    final results = await db.query('attendance',
        where: 'employee_id = ?', whereArgs: [employee_id]);

    if (results.isEmpty) {
      return {};
    } else {
      Map<String, dynamic> attendanceRecord = {};
      attendanceRecord['employee_id'] = results[0]['employee_id'];
      attendanceRecord['office_id'] = results[0]['office_id'];
      attendanceRecord['time_in_am'] = results[0]['time_in_am'];
      attendanceRecord['time_out_am'] = results[0]['time_out_am'];
      attendanceRecord['time_in_pm'] = results[0]['time_in_pm'];
      attendanceRecord['time_out_pm'] = results[0]['time_out_pm'];
      attendanceRecord['sync'] = results[0]['sync'];
      return attendanceRecord;
    }
  }

  Future<List<Map<String, dynamic>>> getAllAttendanceRecords() async {
    final results = await db.query('attendance');

    List<Map<String, dynamic>> attendanceRecords = [];
    for (var row in results) {
      Map<String, dynamic> attendanceRecord = {};
      attendanceRecord['id'] = row['id'];
      attendanceRecord['employee_id'] = row['employee_id'];
      attendanceRecord['office_id'] = row['office_id'];
      attendanceRecord['time_in_am'] = row['time_in_am'];
      attendanceRecord['time_out_am'] = row['time_out_am'];
      attendanceRecord['time_in_pm'] = row['time_in_pm'];
      attendanceRecord['time_out_pm'] = row['time_out_pm'];
      attendanceRecord['sync'] = row['sync'];
      attendanceRecords.add(attendanceRecord);
    }

    return attendanceRecords;
  }

  // Future<bool> isAttendanceRecordExistsDate(
  //     int employee_id, String date_entered) async {
  //   final results = await db.query('attendance',
  //       where: 'employee_id = ? and date_entered = ?',
  //       whereArgs: [employee_id, date_entered]);

  //   return results.isNotEmpty;
  // }

  Future<void> insertUser(int id, String first_name, String last_name,
      String username, String password) async {
    await db.insert('user', {
      'id': id,
      'first_name': first_name,
      'last_name': last_name,
      'username': username,
      'password': password,
    });
  }

  Future<void> insertEmployee(int employee_id, String first_name,
      String last_name, int department) async {
    await db.insert('employee', {
      'id': employee_id,
      'first_name': first_name,
      'last_name': last_name,
      'department': department,
    });
  }

  Future<bool> loginUser(String username, String password) async {
    final List<Map<String, dynamic>> users = await getAllUsers();

    for (var user in users) {
      if (user['username'] == username) {
        // Check password
        final bool checkPassword = BCrypt.checkpw(password, user['password']);
        if (checkPassword) {
          return true;
        }
      }
    }

    return false;
  }

  Future<List<Map<String, dynamic>>> getAllEmployeeRecords() async {
    final results = await db.query('employee');

    List<Map<String, dynamic>> employeeRecords = [];
    for (var row in results) {
      Map<String, dynamic> employeeRecord = {};
      employeeRecord['id'] = row['id'];
      employeeRecord['first_name'] = row['first_name'];
      employeeRecord['last_name'] = row['last_name'];
      employeeRecord['department'] = row['department'];
      employeeRecords.add(employeeRecord);
    }

    return employeeRecords;
  }

  Future<bool> isEmployeeExists(int employee_id) async {
    final result =
        await db.query('employee', where: 'id = ?', whereArgs: [employee_id]);
    return result.isNotEmpty;
  }

  Future<void> updateData() async {
    await db.update('users', {'name': 'John Smith'}, where: 'id = 1');
  }

  Future<void> deleteData() async {
    await db.delete('users', where: 'id = 2');
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await db.query('user');
  }

  Future<Map<String, dynamic>?> getEmployeeById(int id) async {
    final results =
        await db.query('employee', where: 'id = ?', whereArgs: [id]);

    if (results.isEmpty) {
      return {'name': 'null'};
    } else {
      return results.first;
    }
  }

  Future<void> sync() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();

    if (_prefs.getBool('syncing') != true){
        _prefs.setBool('syncing', true);

      try {
        // Retrieve all attendance records
        List<Map<String, dynamic>> attendances = await getAllAttendanceRecords();
        print('Total attendance records: ${attendances.length}');

        // Counter to track synced records
        int counter = 0;

        // Iterate through each attendance record
        for (int i = 0; i < attendances.length; i++) {
          // Check if the record is not yet synced
          if (attendances[i]['sync'] == 0) {
            final url = API_URL + '/attendance';

            final requestBody = {
              "user_id": attendances[i]['employee_id'],
              "office_id": attendances[i]['office_id'],
              "time_in_am": attendances[i]['time_in_am'],
              "time_out_am": attendances[i]['time_out_am'],
              "time_in_pm": attendances[i]['time_in_pm'],
              "time_out_pm": attendances[i]['time_out_pm'],
            };

            // Check if the record has a valid time_out_am value
            if (attendances[i]['time_out_pm'] == 'not set') {
              print('Invalid record: ${attendances[i]}');
            } else {
              try {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String token = prefs.getString('token') ?? '';

                Map<String, String> headers = {
                  "Authorization": "Bearer $token",
                  "Content-Type": "application/json",
                  "Accept": "application/json"
                };
                // Send a POST request to the API
                final response = await http.post(
                  Uri.parse(url),
                  body: json.encode(requestBody),
                  headers: headers,
                );

                if (response.statusCode == 200) {
                  // Request successful
                  final responseBody = json.decode(response.body);
                  print('Response body: $responseBody');

                  // Update the record's sync status
                  await updateSync(attendances[i]['employee_id'], 1);
                } else {
                  // Request failed
                  print('Request failed: ${response.statusCode}');
                  print(requestBody);
                }
              } catch (error) {
                print('Error: $error');
              }
              counter++;
            }
          }
        }
        print('Total records synced: $counter');

        // Sync Employee
        SharedPreferences prefs = await SharedPreferences.getInstance();

        String token = prefs.getString('token') ?? '';
        Map<String, String> headers = {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json"
        };

        final response = await http.get(
          Uri.parse(API_URL + '/users'),
          headers: headers,
        );

        if (response.statusCode == 200) {
          print("200");
          // The request was successful, parse the JSON
          var data = jsonDecode(response.body);

          for (int i = 0; i < data!.length; i++) {
            try {
              // Insert data into the database
              insertEmployee(data[i]['id'], data[i]['first_name'],
                  data[i]['last_name'], data[i]['department_id']);
            } catch (error) {
              print('Error: Error at inserting employee ($error)');
            }
          }
        } else {
          print("Error");
          // The request failed, throw an error
          throw Exception('Something went wrong');
        }

        //
      } catch (error) {
        print('Error: $error');
      }

      _prefs.setBool('syncing', false);
    }
    }

   
}
