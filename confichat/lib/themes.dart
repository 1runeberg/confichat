/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {

  Map<String, ThemeData> themes = {
    'Onyx': onyxTheme,
    'Sapphire': sapphireTheme,
    'Emerald': emeraldTheme,
    'Ruby': rubyTheme,
    'Topaz': topazTheme,
  };

  // Current theme name
  String _currentThemeName = 'Onyx';

  // Get the current theme data
  ThemeData get currentTheme => themes[_currentThemeName]!;

  // Get the current theme name
  String get currentThemeName => _currentThemeName;

  // Set theme by name
  void setTheme(String name) {
    if (themes.containsKey(name)) {
      _currentThemeName = name;
      notifyListeners();
    }
  }
}


// Sapphire theme
const ColorScheme sapphireColorScheme = ColorScheme(
  brightness: Brightness.light,                             
  primary: Color.fromARGB(255, 33, 150, 243),           
  primaryContainer: Color.fromARGB(255, 25, 118, 210),   
  secondary: Color.fromARGB(255, 187, 222, 251),         
  secondaryContainer: Color.fromARGB(255, 144, 202, 249), 
  onSecondaryContainer: Color.fromARGB(255, 211, 235, 255), 
  tertiaryContainer: Color.fromARGB(149, 101, 181, 247),
  tertiaryFixedDim: Color.fromARGB(80, 82, 172, 247),
  surface: Color.fromARGB(255, 255, 255, 255),           
  surfaceBright: Color.fromARGB(255, 0, 0, 255), 
  surfaceDim: Color.fromARGB(255, 189, 189, 189), 
  error: Color.fromARGB(255, 176, 0, 32),             
  onPrimary: Color.fromARGB(255, 255, 255, 255),        
  onSecondary: Color.fromARGB(255, 0, 0, 0),           
  onSurface: Color.fromARGB(255, 0, 0, 0),                
  onError: Color.fromARGB(255, 255, 255, 255),            
);

final ThemeData sapphireTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  colorScheme: sapphireColorScheme,

  scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),

  textTheme: const TextTheme(
    
    titleMedium: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),

    labelSmall: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.normal,
              fontSize: 16.0,
            ),

    displaySmall: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.normal,
              fontSize: 12.0,
            ),

    labelMedium: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
  ),

  appBarTheme:  AppBarTheme(
    backgroundColor: sapphireColorScheme.primaryContainer,
    foregroundColor: Colors.white,
  ),

  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.blue,
    textTheme: ButtonTextTheme.primary,
  ),

);


// Onyx theme
const ColorScheme onyxColorScheme = ColorScheme(
  brightness: Brightness.light,                             
  primary: Color.fromARGB(255, 0, 0, 0),           
  primaryContainer: Color.fromARGB(255, 0, 0, 0),   
  secondary: Color.fromARGB(255, 235, 231, 231),         
  secondaryContainer: Color.fromARGB(255, 139, 139, 139), 
  onSecondaryContainer: Color.fromARGB(255, 211, 235, 255), 
  tertiaryContainer: Color.fromARGB(148, 194, 194, 194),
  tertiaryFixedDim: Color.fromARGB(80, 82, 172, 247),
  surface: Color.fromARGB(255, 255, 255, 255),           
  surfaceBright: Color.fromARGB(255, 0, 0, 0), 
  surfaceDim: Color.fromARGB(255, 226, 225, 225), 
  error: Color.fromARGB(255, 176, 0, 32),             
  onPrimary: Color.fromARGB(255, 255, 255, 255),        
  onSecondary: Color.fromARGB(255, 0, 0, 0),           
  onSurface: Color.fromARGB(255, 0, 0, 0),                
  onError: Color.fromARGB(255, 255, 255, 255),     
);

final ThemeData onyxTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  colorScheme: onyxColorScheme,

  scaffoldBackgroundColor: onyxColorScheme.secondary,

  textTheme: const TextTheme(
    
    titleMedium: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),

    labelSmall: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.normal,
              fontSize: 16.0,
            ),

    displaySmall: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.normal,
              fontSize: 12.0,
            ),

    labelMedium: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
  ),

  appBarTheme:  AppBarTheme(
    backgroundColor: onyxColorScheme.primaryContainer,
    foregroundColor: const Color.fromARGB(255, 255, 255, 255),
  ),

  buttonTheme: const ButtonThemeData(
    buttonColor: Color.fromARGB(255, 255, 255, 255),
    textTheme: ButtonTextTheme.primary,
  ),

);


// Emerald theme
const ColorScheme emeraldColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color.fromARGB(255, 76, 175, 80),          
  primaryContainer: Color.fromARGB(255, 56, 142, 60),   
  secondary: Color.fromARGB(255, 200, 230, 201),        
  secondaryContainer: Color.fromARGB(255, 165, 214, 167), 
  onSecondaryContainer: Color.fromARGB(255, 220, 237, 222),
  tertiaryContainer: Color.fromARGB(149, 129, 199, 132),  
  tertiaryFixedDim: Color.fromARGB(80, 102, 187, 106), 
  surface: Color.fromARGB(255, 255, 255, 255),        
  surfaceBright: Color.fromARGB(255, 0, 255, 0),  
  surfaceDim: Color.fromARGB(255, 189, 189, 189),   
  error: Color.fromARGB(255, 176, 0, 32),             
  onPrimary: Color.fromARGB(255, 255, 255, 255),   
  onSecondary: Color.fromARGB(255, 0, 0, 0),         
  onSurface: Color.fromARGB(255, 0, 0, 0),         
  onError: Color.fromARGB(255, 255, 255, 255),        
);

final ThemeData emeraldTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  colorScheme: emeraldColorScheme,

  scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),

  textTheme: const TextTheme(
    
    titleMedium: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),

    labelSmall: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.normal,
              fontSize: 16.0,
            ),

    displaySmall: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.normal,
              fontSize: 12.0,
            ),

    labelMedium: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
  ),

  appBarTheme:  AppBarTheme(
    backgroundColor: emeraldColorScheme.primaryContainer,
    foregroundColor: Colors.white,
  ),

  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.green,  // Green replacing blue
    textTheme: ButtonTextTheme.primary,
  ),
);


// Ruby theme
const ColorScheme rubyColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color.fromARGB(255, 244, 67, 54),
  primaryContainer: Color.fromARGB(255, 198, 40, 40),
  secondary: Color.fromARGB(255, 255, 205, 210), 
  secondaryContainer: Color.fromARGB(255, 239, 154, 154),
  onSecondaryContainer: Color.fromARGB(255, 255, 235, 238),
  tertiaryContainer: Color.fromARGB(149, 229, 115, 115),
  tertiaryFixedDim: Color.fromARGB(80, 239, 83, 80),
  surface: Color.fromARGB(255, 255, 255, 255),
  surfaceBright: Color.fromARGB(255, 255, 0, 0),
  surfaceDim: Color.fromARGB(255, 189, 189, 189),
  error: Color.fromARGB(255, 176, 0, 32),
  onPrimary: Color.fromARGB(255, 255, 255, 255), 
  onSecondary: Color.fromARGB(255, 0, 0, 0),       
  onSurface: Color.fromARGB(255, 0, 0, 0),         
  onError: Color.fromARGB(255, 255, 255, 255),     
);

final ThemeData rubyTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  colorScheme: rubyColorScheme,

  scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),

  textTheme: const TextTheme(
    
    titleMedium: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),

    labelSmall: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.normal,
              fontSize: 16.0,
            ),

    displaySmall: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.normal,
              fontSize: 12.0,
            ),

    labelMedium: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
  ),

  appBarTheme:  AppBarTheme(
    backgroundColor: rubyColorScheme.primaryContainer,
    foregroundColor: Colors.white,
  ),

  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.red,  // Red replacing blue
    textTheme: ButtonTextTheme.primary,
  ),
);


// Topaz theme
const ColorScheme topazColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color.fromARGB(255, 255, 193, 7),
  primaryContainer: Color.fromARGB(255, 255, 160, 0),
  secondary: Color.fromARGB(255, 255, 224, 130),
  secondaryContainer: Color.fromARGB(255, 255, 202, 40),
  onSecondaryContainer: Color.fromARGB(255, 255, 235, 59),
  tertiaryContainer: Color.fromARGB(149, 255, 179, 0),
  tertiaryFixedDim: Color.fromARGB(80, 255, 152, 0),
  surface: Color.fromARGB(255, 255, 255, 255),
  surfaceBright: Color.fromARGB(255, 255, 214, 0),
  surfaceDim: Color.fromARGB(255, 189, 189, 189),
  error: Color.fromARGB(255, 176, 0, 32),
  onPrimary: Color.fromARGB(255, 255, 255, 255),
  onSecondary: Color.fromARGB(255, 0, 0, 0),
  onSurface: Color.fromARGB(255, 0, 0, 0),
  onError: Color.fromARGB(255, 255, 255, 255),
);

final ThemeData topazTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  colorScheme: topazColorScheme,

  scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),

  textTheme: const TextTheme(
    
    titleMedium: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),

    labelSmall: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.normal,
              fontSize: 16.0,
            ),

    displaySmall: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.normal,
              fontSize: 12.0,
            ),

    labelMedium: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
  ),

  appBarTheme:  AppBarTheme(
    backgroundColor: topazColorScheme.primaryContainer,
    foregroundColor: Colors.white,
  ),

  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.yellow,
    textTheme: ButtonTextTheme.primary,
  ),
);

