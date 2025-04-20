import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:gardencare_app/providers/booking_provider.dart';
import 'package:gardencare_app/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingForm extends StatefulWidget {
  @override
  _BookingFormState createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();

  String? selectedType;
  int? selectedGardenerId;
  int? selectedServiceProviderId;
  String address = "";
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? specialInstructions;
  bool _isLoading = false;

  List<int> selectedServiceIds = [];
  double totalPrice = 0.0;

  List<Map<String, dynamic>> gardeners = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> serviceProviders = [];

  

  @override
  void initState() {
    super.initState();
    _loadData();
  }
     // Initialize PusherService
 

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      fetchGardeners(),
      fetchServices(),
      fetchServiceProviders(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> fetchGardeners() async {
    try {
    final baseUrl = dotenv.get('BASE_URL'); 
      final response = await http.get(
        Uri.parse('$baseUrl/api/gardeners'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          gardeners = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        _showError("Failed to load gardeners");
      }
    } catch (e) {
      _showError("Network error: ${e.toString()}");
    }
  }
  
  Future<void> fetchServices() async {
    try {
    final baseUrl = dotenv.get('BASE_URL'); 
      final response = await http.get(
        Uri.parse('$baseUrl/api/services'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          services = List<Map<String, dynamic>>.from(jsonDecode(response.body)["services"]);
        });
      } else {
        _showError("Failed to load services");
      }
    } catch (e) {
      _showError("Network error: ${e.toString()}");
    }
  }

  Future<void> fetchServiceProviders() async {
    try {
    final baseUrl = dotenv.get('BASE_URL'); 
      final response = await http.get(
        Uri.parse('$baseUrl/api/service_providers'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          serviceProviders = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        _showError("Failed to load service providers");
      }
    } catch (e) {
      _showError("Network error: ${e.toString()}");
    }
  }

  List<Map<String, dynamic>> getFilteredServices() {
    if (selectedType == "Gardening") {
      return services.where((service) => service["type"] == "Gardening").toList();
    } else if (selectedType == "Landscaping") {
      return services.where((service) => service["type"] == "Landscaping").toList();
    }
    return [];
  }

  void updateTotalPrice() {
    double sum = 0.0;
    for (var service in services) {
      if (selectedServiceIds.contains(service["id"])) {
        sum += double.tryParse(service["price"].toString()) ?? 0.0;
      }
    }
    setState(() => totalPrice = sum);
  }

  Future<void> submitBooking() async {  
  if (!_formKey.currentState!.validate()) return;
  _formKey.currentState!.save();

  setState(() => _isLoading = true);

  try {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final int? homeownerId = userProvider.homeownerId;

    if (homeownerId == null) {
      _showError("Please login to book services");
      return;
    }
   final formattedTime = 
        "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";

    final Map<String, dynamic> payload = {
      "type": selectedType,
      "homeowner_id": homeownerId,
      "service_ids": selectedServiceIds,
      "address": address,
      "date": selectedDate!.toIso8601String(),
      "time": formattedTime,
      "total_price": totalPrice,
      "special_instructions": specialInstructions ?? "",
    };

    if (selectedType == "Gardening") {
      payload["gardener_id"] = selectedGardenerId;
    } else if (selectedType == "Landscaping") {
      payload["serviceprovider_id"] = selectedServiceProviderId;
    }
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = dotenv.get('BASE_URL');
    final token = prefs.getString('token') ?? '';
    final response = await http.post(
      Uri.parse('$baseUrl/api/create_booking'),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer ${token}",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      _handleSuccessfulBooking(payload);
    } else {
      _showError("Booking failed: ${response.body}");
    }
  } catch (e) {
    _showError("Error: ${e.toString()}");
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _handleSuccessfulBooking(Map<String, dynamic> bookingData) {
    // Update local state
    Provider.of<BookingProvider>(context, listen: false).addBooking(bookingData);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Booking Created Successfully!"),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate to bookings screen
    Navigator.pushNamed(context, '/bookings');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Booking Form")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Book Service"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildServiceTypeDropdown(),
                if (selectedType == "Gardening") _buildGardenerDropdown(),
                if (selectedType == "Landscaping") _buildServiceProviderDropdown(),
                if (selectedType != null) _buildServiceSelection(),
                if (selectedType != null) _buildTotalPrice(),
                _buildAddressField(),
                _buildDatePicker(),
                _buildTimePicker(),
                _buildSpecialInstructions(),
                SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedType,
      onChanged: (value) {
        setState(() {
          selectedType = value;
          selectedServiceIds = [];
          totalPrice = 0.0;
        });
      },
      items: ["Gardening", "Landscaping"]
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ))
          .toList(),
      decoration: InputDecoration(
        labelText: "Service Type",
        border: OutlineInputBorder(),
      ),
      validator: (value) => value == null ? "Please select service type" : null,
    );
  }

  Widget _buildGardenerDropdown() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DropdownButtonFormField<int>(
        value: selectedGardenerId,
        onChanged: (value) => setState(() => selectedGardenerId = value),
        items: gardeners.map((gardener) {
          return DropdownMenuItem<int>(
            value: gardener["id"],
            child: Text(gardener["name"]),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: "Select Gardener",
          border: OutlineInputBorder(),
        ),
        validator: (value) => value == null ? "Please select a gardener" : null,
      ),
    );
  }

  Widget _buildServiceProviderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DropdownButtonFormField<int>(
        value: selectedServiceProviderId,
        onChanged: (value) => setState(() => selectedServiceProviderId = value),
        items: serviceProviders.map((provider) {
          return DropdownMenuItem<int>(
            value: provider["id"],
            child: Text(provider["name"]),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: "Select Service Provider",
          border: OutlineInputBorder(),
        ),
        validator: (value) => value == null ? "Please select a provider" : null,
      ),
    );
  }

  Widget _buildServiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            "Select Services:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ...getFilteredServices().map((service) {
          return CheckboxListTile(
            title: Text("${service['name']} (₱${service['price']})"),
            value: selectedServiceIds.contains(service['id']),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedServiceIds.add(service['id']);
                } else {
                  selectedServiceIds.remove(service['id']);
                }
                updateTotalPrice();
              });
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTotalPrice() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        "Total Price: ₱${totalPrice.toStringAsFixed(2)}",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAddressField() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: "Address",
          border: OutlineInputBorder(),
        ),
        validator: (value) => value!.isEmpty ? "Please enter address" : null,
        onSaved: (value) => address = value!,
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(Duration(days: 365)),
          );
          if (picked != null) setState(() => selectedDate = picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "Date",
            border: OutlineInputBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedDate == null
                    ? "Select date"
                    : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
              ),
              Icon(Icons.calendar_today),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: InkWell(
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (picked != null) setState(() => selectedTime = picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "Time",
            border: OutlineInputBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedTime == null
                    ? "Select time"
                    : selectedTime!.format(context),
              ),
              Icon(Icons.access_time),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialInstructions() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: "Special Instructions (Optional)",
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        onSaved: (value) => specialInstructions = value,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : submitBooking,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text(
              "CONFIRM BOOKING",
              style: TextStyle(fontSize: 16),
            ),
    );
  }
}