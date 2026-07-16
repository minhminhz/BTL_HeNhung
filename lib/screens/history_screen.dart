import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryScreen extends StatelessWidget {
  final bool isAdmin; // 👈 1. Thêm biến nhận diện Admin

  // Yêu cầu bắt buộc phải truyền biến isAdmin vào khi mở màn hình này
  const HistoryScreen({Key? key, required this.isAdmin}) : super(key: key);

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Toàn Bộ Lịch Sử', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn dọn dẹp toàn bộ lịch sử đóng/mở cửa không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              FirebaseDatabase.instance.ref('home/logs').remove();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã dọn sạch lịch sử!'), backgroundColor: Colors.green),
              );
            },
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            label: const Text('Xóa sạch', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DatabaseReference logsRef = FirebaseDatabase.instance.ref('home/logs');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: StreamBuilder(
        stream: logsRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Lịch sử đang trống', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          // Chuyển đổi dữ liệu linh hoạt dù Firebase trả về Map hay List
          dynamic data = snapshot.data!.snapshot.value;
          List<Map<dynamic, dynamic>> logsList = [];

          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                logsList.add(Map<dynamic, dynamic>.from(value));
              }
            });
          } else if (data is List) {
            for (var item in data) {
              if (item != null && item is Map) {
                logsList.add(Map<dynamic, dynamic>.from(item));
              }
            }
          }

          // Đảo ngược danh sách để hiện tin mới nhất lên đầu
          logsList = logsList.reversed.toList();

          if (logsList.isEmpty) {
            return Center(
              child: Text('Lịch sử chưa có dữ liệu hợp lệ', style: TextStyle(color: Colors.grey.shade500)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logsList.length,
            itemBuilder: (context, index) {
              var log = logsList[index];
              String action = log['action']?.toString() ?? 'Không rõ';
              bool isClose = action.contains('Đóng');
              String user = log['user']?.toString() ?? 'Ẩn danh';

              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isClose ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isClose ? Icons.lock_rounded : Icons.lock_open_rounded,
                          color: isClose ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              log['time']?.toString() ?? 'Không rõ thời gian',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: user == 'Hệ thống' ? Colors.grey.shade100 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: user == 'Hệ thống' ? Colors.grey : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showClearHistoryDialog(context),
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Xóa lịch sử', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}