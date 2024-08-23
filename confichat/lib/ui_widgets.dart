/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:math';

import 'package:confichat/persistent_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:confichat/app_data.dart';

import 'package:markdown/markdown.dart' as md;
import 'dart:convert';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/confichat_logo_text_outline.png', 
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}

class ImagePreview extends StatelessWidget {
  final String base64Image;

  const ImagePreview({super.key, required this.base64Image});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop(); // Close the dialog when tapped
          },
          child: SizedBox(
            width: constraints.maxWidth,
            child: InteractiveViewer(
              child: Image.memory(
                base64Decode(base64Image),
                fit: BoxFit.contain,
                width: constraints.maxWidth, // Use max width
              ),
            ),
          ),
        );
      },
    );
  }
}

class OutlinedText extends StatelessWidget {
  final String textData;
  final TextStyle? textStyle;
  final Color textColor;
  final Color outlineColor;
  final double outlineWidth;
  final TextAlign? textAlign;

  const OutlinedText({
    super.key,
    required this.textData,
    required this.textStyle,
    this.textColor = Colors.white,
    this.outlineColor = Colors.grey,
    this.outlineWidth = 1,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {

    final effectiveTextStyle = textStyle ?? const TextStyle();
    return Stack(
      children: [
        // Outline text
        Text(
          textData,
          style: effectiveTextStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = outlineWidth
              ..color = outlineColor,
          ),
          textAlign: textAlign,
        ),
        // Filled text
        Text(
          textData,
          style: effectiveTextStyle.copyWith(
            color: textColor,
          ),
          textAlign: textAlign,
        ),
      ],
    );
  }
}

class OutlinedIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color iconColor;
  final Color outlineColor;
  final double outlineWidth;

  const OutlinedIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.iconColor,
    required this.outlineColor,
    required this.outlineWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Outline layer
        Icon(
          icon,
          size: size + outlineWidth,
          color: outlineColor,
        ),
        // Inner icon
        Icon(
          icon,
          size: size,
          color: iconColor,
        ),
      ],
    );
  }
}

class DashedBorder extends ShapeBorder {
  final double dashWidth;
  final double dashSpace;
  final Color borderColor;
  final double borderWidth;

  const DashedBorder({
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
    this.borderColor = Colors.black,
    this.borderWidth = 1.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection, BoxShape shape = BoxShape.rectangle, BorderRadius borderRadius = BorderRadius.zero}) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final double width = rect.width;
    final double height = rect.height;

    // Top border
    _drawDashedLine(canvas, const Offset(0, 0), Offset(width, 0), paint);

    // Bottom border
    _drawDashedLine(canvas, Offset(0, height), Offset(width, height), paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;
    double distance = sqrt(dx * dx + dy * dy);
    double dxUnit = dx / distance;
    double dyUnit = dy / distance;

    double currentX = start.dx;
    double currentY = start.dy;

    while (distance > 0) {
      final double dashLength = distance > dashWidth ? dashWidth : distance;
      canvas.drawLine(Offset(currentX, currentY), Offset(currentX + dxUnit * dashLength, currentY + dyUnit * dashLength), paint);

      currentX += dxUnit * (dashLength + dashSpace);
      currentY += dyUnit * (dashLength + dashSpace);

      distance -= dashLength + dashSpace;
    }
  }

  @override
  ShapeBorder scale(double t) => this;
}

class DialogTitle extends StatelessWidget {
  final String title;
  final double width;
  final double height;
  final bool isError;

  const DialogTitle({
    super.key,
    required this.title,
    this.width = double.infinity,
    this.height = 50.0,
    this.isError = false 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
          bottomLeft: Radius.circular(16.0),
          bottomRight: Radius.circular(16.0),
        ),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class CodePreviewBuilder extends MarkdownElementBuilder {

  final BuildContext context;
  CodePreviewBuilder(this.context);

  bool isCodeBlock(md.Element element) {
    return (element.tag == 'pre' || element.tag == 'code') && element.attributes['class'] != null;
  }

  bool isInlineCode(md.Element element) {
    return element.tag == 'pre' && element.attributes['class'] == null;
  }

  String getCodeLanguage(md.Element element) {
    return element.attributes['class']?.replaceFirst('language-', '') ?? 'plaintext';
  }

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {

    if (isInlineCode(element)) {

      return Container(
        padding: const EdgeInsets.all(2),
        child: Text(
          element.textContent,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color.fromARGB(255, 0, 0, 0)),
        ),
      );

    } else  if (isCodeBlock(element)) {

      return Stack(
        children: [

          // Code text
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 233, 233, 233),
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(3),
            ),
            child: HighlightView(
              element.textContent,
              padding: const EdgeInsets.all(10),
              language: getCodeLanguage(element),
              theme: githubTheme, 
              textStyle: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ),

          // Copy to clipboard button
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 25,
              height: 25,
              child: FloatingActionButton(
                mini: true,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: element.textContent));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, content: const Text('Code copied to clipboard')),
                  );
                },
                backgroundColor: const Color.fromARGB(80, 82, 172, 247),
                shape: const CircleBorder(),
                elevation: 3,
                highlightElevation: 0,
                child: const Icon(Icons.copy, size: 16),
              ),
            ),
          ),

        ], // Stack (children)
      ); // Stack

    }
    return null;
  } // widget visitElementAfter

} // class CodePreviewBuilder

class ChatBubble extends StatelessWidget {
  final String textData;
  final bool isUser;
  final bool animateIcon;

  final Function(int)? fnCancelProcessing;
  final int? indexProcessing;
  final List<String>? images;
  final Iterable<String>? documents; 
  final Iterable<String>? codeFiles; 

  const ChatBubble({
    super.key, 
    required this.isUser, 
    required this.animateIcon,
    required this.textData,
    this.fnCancelProcessing,
    this.indexProcessing,
    this.images,
    this.documents,
    this.codeFiles
  });

  @override
  Widget build(BuildContext context) {

    // Check if this is a syustem prompt
    if( textData == AppData.ignoreSystemPrompt){ return const SizedBox.shrink(); }

    // Parse textData for documents and code files
    String sanitizedText = textData;

    List<String> docs = [];
    List<String> code = [];
    PersistentStorage.checkForDocuments(docs, code, sanitizedText);

    // Remove auto prompt added to message for docs and code (if available)    
    if(isUser){
      bool haveDocs = false;
      if(docs.isNotEmpty){
        haveDocs = true;
        sanitizedText = removeAutoPrompt(textData, AppData.promptDocs); 
      }

      bool haveCode = code.isNotEmpty;
      if(!haveDocs && haveCode){
        sanitizedText = removeAutoPrompt(textData, AppData.promptCode);
      }

      if(haveDocs) { sanitizedText += _formatFilenamesAsCodeBlock(docs, 'documents'); }
      if(haveCode) { sanitizedText += _formatFilenamesAsCodeBlock(code, 'code'); }
    }

    return ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0), 
            bottomLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0), 
            bottomRight: Radius.circular(20.0),
          ),
          
        child: Container(
          color: isUser? Colors.blue[50] : Colors.amber[100],
          margin: AppData.instance.getUserDeviceType(context) == UserDeviceType.desktop ? 
            const EdgeInsets.all(3) : const EdgeInsets.symmetric(horizontal: 3, vertical: 8).copyWith(right: 10),

          child: 
            Row ( 
              children: [

                // Icon
                const SizedBox(width:10),

                // Animated icon
                if(!isUser && animateIcon) const AnimIconColorFade(
                  icon: Icons.psychology, 
                  size: 24.0, 
                  duration: 2
                ),

                // Regular icon
                if(!animateIcon) Icon(
                  isUser? Icons.person : Icons.psychology,
                  color: Colors.grey,
                  size: 24.0,
                ),

                // Text
                const SizedBox(width:20),
                Expanded( 
                  child: SelectionArea(
                  child: Container( 
                    margin: const EdgeInsets.all(5), 
                    child: Markdown(
                      data: sanitizedText, 
                      builders: {
                        'code': CodePreviewBuilder(context),
                      },
                      shrinkWrap: true,
                      styleSheet: MarkdownStyleSheet(
                          h3: const TextStyle(color: Colors.black, fontSize: 18),
                          codeblockDecoration: BoxDecoration(
                            color:  Colors.amber[100],
                          ),
                        ),
                      ) 
                  )
                )),

                // Cancel
                if (!isUser && animateIcon && indexProcessing != null)
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 50, 
                    ),
                    child: IconButton( 
                      icon: const Icon(Icons.cancel), 
                      onPressed: indexProcessing == null ? null : () {
                            if (fnCancelProcessing != null && indexProcessing != null) {
                              fnCancelProcessing!(indexProcessing!);
                          }
                        }
                      ),
                  ),


                // Images
                if (images != null && images!.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: AppData.instance.getUserDeviceType(context) == UserDeviceType.phone ? 80 : 250, 
                    ),
                    child: Wrap(
                      spacing: 3.0,
                      children: images!.map((image) {
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  child: ImagePreview(base64Image: image),
                                );
                              },
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            child: Image.memory(
                              base64Decode(image),
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

              ],
            ),

        ),
    );
  }

 String removeAutoPrompt(String text, String delimeter) {
      int delimiterIndex = text.indexOf(delimeter);
      if (delimiterIndex != -1) {
        return text.substring(0, delimiterIndex).trim();
      }
      return text;
  }

  String _formatFilenamesAsCodeBlock(Iterable<String> filenames, String prefix) {
    if (filenames.isEmpty) return '';

    final buffer = StringBuffer('\n\n``$prefix: '); 
    for (var i = 0; i < filenames.length; i++) {

      buffer.write(filenames.elementAt(i));
      if (i < filenames.length - 1) {
        buffer.write(', '); 
      }

    }
    
    buffer.writeln('``');
    return buffer.toString();
  }

}

class AnimIconColorFade extends StatefulWidget {
  final IconData icon;
  final double size;
  final int duration;
  const AnimIconColorFade({super.key, required this.icon, required this.size, required this.duration});

  @override
  AnimIconColorFadeState createState() => AnimIconColorFadeState();
}

class AnimIconColorFadeState extends State<AnimIconColorFade> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: Duration(seconds: widget.duration), // Duration (in seconds) of the full spectrum transition
      vsync: this,
    )..repeat(reverse: true); // Repeat back and forth

    // Define the color tween sequence to cover the entire color spectrum
    _colorAnimation = _controller.drive(
      TweenSequence<Color?>([
        TweenSequenceItem(
          tween: ColorTween(begin: Colors.red, end: Colors.purple),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: ColorTween(begin: Colors.green, end: Colors.cyan),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: ColorTween(begin: Colors.cyan, end: Colors.blue),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: ColorTween(begin: Colors.blue, end: Colors.purple),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: ColorTween(begin: Colors.purple, end: Colors.red),
          weight: 1,
        ),
      ]),
    );

    // Define the fade transition animation
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Icon(
            widget.icon, 
            size: widget.size,
            color: _colorAnimation.value,
          );
        },
      ),
    );
  }

}

class ErrorDialog extends StatelessWidget {
  final String titleText;
  final String message;

  const ErrorDialog({
    super.key,
    required this.titleText,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) {
        if (!didPop) {

          return;
        }
      },
      child: Dialog(
        backgroundColor: Colors.red[100], 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedText(
                textData: titleText,
                textStyle: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                //style: Theme.of(context).textTheme.,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showErrorDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return ErrorDialog(
        titleText: title,
        message: message,
      );
    },
  );
}