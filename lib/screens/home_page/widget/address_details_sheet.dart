import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'delivery_location_page.dart'; 

enum AddressTag { home, work, hotel }

class AddressDetailsSheet extends StatefulWidget {
  const AddressDetailsSheet({
    super.key,
    this.initialArea,
    this.initialAddressLine,
    this.onChangeLocation,
    this.initialPincode,
    this.initialCity,
    this.initialState,
  });

  final String? initialArea;
  final String? initialAddressLine;
  final String? initialPincode;
  final String? initialCity;
  final String? initialState;
  
  final VoidCallback? onChangeLocation;

  @override
  State<AddressDetailsSheet> createState() => _AddressDetailsSheetState();
}

class _AddressDetailsSheetState extends State<AddressDetailsSheet> {
  AddressTag _tag = AddressTag.home;

  final _flatCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _areaCtrl = TextEditingController(); 
  final _landmarkCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _receiverNameCtrl = TextEditingController(); 
  final _pincodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // 1. AUTO-FILL INITIAL VALUES
    if ((widget.initialArea ?? '').isNotEmpty) {
      _areaCtrl.text = widget.initialArea!;
    }
    
    if ((widget.initialPincode ?? '').isNotEmpty) _pincodeCtrl.text = widget.initialPincode!;
    if ((widget.initialCity ?? '').isNotEmpty) _cityCtrl.text = widget.initialCity!;
    if ((widget.initialState ?? '').isNotEmpty) _stateCtrl.text = widget.initialState!;
  }

  @override
  void dispose() {
    _flatCtrl.dispose(); _floorCtrl.dispose(); _areaCtrl.dispose(); 
    _landmarkCtrl.dispose(); _phoneCtrl.dispose(); _receiverNameCtrl.dispose(); 
    _pincodeCtrl.dispose(); _cityCtrl.dispose(); _stateCtrl.dispose();
    super.dispose();
  }

  // 🟢 2. OPEN MAP & AUTO-FILL DETAILS
  Future<void> _openMapSelection() async {
    if (widget.onChangeLocation != null) {
      Navigator.pop(context);
      widget.onChangeLocation!();
    } 
    else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DeliveryLocationPage()),
      );

      // 🟢 3. UPDATE ALL FIELDS FROM MAP RESULT
      if (result != null && result is Map) {
        setState(() {
          // Auto-fill Area
          _areaCtrl.text = result['address'] ?? "";
          
          // Auto-fill Pincode (Check common keys)
          if (result['pincode'] != null) {
            _pincodeCtrl.text = result['pincode'];
          } else if (result['postalCode'] != null) _pincodeCtrl.text = result['postalCode'];
          
          // Auto-fill City (Check common keys)
          if (result['city'] != null) {
            _cityCtrl.text = result['city'];
          } else if (result['locality'] != null) _cityCtrl.text = result['locality'];

          // Auto-fill State (Check common keys)
          if (result['state'] != null) {
            _stateCtrl.text = result['state'];
          } else if (result['administrativeArea'] != null) _stateCtrl.text = result['administrativeArea'];
        });
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    String full = _receiverNameCtrl.text.trim();
    String fName = full;
    String lName = "User"; 

    if (full.contains(" ")) {
      int idx = full.lastIndexOf(" ");
      fName = full.substring(0, idx);
      lName = full.substring(idx + 1);
    }
    if (lName.isEmpty) lName = "."; 

    Navigator.pop(context, {
      'tag': switch (_tag) {
        AddressTag.home => 'home',
        AddressTag.work => 'work',
        AddressTag.hotel => 'hotel',
      },
      'flatHouseBuilding': _flatCtrl.text.trim(),
      'floor': _floorCtrl.text.trim(),
      'area': _areaCtrl.text.trim(),
      'landmark': _landmarkCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'firstName': fName,
      'lastName': lName,
      'pincode': _pincodeCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim(),
      'country': 'IN', 
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Enter address details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 20),
                
                // TAGS
                Row(children: [
                  _buildTagOption("Home", Icons.home_filled, AddressTag.home),
                  _buildTagOption("Work", Icons.work, AddressTag.work),
                  _buildTagOption("Hotel", Icons.hotel, AddressTag.hotel),
                ]),
                const SizedBox(height: 24),
                
                // HOUSE NO
                _buildTextField(controller: _flatCtrl, label: "House No / Flat / Building", validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
                const SizedBox(height: 16),
                
                // 🟢 AREA FIELD (EDITABLE + MAP BUTTON)
                TextFormField(
                  controller: _areaCtrl,
                  readOnly: false, // 🟢 Allowed Editing
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: "Area / Sector / Locality",
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    floatingLabelStyle: const TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.bold),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    
                    // 🟢 MAP BUTTON (For Auto-fill)
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location, color: Color(0xFF0C831F)),
                      onPressed: _openMapSelection,
                      tooltip: "Pick from Map",
                    ),
                  ),
                  validator: (v) => (v?.isEmpty ?? true) ? 'Area is required' : null,
                ),
                const SizedBox(height: 16),

                // PINCODE & CITY (Auto-filled but Editable)
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _pincodeCtrl, label: "Pincode", inputType: TextInputType.number, validator: (v) => (v?.length != 6) ? 'Invalid' : null)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(controller: _cityCtrl, label: "City", validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // STATE (Auto-filled but Editable)
                _buildTextField(controller: _stateCtrl, label: "State", validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
                const SizedBox(height: 16),

                // LANDMARK
                _buildTextField(controller: _landmarkCtrl, label: "Nearby Landmark (Optional)"),
                const SizedBox(height: 24),
                
                const Text("Receiver's Details", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                
                // NAME
                _buildTextField(
                  controller: _receiverNameCtrl, 
                  label: "Receiver's Name", 
                  validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null
                ),
                const SizedBox(height: 16),
                
                // PHONE
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "Receiver's Phone",
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    prefixText: "+91  ",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  validator: (v) => (v == null || v.length < 10) ? 'Enter 10 digits' : null,
                ),
                const SizedBox(height: 30),
                
                // SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C831F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("Save Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagOption(String label, IconData icon, AddressTag value) {
    bool isSelected = _tag == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tag = value),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF7FFF9) : Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFF0C831F) : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? const Color(0xFF0C831F) : Colors.black87),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF0C831F) : Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, String? Function(String?)? validator, TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      validator: validator,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }
}