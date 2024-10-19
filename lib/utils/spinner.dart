import 'dart:async';

import 'package:flutter/material.dart';

class Spinner {
  BuildContext context;

  Color barrierColor;
  //Background color of the barrier

  Color? backgroundColor;
  //Background color of the spinner's view

  Color spinnerColor;
  //Color of the spinner

  double barrierOpacity;
  //Opacity of the barrier's background color

  double width;
  //Width of the spinner's view

  double height;
  //Height of the spinner's view

  double borderRadius;
  //Border radius of the spinner's view

  double spinnerMargin;
  //Margin between the spinner and its view

  Duration transitionDuration;
  //Enter and exit animations duration

  Duration? duration;
  //Visibility duration of the loader

  bool? fromNavigatorToShell;

  bool? useRootNavigator;

  Spinner(
      BuildContext this.context, {
        this.barrierColor = const Color(0xFF121212),
        this.barrierOpacity = 0.5,
        this.transitionDuration = const Duration(milliseconds: 500),
        this.width = 70.0,
        this.height = 70.0,
        this.backgroundColor,
        this.borderRadius = 15.0,
        this.spinnerMargin = 16.0,
        this.spinnerColor = const Color(0xFF604BA5),
        this.duration,
        this.fromNavigatorToShell = false,
        this.useRootNavigator = true,
      });

  show() async {
    await showGeneralDialog(
      context: context,
      useRootNavigator: useRootNavigator!,
      barrierDismissible: false,
      barrierColor: barrierColor.withOpacity(barrierOpacity),
      transitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, widget) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            return;
          },
          child: Transform.scale(
            scale: animation.value,
            child: Opacity(
              opacity: animation.value,
              child: AlertDialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                content: Container(
                  child: Center(
                    child: Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: backgroundColor != null ? backgroundColor : Theme.of(context).dialogBackgroundColor,
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                      padding: EdgeInsets.all(spinnerMargin),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          spinnerColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (duration != null) {
        Timer(duration!, () {
          dismiss();
        });
      }
    });
  }

  dismiss() {
    if (fromNavigatorToShell!) {
      Navigator.of(context, rootNavigator: true).pop();
    } else {
      Navigator.of(context).pop();
    }
  }
}