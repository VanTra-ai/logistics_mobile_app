import 'package:flutter/material.dart';

class MyWalletScreen extends StatefulWidget {
  const MyWalletScreen({super.key});

  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends State<MyWalletScreen> {
  // Mock data
  final double codDebt = 1250000;
  final double incomeBalance = 450000;

  final List<Map<String, dynamic>> codTransactions = [
    {'type': 'COD_COLLECTED', 'amount': 250000, 'date': '2026-07-08 10:30', 'description': 'Thu hộ đơn hàng #VN12345'},
    {'type': 'COD_COLLECTED', 'amount': 1000000, 'date': '2026-07-08 09:15', 'description': 'Thu hộ đơn hàng #VN12346'},
    {'type': 'COD_REMITTED', 'amount': -500000, 'date': '2026-07-07 18:00', 'description': 'Nộp COD cuối ngày'},
  ];

  final List<Map<String, dynamic>> incomeTransactions = [
    {'type': 'COMMISSION_EARNED', 'amount': 15000, 'date': '2026-07-08 10:30', 'description': 'Hoa hồng giao đơn #VN12345'},
    {'type': 'COMMISSION_EARNED', 'amount': 15000, 'date': '2026-07-08 09:15', 'description': 'Hoa hồng giao đơn #VN12346'},
    {'type': 'COMMISSION_EARNED', 'amount': 20000, 'date': '2026-07-07 14:20', 'description': 'Hoa hồng giao đơn #VN12347'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ví của tôi'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.orange.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.orange.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        child: Column(
                          children: [
                            Text(
                              'Tiền đang giữ\n(Nợ COD)',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall?.copyWith(color: Colors.orange.shade900),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${codDebt.toStringAsFixed(0)} đ',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      color: Colors.green.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.green.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        child: Column(
                          children: [
                            Text(
                              'Thu nhập\nhiện tại',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall?.copyWith(color: Colors.green.shade900),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${incomeBalance.toStringAsFixed(0)} đ',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Thu hộ'),
                Tab(text: 'Thu nhập'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab Thu hộ
                  ListView.separated(
                    itemCount: codTransactions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = codTransactions[index];
                      final isRemitted = tx['type'] == 'COD_REMITTED';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isRemitted ? Colors.blue.shade100 : Colors.orange.shade100,
                          child: Icon(
                            isRemitted ? Icons.upload : Icons.download,
                            color: isRemitted ? Colors.blue : Colors.orange,
                          ),
                        ),
                        title: Text(tx['description']),
                        subtitle: Text(tx['date']),
                        trailing: Text(
                          '${isRemitted ? "" : "+"}${tx['amount']} đ',
                          style: TextStyle(
                            color: isRemitted ? Colors.blue.shade700 : Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  // Tab Thu nhập
                  ListView.separated(
                    itemCount: incomeTransactions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = incomeTransactions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(Icons.monetization_on, color: Colors.green),
                        ),
                        title: Text(tx['description']),
                        subtitle: Text(tx['date']),
                        trailing: Text(
                          '+${tx['amount']} đ',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
