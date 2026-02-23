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

    // 2. "ADD" State (Qty is 0)
    if (qty == 0) {
      return InkWell(
        onTap: onAdd,
        child: Container(
          height: double.infinity, width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: const Text(
              "ADD", 
              style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 10,
                  letterSpacing: 0.5
              )
          ),
        ),
      );
    }

    // 3. Counter State (Qty > 0)
    return Container(
      height: double.infinity, width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
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
                child: Icon(Icons.remove, color: Colors.white, size: 12)
            ),
          ),
          Text(
              "$qty", 
              style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 11
              )
          ),
          InkWell(
            onTap: onIncrease,
            child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4), 
                child: Icon(Icons.add, color: Colors.white, size: 12)
            ),
          ),
        ],
      ),
    );
  }
}