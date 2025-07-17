import "package:flutter/material.dart";

class PopupMenuContainer<T> extends StatefulWidget {
  const PopupMenuContainer({
    super.key,
    required this.child,
    required this.items,
    required this.onItemSelected,
  });

  final Widget child;
  final List<PopupMenuEntry<T>> items;
  final void Function(T?) onItemSelected;

  @override
  State<PopupMenuContainer<T>> createState() => PopupMenuContainerState<T>();
}

class PopupMenuContainerState<T> extends State<PopupMenuContainer<T>>{
  late Offset _tapDownPosition;

  @override
  Widget build(BuildContext context) => InkWell(
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTapDown: (TapDownDetails details) => _tapDownPosition = details.globalPosition,
      onLongPress: () async {
        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

        T? value = await showMenu<T>(
          context: context,
          items: widget.items,
          color: Theme.of(context).cardColor,
          position: RelativeRect.fromLTRB(
            _tapDownPosition.dx,
            _tapDownPosition.dy,
            overlay.size.width - _tapDownPosition.dx,
            overlay.size.height - _tapDownPosition.dy,
          ),
        );

        widget.onItemSelected(value);
      },
      child: widget.child
  );
}