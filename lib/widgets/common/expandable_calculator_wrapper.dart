import 'package:flutter/material.dart';

class ExpandableCalculatorWrapper extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget calculator;
  final double iconSize;

  const ExpandableCalculatorWrapper({
    Key? key,
    required this.isExpanded,
    required this.onToggle,
    required this.calculator,
    this.iconSize = 32.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 電卓アイコンはDraggableCalculatorButtonで表示するため、ここでは電卓本体のみ表示
    if (!isExpanded) {
      return const SizedBox.shrink();
    }
    
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: calculator,
      ),
    );
  }
}


