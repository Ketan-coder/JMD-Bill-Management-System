import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:kenan/components/button.dart';
import 'package:kenan/components/text_field.dart';

class AddBillPage extends StatefulWidget {
  const AddBillPage({super.key});
  @override
  State<AddBillPage> createState() => AddBillPageState();
}

class AddBillPageState extends State<AddBillPage> {
  Database? database;

  List<String> names = [];
  List<Map<String, TextEditingController>> billItems = [];
  String? selectedValue;
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerNumberController =
      TextEditingController();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController itemUnitPriceController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDatabase();
    addBillItem(); // Add an initial bill item
  }

  Future<void> initializeDatabase() async {
    String path = join(await getDatabasesPath(), 'bill.db');

    database = await openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS customer (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL
          );
        ''');
      },
      version: 1,
    );

    // Populate initial customer data
    await database!.insert(
      'customer',
      {'id': '1', 'name': 'Harishree Chemists'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await database!.insert(
      'customer',
      {'id': '2', 'name': 'Sri Venkateswara Pharma'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await database!.insert(
      'customer',
      {'id': '3', 'name': 'Mahesh Medical'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    final List<Map<String, dynamic>> customers =
        await database!.query('customer');

    setState(() {
      names = customers.map((row) => row['name'] as String).toList();
      selectedValue = names.isNotEmpty ? names.first : null;
    });
  }

  @override
  void dispose() {
    customerNameController.dispose();
    customerNumberController.dispose();
    itemNameController.dispose();
    unitPriceController.dispose();
    quantityController.dispose();
    totalAmountController.dispose();
    super.dispose();
  }

  void addBillItem() {
    setState(() {
      billItems.add({
        'itemName': TextEditingController(),
        'unitPrice': TextEditingController(),
        'quantity': TextEditingController(),
      });
    });
  }

  void removeBillItem(int index) {
    setState(() {
      billItems.removeAt(index);
    });
  }

  String randomInvoiceNumber() {
    // Generate a random invoice number
    return 'INV-${DateTime.now().millisecondsSinceEpoch}';
  }


  Future<void> saveBill() async {
    if (database == null) return;

    final billId = randomInvoiceNumber();
    final customerId = (await database!
            .query('customer', where: 'name = ?', whereArgs: [selectedValue]))
        .first['id'];

    await database!.insert('bill', {
      'id': billId,
      'name': selectedValue,
      'customer_id': customerId,
      'total_price': 0,
      'is_paid': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    int totalBillAmount = 0;

    for (var item in billItems) {
      final itemTotalPrice = int.parse(item['quantity']!.text) *
          int.parse(item['unitPrice']!.text);

      await database!.insert('bill_item', {
        'bill_id': billId,
        'item_name': item['itemName']!.text,
        'quantity': int.parse(item['quantity']!.text),
        'unit_price': int.parse(item['unitPrice']!.text),
        'total_price': itemTotalPrice,
      });

      totalBillAmount += itemTotalPrice;
    }

    await database!.update(
      'bill',
      {'total_price': totalBillAmount},
      where: 'id = ?',
      whereArgs: [billId],
    );

    setState(() {
      billItems.clear();
      addBillItem(); // Reset to one item
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: Theme.of(context).colorScheme.background,
              leading: BackButton(color: Theme.of(context).colorScheme.primary),
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              snap: false,
              toolbarHeight: 60.0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text("Add Bill",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w400,
                    )),
                expandedTitleScale: 2,
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
            child: SingleChildScrollView(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Text(
                    'Customer Name:',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  padding: const EdgeInsets.fromLTRB(18, 5, 18, 5),
                  value: selectedValue,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedValue = newValue!;
                    });
                  },
                  items: names.map<DropdownMenuItem<String>>(
                    (String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    },
                  ).toList(),
                ),
                Divider(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: billItems.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Text('Item ${index + 1}:'),
                        MyTextField(
                          controller: billItems[index]['itemName'],
                          hintext: 'Enter Item name',
                          obscuretext: false,
                          width: 10,
                          height: 10,
                          maxlines: 1,
                        ),
                        MyTextField(
                          controller: billItems[index]['quantity'],
                          hintext: 'Enter Quantity',
                          obscuretext: false,
                          width: 10,
                          height: 10,
                          maxlines: 1,
                        ),
                        MyTextField(
                          controller: billItems[index]['unitPrice'],
                          hintext: 'Enter Unit price',
                          obscuretext: false,
                          width: 10,
                          height: 10,
                          maxlines: 1,
                        ),
                        Divider(),
                        IconButton(
                          onPressed: () => removeBillItem(index),
                          icon: Icon(Icons.delete),
                        ),
                      ],
                    );
                  },
                ),
                ElevatedButton(
                  onPressed: addBillItem,
                  child: Text('Add Item'),
                ),
                Divider(),
                // ElevatedButton(
                //   onPressed: saveBill,
                //   child: Text('Save Bill'),
                // ),
                MyButton(onPressed: saveBill, text: 'Save Bill'),
              ],
            )),
          ),
        ),
      ),
    );
  }
}
