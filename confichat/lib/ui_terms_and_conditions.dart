/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:confichat/ui_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:confichat/app_localizations.dart';
import 'package:flutter/services.dart' show rootBundle;

class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({super.key});

  Future<String> loadMarkdownFile() async {
    return await rootBundle.loadString('assets/TERMS_AND_CONDITIONS.md');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder(
          future: loadMarkdownFile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text(loc.translate('termsAndConditions.errorFileLoad')));
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   DialogTitle(title: loc.translate('termsAndConditions.title')),
                  const SizedBox(height: 16.0),
                  Expanded(
                    child: Markdown(
                      data: snapshot.data.toString(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      autofocus: true,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(loc.translate('termsAndConditions.closeButton')),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
