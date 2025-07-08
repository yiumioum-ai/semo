import "package:flutter/material.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";

class VerticalMediaList<T> extends StatelessWidget {
  const VerticalMediaList({
    super.key,
    this.pagingController,
    this.itemBuilder,
    this.items,
    this.crossAxisCount = 3,
    this.childAspectRatio = 0.5,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.emptyStateMessage,
    this.errorMessage,
  }) : assert((pagingController != null && itemBuilder != null) || (items != null && itemBuilder != null),
  "Either provide pagingController with itemBuilder for pagination, or items with itemBuilder for simple grid",
  );

  final PagingController<int, T>? pagingController;
  final Widget Function(BuildContext, T, int)? itemBuilder;
  final List<T>? items;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final String? emptyStateMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      // Grid content
      Flexible(
        child: _buildGridView(context),
      ),
    ],
  );

  Widget _buildGridView(BuildContext context) {
    // If pagingController is provided, use paginated grid
    if (pagingController != null) {
      return PagingListener<int, T>(
        controller: pagingController!,
        builder: (BuildContext context, PagingState<int, T> state, NextPageCallback fetchNextPage) => PagedGridView<int, T>(
          state: state,
          fetchNextPage: fetchNextPage,
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding,
          builderDelegate: PagedChildBuilderDelegate<T>(
            itemBuilder: itemBuilder!,
            firstPageErrorIndicatorBuilder: (BuildContext context) => _buildErrorIndicator(
              context,
              errorMessage ?? "Failed to load items",
                  () => pagingController!.refresh(),
              isFirstPage: true,
            ),
            newPageErrorIndicatorBuilder: (BuildContext context) => _buildErrorIndicator(
              context,
              "Failed to load more items",
                  () => pagingController!.fetchNextPage(),
              isFirstPage: false,
            ),
            firstPageProgressIndicatorBuilder: (BuildContext context) => _buildLoadingIndicator(
              context,
              isFirstPage: true,
            ),
            newPageProgressIndicatorBuilder: (BuildContext context) => _buildLoadingIndicator(
              context,
              isFirstPage: false,
            ),
            noItemsFoundIndicatorBuilder: (BuildContext context) => _buildEmptyState(
              context,
              emptyStateMessage ?? "No items found",
            ),
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
        ),
      );
    }

    // If items list is provided, use simple GridView.builder
    if (items != null) {
      if (items!.isEmpty) {
        return _buildEmptyState(context, emptyStateMessage ?? "No items found");
      }

      return GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: items!.length,
        itemBuilder: (BuildContext context, int index) => itemBuilder!(context, items![index], index),
      );
    }

    // Fallback - should never reach here due to assertion
    return Container();
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
            children: <Widget>[
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
              child: const Text("Retry"),
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

  Widget _buildEmptyState(BuildContext context, String message) => Center(
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