import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  final String userRole;
  final String loggedInUser;
  final int userId;
  final String authToken; // Add auth token for authenticated requests

  const CalendarScreen({
    Key? key,
    required this.userRole,
    required this.loggedInUser,
    required this.userId,
    required this.authToken,
  }) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchBookingsForMonth(_focusedDay);
  }

  Future<void> _fetchBookingsForMonth(DateTime month) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);
      
  final String baseUrl = dotenv.get('BASE_URL'); 
      
      final url = Uri.parse(
        '$baseUrl/api/bookings/by-date-range/${widget.userId}?start_date=${DateFormat('yyyy-MM-dd').format(firstDay)}&end_date=${DateFormat('yyyy-MM-dd').format(lastDay)}',
      );

      debugPrint('Fetching bookings from: $url'); // Debug print

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}', // Add auth header
        },
      );

      debugPrint('Response status: ${response.statusCode}'); // Debug print
      debugPrint('Response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bookings = data['bookings'] as List;

        setState(() {
          _events = {};
          for (var booking in bookings) {
            try {
              final date = DateTime.parse(booking['date']).toLocal();
              final dateKey = DateTime.utc(date.year, date.month, date.day);

              _events.putIfAbsent(dateKey, () => []).add({
                'time': booking['time'] ?? 'N/A',
                'client': booking['homeowner']?['name'] ?? 'N/A',
                'service': booking['services']?.map((s) => s['name']).join(', ') ?? 'N/A',
                'gardener': booking['gardener']?['name'] ?? 'N/A',
                'service_provider': booking['service_provider']?['name'] ?? 'N/A',
                'status': booking['status'] ?? 'N/A',
                'address': booking['address'] ?? 'N/A',
                'special_instructions': booking['special_instructions'] ?? '',
              });
            } catch (e) {
              debugPrint('Error processing booking: $e');
            }
          }
        });
      } else {
        throw Exception(
            'Failed to load bookings. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch bookings: ${e.toString()}';
      });
      debugPrint('Error fetching bookings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredEventsForDay(DateTime date) {
    final events = _events[DateTime.utc(date.year, date.month, date.day)] ?? [];
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _fetchBookingsForMonth(focusedDay);
            },
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(formatButtonVisible: false),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: (day) {
              return _getFilteredEventsForDay(day);
            },
          ),
          const SizedBox(height: 16),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: _selectedDay == null
                      ? const Center(
                          child: Text(
                            'Select a date to see events.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : _buildEventList(),
                ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getFilteredEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Text(
          'No bookings for this day',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: events.map((event) => _buildBookingCard(event)).toList(),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> event) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Add onTap functionality if needed
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event['service'],
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event['status']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event['status'].toString().toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(event['status']),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, event['time']),
              if (widget.userRole != 'homeowner')
                _buildDetailRow(Icons.person, 'Client: ${event['client']}'),
              if (widget.userRole == 'homeowner' && event['gardener'] != 'N/A')
                _buildDetailRow(Icons.eco, 'Gardener: ${event['gardener']}'),
              if (widget.userRole == 'homeowner' && event['service_provider'] != 'N/A')
                _buildDetailRow(Icons.business, 'Service Provider: ${event['service_provider']}'),
              _buildDetailRow(Icons.location_on, event['address']),
              if (event['special_instructions'] != null && event['special_instructions'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Special Instructions',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event['special_instructions'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'accepted':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
    }

      
  }