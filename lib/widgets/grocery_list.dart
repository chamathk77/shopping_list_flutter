import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_flutter/data/categories.dart';

import 'package:shopping_list_flutter/models/grocery_item.dart';
import 'package:shopping_list_flutter/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? error = null;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final url = Uri.https(
      'flutter-prep-58e77-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );
    final response = await http.get(url);

    print(response.statusCode);

    if (response.statusCode >= 400) {
      setState(() {
        _isLoading = false;
        error = 'Could not fetch items. Please try again later.';
      });
      return;
    }

    if (response.body == 'null') {
      setState(() {
        _groceryItems = [];
      });
      return;
    }

    final Map<String, dynamic> listdata = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];

    for (final item in listdata.entries) {
      final category = categories.entries.firstWhere(
        (element) => element.value.name == item.value['category'],
        // Provide a default category
      );

      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category.value,
        ),
      );
    }

    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
  }

  Future<void> _addNewItem() async {
    final newItem = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });

    // _loadItems();
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    final url = Uri.https(
      'flutter-prep-58e77-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );
    setState(() {
      _groceryItems.remove(item);
    });

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        // _isLoading = false;
        // error = 'Could not delete item. Please try again later.';
        _groceryItems.insert(index, item);
      });
      return;
    }
  }

  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet!'),
    );

    if (error != null) {
      content = Center(
        child: Text(error!),
      );
    }

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemBuilder: (context, index) => Dismissible(
          onDismissed: (direction) => {
            _removeItem(_groceryItems[index]),
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
        itemCount: _groceryItems.length,
      );
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(icon: const Icon(Icons.add), onPressed: _addNewItem)
          ],
        ),
        body: content);
  }
}
