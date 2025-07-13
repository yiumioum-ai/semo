import "package:flutter/material.dart";

Widget buildErrorIndicator(BuildContext context, String message, VoidCallback onRetry, {required bool isFirstPage,}) {
  if (isFirstPage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  } else {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            message,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white54),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 36),
            ),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}

Widget buildLoadingIndicator({bool isFirstPage = false}) => Center(
  child: Padding(
    padding: EdgeInsets.all(isFirstPage ? 32 : 16),
    child: const CircularProgressIndicator(),
  ),
);

Widget buildEmptyState(BuildContext context, String message) => Center(
  child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(
          Icons.search_off,
          size: 80,
          color: Colors.white54,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  ),
);