import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/settings_store.dart';
import '../../core/theme/app_colors.dart';

/// Manages the group's fine types (name + default amount). These drive the
/// picker on the "Record Fine" screen.
class FineTypesScreen extends StatefulWidget {
  const FineTypesScreen({super.key});

  @override
  State<FineTypesScreen> createState() => _FineTypesScreenState();
}

class _FineTypesScreenState extends State<FineTypesScreen> {
  late List<_Row> _rows;

  @override
  void initState() {
    super.initState();
    _rows = [
      for (final f in context.read<SettingsStore>().fineTypes)
        _Row(name: f.name, amount: _trim(f.amount)),
    ];
    if (_rows.isEmpty) _rows.add(_Row(name: '', amount: ''));
  }

  String _trim(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _add() => setState(() => _rows.add(_Row(name: '', amount: '')));

  void _remove(int i) {
    setState(() {
      _rows.removeAt(i).dispose();
    });
  }

  Future<void> _save(LocaleProvider locale) async {
    final messenger = ScaffoldMessenger.of(context);
    final types = <FineTypeSetting>[
      for (final r in _rows)
        if (r.name.text.trim().isNotEmpty)
          FineTypeSetting(
            r.name.text.trim(),
            double.tryParse(r.amount.text.replaceAll(RegExp(r'[,\s]'), '')) ?? 0,
          ),
    ];
    await context.read<SettingsStore>().setFineTypes(types);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.primary,
        content: Text(locale.t('settings_saved'))));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(locale.t('fine_types_settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          for (var i = 0; i < _rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _rows[i].name,
                      textCapitalization: TextCapitalization.sentences,
                      decoration:
                          InputDecoration(hintText: locale.t('fine_name')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _rows[i].amount,
                      keyboardType: TextInputType.number,
                      decoration:
                          InputDecoration(hintText: locale.t('col_amount')),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.fines),
                    onPressed: _rows.length > 1 ? () => _remove(i) : null,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: Text(locale.t('add_fine_type')),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _save(locale),
            icon: const Icon(Icons.save_outlined),
            label: Text(locale.t('save')),
          ),
        ],
      ),
    );
  }
}

class _Row {
  final TextEditingController name;
  final TextEditingController amount;
  _Row({required String name, required String amount})
      : name = TextEditingController(text: name),
        amount = TextEditingController(text: amount);

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}
