/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:confichat/app_data.dart';
import 'package:flutter/material.dart';
import 'package:confichat/interfaces.dart';
import 'package:confichat/ui_widgets.dart';


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

    UserDeviceType deviceType = AppData.instance.getUserDeviceType(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox( constraints: const BoxConstraints(maxWidth: 400), child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // Window title
            const DialogTitle(title: 'Advanced Prompt Options'),
            const SizedBox(height: 24),

          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500.0, 
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column( 
                children: [

                  _buildSliderWithTooltip(
                    label: 'Temperature',
                    value: temperature,
                    min: 0.0,
                    max: 2.0,
                    divisions: 20,
                    onChanged: (value) => setState(() => temperature = value),
                    description: 'Controls the randomness of the output. Lower values make responses more focused and deterministic, while higher values increase variability and creativity.',
                    whatItMeans: 'Use lower temperatures for precise and predictable outputs and higher values for more creative and varied responses.',
                  ),
                  const SizedBox(height: 8),

                  _buildSliderWithTooltip(
                      label: 'Probability',
                      value: probability,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (value) => setState(() => probability = value),
                      description: 'Determines the diversity of the response by sampling from the top tokens. Lower values focus on the most likely tokens, while higher values consider a wider range of possibilities.',
                      whatItMeans: 'Set lower values for predictable outputs and higher values for more diverse and creative responses.',
                    ),
                    _buildTextInputWithTooltip(
                      label: 'Max Tokens',
                      controller: maxTokensController,
                      onChanged: (value) => setState(() => maxTokens = int.tryParse(value) ?? maxTokens),
                      description: 'Sets the maximum number of tokens that the model will generate in the response. Limits response length for concise or detailed answers.',
                      whatItMeans: 'Limits response length. Use lower values for concise answers and higher values for detailed responses.',
                    ),
                    _buildTextInputWithTooltip(
                      label: 'Stop Sequences',
                      controller: stopSequenceController,
                      onChanged: (value) { setState(() { 
                        widget.api.stopSequences = value.split(',').map((s) => s.trim()).toList();}); }, 
                      description: 'Specifies one or more sequences where the model should stop generating text.  Enter multiple sequences separated by commas.',
                      whatItMeans: 'Define where the response should end to prevent overly lengthy or unnecessary outputs. (example: .,\\n, user:)',
                    ),
                    _buildTextInputWithTooltip(
                      label: 'System Prompt',
                      controller: systemPromptController,
                      isEnabled: widget.enableSystemPrompt,
                      maxLines: 5,
                      onChanged: (value) { setState(() {widget.api.systemPrompt = value;}); }, 
                      description: 'Initial instruction that sets the context or role for the entire conversation. It influences how the model understands and responds to user inputs by defining its persona, tone, or task.',
                      whatItMeans: 'By setting the model\'s role or focus, such as acting as a helpful assistant, technical expert, or creative writer, it aligns the model\'s responses to user expectations and the intended application',
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
                  child: const Text('Save'),
                ),
         
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _resetValues(false),
                  child: const Text('Reset'),
                ),

                if( deviceType != UserDeviceType.phone ) const SizedBox(width: 8),
                if( deviceType != UserDeviceType.phone ) ElevatedButton(
                  onPressed: () => _resetValues(true),
                  child: const Text('Defaults'),
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
                  child: const Text('Cancel'),
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
            keyboardType: label == 'Max Tokens'
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
          title: const Text('Unsaved changes'),
          content: const Text('You have unsaved changes to the advanced options. Are you sure you want to exit?'),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Save changes and close both dialogs
                _saveChanges();
                Navigator.of(context).pop(); // Close confirmation dialog
                Navigator.of(context).pop(true); // Close AdvancedOptions dialog
              },
              child: const Text('Save'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog
                Navigator.of(context).pop(false); // Close AdvancedOptions dialog without saving
              },
              child: const Text('Exit'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog
              },
              child: const Text('Cancel'),
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
  }

}
