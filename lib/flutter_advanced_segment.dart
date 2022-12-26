import 'package:flutter/widgets.dart';

/// An advanced
class AdvancedSegment<K extends Object, V extends String>
    extends StatefulWidget {
  const AdvancedSegment({
    Key? key,
    required this.segments,
    this.controller,
    this.activeStyle = const TextStyle(
      fontWeight: FontWeight.w600,
    ),
    this.inactiveStyle,
    this.itemPadding = const EdgeInsets.symmetric(
      horizontal: 15,
      vertical: 10,
    ),
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.backgroundColor = const Color(0x42000000),
    this.sliderColor = const Color(0xFFFFFFFF),
    this.sliderOffset = 2.0,
    this.rowCount = 1,
    this.animationDuration = const Duration(milliseconds: 250),
    this.shadow = const <BoxShadow>[
      BoxShadow(
        color: Color(0x42000000),
        blurRadius: 8.0,
      ),
    ],
    this.sliderDecoration,
  })  : assert(segments.length > 1, 'Minimum segments amount is 2'),
        super(key: key);

  /// Controls segments selection.
  final ValueNotifier<K>? controller;

  /// Map of segments should be more than one keys.
  final Map<K, V> segments;

  /// Active text style.
  final TextStyle activeStyle;

  /// Inactive text style.
  final TextStyle? inactiveStyle;

  /// Padding of each item.
  final EdgeInsetsGeometry itemPadding;

  /// Common border radius.
  final BorderRadius borderRadius;

  /// Color of slider.
  final Color sliderColor;

  /// Layout background color.
  final Color backgroundColor;

  /// Gap between slider and layout.
  final double sliderOffset;

  /// Selection animation duration.
  final Duration animationDuration;

  /// Slide's Shadow
  final List<BoxShadow>? shadow;

  /// Slider decoration
  final BoxDecoration? sliderDecoration;

  /// Number of horizontal rows of segments
  final int rowCount;

  @override
  _AdvancedSegmentState<K, V> createState() => _AdvancedSegmentState();
}

class _AdvancedSegmentState<K extends Object, V extends String>
    extends State<AdvancedSegment<K, V>> with SingleTickerProviderStateMixin {
  static const _defaultTextStyle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: Color(0xFF000000),
  );
  late final ValueNotifier<K> _defaultController;
  late ValueNotifier<K> _controller;
  late Size _itemSize;
  late Size _containerSize;

  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();

    _initSizes();

    _defaultController = ValueNotifier<K>(widget.segments.keys.first);

    _controller = widget.controller ?? _defaultController;
  }

  void _initSizes() {
    final maxSize =
        widget.segments.values.map(_obtainTextSize).reduce((value, element) {
      return value.width.compareTo(element.width) >= 1 ? value : element;
    });

    _itemSize = Size(
      maxSize.width + widget.itemPadding.horizontal,
      maxSize.height + widget.itemPadding.vertical,
    );

    _containerSize = Size(
      _itemSize.width * (widget.segments.length / widget.rowCount),
      _itemSize.height * widget.rowCount,
    );
  }

  @override
  void didUpdateWidget(covariant AdvancedSegment<K, V> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _controller = widget.controller ?? _defaultController;
    }

    if (oldWidget.segments != widget.segments) {
      _initSizes();
    }
  }

  int get itemsPerRow => (widget.segments.length / widget.rowCount).ceil();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _containerSize.width,
      height: _containerSize.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius,
      ),
      child: Opacity(
        opacity: widget.controller != null ? 1 : 0.75,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: _handlePan,
                onTapUp: _handleTap,
                child: AnimatedContainer(duration: widget.animationDuration,
                    alignment: Directionality.of(context) == TextDirection.rtl ? Alignment.topRight : Alignment.topLeft,
                    curve: Curves.ease,
                    transform: Matrix4.translationValues(Directionality.of(context) == TextDirection.rtl ? -_offset.dx :_offset.dx, _offset.dy, 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / (widget.segments.length / widget.rowCount),
                    heightFactor: 1 / widget.rowCount,
                    child: Container(
                      margin: EdgeInsets.all(widget.sliderOffset),
                      decoration: widget.sliderDecoration ??
                          BoxDecoration(
                            color: widget.sliderColor,
                            borderRadius: widget.borderRadius.subtract(
                                BorderRadius.all(
                                    Radius.circular(widget.sliderOffset))),
                            boxShadow: widget.shadow,
                          ),
                    ),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: ValueListenableBuilder(
                valueListenable: _controller,
                builder: (_, value, __) {
                  return Column(
                    children: List.generate(widget.rowCount, (row) =>
                      Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: widget.segments.entries.toList().sublist(row*itemsPerRow, row*itemsPerRow + itemsPerRow).map((entry) {
                        return Container(
                          width: _itemSize.width,
                          height: _itemSize.height,
                          color: const Color(0x00000000),
                          child: AnimatedDefaultTextStyle(
                            duration: widget.animationDuration,
                            style: _defaultTextStyle.merge(value == entry.key
                                ? widget.activeStyle
                                : widget.inactiveStyle),
                            overflow: TextOverflow.clip,
                            maxLines: 1,
                            softWrap: false,
                            child: Center(
                              child: Text(entry.value),
                            ),
                          ),
                      );
                    }).toList(growable: false),
                  ),
                    ),
                    );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Size _obtainTextSize(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: _defaultTextStyle.merge(widget.activeStyle),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(
        minWidth: 0,
        maxWidth: double.infinity,
      );

    return textPainter.size;
  }

  _handleTap(TapUpDetails details) {
    _handleInteraction(details.localPosition);
  }

  _handlePan(DragUpdateDetails details) {
   _handleInteraction(details.localPosition);
  }

    _handleInteraction(Offset pos) {

    var pX = pos.dx / _containerSize.width;
    var pY = pos.dy / _containerSize.height;

    var iX = (pX * (itemsPerRow-1)).round().clamp(0, itemsPerRow-1);
    if (Directionality.of(context) == TextDirection.rtl) {
      iX = (itemsPerRow - 1) - iX;
    }
    var iY = (pY * (widget.rowCount-1)).round().clamp(0, widget.rowCount-1);
    var index = iX + (iY*itemsPerRow);

    // Snap to segment
setState(() {
  _offset = Offset(iX*_itemSize.width, iY*_itemSize.height);
  _controller.value = widget.segments.keys.elementAt(index);
});

  }

  @override
  void dispose() {
    _defaultController.dispose();
    super.dispose();
  }
}
