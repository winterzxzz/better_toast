import 'dart:async';

import 'package:better_toast/better_toast.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ShowcaseApp());

/// The look presets the showcase can switch between.
enum Look { standard, glass, bold }

/// Root of the showcase. Owns the settings that feed the toast theme.
class ShowcaseApp extends StatefulWidget {
  const ShowcaseApp({super.key});

  @override
  State<ShowcaseApp> createState() => _ShowcaseAppState();
}

class _ShowcaseAppState extends State<ShowcaseApp> {
  ThemeMode _mode = ThemeMode.light;
  bool _rtl = false;
  ToastPosition _position = ToastPosition.top;
  ToastAnimation _animation = ToastAnimation.slideFade;
  ToastStackMode _stackMode = ToastStackMode.stack;
  bool _progressBar = false;
  bool _closeButton = false;
  Look _look = Look.standard;

  BetterToastThemeData get _toastTheme {
    return BetterToastThemeData(
      position: _position,
      animation: _animation,
      stackMode: _stackMode,
      maxVisible: 4,
      showProgressBar: _progressBar,
      // A custom transition, used when "custom" animation is selected.
      transitionBuilder: (context, animation, position, child) =>
          RotationTransition(
        turns: Tween<double>(begin: -0.05, end: 0).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      defaultStyle: switch (_look) {
        Look.standard => ToastStyle(showCloseButton: _closeButton),
        Look.glass => ToastStyle(
            showCloseButton: _closeButton,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            foregroundColor: Colors.white,
            blur: 16,
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
        Look.bold => ToastStyle(
            showCloseButton: _closeButton,
            foregroundColor: Colors.white,
            iconColor: Colors.white,
            progressBarColor: Colors.white,
            border: const Border(),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            titleStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
      },
      // Per-type styles only apply to the "bold" look.
      typeStyles: _look != Look.bold
          ? null
          : const <ToastType, ToastStyle>{
              ToastType.success: ToastStyle(backgroundColor: Color(0xFF15803D)),
              ToastType.error: ToastStyle(backgroundColor: Color(0xFFB91C1C)),
              ToastType.warning: ToastStyle(backgroundColor: Color(0xFFB45309)),
              ToastType.info: ToastStyle(backgroundColor: Color(0xFF1D4ED8)),
              ToastType.loading: ToastStyle(backgroundColor: Color(0xFF334155)),
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'better_toast',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      // One line adds the toast host above the navigator.
      builder: BetterToast.init(
        theme: _toastTheme,
        // Wraps the toast host too, so the RTL switch flips the toasts.
        builder: (context, child) => Directionality(
          textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        ),
      ),
      home: ShowcasePage(
        settings: ShowcaseSettings(
          dark: _mode == ThemeMode.dark,
          rtl: _rtl,
          position: _position,
          animation: _animation,
          stackMode: _stackMode,
          progressBar: _progressBar,
          closeButton: _closeButton,
          look: _look,
        ),
        onChanged: (s) => setState(() {
          _mode = s.dark ? ThemeMode.dark : ThemeMode.light;
          _rtl = s.rtl;
          _position = s.position;
          _animation = s.animation;
          _stackMode = s.stackMode;
          _progressBar = s.progressBar;
          _closeButton = s.closeButton;
          _look = s.look;
        }),
      ),
    );
  }
}

/// The options chosen on the settings panel.
class ShowcaseSettings {
  const ShowcaseSettings({
    required this.dark,
    required this.rtl,
    required this.position,
    required this.animation,
    required this.stackMode,
    required this.progressBar,
    required this.closeButton,
    required this.look,
  });

  final bool dark;
  final bool rtl;
  final ToastPosition position;
  final ToastAnimation animation;
  final ToastStackMode stackMode;
  final bool progressBar;
  final bool closeButton;
  final Look look;

  ShowcaseSettings copyWith({
    bool? dark,
    bool? rtl,
    ToastPosition? position,
    ToastAnimation? animation,
    ToastStackMode? stackMode,
    bool? progressBar,
    bool? closeButton,
    Look? look,
  }) {
    return ShowcaseSettings(
      dark: dark ?? this.dark,
      rtl: rtl ?? this.rtl,
      position: position ?? this.position,
      animation: animation ?? this.animation,
      stackMode: stackMode ?? this.stackMode,
      progressBar: progressBar ?? this.progressBar,
      closeButton: closeButton ?? this.closeButton,
      look: look ?? this.look,
    );
  }
}

/// The single screen of the showcase.
class ShowcasePage extends StatelessWidget {
  const ShowcasePage({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final ShowcaseSettings settings;
  final ValueChanged<ShowcaseSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final Widget page = Scaffold(
      appBar: AppBar(title: const Text('better_toast')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _Section(
            title: 'Types',
            children: [
              _DemoButton(
                  'Success', () => BetterToast.success('Changes saved')),
              _DemoButton(
                'Error',
                () => BetterToast.error(
                  'Upload failed',
                  description: 'The server did not respond.',
                ),
              ),
              _DemoButton(
                'Warning',
                () => BetterToast.warning('Battery below 15%'),
              ),
              _DemoButton(
                'Info',
                () => BetterToast.info('A new version is available'),
              ),
              _DemoButton(
                'Loading',
                () => BetterToast.loading(
                  'Syncing…',
                  id: 'sync',
                  duration: const Duration(seconds: 3),
                ),
              ),
              _DemoButton(
                'Plain',
                () => BetterToast.show(
                  'Copied to clipboard',
                  style: const ToastStyle(
                    showIcon: false,
                    width: 220,
                    contentAlignment: CrossAxisAlignment.center,
                    borderRadius: BorderRadius.all(Radius.circular(40)),
                  ),
                ),
              ),
            ],
          ),
          _Section(
            title: 'Rich content',
            children: [
              _DemoButton(
                'Title + action',
                () => BetterToast.show(
                  'Message moved to Archive.',
                  title: 'Archived',
                  type: ToastType.success,
                  action: ToastAction(
                    label: 'Undo',
                    onPressed: () => BetterToast.info('Restored'),
                  ),
                ),
              ),
              _DemoButton(
                'Widget message',
                () => BetterToast.show(
                  null,
                  message: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Logged in as '),
                        TextSpan(
                          text: '@winter',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _DemoButton(
                'Sticky + tap',
                () => BetterToast.show(
                  'Tap me to dismiss',
                  duration: Duration.zero,
                  onTap: () => BetterToast.dismissAll(),
                ),
              ),
            ],
          ),
          _Section(
            title: 'Update in place',
            children: [
              const _DemoButton('Upload (id)', _simulateUpload),
              _DemoButton('Promise ✓', () {
                BetterToast.promise<String>(
                  Future<String>.delayed(
                    const Duration(seconds: 2),
                    () => 'report.pdf',
                  ),
                  loading: 'Generating report…',
                  success: (file) => '$file is ready',
                  error: (e) => 'Could not generate the report',
                ).ignore();
              }),
              _DemoButton('Promise ✗', () {
                BetterToast.promise<void>(
                  Future<void>.delayed(
                    const Duration(seconds: 2),
                    () => throw StateError('offline'),
                  ),
                  loading: 'Contacting server…',
                  success: (_) => 'Done',
                  error: (e) => 'Failed: $e',
                ).ignore();
              }),
            ],
          ),
          _Section(
            title: 'Custom builder',
            children: [
              _DemoButton(
                'Custom card',
                () => BetterToast.custom(
                  duration: const Duration(seconds: 5),
                  builder: (context, handle) => _CustomToast(handle: handle),
                ),
              ),
            ],
          ),
          _Section(
            title: 'Stacking',
            children: [
              _DemoButton('Burst ×6', () {
                for (var i = 1; i <= 6; i++) {
                  BetterToast.show(
                    'Notification #$i',
                    type: ToastType.values[i % 4],
                  );
                }
              }),
              const _DemoButton('Dismiss all', BetterToast.dismissAll),
            ],
          ),
          const Divider(height: 32),
          Text('Settings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _Choice<ToastPosition>(
            label: 'Position',
            value: settings.position,
            values: ToastPosition.values,
            onChanged: (v) => onChanged(settings.copyWith(position: v)),
          ),
          _Choice<ToastAnimation>(
            label: 'Animation',
            value: settings.animation,
            values: ToastAnimation.values,
            onChanged: (v) => onChanged(settings.copyWith(animation: v)),
          ),
          _Choice<ToastStackMode>(
            label: 'Stack mode',
            value: settings.stackMode,
            values: ToastStackMode.values,
            onChanged: (v) => onChanged(settings.copyWith(stackMode: v)),
          ),
          _Choice<Look>(
            label: 'Look',
            value: settings.look,
            values: Look.values,
            onChanged: (v) => onChanged(settings.copyWith(look: v)),
          ),
          SwitchListTile(
            title: const Text('Progress bar'),
            value: settings.progressBar,
            onChanged: (v) => onChanged(settings.copyWith(progressBar: v)),
          ),
          SwitchListTile(
            title: const Text('Close button'),
            value: settings.closeButton,
            onChanged: (v) => onChanged(settings.copyWith(closeButton: v)),
          ),
          SwitchListTile(
            title: const Text('Dark mode'),
            value: settings.dark,
            onChanged: (v) => onChanged(settings.copyWith(dark: v)),
          ),
          SwitchListTile(
            title: const Text('Right-to-left'),
            value: settings.rtl,
            onChanged: (v) => onChanged(settings.copyWith(rtl: v)),
          ),
        ],
      ),
    );
    if (settings.look != Look.glass) {
      return page;
    }
    // A colorful backdrop makes the glass blur visible.
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: Colors.transparent,
        ),
        child: page,
      ),
    );
  }
}

Future<void> _simulateUpload() async {
  // Showing with the same id updates the toast instead of adding new ones.
  for (var percent = 0; percent <= 100; percent += 20) {
    BetterToast.loading(
      'Uploading… $percent%',
      id: 'upload',
      title: 'photo.jpg',
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
  BetterToast.success('Upload complete', id: 'upload', title: 'photo.jpg');
}

class _CustomToast extends StatelessWidget {
  const _CustomToast({required this.handle});

  final ToastHandle handle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Text('JD')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Jane Doe',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Sent you a message',
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
                const SizedBox(height: 6),
                // The handle exposes the remaining time.
                ValueListenableBuilder<double>(
                  valueListenable: handle.progress,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: scheme.onPrimaryContainer,
            onPressed: handle.dismiss,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(onPressed: onPressed, child: Text(label));
  }
}

class _Choice<T extends Enum> extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<T>(
        value: value,
        onChanged: (v) => onChanged(v ?? value),
        items: [
          for (final v in values)
            DropdownMenuItem<T>(value: v, child: Text(v.name)),
        ],
      ),
    );
  }
}
