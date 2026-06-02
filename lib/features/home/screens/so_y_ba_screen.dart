import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/services/pet_service.dart';

class SoYBaScreen extends StatefulWidget {
  final bool showBottomNav;

  const SoYBaScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  State<SoYBaScreen> createState() => _SoYBaScreenState();
}

class _SoYBaScreenState extends State<SoYBaScreen> {
  static const _orange = Color(0xFFF4A261);
  static const _orangeDark = Color(0xFFD97706);
  static const _green = Color(0xFF4CAF82);
  static const _yellow = Color(0xFFF4B740);
  static const _background = Color(0xFFFAF8F5);
  static const _text = Color(0xFF1F2937);
  static const _muted = Color(0xFF6B7280);

  final PetService _petService = PetService();
  late Future<List<Map<String, dynamic>>> _petsFuture;
  String? _selectedPetId;

  @override
  void initState() {
    super.initState();
    _petsFuture = _petService.getMyPets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _petsFuture,
          builder: (context, petSnapshot) {
            if (petSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _orangeDark));
            }

            final pets = petSnapshot.data ?? [];
            if (pets.isEmpty) {
              return Column(
                children: [
                  _buildHeader(),
                  const Expanded(
                    child: _EmptyState(
                      icon: Icons.pets,
                      title: 'Chua co thu cung',
                      message: 'Hay tao ho so thu cung truoc khi lap so y ba.',
                    ),
                  ),
                ],
              );
            }

            _selectedPetId ??= pets.first['id'] as String?;
            final selectedPet = pets.firstWhere(
              (pet) => pet['id'] == _selectedPetId,
              orElse: () => pets.first,
            );

            return Column(
              children: [
                _buildHeader(),
                _buildPetSelector(pets, selectedPet),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _petService.getMedicalRecordsStream(_selectedPetId!),
                    builder: (context, recordSnapshot) {
                      if (recordSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: _orangeDark));
                      }
                      if (recordSnapshot.hasError) {
                        return _EmptyState(
                          icon: Icons.error_outline,
                          title: 'Khong tai duoc so y ba',
                          message: recordSnapshot.error.toString(),
                        );
                      }

                      final records = (recordSnapshot.data?.docs ?? [])
                          .map(_HealthRecord.fromDoc)
                          .toList();

                      return _buildRecordContent(selectedPet, records);
                    },
                  ),
                ),
                if (widget.showBottomNav) _buildBottomNav(context),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _selectedPetId == null
          ? null
          : FloatingActionButton(
              backgroundColor: _orangeDark,
              foregroundColor: Colors.white,
              onPressed: () => _openAddMenu(_selectedPetId!),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: _text),
            onPressed: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Text(
              'So y ba dien tu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _text),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: _orangeDark),
            onPressed: () {
              setState(() {
                _selectedPetId = null;
                _petsFuture = _petService.getMyPets();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPetSelector(List<Map<String, dynamic>> pets, Map<String, dynamic> selectedPet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: _Card(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.pets, color: _orangeDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPetId,
                  isExpanded: true,
                  items: pets.map((pet) {
                    return DropdownMenuItem<String>(
                      value: pet['id'] as String,
                      child: Text(
                        '${pet['name'] ?? 'Pet'} - ${pet['type'] ?? pet['kind'] ?? 'Thu cung'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedPetId = value),
                ),
              ),
            ),
            _StatusBadge(label: '${selectedPet['age'] ?? '?'} tuoi', color: _green),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordContent(Map<String, dynamic> pet, List<_HealthRecord> records) {
    final vaccines = records.where((record) => record.isVaccine).toList();
    final visits = records.where((record) => record.isVisit).toList();
    final weights = records.where((record) => record.isWeight && record.weight != null).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return RefreshIndicator(
      color: _orangeDark,
      onRefresh: () async => setState(() {}),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _buildSummary(pet, records),
          const SizedBox(height: 16),
          _buildVaccinationTimeline(vaccines),
          const SizedBox(height: 16),
          _buildMedicalJournal(visits),
          const SizedBox(height: 16),
          _buildHealthTracker(weights),
        ],
      ),
    );
  }

  Widget _buildSummary(Map<String, dynamic> pet, List<_HealthRecord> records) {
    final lastDate = records.isEmpty ? 'Chua co du lieu' : DateFormat('dd/MM/yyyy').format(records.first.date);
    return _Card(
      child: Row(
        children: [
          const Icon(Icons.folder_shared_outlined, color: _orangeDark, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet['name'] ?? 'Thu cung',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _text),
                ),
                const SizedBox(height: 4),
                Text('Cap nhat gan nhat: $lastDate', style: const TextStyle(fontSize: 12, color: _muted)),
              ],
            ),
          ),
          _StatusBadge(label: '${records.length} muc', color: _orangeDark),
        ],
      ),
    );
  }

  Widget _buildVaccinationTimeline(List<_HealthRecord> vaccines) {
    return _Section(
      title: 'Lich su tiem chung',
      actionLabel: 'Them vaccine',
      onAction: () => _showRecordForm(type: _RecordType.vaccine, petId: _selectedPetId!),
      child: vaccines.isEmpty
          ? const _EmptyInline(message: 'Chua co mui vaccine nao.')
          : Column(
              children: List.generate(vaccines.length, (index) {
                return _buildVaccineItem(vaccines[index], index == vaccines.length - 1);
              }),
            ),
    );
  }

  Widget _buildVaccineItem(_HealthRecord record, bool isLast) {
    final completed = record.isCompleted;
    final color = completed ? _green : _yellow;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(completed ? Icons.check : Icons.schedule, color: Colors.white, size: 15),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFFE5E7EB))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _RecordTile(
                title: record.title,
                subtitle: '${DateFormat('dd/MM/yyyy').format(record.date)} - ${record.clinicName}',
                body: record.note,
                status: completed ? 'Da tiem' : 'Sap tiem',
                statusColor: color,
                onEdit: () => _showRecordForm(type: _RecordType.vaccine, petId: record.petId, record: record),
                onDelete: () => _confirmDelete(record.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalJournal(List<_HealthRecord> visits) {
    return _Section(
      title: 'Nhat ky kham benh',
      actionLabel: 'Them lan kham',
      onAction: () => _showRecordForm(type: _RecordType.visit, petId: _selectedPetId!),
      child: visits.isEmpty
          ? const _EmptyInline(message: 'Chua co lan kham nao.')
          : Column(
              children: visits.map((record) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecordTile(
                    title: record.title,
                    subtitle: '${DateFormat('dd/MM/yyyy').format(record.date)} - ${record.clinicName}',
                    body: [
                      if (record.diagnosis.isNotEmpty) 'Chan doan: ${record.diagnosis}',
                      if (record.advice.isNotEmpty) 'Loi dan: ${record.advice}',
                      if (record.prescription.isNotEmpty) 'Don thuoc: ${record.prescription}',
                      if (record.note.isNotEmpty) record.note,
                    ].join('\n'),
                    status: 'Kham benh',
                    statusColor: _orangeDark,
                    onEdit: () => _showRecordForm(type: _RecordType.visit, petId: record.petId, record: record),
                    onDelete: () => _confirmDelete(record.id),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildHealthTracker(List<_HealthRecord> weights) {
    return _Section(
      title: 'Theo doi chi so',
      actionLabel: 'Them can nang',
      onAction: () => _showRecordForm(type: _RecordType.weight, petId: _selectedPetId!),
      child: weights.isEmpty
          ? const _EmptyInline(message: 'Chua co du lieu can nang.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeightHeader(weights),
                const SizedBox(height: 16),
                SizedBox(height: 220, child: _buildWeightChart(weights)),
              ],
            ),
    );
  }

  Widget _buildWeightHeader(List<_HealthRecord> weights) {
    final latest = weights.last.weight!;
    final previous = weights.length > 1 ? weights[weights.length - 2].weight! : latest;
    final diff = latest - previous;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(latest.toStringAsFixed(1), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _orangeDark)),
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(' kg', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _orangeDark)),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: _StatusBadge(
            label: '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg',
            color: diff >= 0 ? _green : Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChart(List<_HealthRecord> weights) {
    final minY = weights.map((e) => e.weight!).reduce((a, b) => a < b ? a : b) - 0.5;
    final maxY = weights.map((e) => e.weight!).reduce((a, b) => a > b ? a : b) + 0.5;
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFE8DED3), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10, color: _muted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= weights.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(DateFormat('MM/yy').format(weights[index].date), style: const TextStyle(fontSize: 10, color: _muted)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final record = weights[spot.x.toInt()];
              return LineTooltipItem(
                '${DateFormat('dd/MM').format(record.date)}: ${spot.y.toStringAsFixed(1)} kg',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(weights.length, (index) => FlSpot(index.toDouble(), weights[index].weight!)),
            isCurved: true,
            color: _orangeDark,
            barWidth: 4,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: true, color: _orange.withValues(alpha: 0.16)),
            dotData: FlDotData(
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: _orangeDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddMenu(String petId) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AddActionTile(
                  icon: Icons.vaccines_outlined,
                  title: 'Them mui vaccine',
                  onTap: () {
                    Navigator.pop(context);
                    _showRecordForm(type: _RecordType.vaccine, petId: petId);
                  },
                ),
                _AddActionTile(
                  icon: Icons.medical_services_outlined,
                  title: 'Them nhat ky kham',
                  onTap: () {
                    Navigator.pop(context);
                    _showRecordForm(type: _RecordType.visit, petId: petId);
                  },
                ),
                _AddActionTile(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Them can nang',
                  onTap: () {
                    Navigator.pop(context);
                    _showRecordForm(type: _RecordType.weight, petId: petId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRecordForm({
    required _RecordType type,
    required String petId,
    _HealthRecord? record,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _RecordFormSheet(
        type: type,
        petId: petId,
        record: record,
        petService: _petService,
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(record == null ? 'Da them vao so y ba' : 'Da cap nhat so y ba')),
      );
    }
  }

  Future<void> _confirmDelete(String recordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoa muc nay?'),
        content: const Text('Du lieu se bi xoa khoi so y ba.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _petService.deleteMedicalRecord(recordId);
    }
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: _orange,
        unselectedItemColor: Colors.grey.shade400,
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) Navigator.maybePop(context);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Trang chu'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Dich vu'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Lich'),
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital_outlined), label: 'Kham benh'),
          BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism_outlined), label: 'Cuu tro'),
        ],
      ),
    );
  }
}

enum _RecordType { vaccine, visit, weight }

class _HealthRecord {
  final String id;
  final String petId;
  final String recordType;
  final DateTime date;
  final String title;
  final String clinicName;
  final String note;
  final bool isCompleted;
  final double? weight;
  final String diagnosis;
  final String advice;
  final String prescription;

  const _HealthRecord({
    required this.id,
    required this.petId,
    required this.recordType,
    required this.date,
    required this.title,
    required this.clinicName,
    required this.note,
    required this.isCompleted,
    required this.weight,
    required this.diagnosis,
    required this.advice,
    required this.prescription,
  });

  factory _HealthRecord.fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawDate = data['date'];
    final weightValue = data['weight'];
    return _HealthRecord(
      id: doc.id,
      petId: data['petId'] ?? '',
      recordType: data['recordType'] ?? '',
      date: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      title: data['title'] ?? '',
      clinicName: data['clinicName'] ?? '',
      note: data['note'] ?? '',
      isCompleted: data['isCompleted'] ?? true,
      weight: weightValue is num ? weightValue.toDouble() : double.tryParse('${weightValue ?? ''}'),
      diagnosis: data['diagnosis'] ?? '',
      advice: data['advice'] ?? '',
      prescription: data['prescription'] ?? '',
    );
  }

  bool get isVaccine => recordType == 'vaccine' || recordType.toLowerCase().contains('vaccine') || recordType.toLowerCase().contains('tiem');
  bool get isVisit => recordType == 'visit' || recordType.toLowerCase().contains('kham');
  bool get isWeight => recordType == 'weight' || recordType.toLowerCase().contains('can');
}

class _RecordFormSheet extends StatefulWidget {
  final _RecordType type;
  final String petId;
  final _HealthRecord? record;
  final PetService petService;

  const _RecordFormSheet({
    required this.type,
    required this.petId,
    required this.record,
    required this.petService,
  });

  @override
  State<_RecordFormSheet> createState() => _RecordFormSheetState();
}

class _RecordFormSheetState extends State<_RecordFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _clinicController;
  late final TextEditingController _noteController;
  late final TextEditingController _diagnosisController;
  late final TextEditingController _adviceController;
  late final TextEditingController _prescriptionController;
  late final TextEditingController _weightController;
  late DateTime _date;
  late bool _isCompleted;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _titleController = TextEditingController(text: record?.title ?? _defaultTitle);
    _clinicController = TextEditingController(text: record?.clinicName ?? '');
    _noteController = TextEditingController(text: record?.note ?? '');
    _diagnosisController = TextEditingController(text: record?.diagnosis ?? '');
    _adviceController = TextEditingController(text: record?.advice ?? '');
    _prescriptionController = TextEditingController(text: record?.prescription ?? '');
    _weightController = TextEditingController(text: record?.weight?.toString() ?? '');
    _date = record?.date ?? DateTime.now();
    _isCompleted = record?.isCompleted ?? true;
  }

  String get _defaultTitle {
    switch (widget.type) {
      case _RecordType.vaccine:
        return '';
      case _RecordType.visit:
        return 'Kham benh';
      case _RecordType.weight:
        return 'Can nang';
    }
  }

  String get _recordType {
    switch (widget.type) {
      case _RecordType.vaccine:
        return 'vaccine';
      case _RecordType.visit:
        return 'visit';
      case _RecordType.weight:
        return 'weight';
    }
  }

  String get _title {
    switch (widget.type) {
      case _RecordType.vaccine:
        return widget.record == null ? 'Them vaccine' : 'Sua vaccine';
      case _RecordType.visit:
        return widget.record == null ? 'Them lan kham' : 'Sua lan kham';
      case _RecordType.weight:
        return widget.record == null ? 'Them can nang' : 'Sua can nang';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _clinicController.dispose();
    _noteController.dispose();
    _diagnosisController.dispose();
    _adviceController.dispose();
    _prescriptionController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 16),
              Text(_title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 12),
              if (widget.type == _RecordType.weight)
                _TextField(controller: _weightController, label: 'Can nang (kg)', keyboardType: TextInputType.number, requiredField: true)
              else ...[
                _TextField(controller: _titleController, label: widget.type == _RecordType.vaccine ? 'Ten vaccine' : 'Tieu de', requiredField: true),
                const SizedBox(height: 12),
                _TextField(controller: _clinicController, label: 'Phong kham / Bac si', requiredField: true),
              ],
              if (widget.type == _RecordType.vaccine) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Da tiem'),
                  value: _isCompleted,
                  activeThumbColor: const Color(0xFF4CAF82),
                  onChanged: (value) => setState(() => _isCompleted = value),
                ),
              ],
              if (widget.type == _RecordType.visit) ...[
                const SizedBox(height: 12),
                _TextField(controller: _diagnosisController, label: 'Chan doan', maxLines: 2),
                const SizedBox(height: 12),
                _TextField(controller: _adviceController, label: 'Loi dan bac si', maxLines: 2),
                const SizedBox(height: 12),
                _TextField(controller: _prescriptionController, label: 'Don thuoc', maxLines: 3),
              ],
              const SizedBox(height: 12),
              _TextField(controller: _noteController, label: 'Ghi chu', maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Luu', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => _date = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Ngay',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(DateFormat('dd/MM/yyyy').format(_date)),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final extraData = <String, dynamic>{};
    if (widget.type == _RecordType.vaccine) {
      extraData['isCompleted'] = _isCompleted;
    }
    if (widget.type == _RecordType.visit) {
      extraData['diagnosis'] = _diagnosisController.text.trim();
      extraData['advice'] = _adviceController.text.trim();
      extraData['prescription'] = _prescriptionController.text.trim();
    }
    if (widget.type == _RecordType.weight) {
      extraData['weight'] = double.tryParse(_weightController.text.trim().replaceAll(',', '.')) ?? 0;
    }

    final success = widget.record == null
        ? await widget.petService.addMedicalRecord(
            petId: widget.petId,
            recordType: _recordType,
            date: _date,
            title: _titleController.text.trim().isEmpty ? _defaultTitle : _titleController.text.trim(),
            clinicName: _clinicController.text.trim(),
            note: _noteController.text.trim(),
            extraData: extraData,
          )
        : await widget.petService.updateMedicalRecord(
            recordId: widget.record!.id,
            recordType: _recordType,
            date: _date,
            title: _titleController.text.trim().isEmpty ? _defaultTitle : _titleController.text.trim(),
            clinicName: _clinicController.text.trim(),
            note: _noteController.text.trim(),
            extraData: extraData,
          );

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Khong luu duoc du lieu')));
    }
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final bool requiredField;
  final TextInputType? keyboardType;

  const _TextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.requiredField = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (requiredField && (value == null || value.trim().isEmpty)) {
          return 'Vui long nhap $label';
        }
        return null;
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  const _Section({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _SoYBaScreenState._text))),
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String body;
  final String status;
  final Color statusColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordTile({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.status,
    required this.statusColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0E7DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _SoYBaScreenState._text)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: _SoYBaScreenState._muted)),
                  ],
                ),
              ),
              _StatusBadge(label: status, color: statusColor),
            ],
          ),
          if (body.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(body, style: const TextStyle(fontSize: 12, height: 1.35, color: _SoYBaScreenState._text)),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 20)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _AddActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AddActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFD97706)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _SoYBaScreenState._muted)),
          ],
        ),
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final String message;

  const _EmptyInline({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: _SoYBaScreenState._muted)),
    );
  }
}
