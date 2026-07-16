import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({Key? key}) : super(key: key);


  void _toggleDoor(bool isCurrentlyOpen) {
    DatabaseReference db = FirebaseDatabase.instance.ref();


    bool newState = !isCurrentlyOpen;

    db.update({

      'home/device_status/door_lock': newState,


      'home/control/remote_open': newState,
      'home/control/remote_user': 'Admin App'
    });
  }

  @override
  Widget build(BuildContext context) {
    DatabaseReference statusRef = FirebaseDatabase.instance.ref('home/device_status/door_lock');

    return Center(
      child: StreamBuilder(
        stream: statusRef.onValue,
        builder: (context, snapshot) {
          bool isOpen = false;

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            isOpen = snapshot.data!.snapshot.value as bool;
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Icon(
                isOpen ? Icons.lock_open : Icons.lock,
                size: 100,
                color: isOpen ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 20),


              Text(
                isOpen ? "CỬA ĐANG MỞ" : "CỬA ĐANG KHÓA",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isOpen ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 50),


              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOpen ? Colors.red : Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => _toggleDoor(isOpen),
                child: Text(
                  isOpen ? 'BẤM ĐỂ ĐÓNG CỬA' : 'BẤM ĐỂ MỞ CỬA',
                  style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}