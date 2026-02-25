import 'package:flutter/material.dart';

class SmartAddButton extends StatelessWidget {
  final int qty;
  final bool isLoading;
  final VoidCallback onAdd;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const SmartAddButton({
    Key? key,
    required this.qty,
    this.isLoading = false,
    required this.onAdd,
    required this.onIncrease,
    required this.onDecrease,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Loading State
    if (isLoading) {
      return Container(
        height: double.infinity, width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const SizedBox(
            height: 14, 
            width: 14, 
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
        ),
      );
    }

    // 2. "+" Icon State (Qty is 0)
    if (qty == 0) {
      return InkWell(
        onTap: onAdd,
        child: Container(
          height: double.infinity, width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF27C16B)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: const Icon(
              Icons.add, 
              color: Color(0xFF27C16B), 
              size: 18,
          ),
        ),
      );
    }

    // 3. Counter State (Qty > 0)
    return Container(
      height: double.infinity, width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF27C16B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: onDecrease,
            child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4), 
                child: Icon(Icons.remove, color: Color(0xFF27C16B), size: 14)
            ),
          ),
          Text(
              "$qty", 
              style: const TextStyle(
                  color: Color(0xFF27C16B), 
                  fontWeight: FontWeight.bold, 
                  fontSize: 11
              )
          ),
          InkWell(
            onTap: onIncrease,
            child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4), 
                child: Icon(Icons.add, color: Color(0xFF27C16B), size: 14)
            ),
          ),
        ],
      ),
    );
  }
}