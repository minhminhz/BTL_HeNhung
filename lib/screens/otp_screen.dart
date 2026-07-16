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

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Mã mở cửa một lần (OTP)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tạo mã tạm thời để khách có thể vào nhà',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_moderator),
                  label: const Text('TẠO MÃ OTP MỚI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: _generateOTP,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: otpRef.onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.vpn_key_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Chưa có mã OTP nào', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                Map<dynamic, dynamic> otpMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<MapEntry> otpList = otpMap.entries.toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: otpList.length,
                  itemBuilder: (context, index) {
                    var code = otpList[index].key;
                    bool isUsed = otpList[index].value['is_used'] ?? true;

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUsed ? Colors.grey.shade100 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isUsed ? Icons.lock_clock : Icons.key_rounded,
                                color: isUsed ? Colors.grey : Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    code,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: isUsed ? Colors.grey : Colors.black87,
                                      decoration: isUsed ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  Text(
                                    isUsed ? 'Đã sử dụng' : 'Khả dụng',
                                    style: TextStyle(
                                      color: isUsed ? Colors.red.shade300 : Colors.green.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                              onPressed: () => otpRef.child(code).remove(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}