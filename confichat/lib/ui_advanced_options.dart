/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:confichat/app_data.dart';
import 'package:flutter/material.dart';
import 'package:confichat/interfaces.dart';
import 'package:confichat/ui_widgets.dart';
import 'package:confichat/app_localizations.dart';

class AdvancedOptions extends StatefulWidget {
  final LlmApi api;
  final bool enableSystemPrompt;

  const AdvancedOptions({super.key, required this.api, required this.enableSystemPrompt});

  @override
  AdvancedOptionsState createState() => AdvancedOptionsState();
}

class AdvancedOptionsState extends State<AdvancedOptions> {
  late bool  enableSystemPrompt;
  late double temperature;
  late double probability;
  late int maxTokens;
  late String systemPrompt;

  late TextEditingController maxTokensController;
  late TextEditingController stopSequenceController;
  late TextEditingController systemPromptController;

  final FocusNode _focusNodeButton = FocusNode();

  @override
  void initState() {
    super.initState();
    temperature = widget.api.temperature;
    probability = widget.api.probability;
    maxTokens = widget.api.maxTokens;
    systemPrompt = widget.api.systemPrompt;

    maxTokensController = TextEditingController(text: maxTokens.toString());
    stopSequenceController = TextEditingController(text: widget.api.stopSequences.join(', '));
    systemPromptController = TextEditingController(text: widget.api.systemPrompt);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodeButton.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNodeButton.dispose();
    super.dispose();
  }

  void _resetValues(bool toDefaults) {
    setState(() {
      temperature = toDefaults? widget.api.defaultTemperature : widget.api.temperature;
      probability = toDefaults? widget.api.defaultProbability : widget.api.probability;
      maxTokens = toDefaults? widget.api.defaultMaxTokens : widget.api.maxTokens;
      stopSequenceController.text = toDefaults
        ? widget.api.defaultStopSequences.join(', ')
        : widget.api.stopSequences.join(', ');
    });
  }

  bool _hasUnsavedChanges() {
  return temperature != widget.api.temperature ||
         probability != widget.api.probability ||
         maxTokens != widget.api.maxTokens ||
         stopSequenceController.text != widget.api.stopSequences.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    UserDeviceType deviceType = AppData.instance.getUserDeviceType(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox( constraints:
            BoxConstraints(maxWidth: AppData.instance.getUserDeviceType(context) == UserDeviceType.phone ? double.infinity : 800),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // Window title
            DialogTitle(title: loc.translate('advancedPrompt.title')),
            const SizedBox(height: 24),

          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: AppData.instance.getUserDeviceType(context) == UserDeviceType.phone ? 250.0 : 500, ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
              child: Column( 
                children: [

                  Text(loc.translate('advancedPrompt.scrollMessage'), style: TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),

                  _buildSliderWithTooltip(
                    label: loc.translate('advancedPrompt.tempLabel'),
                    value: temperature,
                    min: 0.0,
                    max: 2.0,
                    divisions: 20,
                    onChanged: (value) => setState(() => temperature = value),
                    description:  loc.translate('advancedPrompt.tempDesc'),
                    whatItMeans:  loc.translate('advancedPrompt.tempMeans'),
                  ),
                  const SizedBox(height: 8),

                  _buildSliderWithTooltip(
                      label: loc.translate('advancedPrompt.probLabel'),
                      value: probability,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (value) => setState(() => probability = value),
                      description:  loc.translate('advancedPrompt.probDesc'),
                      whatItMeans:  loc.translate('advancedPrompt.probMeans'),
                    ),

                    _buildTextInputWithTooltip(
                      label: loc.translate('advancedPrompt.tokensLabel'),
                      controller: maxTokensController,
                      onChanged: (value) => setState(() => maxTokens = int.tryParse(value) ?? maxTokens),
                      description:  loc.translate('advancedPrompt.tokensDesc'),
                      whatItMeans:  loc.translate('advancedPrompt.tokensMeans'),
                    ),

                    _buildTextInputWithTooltip(
                      label: loc.translate('advancedPrompt.systemLabel'),
                      controller: systemPromptController,
                      isEnabled: widget.enableSystemPrompt,
                      maxLines: 5,
                      onChanged: (value) { setState(() {widget.api.systemPrompt = value;}); }, 
                      description: loc.translate('advancedPrompt.systemDesc'),
                      whatItMeans: loc.translate('advancedPrompt.systemMeans'),
                    ),

                    _buildTextInputWithTooltip(
                      label: loc.translate('advancedPrompt.stopLabel'),
                      controller: stopSequenceController,
                      onChanged: (value) { setState(() { 
                        widget.api.stopSequences = value.split(',').map((s) => s.trim()).toList();}); }, 
                      description: loc.translate('advancedPrompt.stopDesc'),
                      whatItMeans: loc.translate('advancedPrompt.stopMeans'),
                    ),

                ] )
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _saveChanges();
                    Navigator.of(context).pop(true);
                  },
                  child: Text(loc.translate('advancedPrompt.saveButton')),
                ),
         
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _resetValues(false),
                  child:  Text(loc.translate('advancedPrompt.resetButton')),
                ),

                if( deviceType != UserDeviceType.phone ) const SizedBox(width: 8),
                if( deviceType != UserDeviceType.phone ) ElevatedButton(
                  onPressed: () => _resetValues(true),
                  child: Text(loc.translate('advancedPrompt.defaultsButton')),
                ),

                const SizedBox(width: 8),
                ElevatedButton(
                  focusNode: _focusNodeButton,
                  onPressed: () {
                  if (_hasUnsavedChanges()) {
                      _showExitConfirmationDialog();
                    } else {
                      Navigator.of(context).pop(false); // Exit if no unsaved changes
                    }
                  },
                  child: Text(loc.translate('advancedPrompt.cancelButton')),
                ),
              ],
            ),
          ],
        ),),
      ), 
    ); 
  }

  Widget _buildSliderWithTooltip({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String description,
    required String whatItMeans,
  }) {
    return Tooltip(
      message: description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.toStringAsFixed(1)}', style: Theme.of(context).textTheme.labelMedium,),
          Slider(
            activeColor: Theme.of(context).colorScheme.secondary,
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
          Text(
            whatItMeans,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildTextInputWithTooltip({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required String description,
    required String whatItMeans,
    bool isEnabled = true,
    int maxLines = 1,
  }) {
    return Tooltip(
      message: description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            enabled: isEnabled,
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: Theme.of(context).textTheme.labelMedium,
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
            ),
            keyboardType: label == AppLocalizations.of(context).translate('advancedPrompt.tokensLabel')
              ? TextInputType.number
              : (maxLines > 1
                  ? TextInputType.multiline 
                  : TextInputType.text), 
            onChanged: onChanged,
          ),
          Text(
            whatItMeans,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ],
      ),
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: DialogTitle(title: AppLocalizations.of(context).translate('advancedPrompt.unsavedChangesTitle'), isError: true),
          content: Text(AppLocalizations.of(context).translate('advancedPrompt.unsavedChangesMessage'), style: Theme.of(context).textTheme.bodyLarge,),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Save changes and close both dialogs
                _saveChanges();
                Navigator.of(context).pop(); // Close confirmation dialog
                Navigator.of(context).pop(true); // Close AdvancedOptions dialog
              },
              child: Text(AppLocalizations.of(context).translate('advancedPrompt.saveButton')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog
                Navigator.of(context).pop(false); // Close AdvancedOptions dialog without saving
              },
              child: Text(AppLocalizations.of(context).translate('advancedPrompt.exitButton')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog
              },
              child: Text(AppLocalizations.of(context).translate('advancedPrompt.cancelButton')),
            ),
          ],
        );
      },
    );
  }

  void _saveChanges() {
    widget.api.temperature = temperature;
    widget.api.probability = probability;
    widget.api.maxTokens = maxTokens;
    widget.api.stopSequences = stopSequenceController.text.split(',').map((s) => s.trim()).toList();
    widget.api.systemPrompt = systemPromptController.text;
  }

}
