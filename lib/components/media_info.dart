import 'package:flutter/material.dart';

class MediaInfo extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? overview;
  final Widget? progressIndicator;

  const MediaInfo({
    Key? key,
    required this.title,
    required this.subtitle,
    this.overview,
    this.progressIndicator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          width: double.infinity,
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ),
        if (progressIndicator != null) progressIndicator!,
        if (overview != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 20),
            child: Text(
              overview!,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white54),
              textAlign: TextAlign.justify,
            ),
          ),
      ],
    );
  }
}