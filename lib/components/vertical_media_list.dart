import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class VerticalMediaList<T> extends StatelessWidget {
  final String? title;
  final String? source;
  final PagingController<int, T> pagingController;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final VoidCallback? onViewAllTap;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final String? emptyStateMessage;
  final String? errorMessage;

  const VerticalMediaList({
    Key? key,
    this.title,
    this.source,
    required this.pagingController,
    required this.itemBuilder,
    this.onViewAllTap,
    this.crossAxisCount = 3,
    this.childAspectRatio = 0.5,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.emptyStateMessage,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title section (optional)
        if (title != null) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Text(
                  title!,
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
          ),
        ],

        // Grid content
        Flexible(
          child: PagingListener<int, T>(
            controller: pagingController,
            builder: (context, state, fetchNextPage) {
              return PagedGridView<int, T>(
                state: state,
                fetchNextPage: fetchNextPage,
                shrinkWrap: shrinkWrap,
                physics: physics,
                padding: padding,
                builderDelegate: PagedChildBuilderDelegate<T>(
                  itemBuilder: itemBuilder,
                  firstPageErrorIndicatorBuilder: (context) => _buildErrorIndicator(
                    context,
                    errorMessage ?? 'Failed to load items',
                        () => pagingController.refresh(),
                    isFirstPage: true,
                  ),
                  newPageErrorIndicatorBuilder: (context) => _buildErrorIndicator(
                    context,
                    'Failed to load more items',
                        () => pagingController.fetchNextPage(),
                    isFirstPage: false,
                  ),
                  firstPageProgressIndicatorBuilder: (context) => _buildLoadingIndicator(
                    context,
                    isFirstPage: true,
                  ),
                  newPageProgressIndicatorBuilder: (context) => _buildLoadingIndicator(
                    context,
                    isFirstPage: false,
                  ),
                  noItemsFoundIndicatorBuilder: (context) => _buildEmptyState(
                    context,
                    emptyStateMessage ?? 'No items found',
                  ),
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                  childAspectRatio: childAspectRatio,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorIndicator(
      BuildContext context,
      String message,
      VoidCallback onRetry, {
        required bool isFirstPage,
      }) {
    if (isFirstPage) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .displayMedium!
                    .copyWith(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
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
          children: [
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .displaySmall!
                  .copyWith(color: Colors.white54),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 36),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLoadingIndicator(BuildContext context, {required bool isFirstPage}) {
    if (isFirstPage) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 80,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .displayMedium!
                  .copyWith(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}