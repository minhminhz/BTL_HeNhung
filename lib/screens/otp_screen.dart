import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class OtpScreen extends StatelessWidget {
  const OtpScreen({Key? key}) : super(key: key);

  void _generateOTP() {
    DatabaseReference db = FirebaseDatabase.instance.ref('home/otps');
    String newOtp = (Random().nextInt(900000) + 100000).toString(); // Mã 6 số
    db.child(newOtp).set({'is_used': false});
  }

  @override
  Widget build(BuildContext context) {
    DatabaseReference otpRef = FirebaseDatabase.instance.ref('home/otps');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('TẠO MÃ OTP MỚI', style: TextStyle(fontSize: 18)),
            onPressed: _generateOTP,
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: otpRef.onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Center(child: Text('Chưa có mã OTP nào'));
              }

              Map<dynamic, dynamic> otpMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              List<MapEntry> otpList = otpMap.entries.toList();

              return ListView.builder(
                itemCount: otpList.length,
                itemBuilder: (context, index) {
                  var code = otpList[index].key;
                  bool isUsed = otpList[index].value['is_used'] ?? true;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 5)),
                      subtitle: Text(isUsed ? 'Đã sử dụng' : 'Chưa sử dụng', style: TextStyle(color: isUsed ? Colors.red : Colors.green)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => otpRef.child(code).remove(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}