import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kenan/database/database_service.dart';

class BillDetail extends StatefulWidget {
  final String billId;

  const BillDetail({Key? key, required this.billId}) : super(key: key);

  @override
  _BillDetailState createState() => _BillDetailState();
}

class _BillDetailState extends State<BillDetail> {
  bool _isLoading = true;
  Map<String, dynamic>? _billDetails;
  Map<String, dynamic>? _customerDetails;
  late DatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _fetchBillDetails();
  }

  Future<void> _fetchBillDetails() async {
    try {
      // Fetch bill details
      final billData = await _databaseService.fetchBillDetails(widget.billId);

      if (billData.isNotEmpty) {
        // Fetch associated customer details
        final customerData = await _databaseService
            .fetchCustomerDetails(billData['customer_id']);

        setState(() {
          _billDetails = billData;
          _customerDetails = customerData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching bill details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAndSavePDF() async {
    try {
      final pdf = pw.Document();

      // Load the font
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Invoice Details',
                  style: pw.TextStyle(
                      font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('Invoice ID: ${_billDetails?['id'] ?? 'Unknown'}',
                  style: pw.TextStyle(font: ttf)),
              pw.Text('Customer: ${_customerDetails?['name'] ?? 'Unknown'}',
                  style: pw.TextStyle(font: ttf)),
              pw.Text(
                  'Customer Number: ${_customerDetails?['phone_number'] ?? 'XXXXXXXXXX'}',
                  style: pw.TextStyle(font: ttf)),
              pw.Text(
                  'Total Amount: \$${_billDetails?['total_price']?.toStringAsFixed(2) ?? '0.00'}',
                  style: pw.TextStyle(font: ttf)),
            ],
          ),
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/invoice_${_billDetails?['id'] ?? 'unknown'}.pdf');
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved at ${file.path}')),
      );

      await OpenFile.open(file.path);
    } catch (e) {
      print('Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF: $e')),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  List<Widget> _buildItemList(List<dynamic> items) {
    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item['item_name'], style: TextStyle(fontSize: 16)),
            Text('Qty: ${item['quantity']}', style: TextStyle(fontSize: 16)),
            Text('Total: \$${item['total_price']}',
                style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      persistentFooterButtons: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.lightBlue, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: _generateAndSavePDF,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.lightBlue,
                    width: 2,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _billDetails?['is_paid'] == 0
                        ? Icons.check_circle_outline // Paid Icon
                        : Icons.payments, // Unpaid Icon
                    color: _billDetails?['is_paid'] == 0
                        ? Colors.green // Green for paid
                        : Colors.blue, // Blue for unpaid
                  ),
                  onPressed: () async {
                    // Toggle paid status
                    final newPaidStatus = _billDetails?['is_paid'] == 0 ? 1 : 0;

                    try {
                      await _databaseService.updateBill(
                        {'is_paid': newPaidStatus},
                        widget.billId,
                      );

                      setState(() {
                        _billDetails?['is_paid'] = newPaidStatus;
                      });

                      // Optional: Show a SnackBar to confirm the action
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            newPaidStatus == 0
                                ? 'Bill marked as Paid'
                                : 'Bill marked as Not Paid',
                          ),
                          backgroundColor:
                              newPaidStatus == 0 ? Colors.green : Colors.orange,
                        ),
                      );
                    } catch (e) {
                      print('Error updating bill status: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to update bill status'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: IconButton(
                onPressed: () async {
                  await _databaseService.deleteBill(widget.billId);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Bill Deleted'),
                    backgroundColor: Colors.red,
                  ));
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_forever_rounded),
              ),
            )),
          ],
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _billDetails == null || _customerDetails == null
              ? const Center(child: Text('No Bill or Customer Found'))
              : NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, innerBoxIsScrolled) {
                    return <Widget>[
                      SliverAppBar(
                        backgroundColor:
                            Theme.of(context).colorScheme.background,
                        centerTitle: true,
                        expandedHeight: 250.0,
                        floating: false,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text(
                            _customerDetails?['name'] ?? 'Customer',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              fontSize: 20.0,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ];
                  },
                  body: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Theme.of(context).colorScheme.shadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildDetailRow('Invoice Id',
                                  _billDetails?['id'] ?? 'Unknown'),
                              _buildDetailRow('Customer',
                                  _customerDetails?['name'] ?? 'Unknown'),
                              _buildDetailRow(
                                  'Customer Number',
                                  _customerDetails?['phone_number'] ??
                                      'XXXXXXXXXX'),
                              _buildDetailRow(
                                  'Total Amount',
                                  _billDetails?['total_price']?.toString() ??
                                      '0.00'),
                              const SizedBox(height: 20),
                              const Text('Items:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              ..._buildItemList(_billDetails?['items'] ?? []),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
