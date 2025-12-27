import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// This file provides responsive sizing utilities for the RescueTN app.
/// It wraps flutter_screenutil to provide consistent sizing across all device sizes.
///
/// Usage:
/// - For width-based sizing: 100.w (100 logical pixels scaled by screen width)
/// - For height-based sizing: 100.h (100 logical pixels scaled by screen height)
/// - For font sizing: 16.sp (16sp scaled appropriately)
/// - For radius: 8.r (8 logical pixels scaled)
/// - For minimum dimension: 16.dm (uses smaller of width/height ratio)
///
/// The app is designed for a standard mobile screen (375 x 812 - iPhone X dimensions).

/// Design width baseline (iPhone X)
const double designWidth = 375;

/// Design height baseline (iPhone X)  
const double designHeight = 812;

/// Extension to add responsive sizing to num values
/// This provides a cleaner API for responsive sizing
extension ResponsiveSize on num {
  /// Width-based responsive sizing
  double get rw => w;
  
  /// Height-based responsive sizing
  double get rh => h;
  
  /// Responsive font sizing
  double get rsp => sp;
  
  /// Responsive radius
  double get rr => r;
}

/// Responsive padding values that scale with screen size
class ResponsivePadding {
  ResponsivePadding._();
  
  /// Extra small padding (4.0)
  static double get xs => 4.w;
  
  /// Small padding (8.0)
  static double get small => 8.w;
  
  /// Medium padding (16.0)
  static double get medium => 16.w;
  
  /// Large padding (24.0)
  static double get large => 24.w;
  
  /// Extra large padding (32.0)
  static double get xLarge => 32.w;
  
  /// Extra extra large padding (48.0)
  static double get xxLarge => 48.w;
}

/// Responsive border radius values
class ResponsiveRadius {
  ResponsiveRadius._();
  
  /// Small radius (4.0)
  static double get small => 4.r;
  
  /// Medium radius (8.0)
  static double get medium => 8.r;
  
  /// Large radius (16.0)
  static double get large => 16.r;
  
  /// Extra large radius (24.0)
  static double get xLarge => 24.r;
  
  /// Circle radius (50.0)
  static double get circle => 50.r;
}

/// Responsive font sizes
class ResponsiveFontSize {
  ResponsiveFontSize._();
  
  /// Extra small (10sp)
  static double get xs => 10.sp;
  
  /// Small (12sp)
  static double get small => 12.sp;
  
  /// Body text (14sp)
  static double get body => 14.sp;
  
  /// Medium (16sp)
  static double get medium => 16.sp;
  
  /// Large (18sp)
  static double get large => 18.sp;
  
  /// Title (20sp)
  static double get title => 20.sp;
  
  /// Headline (24sp)
  static double get headline => 24.sp;
  
  /// Display (32sp)
  static double get display => 32.sp;
}

/// Responsive icon sizes
class ResponsiveIconSize {
  ResponsiveIconSize._();
  
  /// Small icon (16)
  static double get small => 16.r;
  
  /// Medium icon (24)
  static double get medium => 24.r;
  
  /// Large icon (32)
  static double get large => 32.r;
  
  /// Extra large icon (48)
  static double get xLarge => 48.r;
}

/// Helper class for screen breakpoints
class ScreenBreakpoints {
  ScreenBreakpoints._();
  
  /// Check if screen is small (< 360dp width)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }
  
  /// Check if screen is medium (360-414dp width)
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 414;
  }
  
  /// Check if screen is large (>= 414dp width)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 414;
  }
  
  /// Check if screen is tablet (>= 600dp width)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }
}
