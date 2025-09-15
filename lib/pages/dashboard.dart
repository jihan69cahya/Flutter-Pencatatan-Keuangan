import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pencatatan/helpers/helpers.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // Data dari API
  double totalPemasukan = 0;
  double totalPengeluaran = 0;
  double saldoHariIni = 0;
  List<Map<String, dynamic>> transaksiData = [];

  bool isLoading = false;
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'URL_NOT_FOUND';

  @override
  void initState() {
    super.initState();
    _fetchDataDashboard();
  }

  Future<void> _fetchDataDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/data-dashboard'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          totalPemasukan = double.parse(data['pemasukan'].toString());
          totalPengeluaran = double.parse(data['pengeluaran'].toString());
          saldoHariIni = double.parse(data['saldo'].toString());
          transaksiData = List<Map<String, dynamic>>.from(data['transaksi']);
        });
      } else {
        debugPrint('Gagal fetch data dashboard: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memuat data dashboard'),
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

  // Generate bar chart data dari API
  List<BarChartGroupData> _generateBarData() {
    List<BarChartGroupData> barData = [];

    for (int i = 0; i < transaksiData.length; i++) {
      final transaksi = transaksiData[i];
      barData.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: double.parse(transaksi['pemasukan'].toString()),
              color: Colors.green,
              width: 16,
              borderRadius: BorderRadius.zero,
            ),
            BarChartRodData(
              toY: double.parse(transaksi['pengeluaran'].toString()),
              color: Colors.red,
              width: 16,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }

    return barData;
  }

  // Generate month names untuk chart
  String _getMonthName(int monthNumber) {
    const months = [
      '', // index 0 tidak digunakan
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[monthNumber] ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF2a5298),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Saldo Hari Ini',
                          saldoHariIni,
                          Icons.account_balance_wallet,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Pemasukan',
                          totalPemasukan,
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Pengeluaran',
                          totalPengeluaran,
                          Icons.trending_down,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (transaksiData.isNotEmpty) ...[
                    const Text(
                      'Pemasukan vs Pengeluaran Bulanan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2a5298),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: BarChart(
                        BarChartData(
                          maxY: _getMaxYValue(),
                          barGroups: _generateBarData(),
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                getTitlesWidget: (value, meta) {
                                  if (value >= 1000000) {
                                    return Text(
                                      '${(value / 1000000).toInt()} Jt',
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  } else if (value >= 1000) {
                                    return Text(
                                      '${(value / 1000).toInt()}K',
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index < transaksiData.length) {
                                    int monthNumber = int.parse(
                                      transaksiData[index]['bulan'].toString(),
                                    );
                                    return Text(
                                      _getMonthName(monthNumber),
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: Colors.grey.shade400,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    final formatter = NumberFormat.currency(
                                      locale: 'id',
                                      symbol: 'Rp ',
                                      decimalDigits: 0,
                                    );
                                    return BarTooltipItem(
                                      formatter.format(rod.toY),
                                      TextStyle(
                                        color: rod.color ?? Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Pemasukan', Colors.green),
                        const SizedBox(width: 24),
                        _buildLegendItem('Pengeluaran', Colors.red),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Pie Chart - hanya tampil jika ada data pemasukan atau pengeluaran
                  if (totalPemasukan > 0 || totalPengeluaran > 0) ...[
                    const Text(
                      'Proporsi Total Pemasukan vs Pengeluaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2a5298),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: PieChart(
                        PieChartData(
                          sections: [
                            if (totalPemasukan > 0)
                              PieChartSectionData(
                                color: Colors.green,
                                value: totalPemasukan,
                                title: totalPemasukan + totalPengeluaran > 0
                                    ? '${((totalPemasukan / (totalPemasukan + totalPengeluaran)) * 100).toInt()}%'
                                    : '0%',
                                radius: 100,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            if (totalPengeluaran > 0)
                              PieChartSectionData(
                                color: Colors.red,
                                value: totalPengeluaran,
                                title: totalPemasukan + totalPengeluaran > 0
                                    ? '${((totalPengeluaran / (totalPemasukan + totalPengeluaran)) * 100).toInt()}%'
                                    : '0%',
                                radius: 100,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                          centerSpaceRadius: 0,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(
                          'Pemasukan (${Helpers.formatCurrency(totalPemasukan)})',
                          Colors.green,
                        ),
                        const SizedBox(width: 24),
                        _buildLegendItem(
                          'Pengeluaran (${Helpers.formatCurrency(totalPengeluaran)})',
                          Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Tampilkan pesan jika tidak ada data
                  if (transaksiData.isEmpty && !isLoading)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.bar_chart_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada data transaksi',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // Helper untuk menentukan nilai maksimum Y pada chart
  double _getMaxYValue() {
    double maxValue = 0;
    for (var transaksi in transaksiData) {
      double pemasukan = double.parse(transaksi['pemasukan'].toString());
      double pengeluaran = double.parse(transaksi['pengeluaran'].toString());
      if (pemasukan > maxValue) maxValue = pemasukan;
      if (pengeluaran > maxValue) maxValue = pengeluaran;
    }
    // Tambahkan margin 20% untuk tampilan yang lebih baik
    return maxValue * 1.2;
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Helpers.formatCurrency(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
