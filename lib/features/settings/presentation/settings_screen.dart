import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/widgets/backend_status_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../sos/data/emergency.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SectionHeader(title: l10n.settingsAppearance),
          SegmentedButton<ThemeMode>(
            key: const Key('theme-mode-selector'),
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto_outlined),
                label: Text(l10n.settingsThemeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined),
                label: Text(l10n.settingsThemeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined),
                label: Text(l10n.settingsThemeDark),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) =>
                ref.read(themeModeProvider.notifier).setMode(selection.first),
          ),
          SectionHeader(title: l10n.settingsSafety),
          ListTile(
            key: const Key('settings-emergency-number'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.phone_in_talk_outlined),
            title: Text(l10n.settingsEmergencyNumber),
            subtitle: Text(
              '${ref.watch(emergencyNumberProvider)} · '
              '${l10n.settingsEmergencyNumberHint}',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () async {
              final value = await showTextPrompt(
                context,
                title: l10n.settingsEmergencyNumber,
                label: l10n.settingsEmergencyNumber,
                confirmLabel: l10n.actionSave,
                maxLength: 16,
                initialValue: ref.read(emergencyNumberProvider),
                keyboardType: TextInputType.phone,
              );
              if (value == null) return;
              final ok = await ref
                  .read(emergencyNumberProvider.notifier)
                  .set(value);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(l10n.settingsEmergencyNumberInvalid),
                    ),
                  );
              }
            },
          ),
          SectionHeader(title: l10n.settingsServer),
          const BackendStatusCard(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.environmentLabel(config.environment.code),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SectionHeader(title: l10n.settingsAbout),
          Text(l10n.settingsAboutBody),
        ],
      ),
    );
  }
}
