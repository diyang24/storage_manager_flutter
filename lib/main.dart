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
      theme: ThemeData(primarySwatch: Colors.blue),
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
              item['location'].toLowerCase().contains(query);
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
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Item Name"),
            ),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity"),
            ),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: "Location"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (index == null) {
                  await DatabaseHelper.insertItem(
                    _nameCtrl.text,
                    int.tryParse(_qtyCtrl.text) ?? 0,
                    _locationCtrl.text,
                  );
                } else {
                  await DatabaseHelper.updateItem(
                    index,
                    _nameCtrl.text,
                    int.tryParse(_qtyCtrl.text) ?? 0,
                    _locationCtrl.text,
                  );
                }
                _nameCtrl.clear();
                _qtyCtrl.clear();
                _locationCtrl.clear();
                Navigator.of(context).pop();
                _refreshItems();
              },
              child: Text(index == null ? "Add Item" : "Update Item"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Storage Manager")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search items...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(child: Text("No items yet"))
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return Card(
                        child: ListTile(
                          title: Text(item['name']),
                          subtitle: Text(
                            "Qty: ${item['quantity']} • Location: ${item['location']}",
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
                                onPressed: () async {
                                  await DatabaseHelper.deleteItem(index);
                                  _refreshItems();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
