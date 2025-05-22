import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Map<String, String> booking;
  final Function(String) onStatusUpdate;

  const BookingDetailsScreen({
    Key? key,
    required this.booking,
    required this.onStatusUpdate,
  }) : super(key: key);

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late String bookingStatus;

  @override
  void initState() {
    super.initState();
    bookingStatus = widget.booking['status'] ?? 'Pending';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
      case 'Accepted':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Canceled':
      case 'Cancelled':
        return Colors.red;
      case 'Completed':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Booking Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green[800],
        centerTitle: true,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Booking ID
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[100]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number, color: Colors.green),
                  const SizedBox(width: 10),
                  Text(
                    'Booking #${widget.booking['id']}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Details Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.grey.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Text(
                      'Booking Information',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const Divider(height: 24, thickness: 1),
                    
                    // Detail Items
                    _buildDetailItem(
                      icon: Icons.person,
                      title: 'Homeowner',
                      value: widget.booking['name'] ?? 'N/A',
                    ),
                    _buildDetailItem(
                      icon: Icons.location_on,
                      title: 'Address',
                      value: widget.booking['address'] ?? 'N/A',
                      isMultiline: true,
                    ),
                    _buildDetailItem(
                      icon: Icons.calendar_today,
                      title: 'Date',
                      value: widget.booking['date'] ?? 'N/A',
                    ),
                    _buildDetailItem(
                      icon: Icons.access_time,
                      title: 'Time',
                      value: widget.booking['time'] ?? 'N/A',
                    ),
                    _buildDetailItem(
                      icon: Icons.local_offer,
                      title: 'Service',
                      value: widget.booking['service_names'] ?? 'N/A',
                      isMultiline: true,
                    ),
                    _buildDetailItem(
                      icon: Icons.attach_money,
                      title: 'Total Price',
                      value: widget.booking['total_price'] ?? 'N/A',
                    ),
                    
                    const Divider(height: 24, thickness: 1),
                    
                    // Status Item
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Text(
                          'Status: ',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(bookingStatus),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            bookingStatus,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons (example - can be customized)
            if (bookingStatus == 'Pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          bookingStatus = 'Accepted';
                        });
                        widget.onStatusUpdate(bookingStatus);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Accept Booking',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          bookingStatus = 'Cancelled';
                        });
                        widget.onStatusUpdate(bookingStatus);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Decline',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.green, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.65,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  maxLines: isMultiline ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}