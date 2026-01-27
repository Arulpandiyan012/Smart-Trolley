import 'package:flutter/material.dart';

class SmartAddButton extends StatelessWidget {
  final int qty;
  final bool isLoading;
  final VoidCallback onAdd;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const SmartAddButton({
    super.key,
    required this.qty,
    this.isLoading = false,
    required this.onAdd,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Loading State
    if (isLoading) {
      return Container(
        height: 32, width: 75,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF0C831F)),
        ),
        child: const SizedBox(
            height: 14, 
            width: 14, 
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0C831F))
        ),
      );
    }

    // 2. "ADD" State (Qty is 0)
    if (qty == 0) {
      return InkWell(
        onTap: onAdd,
        child: Container(
          height: 32, width: 75,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF0C831F)),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1))
            ],
          ),
          child: const Text(
              "ADD", 
              style: TextStyle(
                  color: Color(0xFF0C831F), 
                  fontWeight: FontWeight.bold, 
                  fontSize: 13
              )
          ),
        ),
      );
    }

    // 3. Counter State (Qty > 0)
    return Container(
      height: 32, width: 85,
      decoration: BoxDecoration(
        color: const Color(0xFF0C831F),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: onDecrease,
            child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6), 
                child: Icon(Icons.remove, color: Colors.white, size: 16)
            ),
          ),
          Text(
              "$qty", 
              style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 13
              )
          ),
          InkWell(
            onTap: onIncrease,
            child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6), 
                child: Icon(Icons.add, color: Colors.white, size: 16)
            ),
          ),
        ],
      ),
    );
  }
}