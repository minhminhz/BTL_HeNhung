import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryScreen extends StatelessWidget {
  final bool isAdmin; 

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
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder(
        stream: logsRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Chưa có lịch sử hoạt động', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

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

          logsList = logsList.reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logsList.length,
            itemBuilder: (context, index) {
              var log = logsList[index];
              String action = log['action']?.toString() ?? 'Không xác định';
              
              // LOGIC NHẬN DIỆN MỚI: Chuẩn hóa chuỗi để so sánh chính xác nhất
              String normalizedAction = action.toLowerCase().trim();
              bool isClose = normalizedAction.contains('dong') || 
                             normalizedAction.contains('đóng') || 
                             normalizedAction.contains('close') ||
                             normalizedAction.contains('khoá') ||
                             normalizedAction.contains('khóa') ||
                             normalizedAction.contains('off');
              
              String user = log['user']?.toString() ?? 'Người dùng';
              String time = log['time']?.toString() ?? '--:--';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  // Thêm viền màu đậm để phân biệt rõ ràng
                  border: Border.all(
                    color: isClose ? Colors.red.shade200 : Colors.green.shade200,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isClose ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isClose ? Icons.lock_rounded : Icons.lock_open_rounded,
                      color: isClose ? Colors.red : Colors.green,
                      size: 26,
                    ),
                  ),
                  title: Text(
                    action,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isClose ? Colors.red.shade800 : Colors.green.shade800,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text(
                          time,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text("•", style: TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text('XÓA LỊCH SỬ', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
