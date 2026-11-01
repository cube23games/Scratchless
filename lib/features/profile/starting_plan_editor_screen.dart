import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/models/starting_plan.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

class StartingPlanEditorScreen extends StatefulWidget {
  final StartingPlan plan;

  const StartingPlanEditorScreen({
    super.key,
    required this.plan,
  });

  @override
  State<StartingPlanEditorScreen> createState() =>
      _StartingPlanEditorScreenState();
}

class _StartingPlanEditorScreenState extends State<StartingPlanEditorScreen> {
  late final TextEditingController _goalController;
  late final TextEditingController _frequencyController;
  late final TextEditingController _spendController;

  late String _problemFit;
  late String _preferredRescue;
  late String _supportPreference;
  late Set<String> _triggers;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(text: widget.plan.goal);
    _frequencyController = TextEditingController(
      text: widget.plan.frequencyPerWeek.toString(),
    );
    _spendController = TextEditingController(
      text: _formatAmount(widget.plan.averageSpend),
    );
    _problemFit = widget.plan.problemFit ?? '';
    _preferredRescue = widget.plan.preferredRescue ?? '';
    _supportPreference = widget.plan.supportPreference ?? '';
    _triggers = widget.plan.triggers.toSet();
  }

  @override
  void dispose() {
    _goalController.dispose();
    _frequencyController.dispose();
    _spendController.dispose();
    super.dispose();
  }

  String _formatAmount(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  String? _nullableValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _save() {
    final goal = _goalController.text.trim();
    final frequency = int.tryParse(_frequencyController.text.trim());
    final spend = double.tryParse(
      _spendController.text.trim().replaceAll(',', ''),
    );

    if (goal.isEmpty) {
      _showError('Add a current focus before saving.');
      return;
    }
    if (frequency == null || frequency <= 0 || frequency > 100) {
      _showError('Enter a realistic number of purchase periods per week.');
      return;
    }
    if (spend == null || spend <= 0 || spend > 100000) {
      _showError('Enter a valid typical spend amount.');
      return;
    }

    Navigator.of(context).pop(
      StartingPlan(
        problemFit: _nullableValue(_problemFit),
        goal: goal,
        frequencyPerWeek: frequency,
        averageSpend: spend,
        triggers: _triggers.toList(),
        preferredRescue: _nullableValue(_preferredRescue),
        supportPreference: _nullableValue(_supportPreference),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _items(List<String> values) {
    return <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: '',
        child: Text('Not set yet'),
      ),
      ...values.map(
        (value) => DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Starting Plan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Starting Plan',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Keep ScratchLess honest about what you are working on.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'These answers shape estimates and the first support ScratchLess shows during an urge. Change them whenever your situation changes.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Current focus'),
                TextField(
                  controller: _goalController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'What would feel like a win?',
                    hintText: 'Stay in control',
                  ),
                ),
                const SizedBox(height: 16),
                _sectionTitle('What feels most true right now?'),
                DropdownButtonFormField<String>(
                  value: _problemFit,
                  isExpanded: true,
                  items: _items(StartingPlan.problemFitOptions),
                  onChanged: (value) {
                    setState(() {
                      _problemFit = value ?? '';
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Starting baseline'),
                TextField(
                  controller: _frequencyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Purchase periods per week',
                    helperText: 'Use your best current estimate.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _spendController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Typical spend each time',
                    prefixText: '\$',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('What usually pulls you in?'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: StartingPlan.triggerOptions.map((trigger) {
                    final selected = _triggers.contains(trigger);
                    return FilterChip(
                      label: Text(trigger),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          if (selected) {
                            _triggers.remove(trigger);
                          } else {
                            _triggers.add(trigger);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Preferred first move during an urge'),
                DropdownButtonFormField<String>(
                  value: _preferredRescue,
                  isExpanded: true,
                  items: _items(StartingPlan.rescueOptions),
                  onChanged: (value) {
                    setState(() {
                      _preferredRescue = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                _sectionTitle('Support preference'),
                DropdownButtonFormField<String>(
                  value: _supportPreference,
                  isExpanded: true,
                  items: _items(StartingPlan.supportOptions),
                  onChanged: (value) {
                    setState(() {
                      _supportPreference = value ?? '';
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Save Starting Plan',
            icon: Icons.check_rounded,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
