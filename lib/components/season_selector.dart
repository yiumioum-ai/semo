import 'package:flutter/material.dart';
import '../models/tv_show.dart';

class SeasonSelector extends StatelessWidget {
  final List<Season> seasons;
  final Season selectedSeason;
  final Function(Season) onSeasonChanged;

  const SeasonSelector({
    Key? key,
    required this.seasons,
    required this.selectedSeason,
    required this.onSeasonChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<Season>(
      initialSelection: selectedSeason,
      requestFocusOnTap: false,
      enableFilter: false,
      enableSearch: false,
      textStyle: Theme.of(context).textTheme.displayLarge,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onSelected: (Season? season) {
        if (season != null) {
          onSeasonChanged(season);
        }
      },
      dropdownMenuEntries: seasons.map<DropdownMenuEntry<Season>>(
            (Season season) {
          return DropdownMenuEntry<Season>(
            value: season,
            label: season.name,
            style: MenuItemButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).cardColor,
            ),
          );
        },
      ).toList(),
    );
  }
}