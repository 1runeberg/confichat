/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';
import 'package:confichat/app_data.dart';
import 'package:confichat/ui_widgets.dart';


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
    _parentModelController = TextEditingController(text: 'Unknown');
    _rootModelController = TextEditingController(text: 'Unknown');
    _createdOnController = TextEditingController(text: 'Unknown');
    _languagesController = TextEditingController(text: 'Unknown');
    _parameterSizeController = TextEditingController(text: 'Unknown');
    _quantizationLevelController = TextEditingController(text: 'Unknown');
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
    return AlertDialog(

      title:   const DialogTitle(title: 'Model Configuration'),  
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Name', _nameController),
              _buildTextField('Parent Model', _parentModelController),
              _buildTextField('Root Model', _rootModelController),
              _buildTextField('Created On', _createdOnController),
              _buildTextField('Languages', _languagesController),
              _buildTextField('Parameter Size', _parameterSizeController),
              _buildTextField('Quantization Level', _quantizationLevelController),
              const SizedBox(height: 8),
              _buildMultilineField('System Prompt (in-model)', _systemPromptController),
            ],
          ),
        )
      ),
      
      actions: [
        ElevatedButton(
          onPressed: () => _confirmDelete(context),
          child: const Text('Delete'),
        ),
        ElevatedButton(
          focusNode: _focusNodeButton,
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
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
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete ${_nameController.text}?'),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the confirmation dialog
                _deleteModel();
                Navigator.of(context).pop(); // Close the config dialog
              },
              child: const Text('Delete'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
              },
              child: const Text('Cancel'),
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
