import 'package:flutter/material.dart';

class MonthSlider extends StatefulWidget {
  final List<String> months;
  final int initialMonthIndex;
  final Function(int) onMonthChanged;
  final Color textColor;
  final Color iconColor;
  final double fontSize;
  final FontWeight fontWeight;

  const MonthSlider({
    super.key,
    required this.months,
    required this.initialMonthIndex,
    required this.onMonthChanged,
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
  });

  @override
  State<MonthSlider> createState() => _MonthSliderState();
}

class _MonthSliderState extends State<MonthSlider> with SingleTickerProviderStateMixin {
  late int currentMonthIndex;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  String _nextPeriod = '';
  bool _isSliding = false;
  bool _slideToRight = true;

  @override
  void initState() {
    super.initState();
    currentMonthIndex = widget.initialMonthIndex;

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initial animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          currentMonthIndex = _slideToRight
              ? (currentMonthIndex + 1) % widget.months.length
              : (currentMonthIndex - 1 + widget.months.length) % widget.months.length;
          _isSliding = false;
          _animationController.reset();
        });

        // Notify parent about the month change
        widget.onMonthChanged(currentMonthIndex);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextMonth() {
    if (_isSliding) return;

    setState(() {
      _isSliding = true;
      _slideToRight = true;
      _nextPeriod = widget.months[(currentMonthIndex + 1) % widget.months.length];

      // Update animation to slide from right
      _slideAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: const Offset(0.0, 0.0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
    });

    _animationController.forward();
  }

  void _previousMonth() {
    if (_isSliding) return;

    setState(() {
      _isSliding = true;
      _slideToRight = false;
      _nextPeriod = widget.months[(currentMonthIndex - 1 + widget.months.length) % widget.months.length];

      // Update animation to slide from left
      _slideAnimation = Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: const Offset(0.0, 0.0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
    });

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: widget.iconColor),
          onPressed: _previousMonth,
        ),
        SizedBox(
          width: 120, // Fixed width for month name
          child: _isSliding
              ? SlideTransition(
            position: _slideAnimation,
            child: Text(
              _nextPeriod,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.textColor,
                fontSize: widget.fontSize,
                fontWeight: widget.fontWeight,
              ),
            ),
          )
              : Text(
            widget.months[currentMonthIndex],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.textColor,
              fontSize: widget.fontSize,
              fontWeight: widget.fontWeight,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: widget.iconColor),
          onPressed: _nextMonth,
        ),
      ],
    );
  }
}