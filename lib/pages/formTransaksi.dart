import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pencatatan/widgets/toast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:pencatatan/helpers/helpers.dart';

class FormTransaksi extends StatefulWidget {
  const FormTransaksi({super.key});

  @override
  State<FormTransaksi> createState() => _FormTransaksiState();
}

class _FormTransaksiState extends State<FormTransaksi>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tanggalController = TextEditingController();
  final _nominalController = TextEditingController();
  final _keteranganController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late bool isEdit;
  late int? index;
  late Map<String, dynamic>? transaksi;
  int? _transactionId;

  final String baseUrl = dotenv.env['BASE_URL'] ?? 'URL_NOT_FOUND';

  String _selectedTipe = 'MASUK';
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _allTipeOptions = [
    {
      'value': 'SALDO AWAL',
      'label': 'Saldo Awal',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF2a5298),
      'description': 'Saldo pembukaan akun',
    },
    {
      'value': 'MASUK',
      'label': 'Pemasukan',
      'icon': Icons.trending_up_rounded,
      'color': Color(0xFF27AE60),
      'description': 'Dana masuk ke rekening',
    },
    {
      'value': 'KELUAR',
      'label': 'Pengeluaran',
      'icon': Icons.trending_down_rounded,
      'color': Color(0xFFE74C3C),
      'description': 'Dana keluar dari rekening',
    },
  ];

  List<Map<String, dynamic>> _tipeOptions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      isEdit = args['isEdit'] ?? false;
      index = args['index'];
      transaksi = args['transaksi'];
    } else {
      isEdit = false;
      index = null;
      transaksi = null;
    }

    _checkEdit();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _tanggalController.text = Helpers.formatDate(_selectedDate.toString());
    _animationController.forward();
  }

  Future<void> _checkEdit() async {
    if (isEdit) {
      final tipe = transaksi?['type'].toString().toUpperCase();
      final tanggal = transaksi?['tanggal'].toString();
      final nominal = transaksi?['nominal'];
      final keterangan = transaksi?['keterangan']?.toString() ?? '';
      final id = transaksi?['id'];

      setState(() {
        _tipeOptions = _allTipeOptions
            .where((opt) => opt['value'] == tipe)
            .toList();
        _selectedTipe = tipe!;

        _transactionId = id;

        if (tanggal != null) {
          _selectedDate = DateTime.parse(tanggal);
          _tanggalController.text = Helpers.formatDate(tanggal);
        }

        if (nominal != null) {
          _nominalController.text = _formatCurrency(nominal.toDouble());
        }

        _keteranganController.text = keterangan;
      });
    } else {
      _cekSaldoAwal();
      _transactionId = null;
    }
  }

  Future<void> _cekSaldoAwal() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cek-saldo-awal'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        setState(() {
          if (result == 1) {
            _tipeOptions = _allTipeOptions
                .where((opt) => opt['value'] != 'SALDO AWAL')
                .toList();
            _selectedTipe = 'MASUK';
          } else {
            _tipeOptions = _allTipeOptions
                .where((opt) => opt['value'] == 'SALDO AWAL')
                .toList();
            _selectedTipe = 'SALDO AWAL';
          }
        });
      } else {
        Toast.showErrorToast(context, 'Gagal cek saldo awal');
      }
    } catch (e) {
      Toast.showErrorToast(context, 'Error: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2a5298),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1e293b),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = Helpers.formatDate(picked.toString());
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedTipe = 'MASUK';
      _tanggalController.text = Helpers.formatDate(_selectedDate.toString());
      _nominalController.clear();
      _keteranganController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Form berhasil direset'),
          ],
        ),
        backgroundColor: const Color(0xFF2a5298),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _simpanTransaksi() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF2a5298), Color(0xFF3b82f6)],
              ),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Menyimpan transaksi...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        final nominal = _nominalController.text.replaceAll('.', '');
        final Map<String, dynamic> requestData = {
          'tanggal': Helpers.formatDateForApi(_selectedDate),
          'tipe': _selectedTipe,
          'nominal': int.parse(nominal),
          'keterangan': _keteranganController.text,
        };

        if (isEdit && _transactionId != null) {
          requestData['id'] = _transactionId;
        }

        final response = await http.post(
          Uri.parse('$baseUrl/simpan-transaksi'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(requestData),
        );

        Navigator.pop(context);

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 && responseData['status'] == true) {
          Toast.showSuccessToast(
            context,
            responseData['message'] ??
                'Transaksi ${_getTipeLabel()} telah disimpan',
          );
          Navigator.pop(context, {
            'success': true,
            'action': isEdit ? 'update' : 'create',
          });
        } else {
          Toast.showErrorToast(
            context,
            responseData['message'] ?? 'Gagal menyimpan transaksi',
          );
        }
      } catch (e) {
        Navigator.pop(context);
        Toast.showErrorToast(context, 'Error: ${e.toString()}');
      }
    }
  }

  String _getTipeLabel() {
    final option = _tipeOptions.firstWhere(
      (opt) => opt['value'] == _selectedTipe,
    );
    return option['label'];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tanggalController.dispose();
    _nominalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2a5298), Color(0xFF1e3a8a), Color(0xFF1e293b)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(),

              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFE),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderCard(),
                            const SizedBox(height: 32),

                            _buildAnimatedSection(
                              delay: 200,
                              child: _buildDateField(),
                            ),
                            const SizedBox(height: 24),

                            _buildAnimatedSection(
                              delay: 300,
                              child: _buildTipeField(),
                            ),
                            const SizedBox(height: 24),

                            _buildAnimatedSection(
                              delay: 400,
                              child: _buildNominalField(),
                            ),
                            const SizedBox(height: 24),

                            _buildAnimatedSection(
                              delay: 500,
                              child: _buildKeteranganField(),
                            ),
                            const SizedBox(height: 40),

                            _buildAnimatedSection(
                              delay: 600,
                              child: _buildActionButtons(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Form Transaksi',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                Text(
                  'Kelola keuangan dengan mudah',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _resetForm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2a5298), Color(0xFF3b82f6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2a5298).withOpacity(0.25),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.add_card_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Transaksi' : 'Transaksi Baru',
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    Text(
                      isEdit
                          ? 'Ubah data transaksi keuangan Anda'
                          : 'Tambahkan data transaksi keuangan Anda',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection({required Widget child, required int delay}) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2a5298).withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: const Color(0xFF2a5298),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tanggal Transaksi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2a5298),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: TextFormField(
              controller: _tanggalController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Pilih tanggal transaksi',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(
                  Icons.event_rounded,
                  color: const Color(0xFF2a5298),
                ),
                suffixIcon: Icon(Icons.touch_app, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              onTap: _selectDate,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tanggal harus diisi';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipeField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2a5298).withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  color: const Color(0xFF2a5298),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tipe Transaksi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2a5298),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: _tipeOptions.map((option) {
                final isSelected = _selectedTipe == option['value'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2a5298).withOpacity(0.08)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2a5298)
                          : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: RadioListTile<String>(
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: option['color'],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            option['icon'],
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option['label'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFF2a5298)
                                      : const Color(0xFF1e293b),
                                ),
                              ),
                              Text(
                                option['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    value: option['value'],
                    groupValue: _selectedTipe,
                    onChanged: (value) {
                      setState(() {
                        _selectedTipe = value!;
                      });
                    },
                    activeColor: const Color(0xFF2a5298),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNominalField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2a5298).withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Icon(
                  Icons.monetization_on_rounded,
                  color: const Color(0xFF2a5298),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Nominal Transaksi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2a5298),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: TextFormField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a5298),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nominal harus diisi';
                }
                final numericValue = value.replaceAll('.', '');
                if (int.tryParse(numericValue) == null ||
                    int.parse(numericValue) <= 0) {
                  return 'Nominal harus berupa angka positif';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeteranganField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2a5298).withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Icon(
                  Icons.description_rounded,
                  color: const Color(0xFF2a5298),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Keterangan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2a5298),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Opsional',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: TextFormField(
              controller: _keteranganController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Masukkan detail atau catatan tambahan...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2a5298), Color(0xFF3b82f6)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2a5298).withOpacity(0.3),
                spreadRadius: 0,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _simpanTransaksi,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  isEdit ? 'Simpan Perubahan' : 'Simpan Transaksi',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2a5298),
              side: const BorderSide(color: Color(0xFF2a5298), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel_rounded, size: 24),
                SizedBox(width: 12),
                Text('Batal', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _formatCurrency(double value) {
  return value
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    double value = double.parse(newValue.text.replaceAll('.', ''));
    String newText = _formatCurrency(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
