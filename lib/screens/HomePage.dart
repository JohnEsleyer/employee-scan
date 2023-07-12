

import 'package:employee_scan/widgets/navbar.dart';
import 'package:employee_scan/screens/ShowAttendanceScreen.dart';
import 'package:employee_scan/screens/ShowEmployeeScreen.dart.dart';
import 'package:employee_scan/widgets/CountdownTimerSync.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/DBProvider.dart';
import '../providers/InternetProvider.dart';

import 'ScanScreen.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late InternetProvider internetProvider;

  late DatabaseProvider db_provider;
  String debug = '';
  int _selectedIndex = 1;

  final List<BottomNavigationBarItem> _bottomNavigationBarItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Attendance',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Scan',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Employee',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    db_provider = Provider.of<DatabaseProvider>(context);
    internetProvider = Provider.of<InternetProvider>(context);

    if (internetProvider.isConnected == true) {
      db_provider.syncAttendance();
    }

    final GlobalKey<ScaffoldState> _key = GlobalKey();

    return Scaffold(
      key: _key,
      drawer: Navbar(),
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavigationBarItems,
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            _key.currentState!.openDrawer();
          },
          child: Icon(
            Icons.menu,
            color: Colors.black,
          ),
        ),
        title: const Text(
          'Employee Scan',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          internetProvider.isConnected
              ? Padding(
                  padding: const EdgeInsets.only(right: 15, top: 15),
                  child: CountdownTimerSync(
                    duration: 30,
                    onFinished: () {
                      db_provider.syncAttendance();
                    },
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
      body: _getBody(),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return ShowAttendanceScreen();
      case 1:
        return QRViewScreen();
      case 2:
        return ShowEmployeeScreen();
      default:
        return Container();
    }
  }
}
