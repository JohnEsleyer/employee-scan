import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:connectivity/connectivity.dart';
import 'package:employee_scan/screens/ShowAttendanceScreen.dart';
import 'package:employee_scan/screens/ShowEmployeeScreen.dart.dart';
import 'package:employee_scan/widgets/FadeAnimationWidget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../navbar.dart';

import '../providers/DBProvider.dart';
import '../providers/InternetProvider.dart';
import '../user_defined_functions.dart';
import '../widgets/neumorphic_button.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late InternetProvider internetProvider;
  late ReceivePort receivePort;
  late Isolate? isolate;
  late DatabaseProvider db_provider;
  String debug = '';

  @override
  void initState() {
    super.initState();
   
    startBackgroundTask();
  }

  @override
  void dispose() {
    stopBackgroundTask();
    super.dispose();
  }

  Future<void> startBackgroundTask() async {

    receivePort = ReceivePort();

    isolate =
        await Isolate.spawn(checkConnectivityInIsolate, receivePort.sendPort);
    receivePort.listen((dynamic message) {
      if (message is bool) {
        internetProvider.setIsConnected(message);
      }
    });
  }

  void stopBackgroundTask() {
    isolate?.kill(priority: Isolate.immediate);
    isolate = null;
    receivePort?.close();
  }

  static void checkConnectivityInIsolate(SendPort sendPort) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = connectivityResult != ConnectivityResult.none;
    sendPort.send(isConnected);

    // Continuously listen for connectivity changes in the isolate
    await for (var result in Connectivity().onConnectivityChanged) {
      final isConnected = result != ConnectivityResult.none;
      sendPort.send(isConnected);
    }
  }

  

  @override
  Widget build(BuildContext context) {
    db_provider = Provider.of<DatabaseProvider>(context);
    internetProvider = Provider.of<InternetProvider>(context);

    if (internetProvider.isConnected == true) {
      db_provider.syncAttendance();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Employee Scan',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          internetProvider.isConnected
              ? Padding(
                  padding: const EdgeInsets.only(right:15, top: 8),
                  child: FadeAnimationWidget(
                    duration: Duration(seconds:1),
                    child: Column(
                      children: [
                        Icon(Icons.sync, color: Colors.green),
                        Text(
                          'Syncing',
                          style: TextStyle(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Icon(Icons.wifi, color: Colors.red),
                      Text(
                        'Disconnected',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                )
        ],
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(debug),
            NeumorphicButton(
              child: const Text('Scan'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const QRViewScreen(),
                ));
              },
            ),
            SizedBox(height: 20),
            NeumorphicButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ShowEmployeeScreen(),
                ));
              },
              child: const Text('Employees List'),
            ),
            SizedBox(height: 20),
            NeumorphicButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ShowAttendanceScreen(),
                ));
              },
              child: const Text('Show Attendance List'),
            ),
          ],
        ),
      ),
    );
  }
}

class QRViewScreen extends StatefulWidget {
  const QRViewScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewScreenState();
}

class _QRViewScreenState extends State<QRViewScreen> {
  String first_name = " ";
  String last_name = " ";
  String? department;
  String? scan_status;
  int? id;
  String temp = " ";
  Barcode? result;
  Color borderColor = Color.fromARGB(255, 255, 255, 255);
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late DatabaseProvider db_provider;
  var scaffoldKey = GlobalKey<ScaffoldState>();

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }
  

  @override
  Widget build(BuildContext context) {
    var internetProvider = Provider.of<InternetProvider>(context);
    var $ScreenWidth = MediaQuery.of(context).size.width;
    var $ScreenHeight = MediaQuery.of(context).size.height;
    var $generalCam = 250.0;
    var $logoPercentage = 10;

    db_provider = Provider.of<DatabaseProvider>(context);
    return Scaffold(
        key: scaffoldKey,
        drawer: const Navbar(),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              // ignore: sized_box_for_whitespace
              Container(
                width: $ScreenWidth,
                height: $ScreenHeight * ($logoPercentage / 100),
                // color: Colors.amber,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => scaffoldKey.currentState?.openDrawer(),
                    ),
                    // Image.asset('assets/placeholder.jpg'),
                    Visibility(
                      visible:
                          true, //TODO: Change visibility when there is connection
                      maintainAnimation: true,
                      maintainState: true,
                      maintainSize: true,
                      child: internetProvider.isConnected ? Padding(
                  padding: const EdgeInsets.only(right:15, top: 8),
                  child: FadeAnimationWidget(
                    duration: Duration(seconds:1),
                    child: Column(
                      children: [
                        Icon(Icons.sync, color: Colors.green),
                        Text(
                          'Syncing',
                          style: TextStyle(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Icon(Icons.wifi, color: Colors.red),
                      Text(
                        'Disconnected',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                )
                    )
                  ],
                ),
              ),
              const SizedBox(height: 50),

              // ignore: sized_box_for_whitespace
              GestureDetector(
                onDoubleTap: () async {
                  await controller?.flipCamera();
                  setState(() {});
                },
                onTap: () async {
                  await controller?.pauseCamera();
                  setState(() {});
                },
                child: Container(
                  width: $generalCam,
                  height: $generalCam,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  // color: Colors.blue,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                      onPermissionSet: (ctrl, p) =>
                          _onPermissionSet(context, ctrl, p),
                      overlay: QrScannerOverlayShape(
                        borderColor: borderColor,
                        borderRadius: 20,
                        borderLength: 40,
                        borderWidth: 15,
                        cutOutSize: $generalCam,
                      ),
                      // onQRViewCreated: onQRViewCreated
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 70,
              ),
              Expanded(
                // ignore: sized_box_for_whitespace
                child: Container(
                  width: $ScreenWidth,
                  // color: Colors.white,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                          width: $ScreenWidth * (70 / 100),
                          height: $ScreenHeight * (30 / 100),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black12,
                                    offset: Offset(2.0, 2.0),
                                    blurRadius: 3.0,
                                    spreadRadius: 0.5)
                              ]),
                          child: Column(
                            children: [
                              SizedBox(
                                width: $ScreenWidth,
                                height: 30,
                                child: const Text(
                                  'ID Number',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Divider(
                                height: 2,
                                thickness: 1,
                                indent: 0,
                                endIndent: 0,
                                color: Colors.black45,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              (temp == 'Employee not found!')
                                  ? SizedBox(
                                      width: $ScreenWidth,
                                      // height: 30,
                                      child: Column(
                                        children: [
                                          Text('INVALID',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold,
                                                // fontWeight: FontWeight.bold
                                              )),
                                          SizedBox(height: 10),
                                          Text(temp,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 15,
                                                // fontWeight: FontWeight.bold
                                              )),
                                        ],
                                      ))
                                  : SizedBox(
                                      width: $ScreenWidth,
                                      // height: 30,
                                      child: (result?.code == null)
                                          ? const Text('No ID scanned',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 15,
                                                // fontWeight: FontWeight.bold
                                              ))
                                          : Column(
                                              children: [
                                                Text('$id',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      // fontWeight: FontWeight.bold
                                                    )),
                                                SizedBox(height: 10),
                                                Text('$last_name, $first_name',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      // fontWeight: FontWeight.bold
                                                    )),
                                                Text(temp,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      // fontWeight: FontWeight.bold
                                                    )),
                                              ],
                                            )),
                            ],
                          )),
                      const SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: borderColor,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      await controller.pauseCamera(); // Pause camera
      setState(() {
        borderColor = Color.fromARGB(255, 17, 139, 10);
      });
      // Check if data is JSON
      if (isJSON(scanData.code as String)) {
        Map<String, dynamic> data = jsonDecode(scanData.code as String);
        setState(() {
          temp = "Is JSON";
        });
        // Check if qr code belongs to the company
        if (data['company'] == 111) {
          setState(() {
            temp = "Infoactiv";
          });

          // Check employee existence
          bool employeeExists =
              await db_provider.isEmployeeExists(data['employee']);
          if (employeeExists) {
            setState(() {
              temp = 'OK';
            });

            // Check if employee was already recorded
            DateTime currentDate = DateTime.now();
            String formattedDate = DateFormat('MM/dd/yyyy').format(currentDate);
            String formattedTime = DateFormat('HH:mm a').format(currentDate);
            bool recordExists = await db_provider.isAttendanceRecordExistsDate(
                data['employee'], formattedDate);
            if (recordExists) {
              Map<String, dynamic> attendanceRecord =
                  await db_provider.getAttendanceByEmployeeIdAndCompany(
                      data['employee'], data['company']);
              if (attendanceRecord.isNotEmpty) {
                // Process the retrieved attendance record
                String timeIn = attendanceRecord['time_in'];
                String timeOut = attendanceRecord['time_out'];

                temp = 'Time In: $timeIn, Time Out: $timeOut';

                if (timeOut == 'not set') {
                  temp = 'not set';
                  // Update timeOut
                  await db_provider.updateTimeOut(
                      data['employee'], data['company'], formattedTime);
                  Map<String, dynamic>? employee =
                      await db_provider.getEmployeeById(data['employee']);
                  setState(() {
                    temp = 'Time out recorded!';
                    id = data['employee'];
                    first_name = employee?['first_name'];
                    last_name = employee?['last_name'];
                  });
                } else {
                  Map<String, dynamic>? employee =
                      await db_provider.getEmployeeById(data['employee']);
                  setState(() {
                    id = data['employee'];
                    first_name = employee?['first_name'];
                    last_name = employee?['last_name'];
                    temp = 'Attendance was already set for today';
                    borderColor = Colors.amber;
                  });
                }
              } else {
                temp = 'No attendance record found ';
              }
            } else {
              // Generate a v4 (random) UUID
              // var uuid = Uuid();
              // String randomUuid = uuid.v4();

              await db_provider.insertAttendance(data['employee'],
                  data['company'], 1, formattedTime, 'not set', formattedDate);

              Map<String, dynamic>? employee =
                  await db_provider.getEmployeeById(data['employee']);
              setState(() {
                temp = 'Time in recorded!';
                id = data['employee'];
                first_name = employee?['first_name'];
                last_name = employee?['last_name'];
              });
            }
          } else {
            setState(() {
              temp = 'Employee not found!';
            });
          }
        } else {
          setState(() {
            temp = "Does not belong!";
          });
        }
      } else {
        setState(() {
          temp = "Not JSON";
          borderColor = Color.fromARGB(255, 242, 38, 38);
        });
      }
      setState(() {
        result = scanData;
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
