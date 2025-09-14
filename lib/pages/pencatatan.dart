import 'package:flutter/material.dart';
import 'package:pencatatan/helpers/helpers.dart';

class Pencatatan extends StatefulWidget {
  const Pencatatan({super.key});

  @override
  State<Pencatatan> createState() => _PencatatanState();
}

class _PencatatanState extends State<Pencatatan> {
  bool isTableView =
      true; // true = tampilan buku tabungan, false = tampilan per transaksi

  final List<Map<String, dynamic>> transaksiList = [
    {
      'tanggal': '2024-01-15',
      'keterangan': 'Gaji Bulanan',
      'masuk': 5000000.0,
      'keluar': 0.0,
      'saldo': 5000000.0,
      'type': 'saldo awal',
    },
    {
      'tanggal': '2024-01-16',
      'keterangan': 'Belanja Bulanan',
      'masuk': 0.0,
      'keluar': 1200000.0,
      'saldo': 3800000.0,
      'type': 'keluar',
    },
    {
      'tanggal': '2024-01-18',
      'keterangan': 'Freelance Project',
      'masuk': 2000000.0,
      'keluar': 0.0,
      'saldo': 5800000.0,
      'type': 'masuk',
    },
    {
      'tanggal': '2024-01-20',
      'keterangan': 'Bayar Listrik',
      'masuk': 0.0,
      'keluar': 250000.0,
      'saldo': 5550000.0,
      'type': 'keluar',
    },
    {
      'tanggal': '2024-01-22',
      'keterangan': 'Bonus Kinerja',
      'masuk': 1500000.0,
      'keluar': 0.0,
      'saldo': 7050000.0,
      'type': 'masuk',
    },
    {
      'tanggal': '2024-01-25',
      'keterangan': 'Makan & Transport',
      'masuk': 0.0,
      'keluar': 350000.0,
      'saldo': 6700000.0,
      'type': 'keluar',
    },
    {
      'tanggal': '2024-01-28',
      'keterangan': 'Investasi Saham',
      'masuk': 0.0,
      'keluar': 1000000.0,
      'saldo': 5700000.0,
      'type': 'keluar',
    },
    {
      'tanggal': '2024-01-30',
      'keterangan': 'Dividen Saham',
      'masuk': 300000.0,
      'keluar': 0.0,
      'saldo': 6000000.0,
      'type': 'masuk',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pencatatan'),
        backgroundColor: const Color(0xFF2a5298),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Toggle Button Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isTableView = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isTableView
                                    ? const Color(0xFF2a5298)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.table_chart,
                                    size: 18,
                                    color: isTableView
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Buku Tabungan',
                                    style: TextStyle(
                                      color: isTableView
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isTableView = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isTableView
                                    ? const Color(0xFF2a5298)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.list,
                                    size: 18,
                                    color: !isTableView
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Per Transaksi',
                                    style: TextStyle(
                                      color: !isTableView
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
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
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),

          // Content based on view mode
          Expanded(child: isTableView ? _buildTableView() : _buildCardView()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/form-transaksi');
        },
        backgroundColor: const Color(0xFF2a5298),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTableView() {
    return Column(
      children: [
        // Header Table
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Tanggal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF2a5298),
                  ),
                ),
              ),
              const Expanded(
                flex: 3,
                child: Text(
                  'Keterangan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF2a5298),
                  ),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Masuk',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF2a5298),
                  ),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Keluar',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF2a5298),
                  ),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Saldo',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF2a5298),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.grey),

        Expanded(
          child: ListView.builder(
            itemCount: transaksiList.length,
            itemBuilder: (context, index) {
              final transaksi = transaksiList[index];
              return _buildTransaksiItem(transaksi, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transaksiList.length,
      itemBuilder: (context, index) {
        final transaksi = transaksiList[index];
        return _buildTransaksiCard(transaksi, index);
      },
    );
  }

  Widget _buildTransaksiCard(Map<String, dynamic> transaksi, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(transaksi['tanggal']),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2a5298),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: transaksi['type'] == 'masuk'
                        ? Colors.green.withOpacity(0.1)
                        : transaksi['type'] == 'keluar'
                        ? Colors.red.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    transaksi['type'] == 'masuk'
                        ? 'Masuk'
                        : transaksi['type'] == 'keluar'
                        ? 'Keluar'
                        : 'Saldo Awal',
                    style: TextStyle(
                      fontSize: 10,
                      color: transaksi['type'] == 'masuk'
                          ? Colors.green[700]
                          : transaksi['type'] == 'keluar'
                          ? Colors.red[700]
                          : Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              transaksi['keterangan'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaksi['masuk'] > 0
                            ? Helpers.formatCurrency(transaksi['masuk'])
                            : '-',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: transaksi['masuk'] > 0
                              ? Colors.green[700]
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keluar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaksi['keluar'] > 0
                            ? Helpers.formatCurrency(transaksi['keluar'])
                            : '-',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: transaksi['keluar'] > 0
                              ? Colors.red[700]
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatCurrency(transaksi['saldo']),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2a5298),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _editTransaction(index);
                  },
                  icon: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Color(0xFF2a5298),
                  ),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Color(0xFF2a5298),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    _deleteTransaction(index);
                  },
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text(
                    'Hapus',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransaksiItem(Map<String, dynamic> transaksi, int index) {
    final isEven = index % 2 == 0;

    return Container(
      color: isEven ? Colors.white : Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(transaksi['tanggal']),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaksi['keterangan'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: transaksi['type'] == 'masuk'
                        ? Colors.green.withOpacity(0.1)
                        : transaksi['type'] == 'keluar'
                        ? Colors.red.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaksi['type'] == 'masuk'
                        ? 'Masuk'
                        : transaksi['type'] == 'keluar'
                        ? 'Keluar'
                        : 'Saldo Awal',
                    style: TextStyle(
                      fontSize: 8,
                      color: transaksi['type'] == 'masuk'
                          ? Colors.green[700]
                          : transaksi['type'] == 'keluar'
                          ? Colors.red[700]
                          : Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              transaksi['masuk'] > 0
                  ? Helpers.formatCurrency(transaksi['masuk'])
                  : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: transaksi['masuk'] > 0 ? Colors.green[700] : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              transaksi['keluar'] > 0
                  ? Helpers.formatCurrency(transaksi['keluar'])
                  : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: transaksi['keluar'] > 0 ? Colors.red[700] : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              Helpers.formatCurrency(transaksi['saldo']),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2a5298),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editTransaction(int index) {
    Navigator.pushNamed(
      context,
      '/form-transaksi',
      arguments: {
        'isEdit': true,
        'index': index,
        'transaksi': transaksiList[index],
      },
    );
  }

  void _deleteTransaction(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus transaksi ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  transaksiList.removeAt(index);
                });
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaksi berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
