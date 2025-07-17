import "dart:async";

import "package:flutter/material.dart";

class Spinner {
  Spinner(
      this.context, {
        this.barrierColor = const Color(0xFF121212),
        this.barrierOpacity = 0.5,
        this.transitionDuration = const Duration(milliseconds: 500),
        this.width = 70.0,
        this.height = 70.0,
        this.backgroundColor,
        this.borderRadius = 15.0,
        this.spinnerMargin = 16.0,
        this.spinnerColor,
        this.duration,
        this.useRootNavigator = true,
      });

  final BuildContext context;

  final Color barrierColor;
  //Background color of the barrier

  final Color? backgroundColor;
  //Background color of the spinner's view

  final Color? spinnerColor;
  //Color of the spinner

  final double barrierOpacity;
  //Opacity of the barrier's background color

  final double width;
  //Width of the spinner's view

  final double height;
  //Height of the spinner's view

  final double borderRadius;
  //Border radius of the spinner's view

  final double spinnerMargin;
  //Margin between the spinner and its view

  final Duration transitionDuration;
  //Enter and exit animations duration

  final Duration? duration;
  //Visibility duration of the loader

  final bool useRootNavigator;

  // Track if spinner is currently showing
  bool _isShowing = false;

  Timer? _autoCloseTimer;

  void show() {
    if (_isShowing) {
      return;
    }

    _isShowing = true;

    showGeneralDialog(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: false,
      barrierColor: barrierColor.withValues(alpha: barrierOpacity),
      transitionDuration: transitionDuration,
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => Container(),
      transitionBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget widget) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          return;
        },
        child: Transform.scale(
          scale: animation.value,
          child: Opacity(
            opacity: animation.value,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              content: Center(
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: backgroundColor ?? Theme.of(context).dialogTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  padding: EdgeInsets.all(spinnerMargin),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      spinnerColor ?? Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      if (duration != null) {
        _autoCloseTimer = Timer(duration!, () {
          dismiss();
        });
      } else {
        _isShowing = false;
      }
    });

    return;
  }

  void dismiss() {
    if (_isShowing) {
      _autoCloseTimer?.cancel();
      _autoCloseTimer = null;
      _isShowing = false;
      Navigator.of(context, rootNavigator: useRootNavigator).pop();
    }
  }
}