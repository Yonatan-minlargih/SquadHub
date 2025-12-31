import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/user.dart';
import '../../core/models/safewalk_session.dart';
import '../../core/widgets/slide_action_button.dart';
import '../auth/bloc/auth_bloc.dart';
import '../status/bloc/status_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/guardian_alarm_service.dart';

class SafewalkScreen extends StatefulWidget {
  const SafewalkScreen({super.key});

  @override
  State<SafewalkScreen> createState() => _SafewalkScreenState();
}

class _SafewalkScreenState extends State<SafewalkScreen>
    with TickerProviderStateMixin {
  User? _selectedGuardian;
  late AnimationController _pulseController;
  late AnimationController _tickPulseController;
  late Animation<double> _tickScaleAnimation;

  final List<int> _durationOptions = [15, 30, 45, 60, 90, 120];
  String? _currentSessionId;
  bool _isActive = false;
  int _selectedDurationMinutes = 30;
  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _tickPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _tickScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _tickPulseController, curve: Curves.easeOut),
    );

    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('safewalk_sessions')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .get();

    if (snapshot.docs.isNotEmpty) {
      final session = SafewalkSession.fromFirestore(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
      _resumeSession(session);
    }
  }

  void _resumeSession(SafewalkSession session) {
    setState(() {
      _isActive = true;
      _currentSessionId = session.id;
      _remainingSeconds = session.expiryTime
          .difference(DateTime.now())
          .inSeconds;
    });

    if (_remainingSeconds > 0) {
      _startTimer();
    } else {
      _triggerEmergencyAlert();
    }
  }

  Future<void> _startWalk() async {
    if (_selectedGuardian == null) return;

    HapticFeedback.mediumImpact();
    final authState = context.read<AuthBloc>().state;
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final startTime = DateTime.now();
    final expiryTime = startTime.add(
      Duration(minutes: _selectedDurationMinutes),
    );

    final session = SafewalkSession(
      id: const Uuid().v4(),
      userId: user.uid,
      guardianId: _selectedGuardian!.id,
      squadId: authState.squadId ?? '',
      status: SafewalkStatus.active,
      startTime: startTime,
      expiryTime: expiryTime,
      durationMinutes: _selectedDurationMinutes,
    );

    await FirebaseFirestore.instance
        .collection('safewalk_sessions')
        .doc(session.id)
        .set(session.toFirestore());

    setState(() {
      _isActive = true;
      _currentSessionId = session.id;
      _remainingSeconds = _selectedDurationMinutes * 60;
    });

    // Schedule background alarm
    await GuardianAlarmService.scheduleEmergencyAlarm(expiryTime);
    _startTimer();
  }

  Future<void> _stopWalk() async {
    HapticFeedback.mediumImpact();
    if (_currentSessionId != null) {
      await FirebaseFirestore.instance
          .collection('safewalk_sessions')
          .doc(_currentSessionId)
          .update({'status': 'completed'});
    }

    // Cancel background alarm
    await GuardianAlarmService.cancelAlarm();
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _remainingSeconds = 0;
      _currentSessionId = null;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        // Haptic tick
        if (_remainingSeconds <= 60) {
          HapticFeedback.lightImpact();
        }

        // Triggers pulse animation with each tick
        _tickPulseController.forward().then((_) {
          _tickPulseController.reverse();
        });
      } else {
        _timer?.cancel();
        _handleTimeExpired();
      }
    });
  }

  Future<void> _handleTimeExpired() async {
    if (_currentSessionId != null) {
      await FirebaseFirestore.instance
          .collection('safewalk_sessions')
          .doc(_currentSessionId)
          .update({'status': 'emergency'});
    }
    _triggerEmergencyAlert();
  }

  void _triggerEmergencyAlert() {
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Iconsax.danger, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'Time Suspicious!',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Your timer has expired. ${_selectedGuardian?.name ?? "Your guardian"} has been notified that you might need help.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _stopWalk();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: const Text('I am Safe'),
          ),
        ],
      ),
    );
  }

  void _showCustomDurationPicker() {
    final controller = TextEditingController(
      text: _selectedDurationMinutes.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Duration'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'minutes'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() {
                  _selectedDurationMinutes = val;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds / 60).floor();
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showGuardianPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Select Guardian', style: AppTextStyles.h3),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ...context
                  .read<StatusBloc>()
                  .state
                  .users
                  .where(
                    (u) => u.id != auth.FirebaseAuth.instance.currentUser?.uid,
                  )
                  .map(
                    (user) => ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: theme.colorScheme.surfaceContainerHighest,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          user.avatarUrl.length > 2
                              ? user.name.substring(0, 1)
                              : user.avatarUrl,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(user.name),
                      trailing: _selectedGuardian?.id == user.id
                          ? const Icon(Iconsax.tick_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedGuardian = user;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _tickPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Enhanced Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.shield,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Walk Safe Anywhere', style: AppTextStyles.h2),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Notify your squad if you\'re in trouble',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Guardian Selection Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: primaryColor,
                        child: Text(
                          _selectedGuardian == null
                              ? "G"
                              : (_selectedGuardian!.avatarUrl.length > 2
                                    ? _selectedGuardian!.name.substring(0, 1)
                                    : _selectedGuardian!.avatarUrl),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guardian',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _selectedGuardian?.name ?? 'Not Selected',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isActive ? null : _showGuardianPicker,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Change'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Timer Display with tick pulse
              if (_isActive) ...[
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _pulseController,
                      _tickScaleAnimation,
                    ]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _tickScaleAnimation.value,
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withValues(
                                alpha: 0.5 + (_pulseController.value * 0.5),
                              ),
                              width: 6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(
                                  alpha: 0.3 * (1 - _pulseController.value),
                                ),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formattedTime,
                                style: AppTextStyles.h1.copyWith(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'ETA',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined, color: primaryColor, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Timer active. Stay safe!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'If the timer reaches 0, your guardian will be alerted.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else ...[
                Center(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Icon(
                      Iconsax.shield,
                      size: 120,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Select Duration (Minutes)',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ..._durationOptions.map((duration) {
                      final isSelected = _selectedDurationMinutes == duration;
                      return ChoiceChip(
                        label: Text('$duration min'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedDurationMinutes = duration;
                            });
                          }
                        },
                      );
                    }),
                    ChoiceChip(
                      label: const Text('Custom...'),
                      selected: !_durationOptions.contains(
                        _selectedDurationMinutes,
                      ),
                      onSelected: (_) => _showCustomDurationPicker(),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Action Button
              SizedBox(
                height: 56,
                child: _isActive
                    ? SlideActionButton(
                        text: 'SLIDE TO STOP',
                        innerColor: Colors.white,
                        onSubmit: _stopWalk,
                      )
                    : FilledButton.icon(
                        onPressed: _selectedGuardian == null
                            ? null
                            : _startWalk,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text(
                          'START WALK',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
