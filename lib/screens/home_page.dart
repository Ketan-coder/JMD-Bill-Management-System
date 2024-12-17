import 'package:flutter/material.dart';
import 'package:kenan/components/button.dart';
import 'package:kenan/components/text_field.dart';
import 'package:kenan/database/database_service.dart';
import 'package:kenan/screens/add_Bill.dart';
import 'package:kenan/screens/bill_detail.dart';
import 'package:kenan/widgets/bill_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> bills = [];
  List<Map<String, dynamic>> filteredBills = [];
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBills(); // Fetch bills when the page loads
  }

  Future<void> fetchBills() async {
    final fetchedBills = await fetchBillsWithCustomers();
    setState(() {
      bills = fetchedBills;
      filteredBills = fetchedBills; // Initially display all bills
      isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchBillsWithCustomers() async {
    final db = await DatabaseService().database;

    return await db.rawQuery('''
    SELECT 
      bill.id AS bill_id,
      bill.name AS bill_name,
      bill.total_price,
      bill.is_paid AS bill_is_paid,
      bill.created_at,
      customer.name AS customer_name,
      customer.phone_number AS customer_phone
    FROM bill
    INNER JOIN customer ON bill.customer_id = customer.id
    ORDER BY bill.created_at DESC
  ''');
  }

  Future<String> fetchCustomerName(String customerId) async {
    final dbService = DatabaseService();
    try {
      final customer = await dbService.getCustomer(customerId);
      return customer[0]['name'] ?? 'Unknown Customer';
    } catch (e) {
      print("Error fetching customer name: $e");
      return 'Unknown Customer';
    }
  }

  // Filter bills based on criteria
  void filterBills({bool? isPaid, int? minTotal}) {
    setState(() {
      filteredBills = bills.where((bill) {
        if (isPaid != null && bill['is_paid'] != (isPaid ? 0 : 1)) {
          return false;
        }
        if (minTotal != null && bill['total_price'] <= minTotal) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  // Search bills by customer name
  void searchBills(String query) {
    setState(() {
      filteredBills = bills.where((bill) {
        final customerName =
            bill['customer_name']?.toString().toLowerCase() ?? '';
        final billName = bill['bill_name']?.toString().toLowerCase() ?? '';
        final phoneNumber =
            bill['customer_phone']?.toString().toLowerCase() ?? '';
        final createdAt = bill['created_at']?.toString().toLowerCase() ?? '';
        final totalPrice = bill['total_price']?.toString() ?? '';

        final searchQuery = query.toLowerCase();

        return customerName.contains(searchQuery) ||
            billName.contains(searchQuery) ||
            phoneNumber.contains(searchQuery) ||
            createdAt.contains(searchQuery) ||
            totalPrice.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddBillPage(),
            ),
          ).then((_) =>
              fetchBillsWithCustomers()); // Refresh bills after adding a new one
        },
        child: const Icon(Icons.add),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: Theme.of(context).colorScheme.background,
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              snap: false,
              toolbarHeight: 60.0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text("Bills",
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
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: MyTextField(
                          controller: searchController,
                          hintext: 'Search',
                          obscuretext: false,
                          width: 10,
                          height: 10,
                          maxlines: 1,
                        ),
                      ),
                      Expanded(
                        child: MyButton(
                          onPressed: () => searchBills(searchController.text),
                          text: 'Search',
                        ),
                      ),
                    ],
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        MyButton(
                          onPressed: () => filterBills(isPaid: false),
                          text: 'Due Bills',
                        ),
                        MyButton(
                          onPressed: () => filterBills(minTotal: 1000),
                          text: 'Total > 1000',
                        ),
                        MyButton(
                          onPressed: () => filterBills(isPaid: true),
                          text: 'Paid Bills',
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 15.0, vertical: 2.0),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: Text('Customer Name')),
                        Expanded(child: Text('Actions')),
                      ],
                    ),
                  ),
                  // Display dynamic list of bills
                  ...filteredBills.map((bill) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BillDetail(
                              billId: bill['bill_id'],
                            ),
                          ),
                        );
                      },
                      child: BillCard(
                        title:
                            bill['bill_name'] ?? 'No Name', // Handle null name
                        subTitle:
                            '${bill['customer_name']}- Total: ${bill['total_price']}', // Handle null customer name
                        is_paid: bill['bill_is_paid'],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
