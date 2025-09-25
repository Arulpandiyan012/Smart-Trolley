import 'package:flutter/material.dart';

enum OrderingFor { myself, someone }
enum AddressTag { home, work, hotel }

class AddressDetailsSheet extends StatefulWidget {
  const AddressDetailsSheet({
    Key? key,
    this.initialArea,
    this.initialAddressLine,
    this.onChangeLocation,
  }) : super(key: key);

  final String? initialArea;
  final String? initialAddressLine;
  final VoidCallback? onChangeLocation;

  @override
  State<AddressDetailsSheet> createState() => _AddressDetailsSheetState();
}

class _AddressDetailsSheetState extends State<AddressDetailsSheet> {

Widget _buildTagChip({
  required String label,
  required IconData icon,
  required AddressTag value,
}) {
  final bool isSelected = _tag == value;

  return ChoiceChip(
    label: Text(
      label,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 10,          // smaller text
        fontWeight: FontWeight.w500,
      ),
    ),
    avatar: Icon(
      icon,
      size: 14,               // smaller icon
      color: Colors.black,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ), // smaller padding
    backgroundColor: Colors.white,
    selectedColor: Colors.green.withOpacity(0.2),
    side: BorderSide(
      color: isSelected ? Colors.green : Colors.grey,
      width: 1,
    ),
    showCheckmark: false,
    selected: isSelected,
    onSelected: (_) => setState(() => _tag = value),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact, // tighter spacing
  );
}



  OrderingFor _orderingFor = OrderingFor.myself;
  AddressTag? _tag = AddressTag.home;

  final _flatCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if ((widget.initialArea ?? '').isNotEmpty) {
      _areaCtrl.text = widget.initialArea!;
    }
  }

  @override
  void dispose() {
    _flatCtrl.dispose();
    _floorCtrl.dispose();
    _areaCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, {
      'orderingFor': _orderingFor == OrderingFor.myself ? 'myself' : 'someone_else',
      'tag': switch (_tag) {
        AddressTag.home => 'home',
        AddressTag.work => 'work',
        AddressTag.hotel => 'hotel',
        _ => null,
      },
      'flatHouseBuilding': _flatCtrl.text.trim(),
      'floor': _floorCtrl.text.trim(),
      'area': _areaCtrl.text.trim(),
      'landmark': _landmarkCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        );

    return SafeArea(
      top: false,
      child: Material( // ensure white background sheet
        color: Colors.white,
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Enter complete address', style: titleStyle),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Who are ordering for?
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Who are ordering for ?',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<OrderingFor>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Myself'),
                        value: OrderingFor.myself,
                        groupValue: _orderingFor,
                        activeColor: Colors.green,
                        onChanged: (v) => setState(() => _orderingFor = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<OrderingFor>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Someone else'),
                        value: OrderingFor.someone,
                        groupValue: _orderingFor,
                        activeColor: Colors.green,
                        onChanged: (v) => setState(() => _orderingFor = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Save address as
Align(
  alignment: Alignment.centerLeft, // ⬅️ hard-left container
  child: Wrap(
    alignment: WrapAlignment.start,        // ⬅️ left on the main axis
    runAlignment: WrapAlignment.start,     // ⬅️ left on wrapped lines
    crossAxisAlignment: WrapCrossAlignment.start,
    spacing: 8,
    runSpacing: 4,
    children: [
      _buildTagChip(label: 'Home',  icon: Icons.home_outlined,  value: AddressTag.home),
      _buildTagChip(label: 'Work',  icon: Icons.work_outline,   value: AddressTag.work),
      _buildTagChip(label: 'Hotel', icon: Icons.hotel_outlined, value: AddressTag.hotel),
    ],
  ),
),




                const SizedBox(height: 16),

               // 1) Flat/House/Building (required)
TextFormField(
  controller: _flatCtrl,
  decoration: InputDecoration(
    labelText: 'Flat/House No/Building name',
    isDense: true,
    // default + enabled state
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    // focused state
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey, width: 2), // keep grey on focus
    ),
    // error state (optional)
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
  ),
  validator: (v) => (v == null || v.trim().isEmpty)
      ? 'Please enter address line'
      : null,
),
const SizedBox(height: 12),

// 2) Floor (optional)
TextField(
  controller: _floorCtrl,
  decoration: InputDecoration(
    labelText: 'Floor (optional)',
    isDense: true,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey, width: 2),
    ),
  ),
),
const SizedBox(height: 12),

// Area/Sector/Locality with inline "Change"
TextFormField(
  controller: _areaCtrl,                   // prefilled from widget.initialArea
  readOnly: true,                          // user changes via "Change"
  decoration: InputDecoration(
    labelText: 'Area/Sector/Locality',
    isDense: true,
    filled: true,
    fillColor: Colors.grey[200],           // ✅ grey background
    // grey outlines always
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey, width: 1.2),
    ),
    // Inline "Change" button
    suffixIcon: Padding(
      padding: const EdgeInsets.only(right: 6),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,           // ✅ white background
          foregroundColor: Colors.green,           // ✅ green text
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
          widget.onChangeLocation?.call();
        },
        child: const Text(
          'Change',
          style: TextStyle(fontWeight: FontWeight.w600,fontSize:8),
        ),
      ),
    ),
    suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
  ),
  validator: (v) =>
      (v == null || v.trim().isEmpty) ? 'Please enter area/locality' : null,
  onTap: () {
    Navigator.pop(context);
    widget.onChangeLocation?.call();
  },
),



                const SizedBox(height: 12),

                // Landmark (optional)
                TextField(
                  controller: _landmarkCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nearby landmark (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                     enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Save button (green) + yellow icon
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,      // ✅ green button
                      foregroundColor: Colors.white,      // text color
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _save,
                    icon: const Icon(Icons.save, color: Colors.yellow), // ✅ yellow icon
                    label: const Text('Save address'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
