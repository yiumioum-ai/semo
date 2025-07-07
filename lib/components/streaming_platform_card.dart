import 'package:flutter/material.dart';
import '../models/streaming_platform.dart';

class StreamingPlatformCard extends StatelessWidget {
  final StreamingPlatform platform;
  final VoidCallback? onTap;

  const StreamingPlatformCard({
    Key? key,
    required this.platform,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          child: Image.asset(
            '${platform.logoPath}',
            width: MediaQuery.of(context).size.width * .4,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}