import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../models/medicine_stock_model.dart';
import '../../providers/inventory_provider.dart';

class MedicineStockScreen extends ConsumerWidget {
  const MedicineStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(medicineStockProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Medicine Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(medicineStockProvider),
          ),
        ],
      ),
      body: stockAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              message: 'No medicines in inventory',
              icon: Icons.medication_outlined,
            );
          }
          // Summary row
          final inStock = items.where((i) => i.status == StockStatus.inStock).length;
          final low = items.where((i) => i.status == StockStatus.low).length;
          final out = items.where((i) => i.status == StockStatus.outOfStock).length;

          return Column(
            children: [
              // Summary banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.surfaceVariant,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryBadge(label: 'In Stock', count: inStock, color: AppColors.riskLow),
                    _SummaryBadge(label: 'Low', count: low, color: AppColors.riskMedium),
                    _SummaryBadge(label: 'Out', count: out, color: AppColors.riskHigh),
                    _SummaryBadge(label: 'Total', count: items.length, color: AppColors.primary),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _MedicineRow(medicine: items[i]),
                ),
              ),
            ],
          );
        },
        loading: () => ListView(
          children: List.generate(6, (_) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: LoadingListItem())),
        ),
        error: (e, _) => EmptyState(
            message: 'Failed to load inventory',
            subtitle: e.toString(),
            icon: Icons.error_outline),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MedicineRow extends StatelessWidget {
  final MedicineStockModel medicine;
  const _MedicineRow({required this.medicine});

  Color get _statusColor {
    switch (medicine.status) {
      case StockStatus.inStock: return AppColors.riskLow;
      case StockStatus.low: return AppColors.riskMedium;
      case StockStatus.outOfStock: return AppColors.riskHigh;
    }
  }

  IconData get _statusIcon {
    switch (medicine.status) {
      case StockStatus.inStock: return Icons.check_circle_outline;
      case StockStatus.low: return Icons.warning_amber_outlined;
      case StockStatus.outOfStock: return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_statusIcon, color: _statusColor, size: 20),
        ),
        title: Text(medicine.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          '${medicine.category}  ·  ${medicine.currentQuantity} ${medicine.unit}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _statusColor.withOpacity(0.4)),
          ),
          child: Text(
            medicine.status.label,
            style: TextStyle(
                fontSize: 11,
                color: _statusColor,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
