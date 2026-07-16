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
      body: StreamBuilder(
        stream: logsRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Lịch sử trống', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
            return const Center(child: Text('Lịch sử chưa có dữ liệu hợp lệ'));
          }

          return ListView.builder(
            itemCount: logsList.length,
            itemBuilder: (context, index) {
              var log = logsList[index];
              String action = log['action']?.toString() ?? 'Không rõ';
              bool isClose = action.contains('Đóng');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isClose ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    child: Icon(
                      isClose ? Icons.lock : Icons.lock_open,
                      color: isClose ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(action, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(log['time']?.toString() ?? 'Không có thời gian'),
                  trailing: Text(
                    log['user']?.toString() ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: log['user']?.toString() == 'Hệ thống' ? Colors.grey : Colors.blue
                    )
                  ),
                ),
              );
            },
          );
        },
      ),
      // 👈 2. KIỂM TRA QUYỀN TRƯỚC KHI HIỆN NÚT DỌN RÁC
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _showClearHistoryDialog(context),
              backgroundColor: Colors.red,
              tooltip: 'Dọn dẹp lịch sử',
              child: const Icon(Icons.delete_sweep, color: Colors.white),
            )
          : null, // Nếu không phải Admin thì ẩn hoàn toàn (trả về null)
    );
  }
}