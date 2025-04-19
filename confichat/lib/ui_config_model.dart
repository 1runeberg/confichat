/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';
import 'package:confichat/app_data.dart';
import 'package:confichat/ui_widgets.dart';
import 'package:confichat/app_localizations.dart';


class ModelConfigDialog extends StatefulWidget {
  final String modelName;

  const ModelConfigDialog({super.key, required this.modelName});

  @override
  ModelConfigDialogState createState() => ModelConfigDialogState();
}

class ModelConfigDialogState extends State<ModelConfigDialog> {
  late TextEditingController _nameController;
  late TextEditingController _parentModelController;
  late TextEditingController _rootModelController;
  late TextEditingController _createdOnController;
  late TextEditingController _languagesController;
  late TextEditingController _parameterSizeController;
  late TextEditingController _quantizationLevelController;
  late TextEditingController _systemPromptController;

  final FocusNode _focusNodeButton = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.modelName);
    _parentModelController = TextEditingController(text: '');
    _rootModelController = TextEditingController(text: '');
    _createdOnController = TextEditingController(text: '');
    _languagesController = TextEditingController(text: '');
    _parameterSizeController = TextEditingController(text: '');
    _quantizationLevelController = TextEditingController(text: '');
    _systemPromptController = TextEditingController(text: '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodeButton.requestFocus();
    });

    _getModelConfig();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parentModelController.dispose();
    _rootModelController.dispose();
    _createdOnController.dispose();
    _languagesController.dispose();
    _parameterSizeController.dispose();
    _quantizationLevelController.dispose();
    _systemPromptController.dispose();
    _focusNodeButton.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(

      title:   DialogTitle(title: loc.translate('modelConfigDialog.title')),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(loc.translate('modelConfigDialog.fields.name'), _nameController),
              _buildTextField(loc.translate('modelConfigDialog.fields.parentModel'), _parentModelController),
              _buildTextField(loc.translate('modelConfigDialog.fields.rootModel'), _rootModelController),
              _buildTextField(loc.translate('modelConfigDialog.fields.createdOn'), _createdOnController),
              _buildTextField(loc.translate('modelConfigDialog.fields.languages'), _languagesController),
              _buildTextField(loc.translate('modelConfigDialog.fields.parameterSize'), _parameterSizeController),
              _buildTextField(loc.translate('modelConfigDialog.fields.quantizationLevel'), _quantizationLevelController),
              const SizedBox(height: 8),
              _buildMultilineField(loc.translate('modelConfigDialog.fields.systemPrompt'), _systemPromptController),
            ],
          ),
        )
      ),
      
      actions: [
        ElevatedButton(
          onPressed: () => _confirmDelete(context),
          child: Text(loc.translate('modelConfigDialog.buttons.delete')),
        ),
        ElevatedButton(
          focusNode: _focusNodeButton,
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(loc.translate('modelConfigDialog.buttons.close')),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: Theme.of(context).textTheme.labelSmall,
                border: const UnderlineInputBorder(),
              ),
              readOnly: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultilineField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: Theme.of(context).textTheme.labelSmall,
          border: const OutlineInputBorder(),
        ),
        maxLines: 3,
        minLines: 3,
        readOnly: true,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('modelConfigDialog.confirmDelete.title')),
          content: Text(AppLocalizations.of(context).translate('modelConfigDialog.confirmDelete.message').replaceAll('{modelName}', _nameController.text)),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the confirmation dialog
                _deleteModel();
                Navigator.of(context).pop(); // Close the config dialog
              },
              child: Text(AppLocalizations.of(context).translate('modelConfigDialog.confirmDelete.buttons.delete')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
              },
              child: Text(AppLocalizations.of(context).translate('modelConfigDialog.confirmDelete.buttons.cancel')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getModelConfig() async {
    ModelInfo modelInfo = ModelInfo(_nameController.text);
    await AppData.instance.api.getModelInfo(modelInfo, _nameController.text);

    setState(() {
      _parameterSizeController.text = modelInfo.parameterSize;
      _parentModelController.text = modelInfo.parentModel;
      _quantizationLevelController.text = modelInfo.quantizationLevel;
      _rootModelController.text = modelInfo.rootModel;
      _languagesController.text = modelInfo.languages;
      _createdOnController.text = modelInfo.createdOn;
      _systemPromptController.text = modelInfo.systemPrompt;
    });

  }

  Future<void> _deleteModel() async {
    AppData.instance.api.deleteModel(_nameController.text); 
  }

}
