import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/person.dart' as model;
import '../utils/urls.dart';

class PersonCard extends StatelessWidget {
  final model.Person person;
  final VoidCallback? onTap;

  const PersonCard({
    super.key,
    required this.person,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CachedNetworkImage(
            imageUrl: '${Urls.imageBase_w300}${person.profilePath}',
            placeholder: (context, url) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                ),
              );
            },
            imageBuilder: (context, image) {
              return InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: onTap,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
            errorWidget: (context, url, error) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Align(
                  alignment: Alignment.center,
                  child: Icon(Icons.error, color: Colors.white54),
                ),
              );
            },
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.4,
          margin: const EdgeInsets.only(top: 10),
          child: Text(
            person.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}