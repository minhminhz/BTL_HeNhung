import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ControlScreen extends StatelessWidget {
  final String userName;
  const ControlScreen({Key? key, required this.userName}) : super(key: key);

  void _toggleDoor(bool isCurrentlyOpen) {
    DatabaseReference db = FirebaseDatabase.instance.ref();
    bool newState = !isCurrentlyOpen;

    db.update({
      'home/device_status/door_lock': newState,
      'home/control/remote_open': newState,
      'home/control/remote_user': userName,
    });
  }

  @override
  Widget build(BuildContext context) {
    DatabaseReference statusRef = FirebaseDatabase.instance.ref('home/device_status/door_lock');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white],
        ),
      ),
      child: Center(
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
                // Hình ảnh/Icon minh họa trạng thái
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isOpen ? Colors.green : Colors.red).withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
                    size: 120,
                    color: isOpen ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  isOpen ? "Cửa đang mở" : "Cửa đang khóa",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isOpen ? "Chạm bên dưới để đóng cửa an toàn" : "Chạm bên dưới để mở cửa từ xa",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 60),

                // Nút điều khiển xịn hơn
                GestureDetector(
                  onTap: () => _toggleDoor(isOpen),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOpen 
                          ? [Colors.redAccent, Colors.red] 
                          : [Colors.blueAccent, Colors.blue],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: (isOpen ? Colors.red : Colors.blue).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isOpen ? Icons.close : Icons.key, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          isOpen ? 'ĐÓNG CỬA' : 'MỞ CỬA',
                          style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}