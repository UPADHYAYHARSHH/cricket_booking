import 'dart:io';

void main() {
  final myBookingFile = File(r'e:\rutvik\projects\box_cricket\booking_app\lib\user_booking\presentation\screens\my_booking\my_booking_screen.dart');
  String myBooking = myBookingFile.readAsStringSync();

  myBooking = myBooking.replaceAll(
    r'''value: "₹${(widget.ticket.price - (widget.ticket.platformFee > 0 ? widget.ticket.platformFee : 30.0)).clamp(0.0, widget.ticket.price).toStringAsFixed(0)}",''',
    r'''value: "₹${(widget.ticket.price - widget.ticket.platformFee).clamp(0.0, widget.ticket.price).toStringAsFixed(0)}",'''
  );

  myBooking = myBooking.replaceAll(
    r'''value: "+ ₹${(widget.ticket.platformFee > 0 ? widget.ticket.platformFee : 30.0).toStringAsFixed(0)}",''',
    r'''value: "+ ₹${widget.ticket.platformFee.toStringAsFixed(0)}",'''
  );

  myBookingFile.writeAsStringSync(myBooking);
  print('Updated my_booking_screen.dart to use widget.ticket.platformFee directly!');
}
