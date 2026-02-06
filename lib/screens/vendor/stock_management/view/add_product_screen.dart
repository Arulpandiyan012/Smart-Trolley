import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart'; // 🟢 Use Dio
import 'package:bagisto_app_demo/utils/app_global_data.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  
  String? _selectedCategoryId; // Store ID
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
        "description": _descCtrl.text,
        "category_id": _selectedCategoryId ?? "1", // Default to Root if null
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
  
  // Extract Categories from GlobalData to simple list
  List<Map<String, String>> _getCategoryOptions() {
      final List<Map<String, String>> options = [];
      try {
         final cats = GlobalData.categoriesDrawerData?.data ?? [];
         for(var c in cats) {
            String name = c.name ?? "Cat";
            String id = c.id ?? "0";
            options.add({"id": id, "name": name});
            // Children
            if (c.children != null) {
               for (var child in c.children!) {
                   options.add({"id": child.id ?? "0", "name": "-- ${child.name}"});
               }
            }
         }
      } catch (_) {}
      return options;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getCategoryOptions();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Product"),
        backgroundColor: const Color(0xFF27C16B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
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
              const SizedBox(height: 20),

              // Fields
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                   Expanded(
                     child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Price (₹)", border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: TextFormField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Stock Qty", border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                   ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                isExpanded: true, // 🟢 Fix Overflow
                decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                value: _selectedCategoryId,
                items: categories.map((c) => DropdownMenuItem(
                  value: c['id'], 
                  child: Text(
                    c['name']!, 
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                )).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                hint: const Text("Select Category"),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
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
