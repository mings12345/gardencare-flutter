import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:gardencare_app/providers/booking_provider.dart'; 

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

  List<int> selectedServiceIds = [];
  double totalPrice = 0.0;

  List<Map<String, dynamic>> gardeners = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> serviceProviders = [];

  @override
  void initState() {
    super.initState();
    fetchGardeners();
    fetchServices();
    fetchServiceProviders();
  }

  Future<void> fetchGardeners() async {
    try {
      final response = await http.get(
        Uri.parse('https://devjeffrey.dreamhosters.com/gardeners'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          gardeners = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      }
    } catch (e) {
      print("Error fetching gardeners: $e");
    }
  }

  Future<void> fetchServices() async {
    try {
      final response = await http.get(
        Uri.parse('https://devjeffrey.dreamhosters.com/api/services'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          services = List<Map<String, dynamic>>.from(data["services"]);
        });
      }
    } catch (e) {
      print("Error fetching services: $e");
    }
  }

  Future<void> fetchServiceProviders() async {
    try {
      final response = await http.get(
        Uri.parse('https://devjeffrey.dreamhosters.com/api/service_providers'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          serviceProviders = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      }
    } catch (e) {
      print("Error fetching service providers: $e");
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
    setState(() {
      totalPrice = sum;
    });
  }

  Future<void> submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final Map<String, dynamic> payload = {
      "type": selectedType,
      "homeowner_id": 2,
      "service_ids": selectedServiceIds,
      "address": address,
      "date": selectedDate!.toIso8601String(),
      "time": "${selectedTime!.hour}:${selectedTime!.minute}",
      "total_price": totalPrice,
      "special_instructions": specialInstructions ?? "",
    };

    if (selectedType == "Gardening") {
      payload["gardener_id"] = selectedGardenerId;
    } else if (selectedType == "Landscaping") {
      payload["serviceprovider_id"] = selectedServiceProviderId;
    }

    final response = await http.post(
      Uri.parse('https://devjeffrey.dreamhosters.com/api/create_booking'),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer YOUR_ACCESS_TOKEN",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking Created Successfully!")),
      );
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      bookingProvider.addBooking(payload);
      // Navigate to BookingsScreen with booking details
      Navigator.pushNamed(
        context,
        '/bookings',
        arguments: payload, // Pass the payload as arguments
      );
    } else {
      print("Booking Failed: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking Failed: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Book Service"),
        backgroundColor: Colors.green, // Gardening theme color
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  onChanged: (value) => setState(() => selectedType = value),
                  items: ["Gardening", "Landscaping"]
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  decoration: InputDecoration(
                    labelText: "Service Type",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (value) => value == null ? "Select service type" : null,
                ),

                if (selectedType == "Gardening") ...[
                  SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    value: selectedGardenerId,
                    onChanged: (value) => setState(() => selectedGardenerId = value),
                    items: gardeners.map<DropdownMenuItem<int>>((gardener) {
                      return DropdownMenuItem<int>(
                        value: gardener["id"],
                        child: Text(gardener["name"]),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: "Select Gardener",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    validator: (value) => value == null ? "Select a gardener" : null,
                  ),
                ],

                if (selectedType == "Landscaping") ...[
                  SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    value: selectedServiceProviderId,
                    onChanged: (value) => setState(() => selectedServiceProviderId = value),
                    items: serviceProviders.map<DropdownMenuItem<int>>((provider) {
                      return DropdownMenuItem<int>(
                        value: provider["id"],
                        child: Text(provider["name"]),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: "Select Service Provider",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    validator: (value) => value == null ? "Select a service provider" : null,
                  ),
                ],

                if (selectedType != null) ...[
                  SizedBox(height: 20),
                  Text("Select Services:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Wrap(
                    children: getFilteredServices().map((service) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: CheckboxListTile(
                          title: Text("${service['name']} (₱${service['price']})"), // Updated to ₱
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
                        ),
                      );
                    }).toList(),
                  ),
                ],

                if (selectedType != null) ...[
                  SizedBox(height: 20),
                  Text("Total Price: ₱${totalPrice.toStringAsFixed(2)}", // Updated to ₱
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],

                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Address",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onSaved: (value) => address = value!,
                  validator: (value) => value!.isEmpty ? "Enter address" : null,
                ),

                SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: Text(selectedDate == null
                        ? "Select Date"
                        : "${selectedDate!.toLocal()}".split(' ')[0]),
                    trailing: Icon(Icons.calendar_today, color: Colors.green),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null) setState(() => selectedDate = pickedDate);
                    },
                  ),
                ),

                SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: Text(selectedTime == null
                        ? "Select Time"
                        : "${selectedTime!.format(context)}"),
                    trailing: Icon(Icons.access_time, color: Colors.green),
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() => selectedTime = pickedTime);
                      }
                    },
                  ),
                ),

                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Special Instructions (Optional)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onSaved: (value) => specialInstructions = value,
                ),

                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: submitBooking,
                  child: Text("Submit Booking"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
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