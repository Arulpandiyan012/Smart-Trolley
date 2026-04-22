import 'dart:convert';
import 'dart:io';
import 'package:bagisto_app_demo/screens/vendor/stock_management/view/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart'; // 🟢 Use Dio
import 'package:bagisto_app_demo/utils/app_global_data.dart';

class AddProductScreen extends StatefulWidget {
  final String? initialCategoryId;
  final String? initialCategoryName;

  const AddProductScreen({
    Key? key,
    this.initialCategoryId,
    this.initialCategoryName,
  }) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _skuCtrl = TextEditingController();
  
  String? _selectedCategoryId; // Store ID
  String? _selectedCategoryName; // Store Name for display if locked
  String? _selectedFeaturedSection = "None"; 
  String _selectedSellingMethod = "loose"; // 🟢 Default to Loose
  String _selectedUnit = "pcs";
  String _selectedWeight = "1";
  List<String> _currentWeightOptions = ["1"];

  final Map<String, List<String>> _weightOptionsMap = {
    'pcs': ["1", "2", "3", "4", "5", "6", "10", "12", "15", "20", "24", "30", "50", "100"],
    'qty': ["1", "2", "3", "4", "5", "6", "10", "12", "15", "20", "24", "30", "50", "100"],
    'g': ["25", "50", "75", "100", "150", "200", "250", "300", "400", "500", "600", "700", "750", "800", "900", "1000"],
    'kg': ["0.25", "0.5", "0.75", "1.0", "1.25", "1.50", "1.75", "2.00", "2.25", "2.50", "3.0", "5.0", "10.0"],
    'ml': ["10", "20", "25", "30", "40", "50", "75", "100", "150", "200", "250", "300", "400", "500", "750", "1000"],
    'l': ["0.25", "0.50", "0.75", "1.0", "1.25", "1.5", "1.75", "2.0", "2.5", "5.0"]
  };

  void _updateWeightOptions() {
    setState(() {
      _currentWeightOptions = _weightOptionsMap[_selectedUnit] ?? ["1"];
      if (!_currentWeightOptions.contains(_selectedWeight)) {
        _selectedWeight = _currentWeightOptions.first;
      }
    });
  }

  File? _imageFile;
  bool _isLoading = false;

  final String _apiUrl = "https://ecom.thesmartedgetech.com/mobikul-vendor-api.php";

  // Pick Image
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  // Submit
  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an image")));
        return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Convert Image to Base64
      List<int> imageBytes = await _imageFile!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // 2. Prepare Data
      final body = {
        "action": "add_product",
        "name": _nameCtrl.text,
        "price": _priceCtrl.text,
        "qty": _qtyCtrl.text,
        "sku": _skuCtrl.text,
        "description": _descCtrl.text,
        "category_id": _selectedCategoryId ?? "1", // Default to Root if null
        "featured_section": _selectedFeaturedSection ?? "None", // 🟢 Passing Tag for Featured Section
        "weight": _selectedWeight,
        "unit": _selectedUnit,
        "selling_method": _selectedSellingMethod, // 🟢 Pass Selling Method
        "image": base64Image
      };

      // 3. Send Request (Dio)
      final response = await Dio().post(
          _apiUrl,
          data: body,
          options: Options(headers: {"Content-Type": "application/json"})
      );

      final data = response.data; // 🟢 Dio decodes automatically if JSON
      dynamic success, message;
      
      // Handle case where data might be Map or String
      if (data is Map) {
         success = data['success'];
         message = data['message'];
      } else if (data is String) {
         try {
           final decoded = jsonDecode(data);
           success = decoded['success'];
           message = decoded['message'];
         } catch(_) {}
      }

      if (success == true) {
         if(!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Added Successfully! 🎉"), backgroundColor: Colors.green));
         Navigator.pop(context); // Go back to List
      } else {
         throw message ?? "Unknown Error";
      }

    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }
  
  List<Map<String, dynamic>> _categories = []; // 🟢 Local State

  @override
  void initState() {
    super.initState();
    _updateWeightOptions();
    if (widget.initialCategoryId != null) {
      _selectedCategoryName = widget.initialCategoryName;
      _selectedCategoryId = widget.initialCategoryId;
      // We don't necessarily need to fetch all categories if it's locked, but we can to be safe.
    } else {
      _fetchCategories(); // 🟢 Fetch on Init only if not locked
    }
  }

  // Fetch Categories Directly from Vendor API
  Future<void> _fetchCategories() async {
     try {
        final resp = await Dio().post(_apiUrl, data: {"action": "get_categories"});
        if (resp.data['success'] == true) {
           setState(() {
              _categories = List<Map<String, dynamic>>.from(resp.data['data']);
           });
        }
     } catch(e) {
        print("Error fetching categories: $e");
     }
  }

  // Add Category Dialog
  Future<void> _showAddCategoryDialog() async {
    final TextEditingController _catNameCtrl = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Category"),
        content: TextField(
          controller: _catNameCtrl,
          decoration: const InputDecoration(hintText: "Category Name (e.g. Dairy)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                  ElevatedButton(
                    onPressed: () async {
                       if (_catNameCtrl.text.isEmpty) return;
                       Navigator.pop(context); // Close dialog
                       
                       setState(() => _isLoading = true);
                       try {
                          final resp = await Dio().post(_apiUrl, data: {
                            "action": "add_category",
                            "name": _catNameCtrl.text
                          });
                          
                          if (resp.data['success'] == true) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                               content: Text("Category Added! Updating list..."),
                               backgroundColor: Colors.green
                             ));
                             // 🟢 REFRESH LIST INSTANTLY
                             await _fetchCategories();
                          } else {
                             throw resp.data['message'];
                          }
                       } catch(e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red));
                       } finally {
                          setState(() => _isLoading = false);
                       }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                    child: const Text("Add", style: TextStyle(color: Colors.white)),
                  )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? Theme.of(context).appBarTheme.backgroundColor ?? Colors.grey[900] : const Color(0xFF27C16B);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Product',
          style: TextStyle(
            color: Color(0xFF27C16B), 
            fontWeight: FontWeight.w800, 
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF27C16B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 0. Selling Method (NEW)
              const Text("Selling Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Loose / Bulk", style: TextStyle(fontSize: 14)),
                      value: "loose",
                      groupValue: _selectedSellingMethod,
                      onChanged: (v) => setState(() => _selectedSellingMethod = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Packaged", style: TextStyle(fontSize: 14)),
                      value: "packaged",
                      groupValue: _selectedSellingMethod,
                      onChanged: (v) => setState(() => _selectedSellingMethod = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Category Section
              widget.initialCategoryId != null 
                ? // Locked Category UI
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.category, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Category: ${_selectedCategoryName!}",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              const Icon(Icons.lock, color: Colors.grey, size: 16), 
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF27C16B), size: 32),
                        tooltip: "Add New Category",
                        onPressed: _showAddCategoryDialog,
                      )
                    ],
                  )
                : // Dropdown for generic addition
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                          value: _selectedCategoryId,
                          items: _categories.map((c) => DropdownMenuItem(
                            value: c['id'].toString(), 
                            child: Text(
                              c['name']!, 
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            )
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedCategoryId = v),
                          hint: const Text("Select Category"),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF27C16B), size: 32),
                        tooltip: "Add New Category",
                        onPressed: _showAddCategoryDialog,
                      )
                    ],
                  ),
              const SizedBox(height: 20),

              // 2. Product Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder(), hintText: "e.g. Fresh Red Apples"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // 2.B. SKU / Barcode (Scan enabled)
              TextFormField(
                controller: _skuCtrl,
                decoration: InputDecoration(
                  labelText: "SKU / Barcode (Optional)", 
                  border: const OutlineInputBorder(),
                  hintText: "Scan or enter barcode",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF27C16B)),
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (_) => VendorQRScannerScreen(
                            onScan: (code) {
                              setState(() {
                                _skuCtrl.text = code;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 3. Price
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price (₹)", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // 4. Units & Weight Selection
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: _selectedSellingMethod == "loose" ? "Base Unit" : "Pack Unit", 
                        border: const OutlineInputBorder()
                      ),
                      value: _selectedUnit,
                      items: ["pcs", "g", "kg", "ml", "l", "qty"].map((u) => DropdownMenuItem(
                        value: u,
                        child: Text(u),
                      )).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedUnit = v!;
                          _updateWeightOptions();
                        });
                      },
                    ),
                  ),
                  if (_selectedSellingMethod == "packaged") ...[
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "Net Volume per Pack", 
                          border: OutlineInputBorder()
                        ),
                        value: _selectedWeight,
                        items: _currentWeightOptions.map((w) => DropdownMenuItem(
                          value: w,
                          child: Text(w),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedWeight = v!),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // 5. Stock (Dynamic Logic)
              TextFormField(
                controller: _qtyCtrl,
                keyboardType: _selectedSellingMethod == "packaged"
                    ? TextInputType.number
                    : const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _selectedSellingMethod == "loose" 
                      ? "Total Stock (Bulk $_selectedUnit)" 
                      : "Total Stock (Number of Packs)",
                  hintText: _selectedSellingMethod == "packaged" ? "e.g. 50" : "e.g. 10.5",
                  helperText: _selectedSellingMethod == "loose"
                      ? "Enter total bulk inventory (Allows decimals)"
                      : "Enter number of whole packets (Enforces integers)",
                  border: const OutlineInputBorder()
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // 6. Home Page Placement
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: "Home Page Placement (Optional)", border: OutlineInputBorder()),
                value: _selectedFeaturedSection,
                items: ["None", "Sweet Tooth", "Cold Drinks & Juices", "Instant & Frozen Food", "Dry Fruit Masala & Oil"].map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s),
                )).toList(),
                onChanged: (v) => setState(() => _selectedFeaturedSection = v),
              ),
              const SizedBox(height: 16),

              // 7. Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder(), hintText: "Brief details about the product..."),
              ),
              const SizedBox(height: 20),

              // 8. Image Picker (NOW AT BOTTOM)
              const Text("Product Image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                  ),
                  child: _imageFile != null 
                     ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                     : Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: const [
                             Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                             SizedBox(height: 8),
                             Text("Tap to add Image", style: TextStyle(color: Colors.grey))
                         ],
                       ),
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27C16B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Product", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
