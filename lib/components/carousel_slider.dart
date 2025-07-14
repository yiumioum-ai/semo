import "package:carousel_slider/carousel_slider.dart" as slider;
import "package:flutter/material.dart";
import "package:semo/components/carousel_poster.dart";
import "package:smooth_page_indicator/smooth_page_indicator.dart";

class CarouselSlider extends StatelessWidget {
  CarouselSlider({
    super.key,
    required this.itemCount,
    required this.currentItemIndex,
    required this.onItemChanged,
    required this.itemBackdropPath,
    required this.itemTitle,
    this.itemOnTap,
  });

  final int itemCount;
  final int currentItemIndex;
  final Function(int index) onItemChanged;
  final String itemBackdropPath;
  final String itemTitle;
  final VoidCallback? itemOnTap;

  final slider.CarouselSliderController _controller = slider.CarouselSliderController();

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      slider.CarouselSlider.builder(
        carouselController: _controller,
        itemCount: itemCount,
        options: slider.CarouselOptions(
          aspectRatio: 2,
          autoPlay: true,
          enlargeCenterPage: true,
          onPageChanged: (int index, slider.CarouselPageChangedReason reason) => onItemChanged(index),
        ),
        itemBuilder: (BuildContext context, int index, int realIndex) => CarouselPoster(
          backdropPath: itemBackdropPath,
          title: itemTitle,
          onTap: itemOnTap,
        ),
      ),
      Container(
        margin: const EdgeInsets.only(top: 20),
        child: AnimatedSmoothIndicator(
          activeIndex: currentItemIndex,
          count: itemCount,
          effect: ExpandingDotsEffect(
            dotWidth: 10,
            dotHeight: 10,
            dotColor: Colors.white30,
            activeDotColor: Theme.of(context).primaryColor,
          ),
        ),
      ),
    ],
  );
}