import 'package:flutter/material.dart';
import 'db_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Storage Manager",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          secondary: Colors.teal,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        useMaterial3: true,
      ),
      home: const StoragePage(),
    );
  }
}

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  List<Map> _items = [];
  List<Map> _filteredItems = [];
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String _selectedCategory = "Others";
  final List<String> _categories = ["Food", "Electronics", "Clothes", "Others"];

  @override
  void initState() {
    super.initState();
    _refreshItems();
    _searchCtrl.addListener(_filterItems);
  }

  void _refreshItems() {
    final data = DatabaseHelper.getItems();
    setState(() {
      _items = data;
      _filteredItems = data;
    });
  }

  void _filterItems() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _items;
      } else {
        _filteredItems = _items.where((item) {
          return item['name'].toLowerCase().contains(query) ||
              item['location'].toLowerCase().contains(query) ||
              item['category'].toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _showForm(int? index) {
    if (index != null) {
      final existing = _items[index];
      _nameCtrl.text = existing['name'];
      _qtyCtrl.text = existing['quantity'].toString();
      _locationCtrl.text = existing['location'];
      _selectedCategory = existing['category'];
    } else {
      _nameCtrl.clear();
      _qtyCtrl.clear();
      _locationCtrl.clear();
      _selectedCategory = "Others";
    }

    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              index == null ? "➕ Add New Item" : "✏️ Update Item",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantity",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: "Location",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              value: _selectedCategory,
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value.toString());
              },
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                if (_nameCtrl.text.isEmpty || _qtyCtrl.text.isEmpty) return;
                if (index == null) {
                  await DatabaseHelper.insertItem(
                    _nameCtrl.text,
                    int.tryParse(_qtyCtrl.text) ?? 0,
                    _locationCtrl.text,
                    _selectedCategory,
                  );
                } else {
                  await DatabaseHelper.updateItem(
                    index,
                    _nameCtrl.text,
                    int.tryParse(_qtyCtrl.text) ?? 0,
                    _locationCtrl.text,
                    _selectedCategory,
                  );
                }
                Navigator.of(context).pop();
                _refreshItems();
              },
              icon: const Icon(Icons.save),
              label: Text(index == null ? "Add Item" : "Update Item"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _items.length;
    final lowStock = _items.where((i) => i['quantity'] <= 5).length;
    final categories = _items.map((i) => i['category']).toSet().length;

    return Scaffold(
      appBar: AppBar(title: const Text("📦 Storage Manager")),
      body: Column(
        children: [
          // Dashboard
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDashboardCard(
                  "Total Items",
                  totalItems.toString(),
                  Icons.inventory,
                  Colors.indigo,
                ),
                _buildDashboardCard(
                  "Low Stock",
                  lowStock.toString(),
                  Icons.warning,
                  Colors.red,
                ),
                _buildDashboardCard(
                  "Categories",
                  categories.toString(),
                  Icons.category,
                  Colors.teal,
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search items...",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Item List
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      "No items yet. Add one using the ➕ button.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal[100],
                            child: const Icon(
                              Icons.inventory,
                              color: Colors.indigo,
                            ),
                          ),
                          title: Text(
                            item['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            "Qty: ${item['quantity']} • ${item['category']} • Location: ${item['location']}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                onPressed: () => _showForm(index),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Delete Item"),
                                      content: const Text(
                                        "Are you sure you want to delete this item? This action cannot be undone.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () async {
                                            await DatabaseHelper.deleteItem(
                                              index,
                                            );
                                            Navigator.of(context).pop();
                                            _refreshItems();
                                          },
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(null),
        icon: const Icon(Icons.add),
        label: const Text("Add Item"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDashboardCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(title, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}
