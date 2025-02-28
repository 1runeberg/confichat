/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:confichat/app_data.dart';
import 'package:confichat/ui_widgets.dart';


class AddModelDialog extends StatefulWidget {
  final List<String> modelNames;
  const AddModelDialog({super.key, required this.modelNames});

  @override
  AddModelDialogState createState() => AddModelDialogState();
}

class AddModelDialogState extends State<AddModelDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();

  final FocusNode _focusNodeButton = FocusNode();


  bool _isLoading = false; // To track loading state
  
  String? _selectedModel; 
  String _selectedQuantization = 'none';
  final List<String> _quantizationOptions = [
    'none',
    'q8_0',
    'q6_K',
    'q5_K_S',
    'q5_K_M',
    'q5_1',
    'q5_0',
    'q4_K_S',
    'q4_K_M',
    'q4_1',
    'q4_0',
    'q3_K_S',
    'q3_K_M',
    'q3_K_L',
    'q2_K',
  ]; 

  @override
  void initState() {
    super.initState();
    if (widget.modelNames.isNotEmpty) {
      _selectedModel = widget.modelNames.first;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodeButton.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _systemPromptController.dispose();
    _focusNodeButton.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DialogTitle(title: 'Add New Model'),  
      content: _isLoading ? const SizedBox(width: 400, height: 300,
                child: Center(child: CircularProgressIndicator())) 
          : Form(
              key: _formKey,
              
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 

              child: SizedBox(width: 400, height: 300,
               child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // (1) Model name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name *'),
                      autofocus: true,
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        } else if (!RegExp(r"^[\p{L}\p{N}_-]+$", unicode: true)
                            .hasMatch(value)) {
                          return 'Use only alphanumeric characters';
                        }

                        return null;
                      },
                    ),

                    // (2) Models
                    DropdownButtonFormField<String>(
                      value: _selectedModel,
                      hint: const Text('Select a Model *'),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedModel = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a model' : null,
                      items: widget.modelNames.map((model) {
                        return DropdownMenuItem<String>(
                          value: model,
                          child: Text(model, style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Theme.of(context).colorScheme.onSurface)),
                        );
                      }).toList(),
                    ),

                    // (3) Quantization
                    DropdownButtonFormField<String>(
                      value: _selectedQuantization,
                      decoration: const InputDecoration(
                        labelText: 'Quantize',
                      ),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedQuantization = newValue!;
                        });
                      },
                      items: _quantizationOptions.map((quantization) {
                        return DropdownMenuItem<String>(
                          value: quantization,
                          child: Text(
                            quantization,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Theme.of(context).colorScheme.onSurface
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 10),

                    // (4) System prompt
                    TextFormField(
                      controller: _systemPromptController,
                      decoration: const InputDecoration(
                          labelText: 'System prompt',
                          alignLabelWithHint: true),
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),),

      actions: <Widget>[
        // (1) Add
        ElevatedButton(
          onPressed: _isLoading ? null : () { 
            if (_formKey.currentState!.validate()) { _addNewModel(); }},
          child: const Text('Add new'),
        ),

        // (2) Cancel
        ElevatedButton(
          focusNode: _focusNodeButton,
          onPressed: _isLoading ? null : () { Navigator.of(context).pop(); },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _addNewModel() async {
    // Start loading indicator
    setState(() {
      _isLoading = true;
    });

    // Assemble modelfile
    await AppData.instance.api.postData(
      url: AppData.instance.api.getUri('/create'),
      requestHeaders: AppData.headerJson,
      requestPayload: jsonEncode({
        'model': _nameController.text,
        'from': _selectedModel,
        'system': _systemPromptController.text,
        'quantize': _selectedQuantization == 'none' ? null : _selectedQuantization,
        'stream': false
      }),
    );

    try {
      // Decode response
      Map<String, dynamic> jsonData = jsonDecode(AppData.instance.api.responseData);

      if (jsonData.containsKey('status') && jsonData['status'] == 'success') {

        if(mounted) {
         setState(() {
            _isLoading = false;
          });
          Navigator.of(context).pop(true); // Close dialog on success
        }
      } else {
        if (kDebugMode) {
          print('Unable to create model: ${AppData.instance.api.responseData}');
        }}
    } catch (e) {
      if (kDebugMode) {
        print(
            'Unable to create model: $e\n Request:  \nResponse: ${AppData.instance.api.responseData}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
