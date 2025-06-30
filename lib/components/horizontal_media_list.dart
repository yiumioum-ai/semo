import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class HorizontalMediaList<T> extends StatelessWidget {
  final String title;
  final String source;
  final PagingController<int, T> pagingController;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final VoidCallback? onViewAllTap;

  const HorizontalMediaList({
    Key? key,
    required this.title,
    required this.source,
    required this.pagingController,
    required this.itemBuilder,
    this.onViewAllTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (onViewAllTap != null)
                GestureDetector(
                  onTap: onViewAllTap,
                  child: Text(
                    'View all',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall!
                        .copyWith(color: Colors.white54),
                  ),
                ),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.25,
            child: PagingListener<int, T>(
              controller: pagingController,
              builder: (context, state, fetchNextPage) {
                return PagedListView<int, T>(
                  state: state,
                  fetchNextPage: fetchNextPage,
                  scrollDirection: Axis.horizontal,
                  builderDelegate: PagedChildBuilderDelegate<T>(
                    itemBuilder: itemBuilder,
                    firstPageErrorIndicatorBuilder: (_) => const Center(
                      child: Text('Error loading items'),
                    ),
                    newPageErrorIndicatorBuilder: (_) => const Center(
                      child: Text('Error loading more items'),
                    ),
                    firstPageProgressIndicatorBuilder: (_) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    newPageProgressIndicatorBuilder: (_) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    noItemsFoundIndicatorBuilder: (_) => const Center(
                      child: Text('No items found'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}