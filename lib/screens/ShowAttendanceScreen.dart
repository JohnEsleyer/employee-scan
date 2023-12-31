import 'package:employee_scan/user_defined_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/DBProvider.dart';

class ShowAttendanceScreen extends StatefulWidget {
  @override
  _ShowAttendanceScreenState createState() => _ShowAttendanceScreenState();
}

class _ShowAttendanceScreenState extends State<ShowAttendanceScreen> {
  late DatabaseProvider db_provider;
  late List<Map<String, dynamic>> allEmployees = [];
  bool isPressed = false;

  Future<List<Map<String, dynamic>>> getAllAttendanceRecordAndEmployee() async {
    var attendances = await db_provider.getAllAttendanceRecords();
    var employees = await db_provider.getAllEmployeeRecords();
    setState(() {
      allEmployees = employees;
    });

    return attendances;
  }

  @override
  Widget build(BuildContext context) {
    db_provider = Provider.of<DatabaseProvider>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0.0,
        backgroundColor: Colors.white,
        title: Text(
          "Local Attendance Records",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                isPressed = true;
              });
              db_provider.clearAllSyncAttendance();
              setState(() {
                isPressed = false;
              });
              Scaffold.of(context).reassemble();
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 10,
                      left: 10,
                    ),
                    child: Text(
                      "Clear All \n Synced Records",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        child: (!isPressed)
            ? FutureBuilder(
                future: getAllAttendanceRecordAndEmployee(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<Map<String, dynamic>>? attendanceRecords =
                        snapshot.data;

                    if (attendanceRecords!.length != 0) {
                      return ListView.builder(
                          itemCount: attendanceRecords.length,
                          itemBuilder: ((context, index) {
                            Map<String, dynamic> attendanceRecord =
                                attendanceRecords[index];
                            return Container(
                              decoration: BoxDecoration(boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(2.0, 2.0),
                                  blurRadius: 3.0,
                                  blurStyle: BlurStyle.outer,
                                  spreadRadius: 0.5,
                                ),
                              ]),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    (attendanceRecord['sync'] == 1)
                                        ? Column(
                                            children: [
                                              Icon(
                                                Icons.check_circle_sharp,
                                                size: 50,
                                                color: Colors.green,
                                              ),
                                              Text('Synced',
                                                  style: TextStyle(
                                                      color: Colors.green)),
                                            ],
                                          )
                                        : Icon(
                                            Icons.radio_button_off,
                                            size: 50,
                                          ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    "Employee ID: ",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(attendanceRecord[
                                                          'employee_id']
                                                      .toString()),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "Name: ",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                      '${allEmployees[index]['last_name']}, ${allEmployees[index]['first_name']}'),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "Time In (AM): ",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                      convertToFormattedDateTime(
                                                          attendanceRecord[
                                                              'time_in_am'])),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "Time Out (AM): ",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                      convertToFormattedDateTime(
                                                          attendanceRecord[
                                                              'time_out_am'])),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "Time In (PM): ",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                      convertToFormattedDateTime(
                                                          attendanceRecord[
                                                              'time_in_pm'])),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "Time Out (PM): ",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                      convertToFormattedDateTime(
                                                          attendanceRecord[
                                                              'time_out_pm'])),
                                                ],
                                              )
                                            ]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }));
                    } else {
                      return Center(
                        child: Text("No Attendance Yet"),
                      );
                    }
                  } else {
                    return Center(
                        child: CircularProgressIndicator(color: Colors.blue));
                  }
                },
              )
            : Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}
