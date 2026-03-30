import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

class OnboardingResult {
  final int frequencyPerWeek;
  final double averageSpend;
  final String goal;

  const OnboardingResult({
    required this.frequencyPerWeek,
    required this.averageSpend,
    required this.goal,
  });
}

class OnboardingScreen extends StatefulWidget {
  final ValueChanged<OnboardingResult> onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _totalSteps = 9;

  int _step = 0;

  String _problemFit = 'I buy scratch-offs more than I want to.';
  String _goal = 'Stay in control';
  int _frequencyPerWeek = 2;
  double _averageSpend = 15;
  final Set<String> _triggerSelections = <String>{};
  String _rescuePlan = 'A quick breathing reset';
  String _privacyPreference = 'Keep it private for now';

  final List<_ChoiceOption<String>> _problemOptions = const [
    _ChoiceOption(
      value: 'I buy scratch-offs more than I want to.',
      label: 'I buy scratch-offs more than I want to.',
    ),
    _ChoiceOption(
      value: 'I spend more than I plan on lottery tickets.',
      label: 'I spend more than I plan on lottery tickets.',
    ),
    _ChoiceOption(
      value: 'I want help stopping the cycle before it starts.',
      label: 'I want help stopping the cycle before it starts.',
    ),
    _ChoiceOption(
      value: 'I’m trying to cut back, not quit completely.',
      label: 'I’m trying to cut back, not quit completely.',
    ),
  ];

  final List<_ChoiceOption<String>> _goalOptions = const [
    _ChoiceOption(
      value: 'Stop completely',
      label: 'Stop completely',
    ),
    _ChoiceOption(
      value: 'Cut back sharply',
      label: 'Cut back sharply',
    ),
    _ChoiceOption(
      value: 'Stay in control',
      label: 'Stay in control',
    ),
  ];

  final List<_ChoiceOption<int>> _frequencyOptions = const [
    _ChoiceOption(
      value: 1,
      label: 'A few times a month',
      subtitle: 'A light but real pattern.',
    ),
    _ChoiceOption(
      value: 2,
      label: 'Once or twice a week',
      subtitle: 'Happens regularly, but not every day.',
    ),
    _ChoiceOption(
      value: 5,
      label: 'Most days',
      subtitle: 'Shows up through much of the week.',
    ),
    _ChoiceOption(
      value: 10,
      label: 'More than once a day',
      subtitle: 'Can hit multiple times in a day.',
    ),
  ];

  final List<_ChoiceOption<double>> _spendOptions = const [
    _ChoiceOption(
      value: 8,
      label: 'Under \$10',
      subtitle: 'A small stop that still adds up.',
    ),
    _ChoiceOption(
      value: 15,
      label: '\$10–\$20',
      subtitle: 'A common “not too bad” range.',
    ),
    _ChoiceOption(
      value: 35,
      label: '\$20–\$50',
      subtitle: 'A bigger hit than it first feels like.',
    ),
    _ChoiceOption(
      value: 60,
      label: '\$50+',
      subtitle: 'A heavy stop with real downstream cost.',
    ),
  ];

  final List<String> _triggerOptions = const [
    'Payday',
    'Gas station stops',
    'Store displays',
    'Stress',
    'Boredom',
    'Loneliness',
    'Chasing losses',
    'Habit / routine',
  ];

  final List<_ChoiceOption<String>> _rescueOptions = const [
    _ChoiceOption(
      value: 'A quick breathing reset',
      label: 'A quick breathing reset',
    ),
    _ChoiceOption(
      value: 'A delay timer',
      label: 'A delay timer',
    ),
    _ChoiceOption(
      value: 'My reasons to stop',
      label: 'My reasons to stop',
    ),
    _ChoiceOption(
      value: 'Texting someone I trust',
      label: 'Texting someone I trust',
    ),
    _ChoiceOption(
      value: 'A replacement activity',
      label: 'A replacement activity',
    ),
  ];

  final List<_ChoiceOption<String>> _privacyOptions = const [
    _ChoiceOption(
      value: 'Keep it private for now',
      label: 'Keep it private for now',
    ),
    _ChoiceOption(
      value: 'Add one trusted person later',
      label: 'Add one trusted person later',
    ),
    _ChoiceOption(
      value: 'I want accountability help',
      label: 'I want accountability help',
    ),
  ];

  bool get _isLastStep => _step == _totalSteps - 1;

  double get _estimatedWeeklySpend => _frequencyPerWeek * _averageSpend;

  double get _estimatedMonthlySpend => _estimatedWeeklySpend * 4.33;

  double get _estimatedYearlySpend => _estimatedMonthlySpend * 12;

  void _next() {
    if (_isLastStep) {
      widget.onComplete(
        OnboardingResult(
          frequencyPerWeek: _frequencyPerWeek,
          averageSpend: _averageSpend,
          goal: _goal,
        ),
      );
      return;
    }

    setState(() {
      _step += 1;
    });
  }

  void _back() {
    if (_step == 0) {
      return;
    }

    setState(() {
      _step -= 1;
    });
  }

  Future<void> _showPremiumPreview() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ScratchLess Premium'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Premium is about deeper support, not blocking help.',
              ),
              SizedBox(height: 12),
              Text('• Advanced trigger insights'),
              Text('• Unlimited reminders and rescue plans'),
              Text('• Accountability tools'),
              Text('• Weekly reflections and recovery reports'),
              Text('• Full history and deeper money tracking'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Continue free'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader({
    required String headline,
    required String body,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(
            color: AppTheme.mutedText,
            fontSize: 15,
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 8),
          Text(
            helper,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChoiceCard({
    required String label,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppTheme.accent : Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(
              Icons.circle,
              size: 8,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          headline: 'Take back control of lottery spending.',
          body:
              'ScratchLess helps you interrupt urges, track the real cost, and make better choices before the next ticket purchase.',
        ),
        const SizedBox(height: 20),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Private support. No shame.',
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This app is built for urges, spending, slips, and recovery — not for judging you.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProblemFitStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          headline: 'What feels most true right now?',
          body:
              'Pick the statement that feels closest. This is just to make the app feel more relevant from the start.',
        ),
        const SizedBox(height: 20),
        ..._problemOptions.map((option) {
          return _buildChoiceCard(
            label: option.label,
            selected: _problemFit == option.value,
            onTap: () {
              setState(() {
                _problemFit = option.value;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          headline: 'What would feel like a win?',
          body:
              'Choose the direction that feels useful right now. You can change this later.',
          helper: 'You can change this later.',
        ),
        const SizedBox(height: 20),
        ..._goalOptions.map((option) {
          return _buildChoiceCard(
            label: option.label,
            selected: _goal == option.value,
            onTap: () {
              setState(() {
                _goal = option.value;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildFrequencyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          headline: 'How often has this been happening lately?',
          body:
              'Best estimate is enough. Tracking will make this more accurate over time.',
          helper: 'Best estimate is enough.',
        ),
        const SizedBox(height: 20),
        ..._frequencyOptions.map((option) {
          return _buildChoiceCard(
            label: option.label,
            subtitle: option.subtitle,
            selected: _frequencyPerWeek == option.value,
            onTap: () {
              setState(() {
                _frequencyPerWeek = option.value;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildSpendStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          headline: 'About how much usually leaves your pocket in one stop?',
          body:
              'This is just a starting estimate. You can make it more accurate later as you log real behavior.',
          helper: 'You can make this more accurate later.',
        ),
        const SizedBox(height: 20),
        ..._spendOptions.map((option) {
          return _buildChoiceCard(
            label: option.label,
            subtitle: option.subtitle,
            selected: _averageSpend == option.value,
            onTap: () {
              setState(() {
                _averageSpend = option.value;
              });
            },
          );
        }),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Starting cost preview',
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_estimatedMonthlySpend.toStringAsFixed(0)} per month',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'That is based on your current best estimate, not a perfection test.',
                style: const TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          headline: 'What usually pulls you in?',
          body:
              'Pick all that apply. This helps ScratchLess feel more relevant in the moments that matter.',
          helper: 'Pick all that apply.',
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _triggerOptions.map((trigger) {
            final selected = _triggerSelections.contains(trigger);
            return FilterChip(
              label: Text(trigger),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  if (selected) {
                    _triggerSelections.remove(trigger);
                  } else {
                    _triggerSelections.add(trigger);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRescueStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          headline: 'What helps you pause?',
          body:
              'We will use this to shape the tone of your first urge-support experience.',
          helper: 'We’ll build your first urge plan around this.',
        ),
        const SizedBox(height: 20),
        ..._rescueOptions.map((option) {
          return _buildChoiceCard(
            label: option.label,
            selected: _rescuePlan == option.value,
            onTap: () {
              setState(() {
                _rescuePlan = option.value;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildPrivacyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          headline: 'Do you want to keep this private or add support?',
          body:
              'You do not have to decide everything right now. This just helps us respect your starting comfort level.',
        ),
        const SizedBox(height: 20),
        ..._privacyOptions.map((option) {
          return _buildChoiceCard(
            label: option.label,
            selected: _privacyPreference == option.value,
            onTap: () {
              setState(() {
                _privacyPreference = option.value;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildPreviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          headline: 'Here’s what ScratchLess helps you do.',
          body:
              'Start with the essentials for free. Upgrade later only if you want deeper support.',
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your starting estimate',
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '\$${_estimatedWeeklySpend.toStringAsFixed(0)} weekly',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '\$${_estimatedMonthlySpend.toStringAsFixed(0)} monthly • \$${_estimatedYearlySpend.toStringAsFixed(0)} yearly',
                style: const TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Goal: $_goal',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What the app will help you do',
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12),
              _StaticBullet('Interrupt urges before the next ticket'),
              _StaticBullet('See the real cost of the habit'),
              _StaticBullet('Build a control streak'),
              _StaticBullet('Recover quickly after a slip'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why this baseline is enough',
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You said this feels most true: $_problemFit',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_triggerSelections.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Common pull-ins: ${_triggerSelections.join(', ')}',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'You can adjust your answers later. Real logging will make the app smarter over time.',
                style: const TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildProblemFitStep();
      case 2:
        return _buildGoalStep();
      case 3:
        return _buildFrequencyStep();
      case 4:
        return _buildSpendStep();
      case 5:
        return _buildTriggerStep();
      case 6:
        return _buildRescueStep();
      case 7:
        return _buildPrivacyStep();
      case 8:
        return _buildPreviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  String get _leftButtonLabel {
    if (_step == 0) {
      return 'I’m just looking';
    }
    if (_isLastStep) {
      return 'See Premium';
    }
    return 'Back';
  }

  VoidCallback get _leftButtonAction {
    if (_step == 0) {
      return _next;
    }
    if (_isLastStep) {
      return _showPremiumPreview;
    }
    return _back;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_step + 1) / _totalSteps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ScratchLess'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Step ${_step + 1} of $_totalSteps',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStepContent(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: _leftButtonLabel,
                      isPrimary: false,
                      onPressed: _leftButtonAction,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: _isLastStep ? 'Start Free' : 'Continue',
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceOption<T> {
  final T value;
  final String label;
  final String? subtitle;

  const _ChoiceOption({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

class _StaticBullet extends StatelessWidget {
  final String text;

  const _StaticBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(
              Icons.circle,
              size: 8,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
