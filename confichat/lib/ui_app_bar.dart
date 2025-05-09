/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:async';
import 'package:confichat/app_data.dart';
import 'package:confichat/chat_notifiers.dart';
import 'package:confichat/ui_add_model.dart';
import 'package:confichat/ui_config_model.dart';
import 'package:confichat/ui_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confichat/app_localizations.dart';

class CCAppBar extends StatefulWidget implements PreferredSizeWidget {
  final AppData appData;
  final ChatSessionSelectedNotifier chatSessionSelectedNotifier;
  final TextEditingController providerController;
  final TextEditingController providerModel;

  const CCAppBar({super.key, 
    required this.appData,
    required this.chatSessionSelectedNotifier,
    required this.providerController,
    required this.providerModel,
  });

  @override
  CCAppBarState createState() => CCAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80.0);
}

class CCAppBarState extends State<CCAppBar> {
  AiProvider? selectedProvider;
  ModelItem? selectedModel;
  Timer? _providerCheckTimer;

  @override
  void initState() {
    super.initState();
    _switchProvider(widget.appData.defaultProvider);
    _populateModelList(true); 

    widget.appData.callbackSwitchProvider = _switchProvider;
    _startProviderAvailabilityCheck();
  }

  void _startProviderAvailabilityCheck() {
      // Check every second for provider availability
      _providerCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (selectedProvider != null && mounted) {
          final modelProvider = Provider.of<ModelProvider>(context, listen: false);
          
          // Only check if models list is empty and selected provider matches the app's current provider
          if (modelProvider.models.isEmpty && selectedProvider == widget.appData.api.aiProvider) {
            // Try to populate the models list
            await _populateModelList(true);
          }
        }
      });
    }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isPhone = widget.appData.getUserDeviceType(context) == UserDeviceType.phone;

        return AppBar(
          title: widget.appData.getUserDeviceType(context) == UserDeviceType.desktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Image.asset(
                      'assets/confichat_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ],
                )
              : null,
          toolbarHeight: 80.0,
          toolbarOpacity: 0.8,
          elevation: 5.0,
          shadowColor: const Color.fromARGB(255, 145, 145, 145),
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          actions: [        
                _buildModelProviderDropdown(context, isPhone, selectedProvider ?? AiProvider.ollama),
                _buildModelDropdown(context, isPhone),
                if (!isPhone) _buildConfigButton(context),
                if (!isPhone) _buildAddButton(context),
          ],
        );
      },
    );
  }

  Widget _buildModelProviderDropdown(BuildContext context, bool isPhone, AiProvider selectedProvider) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: DropdownMenu<AiProvider>(
        initialSelection: selectedProvider,
        controller: widget.providerController,
        requestFocusOnTap: true,
        textStyle: TextStyle(
          color: Theme.of(context).colorScheme.surface,
          fontWeight: FontWeight.normal,
          fontSize: 18,
        ),
        label: OutlinedText(
          textData: AppLocalizations.of(context).translate('appBar.provider'),
          outlineColor: Theme.of(context).colorScheme.onSurface,
          textStyle: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.surface),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.surface),
          ),
          fillColor: Theme.of(context).colorScheme.tertiaryContainer,
          suffixIconColor: Theme.of(context).colorScheme.surface,
          filled: true,
        ),
        onSelected: (AiProvider? provider) {
          _switchProvider(provider);
        },
        dropdownMenuEntries: AiProvider.values
            .map<DropdownMenuEntry<AiProvider>>(
                (AiProvider modelProvider) {
          return DropdownMenuEntry<AiProvider>(
            value: modelProvider,
            label: modelProvider.name,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModelDropdown(BuildContext context, bool isPhone) {
    return Consumer<ModelProvider>(
      builder: (context, modelProvider, child) {
        return Container(
          margin: const EdgeInsets.all(10),
          child: GestureDetector(
            onDoubleTap: isPhone && modelProvider.models.isNotEmpty
                ? () async {
                    await _showConfigDialog(context);
                  }
                : null,
            child: DropdownMenu<ModelItem>(
              controller: widget.providerModel,
              enabled: modelProvider.models.isNotEmpty,
              width: 160,
              requestFocusOnTap: true,
              textStyle: TextStyle(
                color: Theme.of(context).colorScheme.surface,
                fontWeight: FontWeight.normal,
                fontSize: 18,
              ),
              label: OutlinedText(
                textData: AppLocalizations.of(context).translate('appBar.currentModel'),
                outlineColor: Colors.black,
                textStyle: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.surface),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.surface),
                ),
                fillColor: Theme.of(context).colorScheme.tertiaryContainer,
                suffixIconColor: Theme.of(context).colorScheme.surface,
                filled: true,
              ),
              onSelected: (ModelItem? model) {
                if (model != null) {
                  if (model.name == 'AddNewModelItem' && isPhone) {
                    _showAddModelDialog(context, modelProvider);
                  } else {
                    if (widget.appData.clearMessagesOnModelSwitch) {
                      _showModelChangeWarning(context, model);
                    } else {
                      _setModelItem(model);
                    }
                  }
                }
              },
              dropdownMenuEntries: [
                
                ...modelProvider.models.map(
                  (modelItem) => DropdownMenuEntry<ModelItem>(
                    value: modelItem,
                    label: modelItem.name,
                  ),            
                ),

                if (isPhone)
                  DropdownMenuEntry<ModelItem>(
                    value: ModelItem('AddNewModelItem', 'AddNewModelItem'),
                    label: AppLocalizations.of(context).translate('appBar.addModelLabel'),
                  ),

              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfigButton(BuildContext context) {
    return Consumer<ModelProvider>(
      builder: (context, modelProvider, child) {
        return IconButton(
          icon: const Icon(Icons.build_circle_rounded),
          hoverColor: Theme.of(context).colorScheme.secondaryContainer,
          onPressed: modelProvider.models.isEmpty
              ? null
              : () async {
                  await _showConfigDialog(context);
                },
        );
      },
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Consumer<ModelProvider>(
      builder: (context, modelProvider, child) {
        return IconButton(
          icon: const Icon(Icons.add_circle),
          hoverColor: Theme.of(context).colorScheme.secondaryContainer,
          disabledColor: Theme.of(context).colorScheme.surfaceDim,
          onPressed: modelProvider.models.isEmpty ||
                  widget.appData.api.aiProvider.id > 0
              ? null
              : () async {
                  await _showAddModelDialog(context, modelProvider);
                  _populateModelList(false);
                },
        );
      },
    );
  }

  Future<void> _showConfigDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return ModelConfigDialog(modelName: widget.providerModel.text);
      },
    );
  }

  Future<void> _showAddModelDialog(BuildContext context, ModelProvider modelProvider) async {
    List<String> modelList = modelProvider.models.map((model) => model.name).toList();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddModelDialog(modelNames: modelList);
      },
    );
  }


  Future<void> _populateModelList(bool selectFirst) async {
    
    // Check for api app settings
    await widget.appData.api.loadSettings();

    // Retrieve active models for provider
    List<ModelItem> newModels = [];
    await widget.appData.api.getModels(newModels);

    if (mounted){
      // Update the provider with the new models
      Provider.of<ModelProvider>(context, listen: false).updateModels(newModels);
    
      // Update the selected model
      if (newModels.isNotEmpty) {
        final selectedModelProvider = Provider.of<SelectedModelProvider>(context, listen: false);  
        final initialModel = selectFirst ? newModels.first : newModels.last; 
        selectedModelProvider.updateSelectedModel(initialModel);
        widget.providerModel.text = initialModel.name; 
      } else {
        widget.providerModel.clear();
      }
    } 
  }

  Future<void> _showModelChangeWarning(BuildContext context, ModelItem newModel) async {
    
    if(!widget.appData.haveUnsavedMessages) {
      _setModelItem(newModel);
      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const DialogTitle(title: 'Warning', isError: true),
          content: Text(
            'There are unsaved messages in the current chat window - they will be lost. Proceed?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: [
            ElevatedButton(
              child: const Text('Yes'),
              onPressed: () {
                widget.appData.haveUnsavedMessages = false;
                _setModelItem(newModel);
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Cancel'),
              onPressed: () {
                if(mounted && selectedModel != null) {_setModelItem(selectedModel!);}
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _setModelItem(ModelItem newModel){
    if(mounted) {
      setState(() {
       selectedModel = newModel;
        widget.providerModel.text = newModel.name;
        Provider.of<SelectedModelProvider>(context, listen: false).updateSelectedModel(newModel);
      });
    }
  }

  void _switchProvider(AiProvider? provider){

    if(provider == null) {return; }
    widget.appData.setProvider(provider);

    if(mounted) {
      setState(() {
        selectedProvider = provider;
        _populateModelList(true);
      });
    }
  }

}
