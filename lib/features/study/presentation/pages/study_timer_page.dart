import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/study_timer_service.dart';

extension StudyPhaseUI on StudyPhase {
  Color get color {
    switch (this) {
      case StudyPhase.focus:
        return Colors.red;
      case StudyPhase.shortBreak:
        return Colors.green;
      case StudyPhase.longBreak:
        return Colors.blue;
      case StudyPhase.stopped:
        return Colors.grey;
    }
  }

  String get emoji {
    switch (this) {
      case StudyPhase.focus:
        return '🎯';
      case StudyPhase.shortBreak:
        return '☕';
      case StudyPhase.longBreak:
        return '🛌';
      case StudyPhase.stopped:
        return '⏸️';
    }
  }

  String get displayName {
    switch (this) {
      case StudyPhase.focus:
        return 'Focus Time';
      case StudyPhase.shortBreak:
        return 'Short Break';
      case StudyPhase.longBreak:
        return 'Long Break';
      case StudyPhase.stopped:
        return 'Ready to Start';
    }
  }
}

class StudyTimerPage extends StatefulWidget {
  const StudyTimerPage({super.key});

  @override
  State<StudyTimerPage> createState() => _StudyTimerPageState();
}

class _StudyTimerPageState extends State<StudyTimerPage>
    with TickerProviderStateMixin {
  final StudyTimerService _studyService = StudyTimerService.instance;
  late AnimationController _progressController;
  late AnimationController _pulseController;

  // Settings
  int _focusDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;
  int _cyclesBeforeLongBreak = 4;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _studyService.loadSavedSession();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildTimerCircle() {
    return StreamBuilder<int>(
      stream: _studyService.timeLeftStream,
      initialData: _studyService.timeLeft,
      builder: (context, timeSnapshot) {
        return StreamBuilder<StudyPhase>(
          stream: _studyService.phaseStream,
          initialData: _studyService.currentPhase,
          builder: (context, phaseSnapshot) {
            final timeLeft = timeSnapshot.data ?? 0;
            final phase = phaseSnapshot.data ?? StudyPhase.stopped;

            // Calculate total phase duration for progress
            int totalDuration;
            switch (phase) {
              case StudyPhase.focus:
                totalDuration = _focusDuration * 60;
                break;
              case StudyPhase.shortBreak:
                totalDuration = _shortBreakDuration * 60;
                break;
              case StudyPhase.longBreak:
                totalDuration = _longBreakDuration * 60;
                break;
              case StudyPhase.stopped:
                totalDuration = _focusDuration * 60;
                break;
            }

            final progress = totalDuration > 0
                ? (totalDuration - timeLeft) / totalDuration
                : 0.0;

            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: phase.color.withValues(alpha: 0.3),
                        blurRadius: 20 + (_pulseController.value * 10),
                        spreadRadius: 5 + (_pulseController.value * 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),

                      // Progress circle
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            phase.color,
                          ),
                        ),
                      ),

                      // Content
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            phase.emoji,
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            phase.displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: phase.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _formatTime(timeLeft),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                              color: phase.color,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildControlButtons() {
    return StreamBuilder<StudyPhase>(
      stream: _studyService.phaseStream,
      initialData: _studyService.currentPhase,
      builder: (context, phaseSnapshot) {
        return StreamBuilder<bool>(
          stream: _studyService.runningStream,
          initialData: _studyService.isRunning,
          builder: (context, runningSnapshot) {
            final phase = phaseSnapshot.data ?? StudyPhase.stopped;
            final isRunning = runningSnapshot.data ?? false;
            final isPaused = _studyService.isPaused;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Settings button
                FloatingActionButton(
                  heroTag: "settings_fab", // Add unique hero tag
                  onPressed: isRunning ? null : _showSettingsDialog,
                  backgroundColor: isRunning
                      ? Colors.grey.shade300
                      : Colors.grey.shade100,
                  child: Icon(
                    Icons.settings,
                    color: isRunning
                        ? Colors.grey.shade500
                        : Colors.grey.shade700,
                  ),
                ),

                // Start/Stop button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isRunning
                          ? [Colors.red.shade400, Colors.red.shade600]
                          : [phase.color.withValues(alpha: 0.8), phase.color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isRunning ? Colors.red : phase.color)
                            .withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.large(
                    heroTag: "main_fab", // Add unique hero tag
                    onPressed: isRunning ? _stopSession : _startSession,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Icon(
                      isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),

                // Pause/Resume button
                FloatingActionButton(
                  heroTag: "pause_resume_fab", // Add unique hero tag
                  onPressed: isRunning
                      ? _pauseSession
                      : (isPaused ? _resumeSession : null),
                  backgroundColor: isRunning
                      ? Colors.orange.shade100
                      : isPaused
                      ? Colors.green.shade100
                      : Colors.grey.shade300,
                  child: Icon(
                    isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: isRunning
                        ? Colors.orange.shade700
                        : isPaused
                        ? Colors.green.shade700
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatsCard() {
    return StreamBuilder<int>(
      stream: _studyService.cycleStream,
      initialData: _studyService.completedCycles,
      builder: (context, snapshot) {
        final completedCycles = snapshot.data ?? 0;
        final progressToLongBreak = completedCycles % _cyclesBeforeLongBreak;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Study Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),

              // Cycle progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Completed Cycles',
                    completedCycles.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatItem(
                    'Progress to Long Break',
                    '$progressToLongBreak/$_cyclesBeforeLongBreak',
                    Icons.coffee,
                    Colors.blue,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Visual progress to long break
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cycles until Long Break',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(_cyclesBeforeLongBreak, (index) {
                      final isCompleted = index < progressToLongBreak;
                      return Expanded(
                        child: Container(
                          height: 8,
                          margin: EdgeInsets.only(
                            right: index < _cyclesBeforeLongBreak - 1 ? 4 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.blue
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _startSession() async {
    await _studyService.startStudySession(
      focusDuration: _focusDuration,
      shortBreakDuration: _shortBreakDuration,
      longBreakDuration: _longBreakDuration,
      cyclesBeforeLongBreak: _cyclesBeforeLongBreak,
    );
  }

  Future<void> _stopSession() async {
    await _studyService.stopSession();
  }

  Future<void> _pauseSession() async {
    await _studyService.pauseSession();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏸️ Session paused. Tap play to resume.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _resumeSession() async {
    await _studyService.resumeSession();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('▶️ Session resumed!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showSettingsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Study Timer Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSettingSlider(
                  'Focus Duration',
                  _focusDuration,
                  15,
                  60,
                  (value) => setDialogState(() => _focusDuration = value),
                  '${_focusDuration} min',
                ),
                _buildSettingSlider(
                  'Short Break',
                  _shortBreakDuration,
                  3,
                  15,
                  (value) => setDialogState(() => _shortBreakDuration = value),
                  '${_shortBreakDuration} min',
                ),
                _buildSettingSlider(
                  'Long Break',
                  _longBreakDuration,
                  10,
                  45,
                  (value) => setDialogState(() => _longBreakDuration = value),
                  '${_longBreakDuration} min',
                ),
                _buildSettingSlider(
                  'Cycles before Long Break',
                  _cyclesBeforeLongBreak,
                  2,
                  8,
                  (value) =>
                      setDialogState(() => _cyclesBeforeLongBreak = value),
                  '$_cyclesBeforeLongBreak cycles',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    // Force UI update after settings dialog closes
    setState(() {});
  }

  Widget _buildSettingSlider(
    String label,
    int value,
    int min,
    int max,
    Function(int) onChanged,
    String displayValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              displayValue,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: (newValue) => onChanged(newValue.round()),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Study Timer',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('🍅 Pomodoro Technique'),
                  content: const Text(
                    'The Pomodoro Technique is a time management method:\n\n'
                    '1. Work for 25 minutes (Focus)\n'
                    '2. Take a 5-minute break\n'
                    '3. Repeat 4 times\n'
                    '4. Take a longer 15-30 minute break\n\n'
                    'This helps maintain concentration and prevents mental fatigue.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it!'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Timer circle
              Expanded(flex: 3, child: Center(child: _buildTimerCircle())),

              const SizedBox(height: 30),

              // Control buttons
              _buildControlButtons(),

              const SizedBox(height: 30),

              // Stats card
              _buildStatsCard(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
