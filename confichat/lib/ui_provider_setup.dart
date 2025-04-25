/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:confichat/app_data.dart';
import 'package:confichat/app_localizations.dart';
import 'package:confichat/provider_validator.dart';
import 'package:confichat/ui_widgets.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProviderSetupDialog extends StatelessWidget {
  final AppData appData;
  final VoidCallback onOpenSettings;

  const ProviderSetupDialog({
    super.key,
    required this.appData,
    required this.onOpenSettings,
  });

  Future<void> _launchUrl(Uri url) async {
    try {
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DialogTitle(
                  title: loc.translate('providerSetup.title'),
                  isError: true,
                ),
                const SizedBox(height: 24),
                Text(
                  loc.translate('providerSetup.message'),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      loc.translate('providerSetup.offlineOptions'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  children: [
                    _buildProviderButton(
                      context,
                      'Ollama',
                      'https://ollama.com',
                      Icons.computer,
                    ),
                    _buildProviderButton(
                      context,
                      'LlamaCPP',
                      'https://github.com/ggerganov/llama.cpp',
                      Icons.terminal,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      loc.translate('providerSetup.onlineOptions'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  children: [
                    _buildProviderButton(
                      context,
                      'OpenAI',
                      'https://platform.openai.com/api-keys',
                      Icons.cloud,
                    ),
                    _buildProviderButton(
                      context,
                      'Anthropic',
                      'https://console.anthropic.com/settings/keys',
                      Icons.cloud_queue,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onOpenSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: Text(loc.translate('providerSetup.openSettings')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderButton(
    BuildContext context,
    String name,
    String urlString,
    IconData icon,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(name),
      onPressed: () {
        _launchUrl(Uri.parse(urlString));
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class ProviderSetupManager {
  static Future<bool> validateAndSetupProvider(
    BuildContext context,
    AppData appData,
    GlobalKey<ScaffoldState> scaffoldKey,  // Add scaffoldKey parameter
  ) async {
    // (1) Check if Ollama or LlamaCPP can retrieve models
    AiProvider? localProvider = await ProviderValidator.validateLocalProviders(appData);
    if (localProvider != null) {
      return true;
    }
    
    // (2) Check for API keys in online providers
    AiProvider? onlineProvider = await ProviderValidator.checkApiKeyConfigured(appData);
    if (onlineProvider != null) {
      return true;
    }
    
    // (3) No valid providers found, show setup dialog
    if (context.mounted) {
      await showProviderSetupDialog(context, appData, scaffoldKey);  
    }
    
    return false;
  }

  static bool _isDialogShowing = false;
  static Future<void> showProviderSetupDialog(
    BuildContext context,
    AppData appData,
    GlobalKey<ScaffoldState> scaffoldKey, 
  ) async {

    // Check if dialog is already showing
    if (_isDialogShowing) {
      return;
    }
    
    _isDialogShowing = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ProviderSetupDialog(
        appData: appData,
        onOpenSettings: () {
          Navigator.of(dialogContext).pop();
          _openSettingsSidebar(scaffoldKey);  
        },
      ),
    );
  }

  static void _openSettingsSidebar(GlobalKey<ScaffoldState> scaffoldKey) {
    // Start opening drawer
    scaffoldKey.currentState?.openDrawer();

    // Short delay to ensure animation is complete 
    Future.delayed(const Duration(milliseconds: 500), () {
      _isDialogShowing = false;
    });
  }
}