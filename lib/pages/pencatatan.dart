import 'package:flutter/material.dart';
import 'package:pencatatan/helpers/helpers.dart';
import 'package:pencatatan/widgets/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Pencatatan extends StatefulWidget {
  const Pencatatan({super.key});

  @override
  State<Pencatatan> createState() => _PencatatanState();
}

class _PencatatanState extends State<Pencatatan> {
  bool isTableView = true;
  bool isLoading = false;
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'URL_NOT_FOUND';

  List<Map<String, dynamic>> transaksiList = [];

  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchDataTransaksi();
  }

  Future<void> _fetchDataTransaksi({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/data-transaksi?page=$page&per_page=$itemsPerPage'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        final Map<String, dynamic> pagination =
            responseData['pagination'] ?? {};

        setState(() {
          transaksiList = data.map((item) {
            double debit = 0.0;
            double kredit = 0.0;
            double saldo = 0.0;
            double nominal = 0.0;

            if (item['debit'] != null && item['debit'] != '-') {
              debit = double.tryParse(item['debit'].toString()) ?? 0.0;
              nominal = debit;
            }

            if (item['kredit'] != null && item['kredit'] != '-') {
              kredit = double.tryParse(item['kredit'].toString()) ?? 0.0;
              nominal = kredit;
            }

            if (item['saldo'] != null && item['saldo'] != '-') {
              saldo = double.tryParse(item['saldo'].toString()) ?? 0.0;
            }

            return {
              'id': item['id'] ?? '',
              'tanggal': item['tanggal'] ?? '',
              'keterangan': item['keterangan'] ?? '',
              'masuk': debit,
              'keluar': kredit,
              'saldo': saldo,
              'nominal': nominal,
              'type': item['tipe']?.toString().toLowerCase(),
            };
          }).toList();

          currentPage = pagination['current_page'] ?? 1;
          totalPages = pagination['last_page'] ?? 1;
          totalItems = pagination['total'] ?? 0;
          itemsPerPage = pagination['per_page'] ?? 20;
        });
      } else {
        debugPrint('Gagal fetch data transaksi: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memuat data transaksi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat memuat data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _addTransaction() async {
    final result = await Navigator.pushNamed(context, '/form-transaksi');

    if (result != null && (result as Map)['success'] == true) {
      _fetchDataTransaksi();
    }
  }

  void _editTransaction(int index) async {
    final result = await Navigator.pushNamed(
      context,
      '/form-transaksi',
      arguments: {
        'isEdit': true,
        'index': index,
        'transaksi': transaksiList[index],
      },
    );

    if (result != null && (result as Map)['success'] == true) {
      _fetchDataTransaksi();
    }
  }

  Future<void> _deleteTransaction(int index) async {
    final transaksi = transaksiList[index];
    final id = transaksi['id'];
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

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
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  final response = await http.post(
                    Uri.parse("$baseUrl/hapus-transaksi"),
                    headers: {
                      "Content-Type": "application/json",
                      "Accept": "application/json",
                      'Authorization': 'Bearer $token',
                    },
                    body: jsonEncode({"id": id}),
                  );

                  if (!mounted) return;

                  if (response.statusCode == 200) {
                    Toast.showSuccessToast(
                      context,
                      'Transaksi berhasil dihapus',
                    );
                    _fetchDataTransaksi();
                  } else {
                    final error = jsonDecode(response.body);
                    Toast.showErrorToast(
                      context,
                      "Gagal hapus: ${error['error'] ?? 'Terjadi kesalahan'}",
                    );
                    debugPrint(error.toString());
                  }
                } catch (e) {
                  Toast.showErrorToast(context, "Error: $e");
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= totalPages && page != currentPage) {
      _fetchDataTransaksi(page: page);
    }
  }

  void _goToNextPage() {
    if (currentPage < totalPages) {
      _goToPage(currentPage + 1);
    }
  }

  void _goToPreviousPage() {
    if (currentPage > 1) {
      _goToPage(currentPage - 1);
    }
  }

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

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2a5298)),
                  )
                : transaksiList.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada data transaksi',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: isTableView
                            ? _buildTableView()
                            : _buildCardView(),
                      ),
                      _buildPagination(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        backgroundColor: const Color(0xFF2a5298),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Halaman $currentPage dari $totalPages',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNavButton(
                icon: Icons.first_page,
                onTap: currentPage > 1 ? () => _goToPage(1) : null,
                enabled: currentPage > 1,
              ),
              const SizedBox(width: 4),
              _buildNavButton(
                icon: Icons.chevron_left,
                onTap: currentPage > 1 ? _goToPreviousPage : null,
                enabled: currentPage > 1,
              ),
              const SizedBox(width: 8),

              GestureDetector(
                onTap: () => _showPageSelector(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a5298).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF2a5298),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    currentPage.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a5298),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),
              _buildNavButton(
                icon: Icons.chevron_right,
                onTap: currentPage < totalPages ? _goToNextPage : null,
                enabled: currentPage < totalPages,
              ),
              const SizedBox(width: 4),
              _buildNavButton(
                icon: Icons.last_page,
                onTap: currentPage < totalPages
                    ? () => _goToPage(totalPages)
                    : null,
                enabled: currentPage < totalPages,
              ),
            ],
          ),

          Text(
            '$totalItems data',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF2a5298) : Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }

  void _showPageSelector() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Pilih Halaman',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Masukkan nomor halaman (1-$totalPages):',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  hintText: currentPage.toString(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                final page = int.tryParse(controller.text);
                if (page != null && page >= 1 && page <= totalPages) {
                  Navigator.of(context).pop();
                  _goToPage(page);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Halaman harus antara 1 dan $totalPages'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2a5298),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Pilih'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableView() {
    return Column(
      children: [
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
            padding: const EdgeInsets.only(bottom: 80),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: transaksiList.length,
      itemBuilder: (context, index) {
        final transaksi = transaksiList[index];
        return _buildTransaksiCard(transaksi, index);
      },
    );
  }

  Widget _buildTransaksiCard(Map<String, dynamic> transaksi, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Helpers.formatDate(transaksi['tanggal']),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaksi['keterangan'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (transaksi['masuk'] > 0) ...[
                        Icon(
                          Icons.arrow_downward_rounded,
                          color: Colors.green[600],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Helpers.formatCurrency(transaksi['masuk']),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ] else if (transaksi['keluar'] > 0) ...[
                        Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.red[600],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Helpers.formatCurrency(transaksi['keluar']),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Saldo',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a5298).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => _editTransaction(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit,
                              size: 14,
                              color: const Color(0xFF2a5298),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2a5298),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (transaksi['type'] != 'saldo awal') ...[
                  const SizedBox(width: 8),
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _deleteTransaction(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 14,
                                color: Colors.red[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Hapus',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                  Helpers.formatDate(transaksi['tanggal']),
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
}
