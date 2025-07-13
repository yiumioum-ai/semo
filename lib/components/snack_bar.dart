import "package:flutter/material.dart";

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: Theme.of(context).textTheme.displayMedium,
      ),
      backgroundColor: Theme.of(context).cardColor,
    ),
  );
}